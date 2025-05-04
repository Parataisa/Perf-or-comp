#!/bin/bash
#SBATCH --job-name=alloc-bench
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
#SBATCH --time=01:00:00
#SBATCH --output=benchmark_%j.out

cd /scratch/cb761222/Perf-or-comp/07/

module load llvm/15.0.4-python-3.10.8-gcc-8.5.0-bq44zh7

echo "Running benchmark..."
bash performance_test.sh
