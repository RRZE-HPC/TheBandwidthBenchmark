/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#ifndef KERNELS_H_
#define KERNELS_H_
#include <stdlib.h>
#include <time.h>

extern void allocateArrays(double **a, double **b, double **c, double **d, size_t N);
extern void initArrays(double *a, double *b, double *c, double *d, size_t N);
extern double init(double *a, double scalar, size_t N);
extern double sum(double *a, size_t N);
extern double update(double *a, double scalar, size_t N);
extern double copy(double *a, const double *b, size_t N);
extern double triad(double *a, const double *b, const double *c, double scalar, size_t N);
extern double striad(
    double *a, const double *b, const double *c, const double *d, size_t N);
extern double daxpy(double *a, const double *b, double scalar, size_t N);
extern double sdaxpy(double *a, const double *b, const double *c, size_t N);

#ifndef _NVCC
extern double init_seq(double *a, double scalar, size_t N, size_t iter);
extern double update_seq(double *a, double scalar, size_t N, size_t iter);
extern double sum_seq(double *a, size_t N, size_t iter);
extern double copy_seq(double *a, const double *b, size_t N, size_t iter);
extern double triad_seq(
    double *a, const double *b, const double *c, double scalar, size_t N, size_t iter);
extern double striad_seq(
    double *a, const double *b, const double *c, const double *d, size_t N, size_t iter);
extern double daxpy_seq(double *a, const double *b, double scalar, size_t N, size_t iter);
extern double sdaxpy_seq(
    double *a, const double *b, const double *c, size_t N, size_t iter);

extern double init_tp(double *a, double scalar, size_t N, size_t iter);
extern double update_tp(const double *a, double scalar, size_t N, size_t iter);
extern double sum_tp(const double *a, size_t N, size_t iter);
extern double copy_tp(double *a, const double *b, size_t N, size_t iter);
extern double triad_tp(
    double *a, const double *b, const double *c, double scalar, size_t N, size_t iter);
extern double striad_tp(
    double *a, const double *b, const double *c, const double *d, size_t N, size_t iter);
extern double daxpy_tp(
    const double *a, const double *b, double scalar, size_t N, size_t iter);
extern double sdaxpy_tp(
    const double *a, const double *b, const double *c, size_t N, size_t iter);
#endif
#endif
