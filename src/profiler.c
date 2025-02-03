/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of CG-Bench.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#include <float.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "profiler.h"
#include "util.h"

typedef struct {
  char* label;
  size_t words;
  size_t flops;
} workType;

double _t[NUMREGIONS][NTIMES];

static workType _regions[NUMREGIONS] = { { "Init:       ", 1, 0 },
  { "Sum:        ", 1, 1 },
  { "Copy:       ", 2, 0 },
  { "Update:     ", 2, 1 },
  { "Triad:      ", 3, 2 },
  { "Daxpy:      ", 3, 2 },
  { "STriad:     ", 4, 2 },
  { "SDaxpy:     ", 4, 2 } };

void profilerInit(void)
{
  LIKWID_MARKER_INIT;
  _Pragma("omp parallel")
  {
    LIKWID_MARKER_REGISTER("INIT");
    LIKWID_MARKER_REGISTER("SUM");
    LIKWID_MARKER_REGISTER("COPY");
    LIKWID_MARKER_REGISTER("UPDATE");
    LIKWID_MARKER_REGISTER("TRIAD");
    LIKWID_MARKER_REGISTER("DAXPY");
    LIKWID_MARKER_REGISTER("STRIAD");
    LIKWID_MARKER_REGISTER("SDAXPY");
  }

#ifdef VERBOSE_DATASIZE
  for (int i = 0; i < NUMREGIONS; i++) {
    printf("\t%s: %8.2f MB\n",
        benchmarks[i].label,
        benchmarks[i].words * bytesPerWord * N * 1.0E-06);
  }
#endif
}

void profilerPrint(size_t N)
{
  double avgtime[NUMREGIONS], maxtime[NUMREGIONS], mintime[NUMREGIONS];
  size_t bytesPerWord = sizeof(double);

  for (int j = 0; j < NUMREGIONS; j++) {
    avgtime[j] = 0;
    maxtime[j] = 0;
    mintime[j] = FLT_MAX;

    for (int k = 1; k < NTIMES; k++) {
      avgtime[j] = avgtime[j] + _t[j][k];
      mintime[j] = MIN(mintime[j], _t[j][k]);
      maxtime[j] = MAX(maxtime[j], _t[j][k]);
    }
  }

  printf(HLINE);
  printf("Function      Rate(MB/s)  Rate(MFlop/s)  Avg time     Min time     "
         "Max time\n");
  for (int j = 0; j < NUMREGIONS; j++) {
    avgtime[j]   = avgtime[j] / (double)(NTIMES - 1);
    double bytes = (double)_regions[j].words * sizeof(double) * N;
    double flops = (double)_regions[j].flops * N;

    if (flops > 0) {
      printf("%s%11.2f %11.2f %11.4f  %11.4f  %11.4f\n",
          _regions[j].label,
          1.0E-06 * bytes / mintime[j],
          1.0E-06 * flops / mintime[j],
          avgtime[j],
          mintime[j],
          maxtime[j]);
    } else {
      printf("%s%11.2f    -        %11.4f  %11.4f  %11.4f\n",
          _regions[j].label,
          1.0E-06 * bytes / mintime[j],
          avgtime[j],
          mintime[j],
          maxtime[j]);
    }
  }
  printf(HLINE);

  LIKWID_MARKER_CLOSE;
}
