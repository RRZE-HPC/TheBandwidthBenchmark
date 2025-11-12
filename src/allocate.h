/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#ifndef __ALLOCATE_H_
#define __ALLOCATE_H_
#include <stdlib.h>

extern void *allocate(size_t alignment, size_t bytesize);

#endif
