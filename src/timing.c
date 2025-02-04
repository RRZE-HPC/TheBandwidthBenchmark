/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#include <stdlib.h>
#include <time.h>

double getTimeStamp(void)
{
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (double)ts.tv_sec + (double)ts.tv_nsec * 1.e-9;
}

double getTimeResolution(void)
{
  struct timespec ts;
  clock_getres(CLOCK_MONOTONIC, &ts);
  return (double)ts.tv_sec + (double)ts.tv_nsec * 1.e-9;
}
