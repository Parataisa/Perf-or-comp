#!/bin/bash

# --- Default Configuration ---
DEFAULT_LUA_INTERPRETER="./lua-org/src/lua"
DEFAULT_RESULTS_DIR="benchmark_results"
SCRIPT_PATH="./lua/fib.lua"

# --- Helper function for usage instructions ---
usage() {
  echo "Usage: $0 [-l|--lua <path>] [-o|--output <dir>] [-h|--help]"
  echo "  -l, --lua      Path to the Lua interpreter to use."
  echo "                 (default: $DEFAULT_LUA_INTERPRETER)"
  echo "  -o, --output   Directory to save benchmark results."
  echo "                 (default: $DEFAULT_RESULTS_DIR)"
  echo "  -h, --help     Display this help message and exit."
  exit 0
}

# --- Parse Command-Line Arguments ---
LUA_INTERPRETER="$DEFAULT_LUA_INTERPRETER"
RESULTS_DIR="$DEFAULT_RESULTS_DIR"

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -l | --lua)
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Error: Missing argument for $1" >&2
        exit 1
      fi
      LUA_INTERPRETER="$2"
      shift 2
      ;;
    -o | --output)
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Error: Missing argument for $1" >&2
        exit 1
      fi
      RESULTS_DIR="$2"
      shift 2
      ;;
    -h | --help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

# --- Initial Setup & Validation ---
echo "--- Benchmark Configuration ---"
echo "Lua Interpreter: $LUA_INTERPRETER"
echo "Output Directory:  $RESULTS_DIR"
echo "-----------------------------"

if [ ! -f "$SCRIPT_PATH" ]; then
  echo "Error: Lua script not found at '$SCRIPT_PATH'" >&2
  exit 1
fi

if [ ! -x "$LUA_INTERPRETER" ]; then
  echo "Error: Lua interpreter not found or not executable at '$LUA_INTERPRETER'" >&2
  exit 1
fi

mkdir -p "$RESULTS_DIR"
OUTPUT_FILE="$RESULTS_DIR/benchmark_results.csv"
TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")
BENCHMARK_OUTPUT="$RESULTS_DIR/benchmark-$TIMESTAMP.txt"

if [ ! -f "$OUTPUT_FILE" ]; then
  echo "Timestamp,Implementation,Repetitions,N,Average_Runtime(s),Result" > "$OUTPUT_FILE"
fi

# --- Main Benchmark Logic ---
NUM_WARMUP=2
NUM_RUNS=5

echo
echo "Performing $NUM_WARMUP warmup runs..."
for warmup in $(seq 1 $NUM_WARMUP); do
  $LUA_INTERPRETER $SCRIPT_PATH > /dev/null 2>&1
done

declare -a naive_times=()
declare -a tail_times=()
declare -a iter_times=()
naive_result=""
tail_result=""
iter_result=""

echo
echo "Performing $NUM_RUNS measurement runs..."
for run in $(seq 1 $NUM_RUNS); do
  echo "Run $run of $NUM_RUNS"

  output=$($LUA_INTERPRETER $SCRIPT_PATH)
  # Save the raw output of the last run for inspection
  if [ "$run" -eq "$NUM_RUNS" ]; then
    echo "$output" > "$BENCHMARK_OUTPUT"
  fi

  naive_line=$(echo "$output" | grep "fibonacci_naive")
  tail_line=$(echo "$output" | grep "fibonacci_tail")
  iter_line=$(echo "$output" | grep "fibonacci_iter")

  # Extract time using grep for robustness
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

# --- Calculate Averages ---
sum_naive=0
for i in "${naive_times[@]}"; do sum_naive=$(echo "$sum_naive + $i" | bc); done
avg_naive=$(echo "scale=4; $sum_naive / $NUM_RUNS" | bc)

sum_tail=0
for i in "${tail_times[@]}"; do sum_tail=$(echo "$sum_tail + $i" | bc); done
avg_tail=$(echo "scale=4; $sum_tail / $NUM_RUNS" | bc)

sum_iter=0
for i in "${iter_times[@]}"; do sum_iter=$(echo "$sum_iter + $i" | bc); done
avg_iter=$(echo "scale=4; $sum_iter / $NUM_RUNS" | bc)

# --- Save Results ---
echo
echo "Used lua interpreter: $LUA_INTERPRETER" >> "$OUTPUT_FILE"
echo "$TIMESTAMP,fibonacci_naive,100,30,$avg_naive,$naive_result" >> "$OUTPUT_FILE"
echo "$TIMESTAMP,fibonacci_tail,10000000,30,$avg_tail,$tail_result" >> "$OUTPUT_FILE"
echo "$TIMESTAMP,fibonacci_iter,25000000,30,$avg_iter,$iter_result" >> "$OUTPUT_FILE"

echo "Benchmark complete."
echo "Averages saved to $OUTPUT_FILE"
echo "Raw output of final run saved to $BENCHMARK_OUTPUT"