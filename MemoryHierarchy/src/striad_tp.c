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

#include <stdio.h>

#include <timing.h>
#include <allocate.h>

double striad_tp(
        double * restrict a,
        const double * restrict b,
        const double * restrict c,
        const double * restrict d,
        int N,
        int iter
        )
{
    double S, E;

#pragma omp parallel
    {
        double* al = (double*) allocate( ARRAY_ALIGNMENT, N * sizeof(double) );

#pragma omp single
        S = getTimeStamp();
        for(int j = 0; j < iter; j++) {
            for (int i=0; i<N; i++) {
                al[i] = b[i] + d[i] * c[i];
            }

            if (al[N-1] > 2000) printf("Ai = %f\n",al[N-1]);
        }
#pragma omp single
        E = getTimeStamp();
    }

    return E-S;
}
