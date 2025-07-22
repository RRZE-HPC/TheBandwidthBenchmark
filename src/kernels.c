/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#include <stdio.h>
#include <stdlib.h>

#include "kernels.h"
#include "timing.h"

#define HARNESS(kernel)                                                        \
  double S, E;                                                                 \
  S = getTimeStamp();                                                          \
  _Pragma("omp parallel for schedule(static)") for (int i = 0; i < N; i++) {   \
    kernel;                                                                    \
  }                                                                            \
  E = getTimeStamp();                                                          \
  return E - S;

double init(double *restrict a, double scalar, int N) { HARNESS(a[i] = scalar) }

double sum(double *restrict a, int N) {
  double S, E;
  double sum = 0.0;

  S = getTimeStamp();
#pragma omp parallel for reduction(+ : sum) schedule(static)
  for (int i = 0; i < N; i++) {
    sum += a[i];
  }
  E = getTimeStamp();

  /* make the compiler think this makes actually sense */
  a[10] = sum;

  return E - S;
}

double update(double *restrict a, double scalar, int N) {
  HARNESS(a[i] = a[i] * scalar)
}

double copy(double *restrict a, double *restrict b, int N) {
  HARNESS(a[i] = b[i])
}

double triad(double *restrict a, double *restrict b, double *restrict c,
             double scalar, int N) {
  HARNESS(a[i] = b[i] + scalar * c[i])
}

double striad(double *restrict a, double *restrict b, double *restrict c,
              double *restrict d, int N) {
  HARNESS(a[i] = b[i] + d[i] * c[i])
}

double daxpy(double *restrict a, double *restrict b, double scalar, int N) {
  HARNESS(a[i] = a[i] + scalar * b[i])
}

double sdaxpy(double *restrict a, double *restrict b, double *restrict c,
              int N) {
  HARNESS(a[i] = a[i] + b[i] * c[i])
}
