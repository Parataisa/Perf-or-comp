#!/bin/bash

CONTAINERS=("array" "linkedlist_seq" "linkedlist_rand")
INS_DEL_RATIOS=("0.00" "0.01" "0.10" "0.50")
ELEM_SIZES=("8" "512" "8388608")  # 8B, 512B, 8MB
CONTAINER_SIZES=("10" "1000" "100000" "10000000")
READ_RATIO=("1.0", "0.99, "0.90, "0.5")
TEST_DURATION="3"

SCRIPT_DIR="slurm_jobs"
RESULTS_DIR="results"
mkdir -p $SCRIPT_DIR
mkdir -p $RESULTS_DIR

BENCHMARK_DIR="$(cd "$(dirname "$0")" && pwd)"
BENCHMARK_EXE="$BENCHMARK_DIR/benchmark"

echo "Building benchmark executable..."
make clean -C $BENCHMARK_DIR
make -C $BENCHMARK_DIR

RESULTS="$RESULTS_DIR/benchmark_results_cluster.csv"
echo "Container,Size,ElemSize,InsDelRatio,OpsPerSecond,JobID" > $RESULTS

TOTAL_JOBS=0
SUBMITTED_JOBS=0

for container in "${CONTAINERS[@]}"; do
    for size in "${CONTAINER_SIZES[@]}"; do
        for elem_size in "${ELEM_SIZES[@]}"; do      
            for ratio in "${INS_DEL_RATIOS[@]}"; do
                for read_ratio in "${READ_RATIO[@]}"; do
                    TOTAL_JOBS=$((TOTAL_JOBS+1))
                done
            done
        done
    done
done

echo "Preparing to submit $TOTAL_JOBS Slurm jobs..."

for container in "${CONTAINERS[@]}"; do
    for size in "${CONTAINER_SIZES[@]}"; do
        for elem_size in "${ELEM_SIZES[@]}"; do      
            for ratio in "${INS_DEL_RATIOS[@]}"; do
                for read_ratio in "${READ_RATIO[@]}"; do
                    JOB_NAME="${container}_s${size}_e${elem_size}_r${ratio/./_}_rr${read_ratio/./_}"
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
module load ninja/1.11.1-python-3.10.8-gcc-8.5.0-2oc4wj6

# Go to the benchmark directory
cd $BENCHMARK_DIR

# Run the benchmark with specific parameters
OUTPUT=\$(./benchmark $container $size $elem_size $ratio $read_ratio $TEST_DURATION)

# Extract operations per second
OPS=\$(echo "\$OUTPUT" | grep "Operations per second" | awk '{print \$4}')

# Append result to the CSV file
echo "$container,$size,$elem_size,$ratio,\$OPS,\$SLURM_JOB_ID" >> $RESULTS

# Print result to output file too
echo "Container: $container"
echo "Size: $size elements"
echo "Element size: ${elem_size}B"
echo "Ins/Del ratio: $ratio"
echo "Read ratio: $read_ratio"
echo "Operations per second: \$OPS"
EOF

                    chmod +x $JOB_SCRIPT

                    JOB_ID=$(sbatch $JOB_SCRIPT | awk '{print $4}')
                    SUBMITTED_JOBS=$((SUBMITTED_JOBS+1))

                    echo "Submitted job $SUBMITTED_JOBS of $TOTAL_JOBS: $JOB_NAME (Job ID: $JOB_ID)"
                    sleep 0.1
                done
            done
        done
    done
done

echo "All jobs submitted: $SUBMITTED_JOBS of $TOTAL_JOBS"
echo "Results will be combined in: $RESULTS"
echo "Individual job outputs will be in: $RESULTS_DIR"