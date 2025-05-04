#!/bin/bash

CSV_FILE="results.csv"
echo "Allocator,Threads,Repeats,Iterations,MinSize,MaxSize,RealTime,UserTime,SysTime" > $CSV_FILE

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
    
    # Create a temporary file to capture time output
    time_file=$(mktemp)
    
    if [[ "$cmd" == LD_PRELOAD* ]]; then
        lib_path=$(echo "$cmd" | cut -d' ' -f1 | cut -d'=' -f2)
        real_cmd=$(echo "$cmd" | cut -d' ' -f2-)
        
        /usr/bin/time -f "%e %U %S" -o "$time_file" bash -c "LD_PRELOAD=\"$lib_path\" $real_cmd $threads $repeats $iterations $min_size $max_size"
    else
        /usr/bin/time -f "%e %U %S" -o "$time_file" $cmd $threads $repeats $iterations $min_size $max_size
    fi
    
    # Read timing results
    time_result=$(cat "$time_file")
    rm "$time_file"
    
    # Extract real, user, and system time
    real_seconds=$(echo "$time_result" | awk '{print $1}')
    user_seconds=$(echo "$time_result" | awk '{print $2}')
    sys_seconds=$(echo "$time_result" | awk '{print $3}')
    
    # Write results to CSV
    echo "$allocator,$threads,$repeats,$iterations,$min_size,$max_size,$real_seconds,$user_seconds,$sys_seconds" >> $CSV_FILE
    
    echo "  Time: real=$real_seconds, user=$user_seconds, sys=$sys_seconds"
    echo "--------------------------------------------------------------"
}

make all

# Define allocation size test cases
declare -a min_sizes=(10  10   10)
declare -a max_sizes=(100 1000 10000)

# Test parameters
THREADS=1
REPEATS=500
ITERATIONS=1000000

# Run tests for different allocation sizes
for i in "${!min_sizes[@]}"; do
    run_benchmark "Default" $THREADS $REPEATS $ITERATIONS ${min_sizes[$i]} ${max_sizes[$i]} "./malloctest"
    run_benchmark "Arena" $THREADS $REPEATS $ITERATIONS ${min_sizes[$i]} ${max_sizes[$i]} "LD_PRELOAD=./libarena_malloc.so ./malloctest"
done


# Test multi-threaded performance
declare -a thread_counts=(2 8 16)
MIN_SIZE=10
MAX_SIZE=1000

for threads in "${thread_counts[@]}"; do
    run_benchmark "Default" $threads $REPEATS $ITERATIONS $MIN_SIZE $MAX_SIZE "./malloctest"
    run_benchmark "Arena" $threads $REPEATS $ITERATIONS $MIN_SIZE $MAX_SIZE "LD_PRELOAD=./libarena_malloc.so ./malloctest"
done

make clean

echo "Benchmark completed. Results saved to $CSV_FILE"