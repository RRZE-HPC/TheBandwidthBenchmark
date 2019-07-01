/*
 * =======================================================================================
 *
 *      Author:   Jan Eitzinger (je), jan.treibig@gmail.com
 *      Copyright (c) 2019 RRZE, University Erlangen-Nuremberg
 *
 *      Permission is hereby granted, free of charge, to any person obtaining a copy
 *      of this software and associated documentation files (the "Software"), to deal
 *      in the Software without restriction, including without limitation the rights
 *      to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *      copies of the Software, and to permit persons to whom the Software is
 *      furnished to do so, subject to the following conditions:
 *
 *      The above copyright notice and this permission notice shall be included in all
 *      copies or substantial portions of the Software.
 *
 *      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *      IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *      FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *      AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *      LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *      OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *      SOFTWARE.
 *
 * =======================================================================================
 */

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <limits.h>
#include <float.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#include <likwid_markers.h>
#include <timing.h>
#include <allocate.h>
#include <affinity.h>

#define HLINE "----------------------------------------------------------------------------\n"


#ifndef MIN
#define MIN(x,y) ((x)<(y)?(x):(y))
#endif
#ifndef MAX
#define MAX(x,y) ((x)>(y)?(x):(y))
#endif
#ifndef ABS
#define ABS(a) ((a) >= 0 ? (a) : -(a))
#endif

extern double striad_seq(double*, double*, double*, double*, int, int);
extern double striad_tp(double*, double*, double*, double*, int, int);
extern double striad_ws(double*, double*, double*, double*, int, int);

typedef double (*testFunc)(double*, double*, double*, double*, int, int);

int main (int argc, char** argv)
{
    size_t bytesPerWord = sizeof(double);
    size_t N;
    int type;
    size_t iter = 1;
    size_t scale = 1;
    double *a, *b, *c, *d;
    double E, S;
    double	avgtime, maxtime, mintime;
    double times[NTIMES];
    double dataSize;
    testFunc func;
    char* testname;


    if ( argc > 2 ) {
        type = atoi(argv[1]);
        N = atoi(argv[2]);
    } else {
        printf("Usage: %s <test type>  <N>\n",argv[0]);
        printf("Test types: 0 - sequential, 1 - OpenMP throughput, 2 - OpenMP worksharing\n");
        exit(EXIT_SUCCESS);
    }

    LIKWID_MARKER_INIT;

    switch ( type ) {
        case 0:
            func = striad_seq;
            testname = "striad_seq";
            break;
        case 1:
            func = striad_tp;
            testname = "striad_tp";
#ifdef _OPENMP
#pragma omp parallel
            {
#pragma omp single
                scale = omp_get_num_threads();


                LIKWID_MARKER_REGISTER("BENCH");
            }
#endif
            break;
        case 2:
            func = striad_ws;
            testname = "striad_ws";
            break;
        default:
            printf("Unknown test type: %d\n", type);
            exit(EXIT_FAILURE);
    }

    a = (double*) allocate( ARRAY_ALIGNMENT, N * bytesPerWord );
    b = (double*) allocate( ARRAY_ALIGNMENT, N * bytesPerWord );
    c = (double*) allocate( ARRAY_ALIGNMENT, N * bytesPerWord );
    d = (double*) allocate( ARRAY_ALIGNMENT, N * bytesPerWord );

#ifdef VERBOSE
    printf(HLINE);
    dataSize = 4.0 * bytesPerWord * N;

    if ( dataSize < 1.0E06 ) {
        printf ("Total allocated datasize: %8.2f KB\n", dataSize * 1.0E-03);
    } else {
        printf ("Total allocated datasize: %8.2f MB\n", dataSize * 1.0E-06);
    }
#endif
        avgtime = 0;
        maxtime = 0;
        mintime = FLT_MAX;

#ifdef VERBOSE
#ifdef _OPENMP
    printf(HLINE);
#pragma omp parallel
    {
        int k = omp_get_num_threads();
        int i = omp_get_thread_num();

#pragma omp single
        printf ("OpenMP enabled, running with %d threads\n", k);

        printf ("\tThread %d running on processor %d\n", i, affinity_getProcessorId());
    }
#endif
#endif

    S = getTimeStamp();
#pragma omp parallel for
    for (int i=0; i<N; i++) {
        a[i] = 2.0;
        b[i] = 1.0;
        c[i] = 0.8;
        d[i] = 1.01;
    }
    E = getTimeStamp();
#ifdef VERBOSE
    printf ("Timer resolution %.2e ", getTimeResolution());
    printf ("Ticks used %.0e\n", (E-S) / getTimeResolution());
#endif

    iter = 5;
    times[0] = 0.0;
    times[1] = 0.0;

    while ( times[0] < 0.2 ){
        times[0] = func(a, b, c, d, N, iter);
        if ( times[0] > 0.1 ) break;
        double factor = 0.2 / (times[0] - times[1]);
        iter *= (int) factor;
        times[1] = times[0];
    }

#ifdef VERBOSE
    printf ("Using %d iterations \n", iter);
#endif

    for ( int k=0; k < NTIMES; k++) {
        times[k] = func(a, b, c, d, N, iter);
    }

    for (int k=1; k<NTIMES; k++) {
        avgtime = avgtime + times[k];
        mintime = MIN(mintime, times[k]);
        maxtime = MAX(maxtime, times[k]);
    }

#ifdef VERBOSE
    printf(HLINE);
    printf("Function      Rate(MB/s)  Rate(MFlop/s)  Avg time     Min time     Max time\n");
    avgtime = avgtime/(double)(NTIMES-1);
    double bytes = (double) 4.0 * sizeof(double) * N * iter * scale;
    double flops = (double) 2.0 * N * iter * scale;

        printf("%s %11.2f %11.2f %11.4f  %11.4f  %11.4f\n",
                testname,
                1.0E-06 * bytes/mintime,
                1.0E-06 * flops/mintime,
                avgtime,
                mintime,
                maxtime);
    printf("Flops %e\n", flops);
    printf(HLINE);
#else
    double flops = (double) 2 * N * iter * scale;
    printf("%d %.2f\n", N, 1.0E-06 * flops/mintime);
#endif

    LIKWID_MARKER_CLOSE;
    return EXIT_SUCCESS;
}

