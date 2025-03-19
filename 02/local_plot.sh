#!/bin/bash

# Create data files for delannoy, filegen and filesearch programs

# 1. Delannoy program
cat > delannoy_load_comparison.dat << 'EOL'
# Parameters	WithoutLoad	WithLoad	Ratio
"10"	0.01	0.0181333	1.81333
"11"	0.0300667	0.0360667	1.1995563197823507
"12"	0.116333	0.124	1.0659056329674297
"13"	0.556667	0.616667	1.1077843665961875
"14"	3.613333	3.887	1.0757381066179066
EOL

cat > delannoy_runs.dat << 'EOL'
# Parameters	WithoutLoad_Runs	WithLoad_Runs
"10"	3	3
"11"	3	3
"12"	3	3
"13"	3	3
"14"	3	40
EOL

# 1. Filegen program
cat > filegen_load_comparison.dat << 'EOL'
# Parameters	WithoutLoad	WithLoad	Ratio
"5 10 1024 4096"	0.0046	0.0056667	1.2318913043478261
"10 30 4096 16384"	0.0593333	0.068	1.1460680595887975
"20 50 16384 65536"	0.543333	0.58	1.067485317475655
"30 100 16384 1048576"	20.624	21.413333	1.0382725465477116
EOL

cat > filegen_runs.dat << 'EOL'
# Parameters	WithoutLoad_Runs	WithLoad_Runs
"5 10 1024 4096"	3	3
"10 30 4096 16384"	3	3
"20 50 16384 65536"	3	3
"30 100 16384 1048576"	5	6
EOL

# 2. Filesearch program
cat > filesearch_load_comparison.dat << 'EOL'
# Parameters	WithoutLoad	WithLoad	Ratio
"5 10 1024 4096"	0.0007	0.0009	1.2857142857142856
"15 45 4096 32768"	0.0007167	0.0009	1.2557555462536625
"25 45 8192 16384"	0.0007375	0.0009	1.2203389830508475
"20 100 262144 1048576"	0.0007556	0.0009	1.1911064055055585
"20 100 512 4096"	0.0008	0.0008111	1.013875
EOL

cat > filesearch_runs.dat << 'EOL'
# Parameters	WithoutLoad_Runs	WithLoad_Runs
"5 10 1024 4096"	3	3
"15 45 4096 32768"	6	3
"25 45 8192 16384"	8	3
"20 100 262144 1048576"	9	3
"20 100 512 4096"	3	9
EOL

#------------------------------------------------------------------------------
# Create gnuplot scripts for each program and chart type
#------------------------------------------------------------------------------

# 1. Delannoy program
cat > delannoy_load_comparison.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'delannoy_load_comparison_local.svg'
set title 'Delannoy: Performance Comparison With vs. Without Load (Local)'
set xlabel 'Parameters'
set ylabel 'Average Execution Time (s)'
set grid
set style data histogram
set style histogram cluster gap 1
set style fill solid 0.7 border -1
set boxwidth 0.9
set xtic rotate by -45 scale 0
set key top left
set yrange [0:*]

plot 'delannoy_load_comparison.dat' using 2:xtic(1) title 'Without Load' lc rgb '#4169E1', \
     '' using 3 title 'With Load' lc rgb '#FF6347'
EOL

cat > delannoy_ratio.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'delannoy_ratio_local.svg'
set title 'Delannoy: Performance Ratio (With Load / Without Load) (Local)'
set xlabel 'Parameters'
set ylabel 'Ratio (higher means more impact from load)'
set grid
set style data histogram
set style histogram cluster gap 1
set style fill solid 0.7 border -1
set boxwidth 0.9
set xtic rotate by -45 scale 0
set key top left
set yrange [0:*]

plot 'delannoy_load_comparison.dat' using 4:xtic(1) title 'Load Impact Ratio' lc rgb '#8A2BE2' with histogram
EOL

cat > delannoy_runs.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'delannoy_runs_local.svg'
set title 'Delannoy: Runs Required to Reach Target Precision (Local)'
set xlabel 'Parameters'
set ylabel 'Number of Runs'
set grid
set style data histogram
set style histogram cluster gap 1
set style fill solid 0.7 border -1
set boxwidth 0.9
set xtic rotate by -45 scale 0
set key top left
set yrange [0:*]

plot 'delannoy_runs.dat' using 2:xtic(1) title 'Without Load' lc rgb '#4169E1', \
     '' using 3 title 'With Load' lc rgb '#FF6347'
EOL

# Add a log scale version for delannoy comparisons
cat > delannoy_load_comparison_log.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'delannoy_load_comparison_local_log.svg'
set title 'Delannoy: Performance Comparison (Log Scale) (Local)'
set xlabel 'Parameters'
set ylabel 'Average Execution Time (s)'
set grid
set style data histogram
set style histogram cluster gap 1
set style fill solid 0.7 border -1
set boxwidth 0.9
set xtic rotate by -45 scale 0
set key top left
set logscale y
set yrange [0.001:*]

plot 'delannoy_load_comparison.dat' using 2:xtic(1) title 'Without Load' lc rgb '#4169E1', \
     '' using 3 title 'With Load' lc rgb '#FF6347'
EOL

# 2. Filegen program
cat > filegen_load_comparison.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'filegen_load_comparison_local.svg'
set title 'Filegen: Performance Comparison With vs. Without Load (Local)'
set xlabel 'Parameters (numDirs numFiles minSize maxSize)'
set ylabel 'Average Execution Time (s)'
set grid
set style data histogram
set style histogram cluster gap 1
set style fill solid 0.7 border -1
set boxwidth 0.9
set xtic rotate by -45 scale 0
set key top left
set yrange [0:*]

