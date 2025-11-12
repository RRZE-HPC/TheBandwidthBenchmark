/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#ifndef __PROFILER_H_
#define __PROFILER_H_
#include "likwid-marker.h"
#include <stddef.h>

#ifdef _OPENMP
#define PROFILE(tag, call)                                                     \
  _Pragma("omp parallel") { LIKWID_MARKER_START(#tag); }                       \
  _t[tag][k] = call;                                                           \
  _Pragma("omp parallel") { LIKWID_MARKER_STOP(#tag); }
#else
#define PROFILE(tag, call) _t[tag][k] = call;

#endif

typedef enum {
  INIT = 0,
  SUM,
  COPY,
  UPDATE,
  TRIAD,
  DAXPY,
  STRIAD,
  SDAXPY,
  NUMREGIONS
} regions;

extern double _t[NUMREGIONS][NTIMES];
extern int _SEQ;
extern void profilerInit();
extern void profilerPrint(size_t size);
extern void profilerOpenFile(int region);
extern void profilerCloseFile(void);
extern void profilerPrintLine(size_t N, size_t iter, int j);

#endif // __PROFILER_H
