#include <cuda_runtime.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

extern "C" {
#include "timing.h"
static int getSharedMemSize(
    int thread_block_size, int thread_blocks_per_sm, const void* func);
}

#define GPU_ERROR(ans)                                                         \
  do {                                                                         \
    gpuAssert((ans), __FILE__, __LINE__, true);                                \
  } while (0)

static inline void gpuAssert(
    cudaError_t code, const char* file, int line, bool abort)
{
  if (code != cudaSuccess) {
    fprintf(stderr,
        "GPUassert: \"%s\" in %s:%d\n",
        cudaGetErrorString(code),
        file,
        line);
    if (abort) exit((int)code);
  }
}

int thread_block_size                          = 1;
int max_thread_block_size                      = 1;
int max_threads_per_streaming_multiprocessor   = 1;
int thread_blocks_per_streaming_multiprocessor = 1;
double occupancy                               = 0.0;

__global__ void init_all(double* __restrict__ a,
    double* __restrict__ b,
    double* __restrict__ c,
    double* __restrict__ d,
    const size_t N)
{

  int tidx = threadIdx.x + blockIdx.x * blockDim.x;

  if (tidx >= N) return;

  a[tidx] = 2.0;
  b[tidx] = 2.0;
  c[tidx] = 0.5;
  d[tidx] = 1.0;
}

__global__ void initCuda(double* __restrict__ b, int scalar, size_t N)
{

  int tidx = threadIdx.x + blockIdx.x * blockDim.x;

  if (tidx >= N) return;

  b[tidx] = scalar;
}

__global__ void copyCuda(
    double* __restrict__ c, double* __restrict__ a, size_t N)
{

  int tidx = threadIdx.x + blockIdx.x * blockDim.x;

  if (tidx >= N) return;

  c[tidx] = a[tidx];
}

__global__ void updateCuda(double* __restrict__ a, int scalar, size_t N)
{

  int tidx = threadIdx.x + blockIdx.x * blockDim.x;

  if (tidx >= N) return;

  a[tidx] = a[tidx] * scalar;
}

__global__ void triadCuda(double* __restrict__ a,
    double* __restrict__ b,
    double* __restrict__ c,
    int scalar,
    size_t N)
{

  int tidx = threadIdx.x + blockIdx.x * blockDim.x;

  if (tidx >= N) return;

  a[tidx] = b[tidx] + scalar * c[tidx];
}

__global__ void daxpyCuda(
    double* __restrict__ a, double* __restrict__ b, int scalar, size_t N)
{

  int tidx = threadIdx.x + blockIdx.x * blockDim.x;

  if (tidx >= N) return;

  a[tidx] = a[tidx] + scalar * b[tidx];
}

__global__ void striadCuda(double* __restrict__ a,
    double* __restrict__ b,
    double* __restrict__ c,
    double* __restrict__ d,
    size_t N)
{

  int tidx = threadIdx.x + blockIdx.x * blockDim.x;

  if (tidx >= N) return;

  a[tidx] = b[tidx] + d[tidx] * c[tidx];
}

__global__ void sdaxpyCuda(double* __restrict__ a,
    double* __restrict__ b,
    double* __restrict__ c,
    size_t N)
{

  int tidx = threadIdx.x + blockIdx.x * blockDim.x;

  if (tidx >= N) return;

  a[tidx] = a[tidx] + b[tidx] * c[tidx];
}

__device__ void warpReduce(volatile int* shared_data, int tidx)
{
  shared_data[tidx] += shared_data[tidx + 32];
  shared_data[tidx] += shared_data[tidx + 16];
  shared_data[tidx] += shared_data[tidx + 8];
  shared_data[tidx] += shared_data[tidx + 4];
  shared_data[tidx] += shared_data[tidx + 2];
  shared_data[tidx] += shared_data[tidx + 1];
}

// Inspired by the
// https://developer.download.nvidia.com/assets/cuda/files/reduction.pdf
__global__ void sumCuda(
    double* __restrict__ a, double* __restrict__ a_out, size_t N)
{
  extern __shared__ int shared_data[];

  unsigned int tidx = threadIdx.x;
  unsigned int i    = blockIdx.x * (blockDim.x * 2) + threadIdx.x;
  shared_data[tidx] = a[i] + a[i + blockDim.x];
  __syncthreads();

  for (int s = blockDim.x / 2; s > 32; s >>= 1) {

    if (tidx < s) {
      shared_data[tidx] += shared_data[tidx + s];
    }
    __syncthreads();
  }

  if (tidx < 32) {
    warpReduce(shared_data, tidx);
  }

  if (tidx == 0) {
    a[blockIdx.x] = shared_data[0];
  }
}

#define SHARED_MEM(kernel_name)                                                \
  getSharedMemSize(thread_block_size,                                          \
      thread_blocks_per_streaming_multiprocessor,                              \
      (const void*)&kernel_name)

#define HARNESS(kernel, kernel_name)                                           \
  int shared_mem_size = SHARED_MEM(kernel_name);                               \
  GPU_ERROR(cudaSetDevice(0));                                                 \
  GPU_ERROR(cudaFree(0));                                                      \
  double S = getTimeStamp();                                                   \
  kernel;                                                                      \
  GPU_ERROR(cudaDeviceSynchronize());                                          \
  double E = getTimeStamp();                                                   \
  return E - S;