plot 'filegen_load_comparison.dat' using 2:xtic(1) title 'Without Load' lc rgb '#4169E1', \
     '' using 3 title 'With Load' lc rgb '#FF6347'
EOL

cat > filegen_ratio.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'filegen_ratio_local.svg'
set title 'Filegen: Performance Ratio (With Load / Without Load) (Local)'
set xlabel 'Parameters (numDirs numFiles minSize maxSize)'
set ylabel 'Ratio (higher means more impact from load)'
set grid
set style data histogram
set style histogram cluster gap 1
set style fill solid 0.7 border -1
set boxwidth 0.9
set xtic rotate by -45 scale 0
set key top left
set yrange [0:*]

plot 'filegen_load_comparison.dat' using 4:xtic(1) title 'Load Impact Ratio' lc rgb '#8A2BE2' with histogram
EOL

cat > filegen_runs.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'filegen_runs_local.svg'
set title 'Filegen: Runs Required to Reach Target Precision (Local)'
set xlabel 'Parameters (numDirs numFiles minSize maxSize)'
set ylabel 'Number of Runs'
set grid
set style data histogram
set style histogram cluster gap 1
set style fill solid 0.7 border -1
set boxwidth 0.9
set xtic rotate by -45 scale 0
set key top left
set yrange [0:*]

plot 'filegen_runs.dat' using 2:xtic(1) title 'Without Load' lc rgb '#4169E1', \
     '' using 3 title 'With Load' lc rgb '#FF6347'
EOL

# Add a log scale version for filegen comparisons
cat > filegen_load_comparison_log.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'filegen_load_comparison_local_log.svg'
set title 'Filegen: Performance Comparison (Log Scale) (Local)'
set xlabel 'Parameters (numDirs numFiles minSize maxSize)'
set ylabel 'Average Execution Time (s)'
set grid
set style data histogram
set style histogram cluster gap 1
set style fill solid 0.7 border -1
set boxwidth 0.9
set xtic rotate by -45 scale 0
set key top left
set logscale y
set yrange [0.001:*]

plot 'filegen_load_comparison.dat' using 2:xtic(1) title 'Without Load' lc rgb '#4169E1', \
     '' using 3 title 'With Load' lc rgb '#FF6347'
EOL

# 2. Filesearch program
cat > filesearch_load_comparison.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'filesearch_load_comparison_local.svg'
set title 'Filesearch: Performance Comparison With vs. Without Load (Local)'
set xlabel 'Parameters (Depends on filegen with these parameters)'
set ylabel 'Average Execution Time (s)'
set grid
set style data histogram
set style histogram cluster gap 1
set style fill solid 0.7 border -1
set boxwidth 0.9
set xtic rotate by -45 scale 0
set key top left
set yrange [0:*]

plot 'filesearch_load_comparison.dat' using 2:xtic(1) title 'Without Load' lc rgb '#4169E1', \
     '' using 3 title 'With Load' lc rgb '#FF6347'
EOL

cat > filesearch_ratio.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'filesearch_ratio_local.svg'
set title 'Filesearch: Performance Ratio (With Load / Without Load) (Local)'
set xlabel 'Parameters (Depends on filegen with these parameters)'
set ylabel 'Ratio (higher means more impact from load)'
set grid
set style data histogram
set style histogram cluster gap 1
set style fill solid 0.7 border -1
set boxwidth 0.9
set xtic rotate by -45 scale 0
set key top left
set yrange [0:*]

plot 'filesearch_load_comparison.dat' using 4:xtic(1) title 'Load Impact Ratio' lc rgb '#8A2BE2' with histogram
EOL

cat > filesearch_runs.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'filesearch_runs_local.svg'
set title 'Filesearch: Runs Required to Reach Target Precision (Local)'
set xlabel 'Parameters (Depends on filegen with these parameters)'
set ylabel 'Number of Runs'
set grid
set style data histogram
set style histogram cluster gap 1
set style fill solid 0.7 border -1
set boxwidth 0.9
set xtic rotate by -45 scale 0
set key top left
set yrange [0:*]

plot 'filesearch_runs.dat' using 2:xtic(1) title 'Without Load' lc rgb '#4169E1', \
     '' using 3 title 'With Load' lc rgb '#FF6347'
EOL

# Create a comparison script for the filesearch runs pattern
cat > filesearch_runs_pattern.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'filesearch_runs_pattern_local.svg'
set title 'Filesearch: Runs Required Pattern (Local)'
set xlabel 'Parameters'
set ylabel 'Number of Runs'
set grid
set key center right

# Create a curve to highlight the pattern
plot 'filesearch_runs.dat' using 0:2 title 'Without Load' with linespoints lw 2 pt 7 ps 1.5 lc rgb '#4169E1', \
     '' using 0:3 title 'With Load' with linespoints lw 2 pt 9 ps 1.5 lc rgb '#FF6347', \
     '' using 0:(0):1 with labels offset 0,-2 title ''
EOL

echo "All gnuplot scripts and data files created. To run them, execute:"
gnuplot delannoy_load_comparison.gp
gnuplot delannoy_ratio.gp
gnuplot delannoy_runs.gp
gnuplot delannoy_load_comparison_log.gp
gnuplot filegen_load_comparison.gp
gnuplot filegen_ratio.gp
gnuplot filegen_runs.gp
gnuplot filegen_load_comparison_log.gp
gnuplot filesearch_load_comparison.gp
gnuplot filesearch_ratio.gp
gnuplot filesearch_runs.gp
echo "gnuplot filesearch_runs_pattern.gp"