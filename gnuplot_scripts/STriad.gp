# Set the terminal type and output
set terminal pngcairo size 1200,800 enhanced font 'Arial,16'
set output './plots/STriad.png'

# Set labels and title
set title "STriad kernel bandwidth"
set xlabel "Array Size [N]"
set ylabel "Bandwidth [GB/s]"
set grid x,y



# Use logarithmic scale on x-axis if needed (optional)
set logscale x

# Skip the header line that starts with '#'
set datafile commentschars "#"

# Plot the data
plot './dat/STriad.dat' using 1:3 with linespoints title "STriad" pointsize 2  pointtype 7 lw 6
