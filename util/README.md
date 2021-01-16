# Single file teaching version

bwBench.c contains a single file version of The Bandwidth Benchmark that is tailored for usage in Tutorials or Courses.

It should compile with any C99 compiler.

# Benchmarking skripts

## bench.pl to determine the absolute highest main memory bandwidth

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

## extractResults.pl to generate a plottable output files from multiple scaling runs

Please see how to use it in the toplevel [README](https://github.com/RRZE-HPC/TheBandwidthBenchmark#scaling-runs).

## benchmarkSystem.pl to benchmark a system and generate plots and markdown for the result wiki

**Please use with care!**

The script is designed to be used from the root of TheBandwidthBenchmark.
This script cleans and builds the currently configured toolchain. It expects that all Likwid tools are in the path!
Desired frequency settings must be already in place.

Usage:
```
perl ./benchmarkSystem.pl <DATA-DIR> <EXECUTABLE> <PREFIX>
```

where ```<DATA-DIR>``` is the directory where you want to store all results and generated output.
```<EXECUTABLE>``` is the bwBench executable name, this must be in accordance to the configured tool chain in ```config.mk```. E.g. ```./bwBench-CLANG```.
```<PREFIX>``` is the file prefix for all generated output, e.g. Intel-Haswell .


