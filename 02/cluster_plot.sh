#!/bin/bash

# Create data files for all three programs

# 1. Delannoy program
cat > delannoy_load_comparison.dat << 'EOL'
# Parameters	WithoutLoad	WithLoad	Ratio
"10"	0.0256667	0.140667	5.480525349967078
"11"	0.138	0.225333	1.6328478260869563
"12"	0.77	0.8825	1.146103896103896
"13"	4.306667	5.23	1.2143961908362082
"14"	24.256667	28.893333	1.191150169147311
EOL

cat > delannoy_runs.dat << 'EOL'
# Parameters	WithoutLoad_Runs	WithLoad_Runs
"10"	3	3
"11"	3	3
"12"	3	4
"13"	3	3
"14"	3	3
EOL

# 2. Filegen program
cat > filegen_load_comparison.dat << 'EOL'
# Parameters	WithoutLoad	WithLoad	Ratio
"5 10 1024 4096"	0.428	0.411167	0.9606705607476635
"10 30 4096 16384"	2.477778	2.6175	1.0563900397856467
"20 50 16384 65536"	8.383333	8.913333	1.0632206784580787
"30 100 16384 1048576"	39.396667	50.066667	1.2708350937402904
EOL

cat > filegen_runs.dat << 'EOL'
# Parameters	WithoutLoad_Runs	WithLoad_Runs
"5 10 1024 4096"	3	6
"10 30 4096 16384"	9	4
"20 50 16384 65536"	3	3
"30 100 16384 1048576"	3	3
EOL

# 3. Filesearch program
cat > filesearch_load_comparison.dat << 'EOL'
# Parameters	WithoutLoad	WithLoad	Ratio
"5 10 1024 4096"	0.0056333	0.0012583	0.22336818561056573
"15 45 4096 32768" 0.0056667 0.0028000 0.4941147405015
"25 45 8192 16384" 0.0056333 0.0038000 0.67456020449825146
"20 100 262144 1048576" 0.0056667 0.0054833 0.9676354844971
"20 100 512 4096" 0.0056667 0.0054667 0.96470608996
EOL

cat > filesearch_runs.dat << 'EOL'
# Parameters	WithoutLoad_Runs	WithLoad_Runs
"5 10 1024 4096"	3	12
"15 45 4096 32768"	3	3
"25 45 8192 16384"	3	3
"20 100 262144 1048576"	3	6
"20 100 512 4096"	3	3
EOL

#------------------------------------------------------------------------------
# Create gnuplot scripts for each program and chart type
#------------------------------------------------------------------------------

# 1. Delannoy program
cat > delannoy_load_comparison.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'delannoy_load_comparison.svg'
set title 'Delannoy: Performance Comparison With vs. Without Simulated Load'
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
set output 'delannoy_ratio.svg'
set title 'Delannoy: Performance Ratio (With Load / Without Load)'
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
set output 'delannoy_runs.svg'
set title 'Delannoy: Runs Required to Reach Target Precision'
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

# 2. Filegen program
cat > filegen_load_comparison.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'filegen_load_comparison.svg'
set title 'Filegen: Performance Comparison With vs. Without Simulated Load'
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
set output 'filegen_ratio.svg'
set title 'Filegen: Performance Ratio (With Load / Without Load)'
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
set output 'filegen_runs.svg'
set title 'Filegen: Runs Required to Reach Target Precision'
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

# 3. Filesearch program
cat > filesearch_load_comparison.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'filesearch_load_comparison.svg'
set title 'Filesearch: Performance Comparison With vs. Without Simulated Load'
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

plot 'filesearch_load_comparison.dat' using 2:xtic(1) title 'Without Load' lc rgb '#4169E1', \
     '' using 3 title 'With Load' lc rgb '#FF6347'
EOL

cat > filesearch_ratio.gp << 'EOL'
set terminal svg enhanced background rgb 'white' size 800,600
set output 'filesearch_ratio.svg'
set title 'Filesearch: Performance Ratio (With Load / Without Load)'
set xlabel 'Parameters'
set ylabel 'Ratio (lower means faster with load)'
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
set output 'filesearch_runs.svg'
set title 'Filesearch: Runs Required to Reach Target Precision'
set xlabel 'Parameters (Dependencies on filegen configurations)'
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

echo "All gnuplot scripts and data files created. To run them, execute:"
gnuplot delannoy_load_comparison.gp
gnuplot delannoy_ratio.gp
gnuplot delannoy_runs.gp
gnuplot filegen_load_comparison.gp
gnuplot filegen_ratio.gp
gnuplot filegen_runs.gp
gnuplot filesearch_load_comparison.gp
gnuplot filesearch_ratio.gp
gnuplot filesearch_runs.gp