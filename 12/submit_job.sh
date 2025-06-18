#!/bin/bash

JOB_NAME="lua_benchmark"
SCRIPT_DIR="slurm_jobs"
RESULTS_DIR="results"
mkdir -p $SCRIPT_DIR
mkdir -p $RESULTS_DIR

BENCHMARK_DIR="$(cd "$(dirname "$0")" && pwd)"
BENCHMARK_SCRIPT="$BENCHMARK_DIR/benchmark.sh"

echo "Preparing Slurm submission script..."

JOB_SCRIPT="$SCRIPT_DIR/job_${JOB_NAME}.sh"

cat > $JOB_SCRIPT << EOF
#!/bin/bash
#SBATCH --job-name=${JOB_NAME}
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
#SBATCH --time=01:00:00
#SBATCH --output=$RESULTS_DIR/${JOB_NAME}_%j.out

# Load modules
module load gcc/12.2.0-gcc-8.5.0-p4pe45v
module load cmake/3.24.3-gcc-8.5.0-svdlhox
module load llvm/15.0.4-python-3.10.8-gcc-8.5.0-bq44zh7

# Go to the benchmark directory
cd $BENCHMARK_DIR

# Make the benchmark script executable
chmod +x ./benchmark.sh

# Run the benchmark script
./benchmark.sh

# Print completion message
echo "Benchmark completed successfully"
EOF

chmod +x $JOB_SCRIPT

echo "Submitting Lua benchmark job to Slurm..."
JOB_ID=$(sbatch $JOB_SCRIPT | awk '{print $4}')

echo "Job submitted with ID: $JOB_ID"
echo "Results will be in: $RESULTS_DIR"
echo "Job output will be in: $RESULTS_DIR/${JOB_NAME}_${JOB_ID}.out"