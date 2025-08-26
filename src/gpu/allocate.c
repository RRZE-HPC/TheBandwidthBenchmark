/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#include <errno.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <cuda.h>
#include <cuda_runtime.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#include "allocate.h"
#include "gpu.h"

void allocate(double *restrict a[], double *restrict b[], double *restrict c[], double *restrict d[], size_t N) {

#ifdef _OPENMP
  #pragma omp parallel for num_threads(numDevices)
#endif
  for( int i = 0 ; i < numDevices ; ++i )
  {
    GPU_ERROR(cudaSetDevice(i));
    GPU_ERROR(cudaFree(0));

    GPU_ERROR(cudaMalloc((void**)&a[i], N * sizeof(double)));
    GPU_ERROR(cudaMalloc((void**)&b[i], N * sizeof(double)));
    GPU_ERROR(cudaMalloc((void**)&c[i], N * sizeof(double)));
    GPU_ERROR(cudaMalloc((void**)&d[i], N * sizeof(double)));
  }
}