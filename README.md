# The Bandwidth Benchmark

This is a collection of simple streaming kernels for teaching purposes.
It is heavily inspired by John McCalpin's https://www.cs.virginia.edu/stream/.

It contains the following streaming kernels and the corrsponding data access pattern (Notation: S - store, L - load, WA - write allocate):

* init: S1
* sum: L1
* copy: L1, S1, WA
* update: L1, S1
* triad: L2, S1, WA
* daxpy: L2, S1
* striad: L3, S1, WA
* sdaxpy: L3, S1


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
