/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#ifdef _NVCC
extern int CUDA_DEVICE;
#endif

#include "affinity.h"
#include "cli.h"
#include "kernels.h"
#include "profiler.h"
#include "util.h"

static void check(double *, double *, double *, double *, size_t, size_t);
static void kernelSwitch(
    double *, double *, double *, double *, double, size_t, size_t, size_t, int);

int type = WS;

int main(int argc, char **argv)
{
  size_t bytesPerWord = sizeof(double);
  size_t N            = SIZE;

  // ensure N is divisible by 8
  size_t num_threads = 1;
#ifdef _OPENMP
#pragma omp parallel
  {
#pragma omp single
    num_threads = omp_get_num_threads();
  }
#endif
  int base     = (N + num_threads - 1) / num_threads;
  N            = ((base + 7) & ~7) * num_threads;

  size_t ITERS = NTIMES;
  double *a, *b, *c, *d;

  profilerInit();

  parseCommandLineArguments(argc, argv, &N, &ITERS);

  printf("\n");
  printf(BANNER);
  printf(HLINE);
  printf("Total allocated datasize: %8.2f MB\n", 4.0 * bytesPerWord * N * 1.0E-06);

#ifdef _OPENMP
  printf(HLINE);
  _Pragma("omp parallel")
  {
    int k = omp_get_num_threads();
    int i = omp_get_thread_num();

#pragma omp single
    printf("OpenMP enabled, running with %d threads\n", k);

#ifdef VERBOSE_AFFINITY
#pragma omp barrier
#pragma omp critical
    {
      printf("Thread %d running on processor %d\n", i, affinity_getProcessorId());
      affinity_getmask();
    }
#endif
  }
#else
  _SEQ = 1;
#endif

  allocateArrays(&a, &b, &c, &d, N);
  initArrays(a, b, c, d, N);

  double scalar = 0.1;

#ifndef _NVCC
  if (type == TP || type == SQ) {
    printf("Running memory hierarchy sweeps\n");

    for (int j = 0; j < NUMREGIONS; j++) {
      N = 100;

      profilerOpenFile(j);

      while (N < SIZE) {

        double newtime = 0.0;
        double oldtime = 0.0;
        size_t iter    = 2;

        while (newtime < 0.3) {
          newtime = striad_seq(a, b, c, d, N, iter);
          if (newtime > 0.1) {
            break;
          }
          if ((newtime - oldtime) > 0.0) {
            double factor = 0.3 / (newtime - oldtime);
            iter *= (int)factor;
            oldtime = newtime;
          }
        }

        kernelSwitch(a, b, c, d, scalar, N, ITERS, iter, j);

        profilerPrintLine(N, iter, j);
        N = ((double)N * 1.2);
      }

      profilerCloseFile();
    }
    exit(EXIT_SUCCESS);
  }
#endif

  for (int k = 0; k < ITERS; k++) {
    PROFILE(INIT, init(b, scalar, N));
#ifdef _NVCC
    PROFILE(SUM, sum(a, N));
#else
    double tmp = a[10];
    PROFILE(SUM, sum(a, N));
    a[10] = tmp;
#endif
    PROFILE(COPY, copy(c, a, N));
    PROFILE(UPDATE, update(a, scalar, N));
    PROFILE(TRIAD, triad(a, b, c, scalar, N));
    PROFILE(DAXPY, daxpy(a, b, scalar, N));
    PROFILE(STRIAD, striad(a, b, c, d, N));
    PROFILE(SDAXPY, sdaxpy(a, b, c, N));
  }

#ifndef _NVCC
  check(a, b, c, d, N, ITERS);
#endif
  profilerPrint(N);

  return EXIT_SUCCESS;
}

