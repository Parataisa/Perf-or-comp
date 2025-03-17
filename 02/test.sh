#!/bin/bash

# Step 1: Create sample CSV data
cat > sales_data.csv << EOF
Month,Department1,Department2,Department3
Jan,45,32,15
Feb,58,43,21
Mar,65,50,28
Apr,72,55,35
May,83,65,42
Jun,91,72,50
Jul,98,78,55
Aug,90,70,48
Sep,85,65,40
Oct,75,58,32
Nov,68,50,28
Dec,76,62,38
EOF

# Step 2: Create gnuplot script
cat > plot_script.gp << EOF
# Output configuration
set terminal png size 800,500 enhanced font "Arial,12"
set output "department_sales.png"

# Graph styling
set title "Monthly Department Sales" font "Arial,14"
set xlabel "Month" font "Arial,12"
set ylabel "Sales (thousands $)" font "Arial,12"
set grid ytics lc rgb "#dddddd" lw 1
set grid xtics lc rgb "#dddddd" lw 1

# Legend styling
set key outside right top box width 1 height 1 font "Arial,10"

# CSV settings
set datafile separator ","
set xtics rotate by -45
set style data histogram
set style histogram clustered gap 1
set style fill solid 0.8 border -1
set boxwidth 0.8

# Color palette
set style line 1 lc rgb "#4363d8" 
set style line 2 lc rgb "#f58231" 
set style line 3 lc rgb "#3cb44b" 

# Plot the data
plot "sales_data.csv" using 2:xtic(1) title column ls 1, \
     "" using 3 title column ls 2, \
     "" using 4 title column ls 3
EOF

# Step 3: Generate the plot
echo "Generating plot from CSV data..."
gnuplot plot_script.gp

echo "Plot generated as 'department_sales.png'"

# For demonstration purposes, here's how you would also create a line plot 
# from the same data with a different script

cat > line_plot_script.gp << EOF
# Output configuration
set terminal png size 800,500 enhanced font "Arial,12"
set output "sales_trends.png"

# Graph styling
set title "Sales Trends by Department" font "Arial,14"
set xlabel "Month" font "Arial,12"
set ylabel "Sales (thousands $)" font "Arial,12"
set grid ytics lc rgb "#dddddd" lw 1
set grid xtics lc rgb "#dddddd" lw 1

# Legend styling
set key outside right top box width 1 height 1 font "Arial,10"

# CSV settings
set datafile separator ","
set xtics rotate by -45

# Line styles
set style line 1 lc rgb "#4363d8" lw 2 pt 7 ps 1.5
set style line 2 lc rgb "#f58231" lw 2 pt 9 ps 1.5
set style line 3 lc rgb "#3cb44b" lw 2 pt 5 ps 1.5

# Plot the data with lines and points
plot "sales_data.csv" using 2:xtic(1) with linespoints ls 1 title column, \
     "" using 3 with linespoints ls 2 title column, \
     "" using 4 with linespoints ls 3 title column
EOF

# Generate the line plot
echo "Generating line plot from the same CSV data..."
gnuplot line_plot_script.gp

echo "Line plot generated as 'sales_trends.png'"