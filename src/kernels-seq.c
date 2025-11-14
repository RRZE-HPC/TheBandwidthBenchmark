/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#include <stdio.h>
#include <stdlib.h>

#include "kernels.h"
#include "timing.h"

#define HARNESS(kernel)                                                                  \
  double S, E;                                                                           \
  S = getTimeStamp();                                                                    \
  for (size_t j = 0; j < iter; j++) {                                                    \
    for (size_t i = 0; i < N; i++) {                                                     \
      kernel;                                                                            \
    }                                                                                    \
    if (a[N - 1] < 0.0) {                                                                \
      printf("Ai = %f\n", a[N - 1]);                                                     \
      exit(1);                                                                           \
    }                                                                                    \
  }                                                                                      \
  E = getTimeStamp();                                                                    \
  return E - S;

double init_seq(
    double *restrict a, const double scalar, const size_t N, const size_t iter)
{
  HARNESS(a[i] = scalar)
}

double update_seq(
    double *restrict a, const double scalar, const size_t N, const size_t iter)
{
  HARNESS(a[i] = a[i] * scalar)
}

double copy_seq(double *restrict a, double *restrict b, const size_t N, const size_t iter)
{
  HARNESS(a[i] = b[i])
}

double triad_seq(double *restrict a,
    double *restrict b,
    double *restrict c,
    const double scalar,
    const size_t N,
    const size_t iter)
{
  HARNESS(a[i] = b[i] + scalar * c[i])
}

double striad_seq(double *restrict a,
    double *restrict b,
    double *restrict c,
    double *restrict d,
    const size_t N,
    const size_t iter)
{
  HARNESS(a[i] = b[i] + d[i] * c[i])
}

double daxpy_seq(double *restrict a,
    double *restrict b,
    const double scalar,
    const size_t N,
    const size_t iter)
{
  HARNESS(a[i] = a[i] + scalar * b[i])
}

double sdaxpy_seq(double *restrict a,
    double *restrict b,
    double *restrict c,
    const size_t N,
    const size_t iter)
{
  HARNESS(a[i] = a[i] + b[i] * c[i])
}

double sum_seq(double *restrict a, const size_t N, const size_t iter)
{
  double S, E;
  double sum = 0.0;

  S          = getTimeStamp();
  for (size_t j = 0; j < iter; j++) {
    for (size_t i = 0; i < N; i++) {
      sum += a[i];
    }

    a[10] = sum;
  }
  E = getTimeStamp();

  /* make the compiler think this makes actually sense */
  a[10] = sum;

  return E - S;
}