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
#define OMP_PARALLEL _Pragma("omp parallel for num_threads(numDevices) reduction(max:time)")
#else
#define OMP_PARALLEL
#endif

#define HARNESS(kernel)                                                        \
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
  }                                                                         

extern "C" void initArrays(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], double *__restrict__ d[], size_t N) {

#ifdef _OPENMP
  #pragma omp parallel for num_threads(numDevices)
#endif
  for( int i = 0 ; i < numDevices ; ++i )
  {    
    GPU_ERROR(cudaSetDevice(i));
    GPU_ERROR(cudaFree(0));

    init_all<<<N / 1024 + 1, 1024>>>(a[i], b[i], c[i], d[i], N);

    GPU_ERROR(cudaDeviceSynchronize());
  }

}

extern "C" double init_wrapper(double *__restrict__ b[], int scalar, size_t N) {

  double time = 0.0;

  HARNESS((init<<<N / 1024 + 1, 1024>>>(b[i], scalar, N)))

  return time;
}

extern "C" double copy_wrapper(double *__restrict__ c[], double *__restrict__ a[], size_t N) {

  double time = 0.0;

  HARNESS((copy<<<N / 1024 + 1, 1024>>>(c[i], a[i], N)))

  return time;
}

extern "C" double update_wrapper(double *__restrict__ a[], int scalar, size_t N) {

  double time = 0.0;

  HARNESS((update<<<N / 1024 + 1, 1024>>>(a[i], scalar, N)))

  return time;
}


extern "C" double triad_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], int scalar, size_t N) {

  double time = 0.0;

  HARNESS((triad<<<N / 1024 + 1, 1024>>>(a[i], b[i], c[i], scalar, N)))

  return time;
}

extern "C" double daxpy_wrapper(double *__restrict__ a[], double *__restrict__ b[], int scalar, size_t N) {

  double time = 0.0;

  HARNESS((daxpy<<<N / 1024 + 1, 1024>>>(a[i], b[i], scalar, N)))

  return time;
}

extern "C" double striad_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], double *__restrict__ d[], size_t N) {

  double time = 0.0;

  HARNESS((striad<<<N / 1024 + 1, 1024>>>(a[i], b[i], c[i], d[i], N)))

  return time;
}

extern "C" double sdaxpy_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], size_t N) {

  double time = 0.0;

  HARNESS((sdaxpy<<<N / 1024 + 1, 1024>>>(a[i], b[i], c[i], N)))

  return time;
}