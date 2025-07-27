# Set the terminal type and output
set terminal pngcairo size 1200,800 enhanced font 'Arial,16'
set output './plots/Update.png'

# Set labels and title
set title "Update kernel bandwidth"
set xlabel "Array Size [N]"
set ylabel "Bandwidth [GB/s]"
set grid x,y



# Use logarithmic scale on x-axis if needed (optional)
set logscale x

# Skip the header line that starts with '#'
set datafile commentschars "#"

# Plot the data
plot './dat/Update.dat' using 1:3 with linespoints title "Update" pointsize 2  pointtype 7 lw 6
