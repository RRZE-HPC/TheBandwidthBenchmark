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
#include "kernels.h"
#include "profiler.h"
#include "util.h"

int numDevices = 1 ;

static void kernelSwitch(double * restrict*, double * restrict*, double * restrict*, double * restrict*, double, size_t,
                         int, int);

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
    numDevices = 1;
  }

  allocate(a, b, c, d, N);

  setBlockSize();

  printf("\n");
  printf(BANNER);
  printf(HLINE);
  printf("Total allocated datasize per GPU: \t%8.2f GB\n",
         4.0 * bytesPerWord * N * 1.0E-09);
  printf("Total allocated datasize: \t\t%8.2f GB\n",
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
    printf("Running with %d Thread Block Size, %d Thread Block Per SM. Expected %.2f%% thread occupancy\n", thread_block_size, thread_blocks_per_streaming_multiprocessor, occupancy);
    printf(HLINE);
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
  printf("OpenMP disabled, running with 1 threads and 1 GPU\n");
  printf("Running with %d Thread Block Size, %d Thread Block Per SM. Expected %.2f%% thread occupancy\n", thread_block_size, thread_blocks_per_streaming_multiprocessor, occupancy);
  printf(HLINE);

  _SEQ = 1;
#endif

  initArrays(a, b, c, d, N);
  
  double scalar = 0.1;

  if (!strcmp(type, "tp") || !strcmp(type, "seq")) {
    printf("Running memory hierarchy sweeps\n");

    for (int j = 0; j < NUMREGIONS; j++) {
      N = 100;

      profilerOpenFile(j);

      while (N < SIZE) {

        double newtime = 0.0;
        double oldtime = 0.0;
        int iter = 2;

        while (newtime < 0.3) {
          newtime = striad_seq_wrapper(a, b, c, d, N, iter);
          if (newtime > 0.1) {
            break;
          }
          if ((newtime - oldtime) > 0.0) {
            double factor = 0.3 / (newtime - oldtime);
            iter *= (int)factor;
            oldtime = newtime;
          }
        }

        kernelSwitch(a, b, c, d, scalar, N, iter, j);

        profilerPrintLine(N, iter, j);
        N = ((double)N * 1.2);
      }

      profilerCloseFile();
    }

    exit(EXIT_SUCCESS);
  }

  for (int k = 0; k < NTIMES; k++) {
    PROFILE(INIT, init_wrapper(b, scalar, N));
    PROFILE(SUM, sum_wrapper(a, N));
    PROFILE(COPY, copy_wrapper(c, a, N));
    PROFILE(UPDATE, update_wrapper(a, scalar, N));
    PROFILE(TRIAD, triad_wrapper(a, b, c, scalar, N));
    PROFILE(DAXPY, daxpy_wrapper(a, b, scalar, N));
    PROFILE(STRIAD, striad_wrapper(a, b, c, d, N));
    PROFILE(SDAXPY, sdaxpy_wrapper(a, b, c, N));
  }

  profilerPrint(N);
}

void kernelSwitch(double *restrict a[], double *restrict b[], double *restrict c[],
                  double *restrict d[], double scalar, size_t N, int iter, int j) {
  switch (j) {
  case INIT:
    if (_SEQ) {
      for (int k = 0; k < NTIMES; k++) {
        _t[INIT][k] = init_seq_wrapper(a, scalar, N, iter);
      }
    } else {
      for (int k = 0; k < NTIMES; k++) {
        _t[INIT][k] = init_tp_wrapper(a, scalar, N, iter);
      }
    }
    break;

  case SUM:
    if (_SEQ) {
      for (int k = 0; k < NTIMES; k++) {
        _t[SUM][k] = sum_seq_wrapper(a, N, iter);
      }
    } else {
      for (int k = 0; k < NTIMES; k++) {
        _t[SUM][k] = sum_tp_wrapper(a, N, iter);
      }
    }
    break;

  case COPY:
    if (_SEQ) {
      for (int k = 0; k < NTIMES; k++) {
        _t[COPY][k] = copy_seq_wrapper(a, b, N, iter);
      }
    } else {
      for (int k = 0; k < NTIMES; k++) {
        _t[COPY][k] = copy_tp_wrapper(a, b, N, iter);
      }
    }
    break;

  case UPDATE:
    if (_SEQ) {
      for (int k = 0; k < NTIMES; k++) {
        _t[UPDATE][k] = update_seq_wrapper(a, scalar, N, iter);
      }
    } else {
      for (int k = 0; k < NTIMES; k++) {
        _t[UPDATE][k] = update_tp_wrapper(a, scalar, N, iter);
      }
    }
    break;

  case TRIAD:
    if (_SEQ) {
      for (int k = 0; k < NTIMES; k++) {
        _t[TRIAD][k] = triad_seq_wrapper(a, b, c, scalar, N, iter);
      }
    } else {
      for (int k = 0; k < NTIMES; k++) {
        _t[TRIAD][k] = triad_tp_wrapper(a, b, c, scalar, N, iter);
      }
    }
    break;

  case DAXPY:
    if (_SEQ) {
      for (int k = 0; k < NTIMES; k++) {
        _t[DAXPY][k] = daxpy_seq_wrapper(a, b, scalar, N, iter);
      }
    } else {
      for (int k = 0; k < NTIMES; k++) {
        _t[DAXPY][k] = daxpy_tp_wrapper(a, b, scalar, N, iter);
      }
    }
    break;

  case STRIAD:
    if (_SEQ) {
      for (int k = 0; k < NTIMES; k++) {
        _t[STRIAD][k] = striad_seq_wrapper(a, b, c, d, N, iter);
      }
    } else {
      for (int k = 0; k < NTIMES; k++) {
        _t[STRIAD][k] = striad_tp_wrapper(a, b, c, d, N, iter);
      }
    }
    break;

  case SDAXPY:
    if (_SEQ) {
      for (int k = 0; k < NTIMES; k++) {
        _t[SDAXPY][k] = sdaxpy_seq_wrapper(a, b, c, N, iter);
      }
    } else {
      for (int k = 0; k < NTIMES; k++) {
        _t[SDAXPY][k] = sdaxpy_tp_wrapper(a, b, c, N, iter);
      }
    }
    break;
  }
}
