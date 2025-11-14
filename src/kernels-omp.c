/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#include <stdio.h>
#include <stdlib.h>

#include "allocate.h"
#include "kernels.h"
#include "timing.h"
#ifdef AVX512_INTRINSICS
#include <immintrin.h>
#endif

#ifdef AVX512_INTRINSICS
#define INCREMENT i += 8
#else
#define INCREMENT i++
#endif

#define HARNESS(kernel)                                                                  \
  double S, E;                                                                           \
  S = getTimeStamp();                                                                    \
  _Pragma("omp parallel for schedule(static)") for (size_t i = 0; i < N; INCREMENT)      \
  {                                                                                      \
    kernel;                                                                              \
  }                                                                                      \
  E = getTimeStamp();                                                                    \
  return E - S;

void allocateArrays(double **a, double **b, double **c, double **d, const size_t N)
{
  *a = (double *)allocate(ARRAY_ALIGNMENT, N * sizeof(double));
  *b = (double *)allocate(ARRAY_ALIGNMENT, N * sizeof(double));
  *c = (double *)allocate(ARRAY_ALIGNMENT, N * sizeof(double));
  *d = (double *)allocate(ARRAY_ALIGNMENT, N * sizeof(double));
}

void initArrays(double *a, double *b, double *c, double *d, const size_t N)
{

#pragma omp parallel for schedule(static)
  for (size_t i = 0; i < N; i++) {
    a[i] = 2.0;
    b[i] = 2.0;
    c[i] = 0.5;
    d[i] = 1.0;
  }
}

double init(double *restrict a, const double scalar, const size_t N)
{
#ifdef AVX512_INTRINSICS
  __m512d vs =
      _mm512_set_pd(scalar, scalar, scalar, scalar, scalar, scalar, scalar, scalar);

  HARNESS(_mm512_stream_pd(&a[i], vs))
#else
  HARNESS(a[i] = scalar)
#endif
}

double sum(double *restrict a, const size_t N)
{
  double S, E;
  double sum = 0.0;

  S          = getTimeStamp();
#pragma omp parallel for reduction(+ : sum) schedule(static)
  for (size_t i = 0; i < N; i++) {
    sum += a[i];
  }
  E = getTimeStamp();

  /* make the compiler think this makes actually sense */
  a[10] = sum;

  return E - S;
}

double update(double *restrict a, const double scalar, const size_t N)
{
#ifdef AVX512_INTRINSICS
  __m512d vs =
      _mm512_set_pd(scalar, scalar, scalar, scalar, scalar, scalar, scalar, scalar);

  HRNESS(__m512d prod = _mm512_mul_pd(_mm512_load_pd(&a[i]), vs);
      _mm512_stream_pd(&a[i], prod);)
#else
  HARNESS(a[i] = a[i] * scalar)
#endif
}

double copy(double *restrict a, double *restrict b, const size_t N)
{
#ifdef AVX512_INTRINSICS
  double S, E;
  S = getTimeStamp();
#pragma omp parallel for schedule(static)
  for (int i = 0; i < N; i += 8) {
    __m512d load = _mm512_load_pd(&b[i]);
    _mm512_stream_pd(&a[i], load);
  }
  E = getTimeStamp();
  return E - S;
#else
  HARNESS(a[i] = b[i])
#endif
}

double triad(double *restrict a,
    double *restrict b,
    double *restrict c,
    const double scalar,
    const size_t N)
{
#ifdef AVX512_INTRINSICS
  double S, E;
  __m512d vs =
      _mm512_set_pd(scalar, scalar, scalar, scalar, scalar, scalar, scalar, scalar);
  S = getTimeStamp();
#pragma omp parallel for schedule(static)
  for (int i = 0; i < N; i += 8) {
    __m512d bvec = _mm512_load_pd(&b[i]);
    __m512d avec = _mm512_fmadd_pd(_mm512_load_pd(&c[i]), vs, bvec);
    _mm512_stream_pd(&a[i], avec);
  }
  E = getTimeStamp();
  return E - S;
#else
  HARNESS(a[i] = b[i] + scalar * c[i])
#endif
}

double striad(double *restrict a,
    double *restrict b,
    double *restrict c,
    double *restrict d,
    const size_t N)
{
#ifdef AVX512_INTRINSICS
  double S, E;
  S = getTimeStamp();
#pragma omp parallel for schedule(static)
  for (int i = 0; i < N; i += 8) {
    __m512d bvec = _mm512_load_pd(&b[i]);
    __m512d dvec = _mm512_load_pd(&d[i]);
    __m512d avec = _mm512_fmadd_pd(_mm512_load_pd(&c[i]), dvec, bvec);
    _mm512_stream_pd(&a[i], avec);
  }
  E = getTimeStamp();
  return E - S;
#else
  HARNESS(a[i] = b[i] + d[i] * c[i])
#endif
}

double daxpy(double *restrict a, double *restrict b, const double scalar, const size_t N)
{
#ifdef AVX512_INTRINSICS
  double S, E;
  __m512d vs =
      _mm512_set_pd(scalar, scalar, scalar, scalar, scalar, scalar, scalar, scalar);
  S = getTimeStamp();
#pragma omp parallel for schedule(static)
  for (int i = 0; i < N; i += 8) {
    __m512d bvec = _mm512_load_pd(&b[i]);
    __m512d avec = _mm512_fmadd_pd(bvec, vs, _mm512_load_pd(&a[i]));
    _mm512_stream_pd(&a[i], avec);
  }
  E = getTimeStamp();
  return E - S;
#else
  HARNESS(a[i] = a[i] + scalar * b[i])
#endif
}

double sdaxpy(double *restrict a, double *restrict b, double *restrict c, const size_t N)
{
#ifdef AVX512_INTRINSICS
  double S, E;
  S = getTimeStamp();
#pragma omp parallel for schedule(static)
  for (int i = 0; i < N; i += 8) {
    __m512d bvec = _mm512_load_pd(&b[i]);
    __m512d cvec = _mm512_load_pd(&c[i]);
    __m512d avec = _mm512_fmadd_pd(bvec, cvec, _mm512_load_pd(&a[i]));
    _mm512_stream_pd(&a[i], avec);
  }
  E = getTimeStamp();
  return E - S;
#else
  HARNESS(a[i] = a[i] + b[i] * c[i])
#endif
}
