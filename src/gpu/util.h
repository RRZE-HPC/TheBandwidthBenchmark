/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#ifndef __UTIL_H_
#define __UTIL_H_

#include <cuda_runtime.h>
#include <stdbool.h>

#define HLINE                                                                  \
  "--------------------------------------------------------------------------" \
  "------\n"

#define BANNER                                                                 \
  "_|                            _|_|_|                                  _|  " \
  "      \n"                                                                   \
  "_|_|_|    _|      _|      _|  _|    _|    _|_|    _|_|_|      _|_|_|  "     \
  "_|_|_|    \n"                                                               \
  "_|    _|  _|      _|      _|  _|_|_|    _|_|_|_|  _|    _|  _|        _|  " \
  "  _|  \n"                                                                   \
  "_|    _|    _|  _|  _|  _|    _|    _|  _|        _|    _|  _|        _|  " \
  "  _|  \n"                                                                   \
  "_|_|_|        _|      _|      _|_|_|      _|_|_|  _|    _|    _|_|_|  _|  " \
  "  _|  \n"

#ifndef MIN
#define MIN(x, y) ((x) < (y) ? (x) : (y))
#endif

#ifndef MAX
#define MAX(x, y) ((x) > (y) ? (x) : (y))
#endif

#ifndef ABS
#define ABS(a) ((a) >= 0 ? (a) : -(a))
#endif

#define DEBUG_MESSAGE debug_printf

#define GPU_ERROR(ans) \
  do { gpuAssert((ans), __FILE__, __LINE__, true); } while (0)

static inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort)
{
    if (code != cudaSuccess) {
        fprintf(stderr, "GPUassert: \"%s\" in %s:%d\n",
                cudaGetErrorString(code), file, line);
        if (abort)
            exit((int)code);
    }
}

#endif
