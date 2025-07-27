# Set the terminal type and output
set terminal pngcairo size 1200,800 enhanced font 'Arial,16'
set output './plots/Combined.png'

# Set labels and title
set title "All kernels bandwidth"
set xlabel "Array Size [N]"
set ylabel "Bandwidth [GB/s]"
set grid x,y



# Use logarithmic scale on x-axis if needed (optional)
set logscale x

# Skip the header line that starts with '#'
set datafile commentschars "#"

set pointsize 2

# Plot the data
plot './dat/Init.dat' using 1:3 with linespoints title "Init" pointtype 7 lw 6, \
    './dat/Copy.dat' using 1:3 with linespoints title "Copy" pointtype 7 lw 6, \
    './dat/Sum.dat' using 1:3 with linespoints title "Sum" pointtype 7 lw 6, \
    './dat/Update.dat' using 1:3 with linespoints title "Update" pointtype 7 lw 6, \
    './dat/Triad.dat' using 1:3 with linespoints title "Triad" pointtype 7 lw 6, \
    './dat/STriad.dat' using 1:3 with linespoints title "STriad" pointtype 7 lw 6, \
    './dat/Daxpy.dat' using 1:3 with linespoints title "Daxpy" pointtype 7 lw 6, \
    './dat/SDaxpy.dat' using 1:3 with linespoints title "SDaxpy" pointtype 7 lw 6