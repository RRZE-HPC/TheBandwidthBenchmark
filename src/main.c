/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of CG-Bench.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#include <stdio.h>
#include <stdlib.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#include "affinity.h"
#include "allocate.h"
#include "kernels.h"
#include "profiler.h"
#include "timing.h"
#include "util.h"

static void check(double*, double*, double*, double*, int);

int main(int argc, char** argv)
{
  size_t bytesPerWord = sizeof(double);
  size_t N            = SIZE;
  double *a, *b, *c, *d;

  profilerInit();

  a = (double*)allocate(ARRAY_ALIGNMENT, N * bytesPerWord);
  b = (double*)allocate(ARRAY_ALIGNMENT, N * bytesPerWord);
  c = (double*)allocate(ARRAY_ALIGNMENT, N * bytesPerWord);
  d = (double*)allocate(ARRAY_ALIGNMENT, N * bytesPerWord);

  printf("\n");
  printf(BANNER);
  printf(HLINE);
  printf("Total allocated datasize: %8.2f MB\n",
      4.0 * bytesPerWord * N * 1.0E-06);

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
      printf("Thread %d running on processor %d\n",
          i,
          affinity_getProcessorId());
      affinity_getmask();
    }
#endif
  }
#endif

  double S = getTimeStamp();
#pragma omp parallel for schedule(static)
  for (int i = 0; i < N; i++) {
    a[i] = 2.0;
    b[i] = 2.0;
    c[i] = 0.5;
    d[i] = 1.0;
  }
  double E = getTimeStamp();
#ifdef VERBOSE_TIMER
  printf("Timer resolution %.2e ", getTimeResolution());
  printf("Ticks used %.0e\n", (E - S) / getTimeResolution());
#endif

  double scalar = 3.0;

  for (int k = 0; k < NTIMES; k++) {
    PROFILE(INIT, init(b, scalar, N));
    double tmp = a[10];
    PROFILE(SUM, sum(a, N));
    a[10] = tmp;
    PROFILE(COPY, copy(c, a, N));
    PROFILE(UPDATE, update(a, scalar, N));
    PROFILE(TRIAD, triad(a, b, c, scalar, N));
    PROFILE(DAXPY, daxpy(a, b, scalar, N));
    PROFILE(STRIAD, striad(a, b, c, d, N));
    PROFILE(SDAXPY, sdaxpy(a, b, c, N));
  }
  check(a, b, c, d, N);

  profilerPrint(N);
  return EXIT_SUCCESS;
}

void check(double* a, double* b, double* c, double* d, int N)
{
  double aj, bj, cj, dj, scalar;
  double asum, bsum, csum, dsum;
  double epsilon;

  /* reproduce initialization */
  aj = 2.0;
  bj = 2.0;
  cj = 0.5;
  dj = 1.0;

  /* now execute timing loop */
  scalar = 3.0;

  for (int k = 0; k < NTIMES; k++) {
    bj = scalar;
    cj = aj;
    aj = aj * scalar;
    aj = bj + scalar * cj;
    aj = aj + scalar * bj;
    aj = bj + cj * dj;
    aj = aj + bj * cj;
  }

  aj = aj * (double)(N);
  bj = bj * (double)(N);
  cj = cj * (double)(N);
  dj = dj * (double)(N);

  asum = 0.0;
  bsum = 0.0;
  csum = 0.0;
  dsum = 0.0;

  for (int i = 0; i < N; i++) {
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
