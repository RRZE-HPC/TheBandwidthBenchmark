/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#ifndef __ALLOCATE_H_
#define __ALLOCATE_H_
#include <stdlib.h>
#include "util.h"

extern void allocate(double *restrict a[], double *restrict b[], double *restrict c[], double *restrict d[], size_t arraySize);
#endif
