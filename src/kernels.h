/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#ifndef __KERNELS_H_
#define __KERNELS_H_

extern double init(double* a, double scalar, int N);
extern double sum(double* a, int N);
extern double update(double* a, double scalar, int N);
extern double copy(double* a, double* b, int N);
extern double triad(double* a, double* b, double* c, double scalar, int N);
extern double striad(double* a, double* b, double* c, double* d, int N);
extern double daxpy(double* a, double* b, double scalar, int N);
extern double sdaxpy(double* a, double* b, double* c, int N);
#endif
