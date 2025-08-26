/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#ifdef __cplusplus
extern "C" {
#endif

__global__ void init_all(double *__restrict__ a, double *__restrict__ b, double *__restrict__ c, double *__restrict__  d, size_t N);
__global__ void init(double *__restrict__ b, int scalar, size_t N);
__global__ void copy(double *__restrict__ c, double *__restrict__ a, size_t N);
__global__ void update(double *__restrict__ a, int scalar, size_t N);
__global__ void triad(double *__restrict__ a, double *__restrict__ b, double *__restrict__ c, int scalar, size_t N);
__global__ void daxpy(double *__restrict__ a, double *__restrict__ b, int scalar, size_t N);
__global__ void striad(double *__restrict__ a, double *__restrict__ b, double *__restrict__ c, double *__restrict__ d, size_t N);
__global__ void sdaxpy(double *__restrict__ a, double *__restrict__ b, double *__restrict__ c, size_t N);

#ifdef __cplusplus
}
#endif