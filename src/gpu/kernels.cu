#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <cuda_runtime.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#include "kernels.h"
#include "util.h"


__global__ void init_all(double *__restrict__ a, double *__restrict__ b, double *__restrict__ c, double *__restrict__ d, const size_t N) {
  
  int tidx = threadIdx.x + blockIdx.x * blockDim.x;
  
  if (tidx >= N)
    return;

  a[tidx] = 2.0;
  b[tidx] = 2.0;
  c[tidx] = 0.5;
  d[tidx] = 1.0;

}

__global__ void init(double *__restrict__ b, int scalar, size_t N) {
  
  int tidx = threadIdx.x + blockIdx.x * blockDim.x;
  
  if (tidx >= N)
    return;

  b[tidx] = scalar;

}

__global__ void copy(double *__restrict__ c, double *__restrict__ a, size_t N) {
  
  int tidx = threadIdx.x + blockIdx.x * blockDim.x;
  
  if (tidx >= N)
    return;

  c[tidx] = a[tidx];

}

__global__ void update(double *__restrict__ a, int scalar, size_t N) {
  
  int tidx = threadIdx.x + blockIdx.x * blockDim.x;
  
  if (tidx >= N)
    return;

  a[tidx] = a[tidx] * scalar;

}

__global__ void triad(double *__restrict__ a, double *__restrict__ b, double *__restrict__ c, int scalar, size_t N) {
  
  int tidx = threadIdx.x + blockIdx.x * blockDim.x;
  
  if (tidx >= N)
    return;

  a[tidx] =  b[tidx] + scalar * c[tidx];

}

__global__ void daxpy(double *__restrict__ a, double *__restrict__ b, int scalar, size_t N) {
  
  int tidx = threadIdx.x + blockIdx.x * blockDim.x;
  
  if (tidx >= N)
    return;

  a[tidx] =  a[tidx] + scalar * b[tidx];

}

__global__ void striad(double *__restrict__ a, double *__restrict__ b, double *__restrict__ c, double *__restrict__ d, size_t N) {
  
  int tidx = threadIdx.x + blockIdx.x * blockDim.x;
  
  if (tidx >= N)
    return;

  a[tidx] =  b[tidx] + d[tidx] * c[tidx];

}

__global__ void sdaxpy(double *__restrict__ a, double *__restrict__ b, double *__restrict__ c, size_t N) {
  
  int tidx = threadIdx.x + blockIdx.x * blockDim.x;
  
  if (tidx >= N)
    return;

  a[tidx] =  a[tidx] + b[tidx] * c[tidx];

}