void check(double *a, double *b, double *c, double *d, size_t N, size_t ITERS)
{
#ifdef _NVCC
  return;
#endif

  double aj, bj, cj, dj, scalar;
  double asum, bsum, csum, dsum;
  double epsilon;

  /* reproduce initialization */
  aj = 2.0;
  bj = 2.0;
  cj = 0.5;
  dj = 1.0;

  /* now execute timing loop */
  scalar = 0.1;

  for (int k = 0; k < ITERS; k++) {
    bj = scalar;
    cj = aj;
    aj = aj * scalar;
    aj = bj + scalar * cj;
    aj = aj + scalar * bj;
    aj = bj + cj * dj;
    aj = aj + bj * cj;
  }

  aj   = aj * (double)(N);
  bj   = bj * (double)(N);
  cj   = cj * (double)(N);
  dj   = dj * (double)(N);

  asum = 0.0;
  bsum = 0.0;
  csum = 0.0;
  dsum = 0.0;

  for (size_t i = 0; i < N; i++) {
    asum += a[i];
    bsum += b[i];
    csum += c[i];
    dsum += d[i];
  }

#ifdef VERBOSE
  printf("Results Comparison: \n");
  printf("        Expected  : %f %f %f \n", aj, bj, cj);
  printf("        Observed  : %f %f %f \n", asum, bsum, csum);
#endif

  epsilon = 1.e-8;

  if (ABS(aj - asum) / asum > epsilon) {
    printf("Failed Validation on array a[]\n");
    printf("        Expected  : %f \n", aj);
    printf("        Observed  : %f \n", asum);
  } else if (ABS(bj - bsum) / bsum > epsilon) {
    printf("Failed Validation on array b[]\n");
    printf("        Expected  : %f \n", bj);
    printf("        Observed  : %f \n", bsum);
  } else if (ABS(cj - csum) / csum > epsilon) {
    printf("Failed Validation on array c[]\n");
    printf("        Expected  : %f \n", cj);
    printf("        Observed  : %f \n", csum);
  } else if (ABS(dj - dsum) / dsum > epsilon) {
    printf("Failed Validation on array d[]\n");
    printf("        Expected  : %f \n", dj);
    printf("        Observed  : %f \n", dsum);
  } else {
    printf("Solution Validates\n");
  }
}

#ifndef _NVCC
void kernelSwitch(double *restrict a,
    double *restrict b,
    double *restrict c,
    double *restrict d,
    double scalar,
    size_t N,
    size_t ITERS,
    size_t iter,
    int j)
{
  switch (j) {
  case INIT:
    if (_SEQ) {
      for (int k = 0; k < ITERS; k++) {
        _t[INIT][k] = init_seq(a, scalar, N, iter);
      }
    } else {
      for (int k = 0; k < ITERS; k++) {
        _t[INIT][k] = init_tp(a, scalar, N, iter);
      }
    }
    break;

  case SUM:
    if (_SEQ) {
      for (int k = 0; k < ITERS; k++) {
        _t[SUM][k] = sum_seq(a, N, iter);
      }
    } else {
      for (int k = 0; k < ITERS; k++) {
        _t[SUM][k] = sum_tp(a, N, iter);
      }
    }
    break;

  case COPY:
    if (_SEQ) {
      for (int k = 0; k < ITERS; k++) {
        _t[COPY][k] = copy_seq(a, b, N, iter);
      }
    } else {
      for (int k = 0; k < ITERS; k++) {
        _t[COPY][k] = copy_tp(a, b, N, iter);
      }
    }
    break;

  case UPDATE:
    if (_SEQ) {
      for (int k = 0; k < ITERS; k++) {
        _t[UPDATE][k] = update_seq(a, scalar, N, iter);
      }
    } else {
      for (int k = 0; k < ITERS; k++) {
        _t[UPDATE][k] = update_tp(a, scalar, N, iter);
      }
    }
    break;

  case TRIAD:
    if (_SEQ) {
      for (int k = 0; k < ITERS; k++) {
        _t[TRIAD][k] = triad_seq(a, b, c, scalar, N, iter);
      }
    } else {
      for (int k = 0; k < ITERS; k++) {
        _t[TRIAD][k] = triad_tp(a, b, c, scalar, N, iter);
      }
    }
    break;

  case DAXPY:
    if (_SEQ) {
      for (int k = 0; k < ITERS; k++) {
        _t[DAXPY][k] = daxpy_seq(a, b, scalar, N, iter);
      }
    } else {
      for (int k = 0; k < ITERS; k++) {
        _t[DAXPY][k] = daxpy_tp(a, b, scalar, N, iter);
      }
    }
    break;

  case STRIAD:
    if (_SEQ) {
      for (int k = 0; k < ITERS; k++) {
        _t[STRIAD][k] = striad_seq(a, b, c, d, N, iter);
      }
    } else {
      for (int k = 0; k < ITERS; k++) {
        _t[STRIAD][k] = striad_tp(a, b, c, d, N, iter);
      }
    }
    break;

  case SDAXPY:
    if (_SEQ) {
      for (int k = 0; k < ITERS; k++) {
        _t[SDAXPY][k] = sdaxpy_seq(a, b, c, N, iter);
      }
    } else {
      for (int k = 0; k < ITERS; k++) {
        _t[SDAXPY][k] = sdaxpy_tp(a, b, c, N, iter);
      }
    }
    break;
  }
}
#endif
