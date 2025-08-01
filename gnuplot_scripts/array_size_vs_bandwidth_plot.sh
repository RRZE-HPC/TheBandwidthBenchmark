#!/bin/bash -l

mkdir -p plots

kernels=("Init" "Copy" "Sum" "Update" "Triad" "STriad" "Daxpy" "SDaxpy")
combined_plot_commands=()

# Generate individual plots
for kernel in "${kernels[@]}"; do
  dat_file="./dat/${kernel}.dat"
  png_file="./plots/${kernel}.png"

  if [[ -f "$dat_file" ]]; then
    echo "Plotting ${kernel}..."

    gnuplot -persist <<EOF
set terminal pngcairo size 1200,800 enhanced font 'Arial,16'
set output '${png_file}'
set title "${kernel} kernel bandwidth"
set xlabel "Array Size [N]"
set ylabel "Bandwidth [GB/s]"
set format x "%.0e"
set grid x,y
set xrange [100:]
set yrange [0:]
set logscale x
set datafile commentschars "#"
plot '${dat_file}' using 1:3 with linespoints title "${kernel}" pointsize 2 pointtype 7 lw 4 lt 7
EOF

    # Append to combined plot
    combined_plot_commands+=("'${dat_file}' using 1:3 with linespoints title '${kernel}' pointtype 7 lw 4,")
  else
    echo "Skipping ${kernel}: Data file not found."
  fi
done

# Generate combined plot
if [[ ${#combined_plot_commands[@]} -gt 0 ]]; then
  echo "Generating combined plot..."

  gnuplot -persist <<EOF
set terminal pngcairo size 1200,800 enhanced font 'Arial,16'
set output './plots/Combined.png'
set title "All kernels bandwidth"
set xlabel "Array Size [N]"
set ylabel "Bandwidth [GB/s]"
set grid x,y
set format x "%.0e"
set xrange [100:]
set yrange [0:]
set logscale x
set datafile commentschars "#"
set pointsize 2
plot ${combined_plot_commands[*]}
EOF

else
  echo "No data files found. Combined plot not created."
fi
