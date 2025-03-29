#!/bin/bash
#SBATCH --partition=lva
#SBATCH --job-name=perf_analysis
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --exclusive

module load gcc/12.2.0-gcc-8.5.0-p4pe45v
module load cmake/3.24.3-gcc-8.5.0-svdlhox
module load ninja/1.11.1-python-3.10.8-gcc-8.5.0-2oc4wj6

bash $1 

echo "Performance analysis complete!"
