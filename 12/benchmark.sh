#!/bin/bash

LUA_INTERPRETER="./lua-org/src/lua"
SCRIPT_PATH="./lua/fib.lua"
RESULTS_DIR="mac_fabio"
mkdir -p "$RESULTS_DIR"
OUTPUT_FILE="$RESULTS_DIR/benchmark_results.csv"

TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")
BENCHMARK_OUTPUT="$RESULTS_DIR/benchmark-$TIMESTAMP.txt"

if [ ! -f "$OUTPUT_FILE" ]; then
    echo "Timestamp,Implementation,Repetitions,N,Average_Runtime(s),Result" > "$OUTPUT_FILE"
fi

NUM_WARMUP=2
NUM_RUNS=5

echo "Performing warmup runs..."
for warmup in $(seq 1 $NUM_WARMUP); do
    $LUA_INTERPRETER $SCRIPT_PATH > /dev/null 2>&1
done

declare -a naive_times=()
declare -a tail_times=()
declare -a iter_times=()
naive_result=""
tail_result=""
iter_result=""

echo "Performing measurement runs..."
for run in $(seq 1 $NUM_RUNS); do
    echo "Run $run of $NUM_RUNS"
    
    output=$($LUA_INTERPRETER $SCRIPT_PATH)
    echo "$output" > "$BENCHMARK_OUTPUT"
    
    naive_line=$(echo "$output" | grep "fibonacci_naive")
    tail_line=$(echo "$output" | grep "fibonacci_tail")
    iter_line=$(echo "$output" | grep "fibonacci_iter")
    
    # Extract time using cut instead of awk for more reliable parsing
    naive_time=$(echo "$naive_line" | grep -o 'time:[ ]*[0-9.]*' | grep -o '[0-9.]*')
    tail_time=$(echo "$tail_line" | grep -o 'time:[ ]*[0-9.]*' | grep -o '[0-9.]*')
    iter_time=$(echo "$iter_line" | grep -o 'time:[ ]*[0-9.]*' | grep -o '[0-9.]*')
    
    # Extract result - everything after "--" and trimmed
    naive_result=$(echo "$naive_line" | grep -o '\-\-[ ]*[0-9]*' | grep -o '[0-9]*')
    tail_result=$(echo "$tail_line" | grep -o '\-\-[ ]*[0-9]*' | grep -o '[0-9]*')
    iter_result=$(echo "$iter_line" | grep -o '\-\-[ ]*[0-9]*' | grep -o '[0-9]*')
    
    naive_times+=($naive_time)
    tail_times+=($tail_time)
    iter_times+=($iter_time)
    
    echo "  naive: $naive_time s → $naive_result"
    echo "  tail:  $tail_time s → $tail_result"
    echo "  iter:  $iter_time s → $iter_result"
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

echo "Used lua interpreter: $LUA_INTERPRETER"
echo "$TIMESTAMP,fibonacci_naive,100,30,$avg_naive,$naive_result" >> "$OUTPUT_FILE"
echo "$TIMESTAMP,fibonacci_tail,10000000,30,$avg_tail,$tail_result" >> "$OUTPUT_FILE"
echo "$TIMESTAMP,fibonacci_iter,25000000,30,$avg_iter,$iter_result" >> "$OUTPUT_FILE"

echo "Benchmark complete. Results saved to $OUTPUT_FILE"
echo "Raw output of final run saved to $BENCHMARK_OUTPUT"