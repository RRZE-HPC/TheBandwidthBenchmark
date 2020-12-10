/*
 * =======================================================================================
 *
 *      Author:   Jan Eitzinger (je), jan.eitzinger@fau.de
 *      Copyright (c) 2020 RRZE, University Erlangen-Nuremberg
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
#define _GNU_SOURCE
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include <limits.h>
#include <float.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#define SIZE 120000000ull
#define NTIMES 5
#define ARRAY_ALIGNMENT 64
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

typedef enum benchmark {
    INIT = 0,
    COPY,
    UPDATE,
    TRIAD,
    DAXPY,
    STRIAD,
    SDAXPY,
    NUMBENCH
} benchmark;

typedef struct {
    char* label;
    int words;
    int flops;
} benchmarkType;

extern double init(double*, double, int);
extern double copy(double*, double*, int);
extern double update(double*, double, int);
extern double triad(double*, double*, double*, double, int);
extern double daxpy(double*, double*, double, int);
extern double striad(double*, double*, double*, double*, int);
extern double sdaxpy(double*, double*, double*, int);
extern void check(double*, double*, double*, double*, int);
extern double getTimeStamp();

int main (int argc, char** argv)
{
    size_t bytesPerWord = sizeof(double);
    size_t N = SIZE;
    double *a, *b, *c, *d;
    double scalar, tmp;
    double E, S;

    double	avgtime[NUMBENCH],
            maxtime[NUMBENCH],
            mintime[NUMBENCH];

    double times[NUMBENCH][NTIMES];

    benchmarkType benchmarks[NUMBENCH] = {
        {"Init:       ", 1, 0},
        {"Copy:       ", 2, 0},
        {"Update:     ", 2, 1},
        {"Triad:      ", 3, 2},
        {"Daxpy:      ", 3, 2},
        {"STriad:     ", 4, 2},
        {"SDaxpy:     ", 4, 2}
    };

    posix_memalign((void**) &a, ARRAY_ALIGNMENT, N * bytesPerWord );
    posix_memalign((void**) &b, ARRAY_ALIGNMENT, N * bytesPerWord );
    posix_memalign((void**) &c, ARRAY_ALIGNMENT, N * bytesPerWord );
    posix_memalign((void**) &d, ARRAY_ALIGNMENT, N * bytesPerWord );

    for (int i=0; i<NUMBENCH; i++) {
        avgtime[i] = 0;
        maxtime[i] = 0;
        mintime[i] = FLT_MAX;
    }

#ifdef _OPENMP
    printf(HLINE);
#pragma omp parallel
    {
        int k = omp_get_num_threads();
        int i = omp_get_thread_num();

#pragma omp single
        printf ("OpenMP enabled, running with %d threads\n", k);
    }
#endif

#pragma omp parallel for schedule(static)
    for (int i=0; i<N; i++) {
        a[i] = 2.0;
        b[i] = 2.0;
        c[i] = 0.5;
        d[i] = 1.0;
    }

    scalar = 3.0;

    for ( int k=0; k < NTIMES; k++) {
        times[INIT][k]   = init(b, scalar, N);
        times[COPY][k]   = copy(c, a, N);
        times[UPDATE][k] = update(a, scalar, N);
        times[TRIAD][k]  = triad(a, b, c, scalar, N);
        times[DAXPY][k]  = daxpy(a, b, scalar, N);
        times[STRIAD][k] = striad(a, b, c, d, N);
        times[SDAXPY][k] = sdaxpy(a, b, c, N);
    }

    for (int j=0; j<NUMBENCH; j++) {
        for (int k=1; k<NTIMES; k++) {
            avgtime[j] = avgtime[j] + times[j][k];
            mintime[j] = MIN(mintime[j], times[j][k]);
            maxtime[j] = MAX(maxtime[j], times[j][k]);
        }
    }

    printf(HLINE);
    printf("Function      Rate(MB/s)  Rate(MFlop/s)  Avg time     Min time     Max time\n");
    for (int j=0; j<NUMBENCH; j++) {
        avgtime[j] = avgtime[j]/(double)(NTIMES-1);
        double bytes = (double) benchmarks[j].words * sizeof(double) * N;
        double flops = (double) benchmarks[j].flops *  N;

        if (flops > 0){
            printf("%s%11.2f %11.2f %11.4f  %11.4f  %11.4f\n", benchmarks[j].label,
                    1.0E-06 * bytes/mintime[j],
                    1.0E-06 * flops/mintime[j],
                    avgtime[j],
                    mintime[j],
                    maxtime[j]);
        } else {
            printf("%s%11.2f    -        %11.4f  %11.4f  %11.4f\n", benchmarks[j].label,
                    1.0E-06 * bytes/mintime[j],
                    avgtime[j],
                    mintime[j],
                    maxtime[j]);
        }
    }
    printf(HLINE);
    check(a, b, c, d, N);

    return EXIT_SUCCESS;
}

void check(
        double * a,
        double * b,
        double * c,
        double * d,
        int N
        )
{
    double aj, bj, cj, dj, scalar;
    double asum, bsum, csum, dsum;
    double epsilon;

    /* reproduce initialization */
    aj = 2.0;
    bj = 2.0;
    cj = 0.5;
    dj = 1.0;

    /* now execute timing loop */
    scalar = 3.0;

    for (int k=0; k<NTIMES; k++) {
        bj = scalar;
        cj = aj;
        aj = aj * scalar;
        aj = bj + scalar * cj;
        aj = aj + scalar * bj;
        aj = bj + cj * dj;
        aj = aj + bj * cj;
    }

    aj = aj * (double) (N);
    bj = bj * (double) (N);
    cj = cj * (double) (N);
    dj = dj * (double) (N);

    asum = 0.0; bsum = 0.0; csum = 0.0; dsum = 0.0;

    for (int i=0; i<N; i++) {
        asum += a[i];
        bsum += b[i];
        csum += c[i];
        dsum += d[i];
    }

