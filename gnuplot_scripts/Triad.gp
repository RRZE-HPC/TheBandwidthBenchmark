# Set the terminal type and output
set terminal pngcairo size 1200,800 enhanced font 'Arial,16'
set output './plots/Triad.png'

# Set labels and title
set title "Triad kernel bandwidth"
set xlabel "Array Size [N]"
set ylabel "Bandwidth [GB/s]"
set grid x,y



# Use logarithmic scale on x-axis if needed (optional)
set logscale x

# Skip the header line that starts with '#'
set datafile commentschars "#"

# Plot the data
plot './dat/Triad.dat' using 1:3 with linespoints title "Triad" pointsize 2  pointtype 7 lw 6
