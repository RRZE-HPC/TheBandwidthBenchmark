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

#ifdef _OPENMP
#define OMP_PARALLEL _Pragma("omp parallel for num_threads(numDevices) reduction(+:time)")
#else
#define OMP_PARALLEL
#endif

int threadBlockSize = 1;
int maxThreadBlockSize = 1;
int maxThreadsPerStreamingMultiprocessor = 1;
int threadBlocksPerStreamingMultiprocessor = 1;
double occupancy = 0.0;

#define HARNESS(kernel)                                                        \
  double time = 0.0;                                                           \
  OMP_PARALLEL                                                                 \
  for( int i = 0 ; i < numDevices ; ++i )                                      \
  {                                                                            \
    GPU_ERROR(cudaSetDevice(i));                                               \
    GPU_ERROR(cudaFree(0));                                                    \
    double S = getTimeStamp();                                                 \
    kernel;                                                                    \
    GPU_ERROR(cudaDeviceSynchronize());                                        \
    double E = getTimeStamp();                                                 \
    time = E - S;                                                              \
  }                                                                            \
  return (time/numDevices);


extern "C" void initArrays(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], double *__restrict__ d[], size_t N) {

#ifdef _OPENMP
  #pragma omp parallel for num_threads(numDevices)
#endif
  for( int i = 0 ; i < numDevices ; ++i )
  {    
    GPU_ERROR(cudaSetDevice(i));
    GPU_ERROR(cudaFree(0));

    init_all<<<N / threadBlockSize + 1, threadBlockSize>>>(a[i], b[i], c[i], d[i], N);

    GPU_ERROR(cudaDeviceSynchronize());
  }

}

extern "C" double init_wrapper(double *__restrict__ b[], int scalar, size_t N) {

  HARNESS((init<<<N / threadBlockSize + 1, threadBlockSize>>>(b[i], scalar, N)))

}

extern "C" double copy_wrapper(double *__restrict__ c[], double *__restrict__ a[], size_t N) {

  HARNESS((copy<<<N / threadBlockSize + 1, threadBlockSize>>>(c[i], a[i], N)))

}

extern "C" double sum_wrapper(double *__restrict__ c[], double *__restrict__ a[], size_t N) {

  HARNESS((sum<<<N / threadBlockSize + 1, threadBlockSize>>>(a[i], N)))

}

extern "C" double update_wrapper(double *__restrict__ a[], int scalar, size_t N) {

  HARNESS((update<<<N / threadBlockSize + 1, threadBlockSize>>>(a[i], scalar, N)))

}

extern "C" double triad_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], int scalar, size_t N) {

  HARNESS((triad<<<N / threadBlockSize + 1, threadBlockSize>>>(a[i], b[i], c[i], scalar, N)))

}

extern "C" double daxpy_wrapper(double *__restrict__ a[], double *__restrict__ b[], int scalar, size_t N) {

  HARNESS((daxpy<<<N / threadBlockSize + 1, threadBlockSize>>>(a[i], b[i], scalar, N)))

}

extern "C" double striad_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], double *__restrict__ d[], size_t N) {

  HARNESS((striad<<<N / threadBlockSize + 1, threadBlockSize>>>(a[i], b[i], c[i], d[i], N)))

}

extern "C" double sdaxpy_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], size_t N) {

  HARNESS((sdaxpy<<<N / threadBlockSize + 1, threadBlockSize>>>(a[i], b[i], c[i], N)))

}

extern "C" void setBlockSize()
{
  cudaDeviceProp prop;
  GPU_ERROR(cudaGetDeviceProperties(&prop, 0));

  maxThreadBlockSize = prop.maxThreadsPerBlock;
  maxThreadsPerStreamingMultiprocessor = prop.maxThreadsPerMultiProcessor;
  int maxBlocksPerSM = prop.maxBlocksPerMultiProcessor;
  int warpSize = prop.warpSize; 
  printf("TB: %d\nWP: %d, TperSM: %d\nBperSM: %d\n",maxThreadBlockSize, warpSize, maxThreadsPerStreamingMultiprocessor, maxBlocksPerSM);

  // Assuming that maxThreadsPerMultiProcessor is multiple of 32 and even.
  // For max occupancy, threadBlockSize is divided into 2 so that GPU can 
  // schedule 2 thread block per Streaming Multiprocessor.
  threadBlockSize = maxThreadBlockSize;

#ifdef BLOCKSIZE
  threadBlockSize = BLOCKSIZE;
#endif

  threadBlocksPerStreamingMultiprocessor = floor(maxThreadsPerStreamingMultiprocessor/threadBlockSize);
  occupancy = (((double)threadBlockSize * (double)threadBlocksPerStreamingMultiprocessor)/ (double)maxThreadsPerStreamingMultiprocessor)*100;
}