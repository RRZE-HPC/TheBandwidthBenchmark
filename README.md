# The Bandwidth Benchmark

This is a collection of simple streaming kernels.

Apart from the micro-benchmark functionality this is also a blueprint for other micro-benchmark applications.

It contains C modules for:
* Aligned data allocation
* Query and control affinity settings
* Accurate timing

Moreover the benchmark showcases a simple generic Makefile that can be used in other projects.

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

OPTIONS  =  -DSIZE=40000000ull
OPTIONS +=  -DNTIMES=10
OPTIONS +=  -DARRAY_ALIGNMENT=64
#OPTIONS +=  -DVERBOSE_AFFINITY
#OPTIONS +=  -DVERBOSE_DATASIZE
#OPTIONS +=  -DVERBOSE_TIMER
```

The verbosity options enable detailed output about affinity settings, allocation sizes and timer resolution.

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

We recommend to use likwid-pin for benchmarking:
```
likwid-pin -c 0-3 ./bwbench-GCC
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