#ifdef VERBOSE
    printf ("Results Comparison: \n");
    printf ("        Expected  : %f %f %f \n",aj,bj,cj);
    printf ("        Observed  : %f %f %f \n",asum,bsum,csum);
#endif

    epsilon = 1.e-8;

    if (ABS(aj-asum)/asum > epsilon) {
        printf ("Failed Validation on array a[]\n");
        printf ("        Expected  : %f \n",aj);
        printf ("        Observed  : %f \n",asum);
    }
    else if (ABS(bj-bsum)/bsum > epsilon) {
        printf ("Failed Validation on array b[]\n");
        printf ("        Expected  : %f \n",bj);
        printf ("        Observed  : %f \n",bsum);
    }
    else if (ABS(cj-csum)/csum > epsilon) {
        printf ("Failed Validation on array c[]\n");
        printf ("        Expected  : %f \n",cj);
        printf ("        Observed  : %f \n",csum);
    }
    else if (ABS(dj-dsum)/dsum > epsilon) {
        printf ("Failed Validation on array d[]\n");
        printf ("        Expected  : %f \n",dj);
        printf ("        Observed  : %f \n",dsum);
    }
    else {
        printf ("Solution Validates\n");
    }
}

double getTimeStamp()
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1.e-9;
}

double init(
        double * restrict a,
        double scalar,
        int N
        )
{
    double S, E;

    S = getTimeStamp();
#pragma omp parallel for schedule(static)
    for (int i=0; i<N; i++) {
        a[i] = scalar;
    }
    E = getTimeStamp();

    return E-S;
}

double copy(
        double * restrict a,
        double * restrict b,
        int N
        )
{
    double S, E;

    S = getTimeStamp();
#pragma omp parallel for schedule(static)
    for (int i=0; i<N; i++) {
        a[i] = b[i];
    }
    E = getTimeStamp();

    return E-S;
}

double update(
        double * restrict a,
        double scalar,
        int N
        )
{
    double S, E;

    S = getTimeStamp();
#pragma omp parallel for schedule(static)
    for (int i=0; i<N; i++) {
        a[i] = a[i] * scalar;
    }
    E = getTimeStamp();

    return E-S;
}

double triad(
        double * restrict a,
        double * restrict b,
        double * restrict c,
        double scalar,
        int N
        )
{
    double S, E;

    S = getTimeStamp();
#pragma omp parallel for schedule(static)
    for (int i=0; i<N; i++) {
        a[i] = b[i] + scalar * c[i];
    }
    E = getTimeStamp();

    return E-S;
}

double daxpy(
        double * restrict a,
        double * restrict b,
        double scalar,
        int N
        )
{
    double S, E;

    S = getTimeStamp();
#pragma omp parallel for schedule(static)
    for (int i=0; i<N; i++) {
        a[i] = a[i] + scalar * b[i];
    }
    E = getTimeStamp();

    return E-S;
}

double striad(
        double * restrict a,
        double * restrict b,
        double * restrict c,
        double * restrict d,
        int N
        )
{
    double S, E;

    S = getTimeStamp();
#pragma omp parallel for schedule(static)
    for (int i=0; i<N; i++) {
        a[i] = b[i] + d[i] * c[i];
    }
    E = getTimeStamp();

    return E-S;
}

double sdaxpy(
        double * restrict a,
        double * restrict b,
        double * restrict c,
        int N
        )
{
    double S, E;

    S = getTimeStamp();
#pragma omp parallel for schedule(static)
    for (int i=0; i<N; i++) {
        a[i] = a[i] + b[i] * c[i];
    }
    E = getTimeStamp();

    return E-S;
}
