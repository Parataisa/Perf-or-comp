#!/bin/bash

LUA_INTERPRETER="./lua-5.4.8/src/lua"
SCRIPT_PATH="./lua/fib.lua"
RESULTS_DIR="results"
mkdir -p "$RESULTS_DIR"
OUTPUT_FILE="$RESULTS_DIR/benchmark_results.csv"

TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")
BENCHMARK_OUTPUT="$RESULTS_DIR/benchmark-$TIMESTAMP.txt"

NUM_WARMUP=1
NUM_RUNS=1

echo "Implementation,Repetitions,N,Average_Runtime(s),Result" > "$OUTPUT_FILE"
echo "Starting Lua Fibonacci benchmark..."
echo "Running $NUM_WARMUP warmup runs and $NUM_RUNS actual runs"

echo "Performing warmup runs..."
for warmup in $(seq 1 $NUM_WARMUP); do
    echo "  Warmup run $warmup..."
    $LUA_INTERPRETER $SCRIPT_PATH > /dev/null 2>&1
done

# Arrays to collect values
declare -a naive_times=()
declare -a tail_times=()
declare -a iter_times=()
naive_result=""
tail_result=""
iter_result=""

echo "Performing measurement runs..."
for run in $(seq 1 $NUM_RUNS); do
    echo "  Run $run of $NUM_RUNS..."
    
    output=$($LUA_INTERPRETER $SCRIPT_PATH)
    
    naive_line=$(echo "$output" | grep "fibonacci_naive")
    tail_line=$(echo "$output" | grep "fibonacci_tail")
    iter_line=$(echo "$output" | grep "fibonacci_iter")
    
    naive_time=$(echo "$naive_line" | awk '{print $6}')
    tail_time=$(echo "$tail_line" | awk '{print $6}')
    iter_time=$(echo "$iter_line" | awk '{print $6}')
    
    naive_result=$(echo "$naive_line" | awk '{print $9}')
    tail_result=$(echo "$tail_line" | awk '{print $9}')
    iter_result=$(echo "$iter_line" | awk '{print $9}')
    
    naive_times+=($naive_time)
    tail_times+=($tail_time)
    iter_times+=($iter_time)
    
    echo "    naive: ${naive_time}s, tail: ${tail_time}s, iter: ${iter_time}s"
    
    if [ $run -eq $NUM_RUNS ]; then
        echo "$output" > "$BENCHMARK_OUTPUT"
    fi
done

sum_naive=0
sum_tail=0
sum_iter=0

for i in "${naive_times[@]}"; do
    sum_naive=$(echo "$sum_naive + $i" | bc)
done

for i in "${tail_times[@]}"; do
    sum_tail=$(echo "$sum_tail + $i" | bc)
done

for i in "${iter_times[@]}"; do
    sum_iter=$(echo "$sum_iter + $i" | bc)
done

avg_naive=$(echo "scale=4; $sum_naive / $NUM_RUNS" | bc)
avg_tail=$(echo "scale=4; $sum_tail / $NUM_RUNS" | bc)
avg_iter=$(echo "scale=4; $sum_iter / $NUM_RUNS" | bc)

echo "fibonacci_naive,100,30,$avg_naive,$naive_result" >> "$OUTPUT_FILE"
echo "fibonacci_tail,10000000,30,$avg_tail,$tail_result" >> "$OUTPUT_FILE"
echo "fibonacci_iter,25000000,30,$avg_iter,$iter_result" >> "$OUTPUT_FILE"

echo -e "\nResults:"
echo "  fibonacci_naive(30) - Avg time: ${avg_naive}s - Result: $naive_result"
echo "  fibonacci_tail(30)  - Avg time: ${avg_tail}s - Result: $tail_result"
echo "  fibonacci_iter(30)  - Avg time: ${avg_iter}s - Result: $iter_result"

echo -e "\nBenchmark complete."
echo "Averaged results saved to $OUTPUT_FILE"
echo "Raw output of final run saved to $BENCHMARK_OUTPUT"