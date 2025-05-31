#!/bin/bash

EXECUTABLE="./delannoy"
OUTPUT_FILE="benchmark_results.csv"
IMPLEMENTATIONS=(0 1 2)  # 0=recursive, 1=memoized, 2=tabular
IMPL_NAMES=("recursive" "memoized" "tabular")
SIZES=(5 8 10 12 15)     
NUM_RUNS=5               

echo "Implementation,Size,Run,Runtime(s),MemoryUsage(KB)" > "$OUTPUT_FILE"

for i in "${!IMPLEMENTATIONS[@]}"; do
    impl="${IMPLEMENTATIONS[$i]}"
    impl_name="${IMPL_NAMES[$i]}"
    
    echo "=== Testing ${impl_name} implementation ==="
    
    for size in "${SIZES[@]}"; do
        echo "--- Size: $size ---"
        
        echo "  Performing warmup run..."
        $EXECUTABLE $size $impl > /dev/null 2>&1
        
        total_time=0
        total_mem=0
        
        for run in $(seq 1 $NUM_RUNS); do
            echo "  Run $run of $NUM_RUNS..."
            
            output=$(/usr/bin/time -f "%e:%M" $EXECUTABLE $size $impl +t 2>&1)
            
            verification=$(echo "$output" | grep "Verification")
            app_time=$(echo "$output" | grep "Time taken" | awk '{print $3}')
            metrics=$(echo "$output" | tail -n 1)
            
            runtime=$(echo $metrics | cut -d':' -f1)
            memory=$(echo $metrics | cut -d':' -f2)
            
            total_time=$(echo "$total_time + $runtime" | bc)
            total_mem=$(echo "$total_mem + $memory" | bc)
            
            echo "$impl_name,$size,$run,$runtime,$memory" >> "$OUTPUT_FILE"
            
            echo "    Runtime: ${runtime}s, Memory: ${memory}KB, $verification"
        done
        
        avg_time=$(echo "scale=6; $total_time / $NUM_RUNS" | bc)
        avg_mem=$(echo "scale=2; $total_mem / $NUM_RUNS" | bc)
        
        echo "$impl_name,$size,Average,$avg_time,$avg_mem" >> "$OUTPUT_FILE"
        
        echo "  Average runtime: ${avg_time}s"
        echo "  Average memory usage: ${avg_mem}KB"
    done
    
    echo ""
done

echo "Benchmark complete. Results saved to $OUTPUT_FILE"