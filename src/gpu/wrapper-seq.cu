#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <cuda_runtime.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#include "kernels.h"
#include "util.h"
#include "gpu.h" 
#include "timing.h" 

#define HARNESS(kernel)                                                        \
  double time = 0.0;                                                           \
  for( int i = 0 ; i < numDevices ; ++i )                                      \
  {                                                                            \
    GPU_ERROR(cudaSetDevice(i));                                               \
    GPU_ERROR(cudaFree(0));                                                    \
    double S = getTimeStamp();                                                 \
    for (int j = 0; j < iter; j++) {                                           \
      kernel;                                                                  \
    }                                                                          \
    GPU_ERROR(cudaDeviceSynchronize());                                        \
    double E = getTimeStamp();                                                 \
    time = E - S;                                                              \
  }                                                                            \
  return (time/numDevices);



extern "C" double init_seq_wrapper(double *__restrict__ b[], int scalar, size_t N, int iter) {

  HARNESS((init<<<N / thread_block_size + 1, thread_block_size>>>(b[i], scalar, N)))

}

extern "C" double copy_seq_wrapper(double *__restrict__ c[], double *__restrict__ a[], size_t N, int iter) {

  HARNESS((copy<<<N / thread_block_size + 1, thread_block_size>>>(c[i], a[i], N)))

}

extern "C" double sum_seq_wrapper(double *__restrict__ a[], size_t N, int iter) {

  // HARNESS((sum<<<N / thread_block_size + 1, thread_block_size>>>(a[i], N)))

}

extern "C" double update_seq_wrapper(double *__restrict__ a[], int scalar, size_t N, int iter) {

  HARNESS((update<<<N / thread_block_size + 1, thread_block_size>>>(a[i], scalar, N)))

}

extern "C" double triad_seq_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], int scalar, size_t N, int iter) {

  HARNESS((triad<<<N / thread_block_size + 1, thread_block_size>>>(a[i], b[i], c[i], scalar, N)))

}

extern "C" double daxpy_seq_wrapper(double *__restrict__ a[], double *__restrict__ b[], int scalar, size_t N, int iter) {

  HARNESS((daxpy<<<N / thread_block_size + 1, thread_block_size>>>(a[i], b[i], scalar, N)))

}

extern "C" double striad_seq_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], double *__restrict__ d[], size_t N, int iter) {

  HARNESS((striad<<<N / thread_block_size + 1, thread_block_size>>>(a[i], b[i], c[i], d[i], N)))

}

extern "C" double sdaxpy_seq_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], size_t N, int iter) {

  HARNESS((sdaxpy<<<N / thread_block_size + 1, thread_block_size>>>(a[i], b[i], c[i], N)))

}