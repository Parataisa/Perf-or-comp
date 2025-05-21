#!/bin/bash

RESULTS_DIR="results"
RESULTS_FILE="$RESULTS_DIR/benchmark_results_cluster.csv"

if [ ! -f "$RESULTS_FILE" ]; then
    echo "Results file not found: $RESULTS_FILE"
    exit 1
fi

echo "Processing benchmark results..."

TOTAL_LINES=$(wc -l < $RESULTS_FILE)
COMPLETED_JOBS=$((TOTAL_LINES - 1)) 

echo "Found results for $COMPLETED_JOBS test combinations"

echo "Finding best and worst configurations..."

BEST=$(tail -n +2 $RESULTS_FILE | sort -t, -k5,5nr | head -1)
BEST_CONTAINER=$(echo $BEST | cut -d, -f1)
BEST_SIZE=$(echo $BEST | cut -d, -f2)
BEST_ELEMSIZE=$(echo $BEST | cut -d, -f3)
BEST_RATIO=$(echo $BEST | cut -d, -f4)
BEST_OPS=$(echo $BEST | cut -d, -f5)

WORST=$(tail -n +2 $RESULTS_FILE | sort -t, -k5,5n | head -1)
WORST_CONTAINER=$(echo $WORST | cut -d, -f1)
WORST_SIZE=$(echo $WORST | cut -d, -f2)
WORST_ELEMSIZE=$(echo $WORST | cut -d, -f3)
WORST_RATIO=$(echo $WORST | cut -d, -f4)
WORST_OPS=$(echo $WORST | cut -d, -f5)

echo "Best performance:"
echo "  Container: $BEST_CONTAINER"
echo "  Size: $BEST_SIZE"
echo "  Element Size: $BEST_ELEMSIZE"
echo "  Ins/Del Ratio: $BEST_RATIO"
echo "  Operations/sec: $BEST_OPS"

echo "Worst performance:"
echo "  Container: $WORST_CONTAINER"
echo "  Size: $WORST_SIZE"
echo "  Element Size: $WORST_ELEMSIZE"
echo "  Ins/Del Ratio: $WORST_RATIO"
echo "  Operations/sec: $WORST_OPS"

echo "Cleaning up .out files..."
find $RESULTS_DIR -name "*.out" -type f -delete
echo "Cleanup completed!"

echo "Cleaning up slurm job files..."
find slurm_jobs -name "job_*.sh" -type f -delete
rm -rf slurm_jobs
echo "Slurm job files cleanup completed!"

echo "Results processing completed!"