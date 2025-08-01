/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#include <stdio.h>
#include <stdlib.h>

#include "allocate.h"
#include "kernels.h"
#include "timing.h"

#define HARNESS(kernel)                                                        \
  double S, E;                                                                 \
  _Pragma("omp parallel")                                                      \
  {                                                                            \
    double* al = (double*)allocate(ARRAY_ALIGNMENT, N * sizeof(double));       \
    _Pragma("omp single") S = getTimeStamp();                                  \
    for (int j = 0; j < iter; j++) {                                           \
      _Pragma("omp simd") for (int i = 0; i < N; i++) { kernel; }              \
      if (al[N - 1] < 0.0) printf("Ai = %f\n", al[N - 1]);                     \
    }                                                                          \
    _Pragma("omp single") E = getTimeStamp();                                  \
    free(al);                                                                  \
  }                                                                            \
  return E - S;

double init_tp(double* restrict a, double scalar, int N, int iter)
{
  HARNESS(al[i] = scalar)
}

double update_tp(double* restrict a, double scalar, int N, int iter)
{
  HARNESS(al[i] = a[i] * scalar)
}

double copy_tp(double* restrict a, double* restrict b, int N, int iter)
{
  HARNESS(al[i] = b[i])
}

double triad_tp(double* restrict a,
    double* restrict b,
    double* restrict c,
    double scalar,
    int N,
    int iter)
{
  HARNESS(al[i] = b[i] + scalar * c[i])
}

double striad_tp(double* restrict a,
    double* restrict b,
    double* restrict c,
    double* restrict d,
    int N,
    int iter)
{
  HARNESS(al[i] = b[i] + d[i] * c[i])
}

double daxpy_tp(
    double* restrict a, double* restrict b, double scalar, int N, int iter)
{
  HARNESS(al[i] = a[i] + scalar * b[i])
}

double sdaxpy_tp(
    double* restrict a, double* restrict b, double* restrict c, int N, int iter)
{
  HARNESS(al[i] = a[i] + b[i] * c[i])
}

double sum_tp(double* restrict a, int N, int iter)
{
  double S, E;

  _Pragma("omp parallel")
  {
    double* al = (double*)allocate(ARRAY_ALIGNMENT, N * sizeof(double));
    _Pragma("omp simd") for (int i = 0; i < N; i++) { al[i] = a[i]; }
    double sum = 0.0;

    _Pragma("omp single") S = getTimeStamp();
    for (int j = 0; j < iter; j++) {
      _Pragma("omp simd") for (int i = 0; i < N; i++) { sum += al[i]; }
      al[N / 2] += sum;
    }
    _Pragma("omp single") E = getTimeStamp();

    free(al);
  }

  /* make the compiler think this makes actually sense */

  return E - S;
}