#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cuda_runtime.h>
#include <cuda.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#include "affinity.h"
#include "allocate.h"
#include "wrapper.h"
#include "profiler.h"
#include "util.h"

int numDevices = 1 ;

extern inline void gpuBenchmarks(int argc, char **argv) {
    char *type = "ws";
    size_t bytesPerWord = sizeof(double);
    size_t N = SIZE;

#ifdef _OPENMP
  GPU_ERROR(cudaGetDeviceCount(&numDevices));
  _Pragma("omp parallel") {
    int k = omp_get_num_threads();
    numDevices = MIN(k, numDevices);
    omp_set_num_threads(numDevices);
  }
#endif

  double *a[numDevices], *b[numDevices], *c[numDevices], *d[numDevices];

  if (argc > 1 && !strcmp(argv[1], "tp")) {
    type = "tp";
    _SEQ = 0;
  } else if (argc > 1 && !strcmp(argv[1], "seq")) {
    type = "seq";
    _SEQ = 1;
  }

  allocate(a, b, c, d, N);

  setBlockSize();

  printf("\n");
  printf(BANNER);
  printf(HLINE);
  printf("Total allocated datasize per GPU: %8.2f GB\n",
         4.0 * bytesPerWord * N * 1.0E-09);
  printf("Total allocated datasize: %8.2f GB\n",
         4.0 * bytesPerWord * N * numDevices * 1.0E-09);

#ifdef _OPENMP
  printf(HLINE);
  _Pragma("omp parallel") {
    int k = omp_get_num_threads();
    int i = omp_get_thread_num();
    // Logic to set maximum of #threads vs #GPUs available on node
    // #threads can be > #GPUs. If no OpenMP, then numDevices stays 1, 
    // meaning only 1 GPU is used for benchmarking.

#pragma omp single
  {
    printf("OpenMP enabled, running with %d threads and %d GPUs\n", k, numDevices);
    printf("Running with %d threadBlockSize, %d threadBlockPerSM. Expected %.2f%% thread occupancy\n", threadBlockSize, threadBlocksPerStreamingMultiprocessor, occupancy);
  }

#ifdef VERBOSE_AFFINITY
#pragma omp barrier
#pragma omp critical
    {
      printf("Thread %d running on processor %d\n", i,
             affinity_getProcessorId());
      affinity_getmask();
    }
#endif
  }
#else
  printf(HLINE);
  _SEQ = 1;
#endif

  initArrays(a, b, c, d, N);
  
  double scalar = 0.1;

  if (!strcmp(type, "tp") || !strcmp(type, "seq")) {
    printf("Running memory hierarchy sweeps\n");

    exit(EXIT_SUCCESS);
  }

  for (int k = 0; k < NTIMES; k++) {
    PROFILE(INIT, init_wrapper(b, scalar, N));
    // PROFILE(SUM, sum_wrapper(a, N));
    PROFILE(COPY, copy_wrapper(c, a, N));
    PROFILE(UPDATE, update_wrapper(a, scalar, N));
    PROFILE(TRIAD, triad_wrapper(a, b, c, scalar, N));
    PROFILE(DAXPY, daxpy_wrapper(a, b, scalar, N));
    PROFILE(STRIAD, striad_wrapper(a, b, c, d, N));
    PROFILE(SDAXPY, sdaxpy_wrapper(a, b, c, N));
  }

  profilerPrint(N);
}