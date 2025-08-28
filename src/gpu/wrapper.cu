#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <cuda_runtime.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#include "kernels.h"
#include "wrapper.h"
#include "util.h"
#include "gpu.h" 
#include "timing.h" 


#ifdef _OPENMP
#define OMP_PARALLEL _Pragma("omp parallel for num_threads(numDevices) reduction(+:time)")
#else
#define OMP_PARALLEL
#endif

#define SHARED_MEM(kernel_name) getSharedMemSize(thread_block_size, thread_blocks_per_streaming_multiprocessor, (const void*)&kernel_name) 

#define HARNESS(kernel, kernel_name)                                           \
  double time = 0.0;                                                           \
  int shared_mem_size = SHARED_MEM(kernel_name);                               \
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

    init_all<<<N / thread_block_size + 1, thread_block_size>>>(a[i], b[i], c[i], d[i], N);

    GPU_ERROR(cudaDeviceSynchronize());
  }

}

extern "C" double init_wrapper(double *__restrict__ b[], int scalar, size_t N) {

  HARNESS((init<<<N / thread_block_size + 1, thread_block_size, shared_mem_size>>>(b[i], scalar, N)), init)

}

extern "C" double copy_wrapper(double *__restrict__ c[], double *__restrict__ a[], size_t N) {

  HARNESS((copy<<<N / thread_block_size + 1, thread_block_size, shared_mem_size>>>(c[i], a[i], N)), copy)

}

extern "C" double update_wrapper(double *__restrict__ a[], int scalar, size_t N) {

  HARNESS((update<<<N / thread_block_size + 1, thread_block_size, shared_mem_size>>>(a[i], scalar, N)), update)

}

extern "C" double triad_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], int scalar, size_t N) {

  HARNESS((triad<<<N / thread_block_size + 1, thread_block_size, shared_mem_size>>>(a[i], b[i], c[i], scalar, N)), triad)

}

extern "C" double daxpy_wrapper(double *__restrict__ a[], double *__restrict__ b[], int scalar, size_t N) {

  HARNESS((daxpy<<<N / thread_block_size + 1, thread_block_size, shared_mem_size>>>(a[i], b[i], scalar, N)), daxpy)

}

extern "C" double striad_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], double *__restrict__ d[], size_t N) {

  HARNESS((striad<<<N / thread_block_size + 1, thread_block_size, shared_mem_size>>>(a[i], b[i], c[i], d[i], N)), striad)

}

extern "C" double sdaxpy_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], size_t N) {

  HARNESS((sdaxpy<<<N / thread_block_size + 1, thread_block_size, shared_mem_size>>>(a[i], b[i], c[i], N)), sdaxpy)

}

extern "C" double sum_wrapper(double *__restrict__ a[], size_t N) {

  double time = 0.0;
  OMP_PARALLEL
  for( int i = 0 ; i < numDevices ; ++i )
  {    
    GPU_ERROR(cudaSetDevice(i));
    GPU_ERROR(cudaFree(0));
    double *a_out;
    GPU_ERROR(cudaMalloc(&a_out, (N  + (thread_block_size - 1)) / thread_block_size * sizeof(double)));
    double S = getTimeStamp();
    sum<<<N / (thread_block_size * 2) + 1, thread_block_size, thread_block_size * sizeof(double)>>>(a[i], a_out, N);
    GPU_ERROR(cudaDeviceSynchronize());
    double E = getTimeStamp();
    time = E - S;
  }
  return (time/numDevices);

}

extern "C" void setBlockSize()
{
  cudaDeviceProp prop;
  GPU_ERROR(cudaGetDeviceProperties(&prop, 0));

  max_thread_block_size = prop.maxThreadsPerBlock;
  max_threads_per_streaming_multiprocessor = prop.maxThreadsPerMultiProcessor;

  // Not the best case for thread_block_size. 
  // Varying thread_block_size can result in 
  // better performance and thread occupancy.
  thread_block_size = max_thread_block_size;

#ifdef THREADBLOCKSIZE
  thread_block_size = THREADBLOCKSIZE;
#endif

  thread_blocks_per_streaming_multiprocessor = floor(max_threads_per_streaming_multiprocessor/thread_block_size);

#ifdef THREADBLOCKPERSM
  thread_blocks_per_streaming_multiprocessor = MIN(thread_blocks_per_streaming_multiprocessor, THREADBLOCKPERSM);
#endif

  occupancy = (((double)thread_block_size * (double)thread_blocks_per_streaming_multiprocessor)/ (double)max_threads_per_streaming_multiprocessor)*100;
}

int getSharedMemSize(int thread_block_size, int thread_blocks_per_sm, const void* func) {

#ifdef THREADBLOCKPERSM
  int max_active_thread_blocks = 0;
  int shared_mem_size = 1024;

  GPU_ERROR(cudaOccupancyMaxActiveBlocksPerMultiprocessor(
      &max_active_thread_blocks, func, thread_block_size, shared_mem_size));

  while (max_active_thread_blocks > thread_blocks_per_sm) {
    shared_mem_size += 256;
    GPU_ERROR(cudaOccupancyMaxActiveBlocksPerMultiprocessor(
        &max_active_thread_blocks, func, thread_block_size, shared_mem_size));
  }
  return shared_mem_size;
#else
  return 1;
#endif

}
