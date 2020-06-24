# Single file teaching version

bwBench.c contains a single file version of The Bandwidth Benchmark that is tailored for usage in Tutorials or Courses.

It should compile with any C99 compiler.

# Benchmarking skript

A wrapper scripts in perl (bench.pl) and python (bench.py) are also provided to scan ranges of thread counts and determine the absolute highest sustained main memory bandwidth. In order to use it `likwid-pin` has to be in your path. The script has three required and one optional command line arguments:
```
$./bench.pl <executable> <thread count range>  <repetitions> [<SMT setting>]
```
Example usage:
```
$./bench.pl ./bwbench-GCC 2-8 6
```
The script will always use physical cores only, where two SMT threads is the default. For different SMT thread counts use the 4th command line argument. Example for a processor without SMT:
```
$./bench.pl ./bwbench-GCC 14-24  10  1
```
