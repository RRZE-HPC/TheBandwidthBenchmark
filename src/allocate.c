/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#include <errno.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

#include "allocate.h"

void *allocate(size_t alignment, size_t bytesize)
{
  int errorCode;
  void *ptr;

  errorCode = posix_memalign(&ptr, alignment, bytesize);

  if (errorCode) {
    if (errorCode == EINVAL) {
      fprintf(stderr, "Error: Alignment parameter is not a power of two\n");
      exit(EXIT_FAILURE);
    }
    if (errorCode == ENOMEM) {
      fprintf(stderr, "Error: Insufficient memory to fulfill the request\n");
      exit(EXIT_FAILURE);
    }
  }

  if (ptr == NULL) {
    fprintf(stderr, "Error: posix_memalign failed!\n");
    exit(EXIT_FAILURE);
  }

  return ptr;
}
