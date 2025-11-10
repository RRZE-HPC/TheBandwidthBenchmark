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
  S = getTimeStamp();                                                          \
  _Pragma("omp parallel for schedule(static)") for (size_t i = 0; i < N; i++)  \
  {                                                                            \
    kernel;                                                                    \
  }                                                                            \
  E = getTimeStamp();                                                          \
  return E - S;

void allocateArrays(
    double** a, double** b, double** c, double** d, const size_t N)
{
  *a = (double*)allocate(ARRAY_ALIGNMENT, N * sizeof(double));
  *b = (double*)allocate(ARRAY_ALIGNMENT, N * sizeof(double));
  *c = (double*)allocate(ARRAY_ALIGNMENT, N * sizeof(double));
  *d = (double*)allocate(ARRAY_ALIGNMENT, N * sizeof(double));
}

void initArrays(double* a, double* b, double* c, double* d, const size_t N)
{

#pragma omp parallel for schedule(static)
  for (size_t i = 0; i < N; i++) {
    a[i] = 2.0;
    b[i] = 2.0;
    c[i] = 0.5;
    d[i] = 1.0;
  }
}

double init(double* restrict a, const double scalar, const size_t N)
{
  HARNESS(a[i] = scalar)
}

double sum(double* restrict a, const size_t N)
{
  double S, E;
  double sum = 0.0;

  S = getTimeStamp();
#pragma omp parallel for reduction(+ : sum) schedule(static)
  for (size_t i = 0; i < N; i++) {
    sum += a[i];
  }
  E = getTimeStamp();

  /* make the compiler think this makes actually sense */
  a[10] = sum;

  return E - S;
}

double update(double* restrict a, const double scalar, const size_t N)
{
  HARNESS(a[i] = a[i] * scalar)
}

double copy(double* restrict a, double* restrict b, const size_t N)
{
  HARNESS(a[i] = b[i])
}

double triad(double* restrict a,
    double* restrict b,
    double* restrict c,
    const double scalar,
    const size_t N)
{
  HARNESS(a[i] = b[i] + scalar * c[i])
}

double striad(double* restrict a,
    double* restrict b,
    double* restrict c,
    double* restrict d,
    const size_t N)
{
  HARNESS(a[i] = b[i] + d[i] * c[i])
}

double daxpy(
    double* restrict a, double* restrict b, const double scalar, const size_t N)
{
  HARNESS(a[i] = a[i] + scalar * b[i])
}

double sdaxpy(
    double* restrict a, double* restrict b, double* restrict c, const size_t N)
{
  HARNESS(a[i] = a[i] + b[i] * c[i])
}
