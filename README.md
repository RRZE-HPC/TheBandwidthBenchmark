# The Bandwidth Benchmark

This is a collection of simple streaming kernels.

Apart from the micro-benchmark functionality this is also a blueprint for other micro-benchmark applications.

It contains C modules for:
* Aligned data allocation
* Query and control affinity settings
* Accurate timing

Moreover the benchmark showcases a simple generic Makefile that can be used in other projects.

You may want to have a look at https://github.com/RRZE-HPC/TheBandwidthBenchmark/wiki for a collection of results that were created using TheBandwidthBenchmark.

## Overview

The benchmark is heavily inspired by John McCalpin's https://www.cs.virginia.edu/stream/ benchmark.

It contains the following streaming kernels with corresponding data access pattern (Notation: S - store, L - load, WA - write allocate). All variables are vectors, s is a scalar:

* init (S1, WA): Initilize an array: `a = s`. Store only.
* sum (L1): Vector reduction: `s += a`. Load only.
* copy  (L1, S1, WA): Classic memcopy: `a = b`.
* update (L1, S1): Update vector: `a = a * scalar`. Also load + store but without write allocate.
* triad (L2, S1, WA): Stream triad: `a = b + c * scalar`.
* daxpy (L2, S1): Daxpy: `a = a + b * scalar`.
* striad (L3, S1, WA): Schoenauer triad: `a = b + c * d`.
* sdaxpy (L3, S1): Schoenauer triad without write allocate: `a = a + b * c`.

As added benefit the code is a blueprint for a minimal benchmarking application with a generic makefile and modules for aligned array allocation, accurate timing and affinity settings. Those components can be used standalone in your own project.

## Build

1. Configure the toolchain and additional options in `config.mk`:
```
# Supported: GCC, CLANG, ICC
TAG ?= GCC
ENABLE_OPENMP ?= false
ENABLE_LIKWID ?= false

OPTIONS  =  -DSIZE=120000000ull
OPTIONS +=  -DNTIMES=10
OPTIONS +=  -DARRAY_ALIGNMENT=64
#OPTIONS +=  -DVERBOSE_AFFINITY
#OPTIONS +=  -DVERBOSE_DATASIZE
#OPTIONS +=  -DVERBOSE_TIMER
```

The verbosity options enable detailed output about affinity settings, allocation sizes and timer resolution.

*Notice:* OpenMP involves significant overhead through barrier cost, especially on systems with many memory domains. The default problem size is set to almost 4GB to have enough work vs overhead. If you suspect that the result should be better you may try to further increase the problem size. To compare to original stream results on X86 systems you have to ensure that streaming store instructions are used. For the ICC toolchain this is now the default (Option `-qopt-streaming-stores=always`). 

2. Build with:
```
make
```

You can build multiple toolchains in the same directory, but notice that the Makefile is only acting on the one currently set. Intermediate build results are located in the `<TOOLCHAIN>` directory.

To output the executed commands use:
```
make Q=
```

3. Clean up with:
```
make clean
```
to clean intermediate build results.

```
make distclean
```
to clean intermediate build results and binary.

4. (Optional) Generate assembler:
```
make asm
```
The assembler files will also be located in the `<TOOLCHAIN>` directory.

## Usage

To run the benchmark call:
```
./bwBench-<TOOLCHAIN>
```

The benchmark will output the results similar to the stream benchmark. Results are validated.
For threaded execution it is recommended to control thread affinity.

We recommend to use likwid-pin for setting the number of threads used and to control thread affinity:
```
likwid-pin -C 0-3 ./bwbench-GCC
```

Example output for threaded execution:
```
-------------------------------------------------------------
[pthread wrapper]
[pthread wrapper] MAIN -> 0
[pthread wrapper] PIN_MASK: 0->1  1->2  2->3
[pthread wrapper] SKIP MASK: 0x0
        threadid 140271463495424 -> core 1 - OK
        threadid 140271455102720 -> core 2 - OK
        threadid 140271446710016 -> core 3 - OK
OpenMP enabled, running with 4 threads
----------------------------------------------------------------------------
Function      Rate(MB/s)  Rate(MFlop/s)  Avg time     Min time     Max time
Init:          22111.53    -             0.0148       0.0145       0.0165
Sum:           46808.59    46808.59      0.0077       0.0068       0.0140
Copy:          30983.06    -             0.0207       0.0207       0.0208
Update:        43778.69    21889.34      0.0147       0.0146       0.0148
Triad:         34476.64    22984.43      0.0282       0.0278       0.0305
Daxpy:         45908.82    30605.88      0.0214       0.0209       0.0242
STriad:        37502.37    18751.18      0.0349       0.0341       0.0388
SDaxpy:        46822.63    23411.32      0.0281       0.0273       0.0325
----------------------------------------------------------------------------
Solution Validates
```

## Scaling runs

Apart from the highest sustained memory bandwidth also the scaling behavior within memory domains is a important system property.

There is a helper script included in util (```extractResults.pl```) that creates a text result file from multiple runs that can be used as input to plotting applications as gnuplot and xmgrace.
This involves two steps: Executing the benchmark runs and creating the data file.

To run the benchmark for different thread counts within a memory domain execute (this assumes bash or zsh):
```
$ for nt in 1 2 4 6 8 10; do likwid-pin -q -C E:M0:$nt:1:2 ./bwbench-ICC > dat/emmy-$nt.txt; done
```

It is recommended to just use one thread per core in case the processor supports hyperthreading.
Use whatever stepping you like, here a stepping of two was used.
The ```-q``` option suppresses output from ```likwid-pin```.
Above line uses the expression based syntax, on systems with hyperthreading enabled (check with, e.g., ```likwid-topology```) you have to skip the other hardware threads on each core.
For above system with 2 hardware threads per core this results in ```-C E:M0:$nt:1:2```, on a system with 4 hardware threads per core you would need ```-C E:M0:$nt:1:4```.
The string before the dash (here emmy) can be arbitrary, but the the extraction script expects the thread count after the dash.
Also the file ending has to be ```.txt```.
Please check with a text editor on some result files if everything worked as expected.

To extract the results and output in a plottable format execute:
```
./extractResults.pl ./dat
```

The script will pick up all result files in the directory specified and create a column format output file.
In this case:
```
#nt	Init	Sum	Copy	Update	Triad	Daxpy	STriad	SDaxpy
1	4109	11900	5637	8025	7407	9874	8981	11288
2	8057	22696	11011	15174	14821	18786	17599	21475
4	15602	39327	21020	28197	27287	33633	31939	37146
6	22592	45877	29618	37155	36664	40259	39911	41546
8	28641	46878	35763	40111	40106	41293	41022	41950
10	33151	46741	38187	40269	39960	40922	40567	41606
```

Please be aware the the single core memory bandwidth as well as the scaling behavior depends on the frequency settings.
