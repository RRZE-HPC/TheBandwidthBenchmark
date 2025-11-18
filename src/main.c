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
#include "affinity.h"
#include <omp.h>
#endif

#include "cli.h"
#include "kernels.h"
#include "profiler.h"
#include "util.h"

static void check(
    const double *, const double *, const double *, const double *, size_t, size_t);
static void kernelSwitch(double *,
    const double *,
    const double *,
    const double *,
    double,
    size_t,
    size_t,
    size_t,
    int);

int main(const int argc, char **argv)
{
  const size_t bytesPerWord = sizeof(double);

  // Data initialization from config.mk
  N     = SIZE;
  ITERS = NTIMES;

  // ensure N is divisible by 8
  size_t num_threads = 1;

#ifdef _OPENMP
#pragma omp parallel
  {
#pragma omp single
    num_threads = omp_get_num_threads();
  }
#endif

  const int base = (N + num_threads - 1) / num_threads;
  N              = ((base + 7) & ~7) * num_threads;

  double *a, *b, *c, *d;

  profilerInit();

  parseCLI(argc, argv);

  allocateTimer();

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
  SEQ = 1;
#endif

  allocateArrays(&a, &b, &c, &d, N);
  initArrays(a, b, c, d, N);

  const double scalar = 0.1;

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
            const double factor = 0.3 / (newtime - oldtime);
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
    const double tmp = a[10];
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

  freeTimer();

  return EXIT_SUCCESS;
}

void check(const double *a,
    const double *b,
    const double *c,
    const double *d,
    const size_t N,
    const size_t ITERS)
{
  if (data_init_type == 1) {
    return;
  }

  double epsilon;

  /* reproduce initialization */
  double aj = 2.0;
  double bj = 2.0;
  double cj = 0.5;
  double dj = 1.0;

  /* now execute timing loop */
  for (int k = 0; k < ITERS; k++) {
    const double scalar = 0.1;
    bj                  = scalar;
    cj                  = aj;
    aj                  = aj * scalar;
    aj                  = bj + scalar * cj;
    aj                  = aj + scalar * bj;
    aj                  = bj + cj * dj;
    aj                  = aj + bj * cj;
  }

  aj          = aj * (double)(N);
  bj          = bj * (double)(N);
  cj          = cj * (double)(N);
  dj          = dj * (double)(N);

  double asum = 0.0;
  double bsum = 0.0;
  double csum = 0.0;
  double dsum = 0.0;

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
    const double *restrict b,
    const double *restrict c,
    const double *restrict d,
    const double scalar,
    const size_t N,
    const size_t ITERS,
    const size_t iter,
    const int j)
{
  switch (j) {
  case INIT:
    if (SEQ) {
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
    if (SEQ) {
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
    if (SEQ) {
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
    if (SEQ) {
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
    if (SEQ) {
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
    if (SEQ) {
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
    if (SEQ) {
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
    if (SEQ) {
      for (int k = 0; k < ITERS; k++) {
        _t[SDAXPY][k] = sdaxpy_seq(a, b, c, N, iter);
      }
    } else {
      for (int k = 0; k < ITERS; k++) {
        _t[SDAXPY][k] = sdaxpy_tp(a, b, c, N, iter);
      }
    }
    break;
  default:;
  }
}
#endif
