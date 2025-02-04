/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#include "kernels.h"
#include "timing.h"

double init(double* restrict a, double scalar, int N)
{
  double S, E;

  S = getTimeStamp();
#pragma omp parallel for schedule(static)
  for (int i = 0; i < N; i++) {
    a[i] = scalar;
  }
  E = getTimeStamp();

  return E - S;
}

double sum(double* restrict a, int N)
{
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

double update(double* restrict a, double scalar, int N)
{
  double S, E;

  S = getTimeStamp();
#pragma omp parallel for schedule(static)
  for (int i = 0; i < N; i++) {
    a[i] = a[i] * scalar;
  }
  E = getTimeStamp();

  return E - S;
}

double copy(double* restrict a, double* restrict b, int N)
{
  double S, E;

  S = getTimeStamp();
#pragma omp parallel for schedule(static)
  for (int i = 0; i < N; i++) {
    a[i] = b[i];
  }
  E = getTimeStamp();

  return E - S;
}

double triad(double* restrict a,
    double* restrict b,
    double* restrict c,
    double scalar,
    int N)
{
  double S, E;

  S = getTimeStamp();
#pragma omp parallel for schedule(static)
  for (int i = 0; i < N; i++) {
    a[i] = b[i] + scalar * c[i];
  }
  E = getTimeStamp();

  return E - S;
}

double striad(double* restrict a,
    double* restrict b,
    double* restrict c,
    double* restrict d,
    int N)
{
  double S, E;

  S = getTimeStamp();
#pragma omp parallel for schedule(static)
  for (int i = 0; i < N; i++) {
    a[i] = b[i] + d[i] * c[i];
  }
  E = getTimeStamp();

  return E - S;
}

double daxpy(double* restrict a, double* restrict b, double scalar, int N)
{
  double S, E;

  S = getTimeStamp();
#pragma omp parallel for schedule(static)
  for (int i = 0; i < N; i++) {
    a[i] = a[i] + scalar * b[i];
  }
  E = getTimeStamp();

  return E - S;
}

double sdaxpy(double* restrict a, double* restrict b, double* restrict c, int N)
{
  double S, E;

  S = getTimeStamp();
#pragma omp parallel for schedule(static)
  for (int i = 0; i < N; i++) {
    a[i] = a[i] + b[i] * c[i];
  }
  E = getTimeStamp();

  return E - S;
}
