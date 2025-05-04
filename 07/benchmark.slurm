#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
#SBATCH --time=01:00:00
#SBATCH --job-name=malloc-bench
#SBATCH --output=malloc-bench-%j.out

cd /scratch/cb761222/Perf-or-comp/07/
bash performance_test.sh