extern "C" {
void allocateArrays(double** a, double** b, double** c, double** d, size_t N)
{
  GPU_ERROR(cudaSetDevice(0));
  GPU_ERROR(cudaFree(0));

  GPU_ERROR(cudaMalloc((void**)a, N * sizeof(double)));
  GPU_ERROR(cudaMalloc((void**)b, N * sizeof(double)));
  GPU_ERROR(cudaMalloc((void**)c, N * sizeof(double)));
  GPU_ERROR(cudaMalloc((void**)d, N * sizeof(double)));
}

void initArrays(double* __restrict__ a,
    double* __restrict__ b,
    double* __restrict__ c,
    double* __restrict__ d,
    size_t N)
{
  GPU_ERROR(cudaSetDevice(0));
  GPU_ERROR(cudaFree(0));

  init_all<<<N / thread_block_size + 1, thread_block_size>>>(a, b, c, d, N);

  GPU_ERROR(cudaDeviceSynchronize());
}

double init(double* __restrict__ b, int scalar, size_t N)
{

  HARNESS((initCuda<<<N / thread_block_size + 1,
                  thread_block_size,
                  shared_mem_size>>>(b, scalar, N)),
      init)
}

double copy(double* __restrict__ c, double* __restrict__ a, size_t N)
{

  HARNESS((copyCuda<<<N / thread_block_size + 1,
                  thread_block_size,
                  shared_mem_size>>>(c, a, N)),
      copy)
}

double update(double* __restrict__ a, int scalar, size_t N)
{

  HARNESS((updateCuda<<<N / thread_block_size + 1,
                  thread_block_size,
                  shared_mem_size>>>(a, scalar, N)),
      update)
}

double triad(double* __restrict__ a,
    double* __restrict__ b,
    double* __restrict__ c,
    int scalar,
    size_t N)
{

  HARNESS((triadCuda<<<N / thread_block_size + 1,
                  thread_block_size,
                  shared_mem_size>>>(a, b, c, scalar, N)),
      triad)
}

double daxpy(
    double* __restrict__ a, double* __restrict__ b, int scalar, size_t N)
{

  HARNESS((daxpyCuda<<<N / thread_block_size + 1,
                  thread_block_size,
                  shared_mem_size>>>(a, b, scalar, N)),
      daxpy)
}

double striad(double* __restrict__ a,
    double* __restrict__ b,
    double* __restrict__ c,
    double* __restrict__ d,
    size_t N)
{

  HARNESS((striadCuda<<<N / thread_block_size + 1,
                  thread_block_size,
                  shared_mem_size>>>(a, b, c, d, N)),
      striad)
}

double sdaxpy(double* __restrict__ a,
    double* __restrict__ b,
    double* __restrict__ c,
    size_t N)
{

  HARNESS((sdaxpyCuda<<<N / thread_block_size + 1,
                  thread_block_size,
                  shared_mem_size>>>(a, b, c, N)),
      sdaxpy)
}

double sum(double* __restrict__ a, size_t N)
{
  GPU_ERROR(cudaSetDevice(0));
  GPU_ERROR(cudaFree(0));
  double* a_out;
  GPU_ERROR(cudaMalloc(&a_out,
      (N + (thread_block_size - 1)) / thread_block_size * sizeof(double)));
  double S = getTimeStamp();
  sumCuda<<<N / (thread_block_size * 2) + 1,
      thread_block_size,
      thread_block_size * sizeof(double)>>>(a, a_out, N);
  GPU_ERROR(cudaDeviceSynchronize());
  double E = getTimeStamp();
  return E - S;
}

void setBlockSize()
{
  cudaDeviceProp prop;
  GPU_ERROR(cudaGetDeviceProperties(&prop, 0));

  max_thread_block_size                    = prop.maxThreadsPerBlock;
  max_threads_per_streaming_multiprocessor = prop.maxThreadsPerMultiProcessor;

  // Not the best case for thread_block_size.
  // Varying thread_block_size can result in
  // better performance and thread occupancy.
  thread_block_size = max_thread_block_size;

#ifdef THREADBLOCKSIZE
  thread_block_size = THREADBLOCKSIZE;
#endif

  thread_blocks_per_streaming_multiprocessor = floor(
      max_threads_per_streaming_multiprocessor / thread_block_size);

#ifdef THREADBLOCKPERSM
  thread_blocks_per_streaming_multiprocessor = MIN(
      thread_blocks_per_streaming_multiprocessor,
      THREADBLOCKPERSM);
#endif

  occupancy = (((double)thread_block_size *
                   (double)thread_blocks_per_streaming_multiprocessor) /
                  (double)max_threads_per_streaming_multiprocessor) *
              100;
}

int getSharedMemSize(
    int thread_block_size, int thread_blocks_per_sm, const void* func)
{

#ifdef THREADBLOCKPERSM
  int max_active_thread_blocks = 0;
  int shared_mem_size          = 1024;

  GPU_ERROR(
      cudaOccupancyMaxActiveBlocksPerMultiprocessor(&max_active_thread_blocks,
          func,
          thread_block_size,
          shared_mem_size));

  while (max_active_thread_blocks > thread_blocks_per_sm) {
    shared_mem_size += 256;
    GPU_ERROR(
        cudaOccupancyMaxActiveBlocksPerMultiprocessor(&max_active_thread_blocks,
            func,
            thread_block_size,
            shared_mem_size));
  }
  return shared_mem_size;
#else
  return 1;
#endif
}
}
