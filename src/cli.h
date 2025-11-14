/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#ifndef CLI_H
#define CLI_H

#include <stdio.h>
#include <stdlib.h>

typedef enum { WS = 0, TP, SQ, NUMTYPES } types;

#define HELPTEXT                                                                         \
  "Usage: bwBench [options]\n\n"                                                         \
  "Options:\n"                                                                           \
  "  -h              Show this help text\n"                                              \
  "  -m <type>       Benchmark type, can be ws (default), tp, or seq.\n"                 \
  "  -s <long int>   Size in GB for allocated vectors\n"                                 \
  "  -n <long int>   Number of iterations\n"                                             \
  "  -i <type>       Data initialization type, can be constant, or random"               \
  "  -d <int>        (If GPU enabled) GPU ID on which you want your program "            \
  "to run\n"

extern int CUDA_DEVICE;
extern int type;
extern int _SEQ;
extern int data_init_type;
extern size_t N;
extern size_t ITERS;

extern void parseCLI(int, char **);

#endif /*CLI_H*/
