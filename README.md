# The Bandwidth Benchmark

This is a collection of simple streaming kernels for teaching purposes.
It is heavily inspired by John McCalpin's https://www.cs.virginia.edu/stream/.

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

5. (Optional) Generate assembler files:
```
make asm
```
The assembler files will also be located in the `<TOOLCHAIN>` directory.


