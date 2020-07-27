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
package main

import (
	"flag"
	"fmt"
	"math"
	"sync"
	"time"
)

type bench func(int, *sync.WaitGroup)

type benchmark struct {
	label string
	words float64
	flops float64
	fct   bench
}

func Min(x, y int) int {
	if x < y {
		return x
	}
	return y
}

func getChunk(N int, tid int, numThreads int) (is, ie int) {
	cs := N / numThreads
	is = tid * cs
	ie = Min(N, is+cs)
	return
}

func main() {
	const NTIMES int = 4
	var N int = 40000000
	var scalar float64 = 3.0
	a := make([]float64, N)
	b := make([]float64, N)
	c := make([]float64, N)
	d := make([]float64, N)

	numThreads := flag.Int("nt", 4, "Number of threads")
	flag.Parse()

	for i := 0; i < N; i++ {
		a[i] = 2.0
		b[i] = 2.0
		c[i] = 0.5
		d[i] = 1.0
	}

	benchmarks := [...]benchmark{
		{label: "Init", words: 1, flops: 0,
			fct: func(threadId int, wg *sync.WaitGroup) {
				defer wg.Done()
				is, ie := getChunk(N, threadId, *numThreads)
				for i := is; i < ie; i++ {
					b[i] = scalar
				}
			}},
		{label: "Copy", words: 2, flops: 0,
			fct: func(threadId int, wg *sync.WaitGroup) {
				defer wg.Done()
				is, ie := getChunk(N, threadId, *numThreads)
				for i := is; i < ie; i++ {
					c[i] = a[i]
				}
			}},
		{label: "Update", words: 2, flops: 1,
			fct: func(threadId int, wg *sync.WaitGroup) {
				defer wg.Done()
				is, ie := getChunk(N, threadId, *numThreads)
				for i := is; i < ie; i++ {
					a[i] = a[i] * scalar
				}
			}},
		{label: "Triad", words: 3, flops: 2,
			fct: func(threadId int, wg *sync.WaitGroup) {
				defer wg.Done()
				is, ie := getChunk(N, threadId, *numThreads)
				for i := is; i < ie; i++ {
					a[i] = b[i] + scalar*c[i]
				}
			}},
		{label: "Daxpy", words: 3, flops: 2,
			fct: func(threadId int, wg *sync.WaitGroup) {
				defer wg.Done()
				is, ie := getChunk(N, threadId, *numThreads)
				for i := is; i < ie; i++ {
					a[i] = a[i] + scalar*b[i]
				}
			}},
		{label: "STriad", words: 4, flops: 2,
			fct: func(threadId int, wg *sync.WaitGroup) {
				defer wg.Done()
				is, ie := getChunk(N, threadId, *numThreads)
				for i := is; i < ie; i++ {
					a[i] = b[i] + d[i]*c[i]
				}
			}},
		{label: "SDaxpy", words: 4, flops: 2,
			fct: func(threadId int, wg *sync.WaitGroup) {
				defer wg.Done()
				is, ie := getChunk(N, threadId, *numThreads)
				for i := is; i < ie; i++ {
					a[i] = a[i] + b[i]*c[i]
				}
			}}}

	var min, max, avg [len(benchmarks)]float64
	var times [len(benchmarks)][NTIMES]float64

	for i := 0; i < len(benchmarks); i++ {
		avg[i], max[i] = 0.0, 0.0
		min[i] = math.MaxFloat64
	}

	for k := 0; k < NTIMES; k++ {
		for j := 0; j < len(benchmarks); j++ {
			times[j][k] = execBench(*numThreads, benchmarks[j].fct)
		}
	}

	for j := 0; j < len(benchmarks); j++ {
		for k := 0; k < NTIMES; k++ {
			avg[j] = avg[j] + times[j][k]
			min[j] = math.Min(min[j], times[j][k])
			max[j] = math.Max(max[j], times[j][k])
		}
	}

	fmt.Println("----------------------------------------------------------------------------")
	fmt.Printf("Function      Rate(MB/s)  Rate(MFlop/s)  Avg time     Min time     Max time\n")
	for j := 0; j < len(benchmarks); j++ {
		avg[j] = avg[j] / float64(NTIMES-1)
		bytes := benchmarks[j].words * 8.0 * float64(N)
		flops := benchmarks[j].flops * float64(N)

		if flops > 0 {
			fmt.Printf("%s%11.2f %11.2f %11.4f  %11.4f  %11.4f\n", benchmarks[j].label,
				1.0E-06*bytes/min[j], 1.0E-06*flops/min[j],
				avg[j], min[j], max[j])
		} else {
			fmt.Printf("%s%11.2f    -        %11.4f  %11.4f  %11.4f\n", benchmarks[j].label,
				1.0E-06*bytes/min[j], avg[j], min[j], max[j])
		}
	}
	fmt.Println("----------------------------------------------------------------------------")

	check(a, b, c, d, N, NTIMES)
}

func check(
	a []float64,
	b []float64,
	c []float64,
	d []float64,
	N int, NTIMES int) {
	var aj, bj, cj, dj, scalar float64
	var asum, bsum, csum, dsum float64
	var epsilon float64

	/* reproduce initialization */
	aj = 2.0
	bj = 2.0
	cj = 0.5
	dj = 1.0

	/* now execute timing loop */
	scalar = 3.0

	for k := 0; k < NTIMES; k++ {
		bj = scalar
		cj = aj
		aj = aj * scalar
		aj = bj + scalar*cj
		aj = aj + scalar*bj
		aj = bj + cj*dj
		aj = aj + bj*cj
	}

	aj = aj * float64(N)
	bj = bj * float64(N)
	cj = cj * float64(N)
	dj = dj * float64(N)

	asum = 0.0
	bsum = 0.0
	csum = 0.0
	dsum = 0.0

	for i := 0; i < N; i++ {
		asum += a[i]
		bsum += b[i]
		csum += c[i]
		dsum += d[i]
	}

	epsilon = 1.e-8

	if math.Abs(aj-asum)/asum > epsilon {
		fmt.Printf("Failed Validation on array a[]\n")
		fmt.Printf("        Expected  : %f \n", aj)
		fmt.Printf("        Observed  : %f \n", asum)
	} else if math.Abs(bj-bsum)/bsum > epsilon {
		fmt.Printf("Failed Validation on array b[]\n")
		fmt.Printf("        Expected  : %f \n", bj)
		fmt.Printf("        Observed  : %f \n", bsum)
	} else if math.Abs(cj-csum)/csum > epsilon {
		fmt.Printf("Failed Validation on array c[]\n")
		fmt.Printf("        Expected  : %f \n", cj)
		fmt.Printf("        Observed  : %f \n", csum)
	} else if math.Abs(dj-dsum)/dsum > epsilon {
		fmt.Printf("Failed Validation on array d[]\n")
		fmt.Printf("        Expected  : %f \n", dj)
		fmt.Printf("        Observed  : %f \n", dsum)
	} else {
		fmt.Printf("Solution Validates\n")
	}

}

func execBench(
	numThreads int,
	fnc bench) float64 {

	var wg sync.WaitGroup
	wg.Add(numThreads)

	S := time.Now()

	for id := 0; id < numThreads; id++ {
		go fnc(id, &wg)
	}
	wg.Wait()

	E := time.Now()
	return E.Sub(S).Seconds()
}
