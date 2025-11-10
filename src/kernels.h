/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#ifndef __KERNELS_H_
#define __KERNELS_H_
#include <stdlib.h>

extern void allocateArrays(
    double** a, double** b, double** c, double** d, const size_t N);
extern void initArrays(
    double* a, double* b, double* c, double* d, const size_t N);
extern double init(double* a, const double scalar, const size_t N);
extern double sum(double* a, const size_t N);
extern double update(double* a, const double scalar, const size_t N);
extern double copy(double* a, double* b, const size_t N);
extern double triad(
    double* a, double* b, double* c, const double scalar, const size_t N);
extern double striad(
    double* a, double* b, double* c, double* d, const size_t N);
extern double daxpy(
    double* a, double* b, const double scalar, const size_t N);
extern double sdaxpy(double* a, double* b, double* c, const size_t N);

#ifndef _NVCC
extern double init_seq(double* a,
    const double scalar,
    const size_t N,
    const size_t iter);
extern double update_seq(double* a,
    const double scalar,
    const size_t N,
    const size_t iter);
extern double sum_seq(double* a, const size_t N, const size_t iter);
extern double copy_seq(
    double* a, double* b, const size_t N, const size_t iter);
extern double triad_seq(double* a,
    double* b,
    double* c,
    const double scalar,
    const size_t N,
    const size_t iter);
extern double striad_seq(double* a,
    double* b,
    double* c,
    double* d,
    const size_t N,
    const size_t iter);
extern double daxpy_seq(double* a,
    double* b,
    const double scalar,
    const size_t N,
    const size_t iter);
extern double sdaxpy_seq(double* a,
    double* b,
    double* c,
    const size_t N,
    const size_t iter);

extern double init_tp(double* a,
    const double scalar,
    const size_t N,
    const size_t iter);
extern double update_tp(double* a,
    const double scalar,
    const size_t N,
    const size_t iter);
extern double sum_tp(double* a, const size_t N, const size_t iter);
extern double copy_tp(
    double* a, double* b, const size_t N, const size_t iter);
extern double triad_tp(double* a,
    double* b,
    double* c,
    const double scalar,
    const size_t N,
    const size_t iter);
extern double striad_tp(double* a,
    double* b,
    double* c,
    double* d,
    const size_t N,
    const size_t iter);
extern double daxpy_tp(double* a,
    double* b,
    const double scalar,
    const size_t N,
    const size_t iter);
extern double sdaxpy_tp(double* a,
    double* b,
    double* c,
    const size_t N,
    const size_t iter);
#endif
#endif
