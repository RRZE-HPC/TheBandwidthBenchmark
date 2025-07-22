/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#include <float.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "profiler.h"
#include "util.h"

typedef struct {
  char *label;
  size_t words;
  size_t flops;
} workType;

double _t[NUMREGIONS][NTIMES];
FILE *profilerFile = NULL;

static workType _regions[NUMREGIONS] = {
    {"Init", 1, 0},  {"Sum", 1, 1},   {"Copy", 2, 0},   {"Update", 2, 1},
    {"Triad", 3, 2}, {"Daxpy", 3, 2}, {"STriad", 4, 2}, {"SDaxpy", 4, 2}};

void profilerInit(void) {
  LIKWID_MARKER_INIT;
  _Pragma("omp parallel") {
    LIKWID_MARKER_REGISTER("INIT");
    LIKWID_MARKER_REGISTER("SUM");
    LIKWID_MARKER_REGISTER("COPY");
    LIKWID_MARKER_REGISTER("UPDATE");
    LIKWID_MARKER_REGISTER("TRIAD");
    LIKWID_MARKER_REGISTER("DAXPY");
    LIKWID_MARKER_REGISTER("STRIAD");
    LIKWID_MARKER_REGISTER("SDAXPY");
  }
}

static void computeStats(double *avgtime, double *maxtime, double *mintime,
                         int j) {
  *avgtime = 0;
  *maxtime = 0;
  *mintime = FLT_MAX;

  for (int k = 1; k < NTIMES; k++) {
    *avgtime += _t[j][k];
    *mintime = MIN(*mintime, _t[j][k]);
    *maxtime = MAX(*maxtime, _t[j][k]);
  }

  *avgtime /= (double)(NTIMES - 1);
}

void profilerOpenFile(int region) {
  char filename[40];
  sprintf(filename, "%s.dat", _regions[region].label);
  profilerFile = fopen(filename, "w");
  if (_regions[region].flops == 0) {
    fprintf(profilerFile, "# %s: %lu words, no flops\n", _regions[region].label,
            _regions[region].words);
    fprintf(
        profilerFile,
        "# N  Bytes(MB)  Rate(GB/s)  Avg time(s)  Min time(s)  Max time(s)\n");
  } else {
    fprintf(profilerFile, "# %s: %lu words, %lu flops\n",
            _regions[region].label, _regions[region].words,
            _regions[region].words);
    fprintf(
        profilerFile,
        "# N  Bytes(MB)  Rate(GB/s)  Rate(MFlop/s)  Avg time(s)  Min time(s)  "
        "Max time(s)\n");
  }

  printf("Running kernel %s\n", _regions[region].label);
}

void profilerCloseFile(void) { fclose(profilerFile); }

void profilerPrintLine(size_t N, int iter, int j) {
  size_t bytesPerWord = sizeof(double);
  double avgtime, maxtime, mintime;

  computeStats(&avgtime, &maxtime, &mintime, j);
  double bytes = (double)_regions[j].words * sizeof(double) * N;
  double flops = (double)_regions[j].flops * N * iter;

  if (flops > 0) {
    fprintf(profilerFile, "%lu %11.2f %11.2f %11.2f %11.4f  %11.4f  %11.4f\n",
            N, 1.0E-06 * bytes, 1.0E-09 * bytes * iter / mintime,
            1.0E-06 * flops / mintime, avgtime, mintime, maxtime);
  } else {
    fprintf(profilerFile, "%lu %11.2f %11.2f %11.4f  %11.4f  %11.4f\n", N,
            1.0E-06 * bytes, 1.0E-09 * bytes * iter / mintime, avgtime, mintime,
            maxtime);
  }
}

void profilerPrint(size_t N) {
  size_t bytesPerWord = sizeof(double);
  double avgtime, maxtime, mintime;

#ifdef VERBOSE_DATASIZE
  printf(HLINE);
  printf("Dataset sizes\n");
  for (int i = 0; i < NUMREGIONS; i++) {
    printf("%s: %8.2f MB\n", _regions[i].label,
           _regions[i].words * bytesPerWord * N * 1.0E-06);
  }
#endif

  printf(HLINE);
  printf("Function      Rate(MB/s)  Rate(MFlop/s)  Avg time     Min time     "
         "Max time\n");

  for (int j = 0; j < NUMREGIONS; j++) {
    computeStats(&avgtime, &maxtime, &mintime, j);
    double bytes = (double)_regions[j].words * sizeof(double) * N;
    double flops = (double)_regions[j].flops * N;

    if (flops > 0) {
      printf("%s%11.2f %11.2f %11.4f  %11.4f  %11.4f\n", _regions[j].label,
             1.0E-06 * bytes / mintime, 1.0E-06 * flops / mintime, avgtime,
             mintime, maxtime);
    } else {
      printf("%s%11.2f    -        %11.4f  %11.4f  %11.4f\n", _regions[j].label,
             1.0E-06 * bytes / mintime, avgtime, mintime, maxtime);
    }
  }
  printf(HLINE);

  LIKWID_MARKER_CLOSE;
}
