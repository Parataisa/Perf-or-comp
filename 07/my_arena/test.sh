#!/bin/bash

CSV_FILE="results.csv"
echo "Allocator,Threads,Repeats,Iterations,MinSize,MaxSize,RealTime,UserTime,SysTime,MemoryKB" > $CSV_FILE

# Test different allocation sizes with both allocators
run_benchmark() {
    local allocator=$1
    local threads=$2
    local repeats=$3
    local iterations=$4
    local min_size=$5
    local max_size=$6
    local cmd=$7
    
    echo "Running benchmark: $allocator - threads=$threads, repeats=$repeats, iterations=$iterations, size=$min_size-$max_size"
    
    time_file=$(mktemp)
    
    /usr/bin/time -v $cmd $threads $repeats $iterations $min_size $max_size 2> "$time_file"
    
    real_seconds=$(grep "Elapsed (wall clock) time" "$time_file" | sed 's/.*: //' | awk -F: '{ if (NF == 2) print $1*60+$2; else print $1*3600+$2*60+$3 }')
    user_seconds=$(grep "User time" "$time_file" | sed 's/.*: //')
    sys_seconds=$(grep "System time" "$time_file" | sed 's/.*: //')
    memory_kb=$(grep "Maximum resident set size" "$time_file" | sed 's/.*: //')
    
    rm "$time_file"
    
    # Write results to CSV
    echo "$allocator,$threads,$repeats,$iterations,$min_size,$max_size,$real_seconds,$user_seconds,$sys_seconds,$memory_kb" >> $CSV_FILE
    
    echo "  Time: real=$real_seconds, user=$user_seconds, sys=$sys_seconds"
    echo "  Memory: $memory_kb KB"
    echo "--------------------------------------------------------------"
}

make all

# Define allocation size test cases
declare -a min_sizes=(10 10  10  )
declare -a max_sizes=(50 100 1000)

# Test parameters
THREADS=1
REPEATS=500
ITERATIONS=1000000

# Run tests for different allocation sizes
for i in "${!min_sizes[@]}"; do
    run_benchmark "Default" $THREADS $REPEATS $ITERATIONS ${min_sizes[$i]} ${max_sizes[$i]} "./malloctest"
    run_benchmark "Arena" $THREADS $REPEATS $ITERATIONS ${min_sizes[$i]} ${max_sizes[$i]} "./malloctest_arena"
done

make clean

echo "Benchmark completed. Results saved to $CSV_FILE"