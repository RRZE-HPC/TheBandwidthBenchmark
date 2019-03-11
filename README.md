# The Bandwidth Benchmark

This is a collection of simple streaming kernels for teaching purposes.
It is heavily inspired by John McCalpin's https://www.cs.virginia.edu/stream/.

It contains the following streaming kernels with corresponding data access pattern (Notation: S - store, L - load, WA - write allocate):

* init (S1, WA): Initilize an array. Store only.
* sum (L1): Vector reduction. Load only.
* copy  (L1, S1, WA): Classic memcopy.
* update (L1, S1): Update a vector. Also load + store but without write allocate.
* triad (L2, S1, WA): Stream triad - `a = b + b * scalar`.
* daxpy (L2, S1): Daxpy - `a = a + b * scalar`.
* striad (L3, S1, WA): Schoenauer triad - `a = b + c * d`.
* sdaxpy (L3, S1): Schoenauer triad without write allocate - `a = a + b * c`.


## Build

1. Configure the toolchain to use in the `Makefile`:
```
TAG = GCC  # Supported GCC, CLANG, ICC
```

2. Review the flags for toolchain in the corresponding included file, e.g. `include_GCC.mk`. OpenMP is disabled per default, you can enable it by uncommenting the OpenMP flag:
```
OPENMP   = -fopenmp
```

3. Build with:
```
make
```

You can build multiple toolchains in the same directory, but notice that the Makefile is only acting on the one currently set.
Intermediate build results are located in the `<TOOLCHAIN>` directory.

4. Clean up with:
```
make clean
```
to clean intermediate build results.

```
make distclean
```
to clean intermediate build results and binary.

5. (Optional) Generate assembler:
```
make asm
```
The assembler files will also be located in the `<TOOLCHAIN>` directory.

## Usage

To run just call:
```
./bwBench-<TOOLCHAIN>
```

The benchmark will output the results similar to the stream benchmark. Results are validated.
For threaded execution it is recommended to control thread affinity.

We recommend to use likwid-pin for benchmarking:
```
likwid-pin -c 0-3 ./bwbench-GCC  
```

Example output for threaded version:
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
-------------------------------------------------------------
Function      Rate (MB/s)   Avg time     Min time     Max time
Init:        14681.5000       0.0110       0.0109       0.0111
Sum:         20634.9290       0.0079       0.0078       0.0082
Copy:        18822.2827       0.0172       0.0170       0.0176
Update:      28135.9717       0.0115       0.0114       0.0117
Triad:       19263.0634       0.0253       0.0249       0.0268
Daxpy:       26718.1377       0.0182       0.0180       0.0187
STriad:      21229.4470       0.0305       0.0301       0.0313
SDaxpy:      26714.3897       0.0243       0.0240       0.0253
-------------------------------------------------------------
Solution Validates
```
