set terminal png size 1024,768 enhanced font ,12
set output 'striad.png'
set xlabel 'Size [kB]'
set xrange [100:]
set yrange [0:]
set ylabel 'Performance [MFLOP/s]'
cpuname = system("likwid-topology | grep 'CPU name' | cut -d ':' -f2 | sort -u | xargs")
numcores = system("grep 'striad' striad.dat | cut -d ' ' -f 3")
smt = system("grep 'striad' striad.dat | cut -d ' ' -f 4")
type = system("grep 'striad' striad.dat | cut -d ' ' -f 5")
set title sprintf("Benchmark of stream triad A[i] = B[i] + C[i] * D[i]\nType '%s', Threads %s, SMT %s, CPU %s", type, numcores, smt, cpuname)
set logscale x


plot 'striad.dat' u 1:2 w linespoints title 'striad'
