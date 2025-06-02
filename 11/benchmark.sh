#!/bin/bash

EXECUTABLE="./delannoy"
OUTPUT_FILE="benchmark_results.csv"
IMPLEMENTATIONS=(0 1 2)  # 0=recursive, 1=memoized, 2=tabular
IMPL_NAMES=("recursive" "memoized" "tabular")
SIZES=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22)  # Sizes to test
NUM_WARMUP=2
NUM_RUNS=5               

echo "Implementation,Size,Run,Runtime(s),MemoryUsage(KB)" > "$OUTPUT_FILE"

for i in "${!IMPLEMENTATIONS[@]}"; do
    impl="${IMPLEMENTATIONS[$i]}"
    impl_name="${IMPL_NAMES[$i]}"
    
    echo "=== Testing ${impl_name} implementation ==="
    
    for size in "${SIZES[@]}"; do
        echo "--- Size: $size ---"
        if [ "$impl" -eq 0 ] && [ "$size" -gt 14 ]; then
            echo "    Skipping benchmark for recursive implementation on size $size (too large)"
            continue
        fi
        
        echo "  Performing warmup run..."
        for warmup in $(seq 1 $NUM_WARMUP); do
            echo "    Warmup run $warmup..."
            $EXECUTABLE $size $impl > /dev/null 2>&1
        done
        
        total_time=0
        total_mem=0
        
        for run in $(seq 1 $NUM_RUNS); do
            echo "  Run $run of $NUM_RUNS..."
            
            memory_output=$(/usr/bin/time -f "%M" $EXECUTABLE $size $impl +t 2>&1)
            
            runtime=$(echo "$memory_output" | grep "Time taken:" | awk '{print $3}')
            
            memory=$(echo "$memory_output" | tail -n1)
            verification=$(echo "$memory_output" | grep "Verification")
            
            total_time=$(echo "$total_time + $runtime" | bc)
            total_mem=$(echo "$total_mem + $memory" | bc)
            
            echo "$impl_name,$size,$run,$runtime,$memory" >> "$OUTPUT_FILE"
            
            echo "    Runtime: ${runtime}s, Memory: ${memory}KB, $verification"
        done
        
        avg_time=$(echo "scale=9; $total_time / $NUM_RUNS" | bc)
        avg_mem=$(echo "scale=2; $total_mem / $NUM_RUNS" | bc)
        
        echo "$impl_name,$size,Average,$avg_time,$avg_mem" >> "$OUTPUT_FILE"
        
        echo "  Average runtime: ${avg_time}s"
        echo "  Average memory usage: ${avg_mem}KB"
    done
    
    echo ""
done

echo "Benchmark complete. Results saved to $OUTPUT_FILE"