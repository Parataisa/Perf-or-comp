#!/bin/bash
declare -a LUA_INTERPRETERS=(
    "./lua-5.4.8/src/lua"
    "./lua-5.4.8-memorization/src/lua"
    "./lua-own-jit/src/lua"
    "./lua-jit/src/lua luajit"
)

# Array of interpreter names (for cleaner CSV output)
declare -a INTERPRETER_NAMES=(
    "lua-5.4.8-default"
    "lua-5.4.8-memoized"
    "lua-5.4.8-own-jit"
    "luajit"
)

# Array of build directories (parent directories of src/)
declare -a BUILD_DIRS=(
    "./lua-5.4.8"
    "./lua-5.4.8-memorization"
    "./lua-own-jit"
    "./lua-jit"
)

# Array of build commands (customize per interpreter if needed)
declare -a BUILD_COMMANDS=(
    "make"
    "make"
    "make"
    "make"
)

# Array of additional build directories for dependencies
declare -a ADDITIONAL_BUILD_DIRS=(
    ""
    ""
    ""
    "./lua-jit/luajit"  # LuaJIT directory needs to be built separately
)

# Array of additional build commands
declare -a ADDITIONAL_BUILD_COMMANDS=(
    ""
    ""
    ""
    "make"
)

SCRIPT_PATH="./lua/fib.lua"
RESULTS_DIR="results_github_actions"
mkdir -p "$RESULTS_DIR"
OUTPUT_FILE="$RESULTS_DIR/benchmark_results.csv"

TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")
BENCHMARK_OUTPUT="$RESULTS_DIR/benchmark-$TIMESTAMP.txt"

if [ ! -f "$OUTPUT_FILE" ]; then
    echo "Timestamp,Interpreter,Implementation,Repetitions,N,Average_Runtime(s),Result" > "$OUTPUT_FILE"
fi

NUM_WARMUP=2
NUM_RUNS=5

build_interpreter() {
    local build_dir="$1"
    local build_cmd="$2"
    local name="$3"
    
    echo "Building $name in $build_dir..."
    
    if [ ! -d "$build_dir" ]; then
        echo "Error: Build directory $build_dir does not exist"
        return 1
    fi
    
    cd "$build_dir" || return 1
    
    echo "Running: $build_cmd"
    if eval $build_cmd; then
        echo "✓ Successfully built $name"
        cd - > /dev/null
        return 0
    else
        echo "✗ Failed to build $name"
        cd - > /dev/null
        return 1
    fi
}

clean_interpreter() {
    local build_dir="$1"
    local name="$2"
    
    echo "Cleaning $name in $build_dir..."
    
    if [ ! -d "$build_dir" ]; then
        echo "Warning: Build directory $build_dir does not exist"
        return 1
    fi
    
    cd "$build_dir" || return 1
    
    if make clean > /dev/null 2>&1; then
        echo "✓ Successfully cleaned $name"
    else
        echo "✗ Failed to clean $name (may not matter)"
    fi
    
    cd - > /dev/null
}

get_interpreter_name() {
    local interpreter_path="$1"
    local index="$2"
    
    if [ ${#INTERPRETER_NAMES[@]} -gt $index ]; then
        echo "${INTERPRETER_NAMES[$index]}"
    else
        echo "$(basename $(dirname "$interpreter_path"))/$(basename "$interpreter_path")"
    fi
}

check_interpreter() {
    local interpreter="$1"
    local name="$2"
    
    local interpreter_path=$(echo "$interpreter" | awk '{print $1}')
    
    if [ ! -f "$interpreter_path" ]; then
        echo "Warning: Interpreter $name not found at $interpreter_path - skipping"
        return 1
    fi
    
    if [ ! -x "$interpreter_path" ]; then
        echo "Warning: Interpreter $name at $interpreter_path is not executable - skipping"
        return 1
    fi
    
    if ! $interpreter_path -v > /dev/null 2>&1; then
        echo "Warning: Interpreter $name at $interpreter_path failed version check - skipping"
        return 1
    fi
    
    return 0
}

echo "=================================================="
echo "Building all interpreters..."
echo "=================================================="

for i in "${!BUILD_DIRS[@]}"; do
    INTERPRETER_NAME=$(get_interpreter_name "${LUA_INTERPRETERS[$i]}" $i)
    BUILD_DIR="${BUILD_DIRS[$i]}"
    BUILD_CMD="${BUILD_COMMANDS[$i]}"
    
    build_interpreter "$BUILD_DIR" "$BUILD_CMD" "$INTERPRETER_NAME"
    
    if [ -n "${ADDITIONAL_BUILD_DIRS[$i]}" ]; then
        ADDITIONAL_DIR="${ADDITIONAL_BUILD_DIRS[$i]}"
        ADDITIONAL_CMD="${ADDITIONAL_BUILD_COMMANDS[$i]}"
        
        if [ -n "$ADDITIONAL_DIR" ] && [ -n "$ADDITIONAL_CMD" ]; then
            build_interpreter "$ADDITIONAL_DIR" "$ADDITIONAL_CMD" "$INTERPRETER_NAME (dependency)"
        fi
    fi
done

for i in "${!LUA_INTERPRETERS[@]}"; do
    CURRENT_INTERPRETER="${LUA_INTERPRETERS[$i]}"
    INTERPRETER_NAME=$(get_interpreter_name "$CURRENT_INTERPRETER" $i)
    
    echo "=================================================="
    echo "Testing interpreter: $INTERPRETER_NAME"
    echo "Path: $CURRENT_INTERPRETER"
    echo "=================================================="
    
    if ! check_interpreter "$CURRENT_INTERPRETER" "$INTERPRETER_NAME"; then
        continue
    fi
    
    if ! $CURRENT_INTERPRETER "$SCRIPT_PATH" > /dev/null 2>&1; then
        echo "Warning: Script failed to run with $INTERPRETER_NAME - skipping"
        continue
    fi
    
    echo "Performing warmup runs for $INTERPRETER_NAME..."
    for warmup in $(seq 1 $NUM_WARMUP); do
        $CURRENT_INTERPRETER "$SCRIPT_PATH" > /dev/null 2>&1
    done

    declare -a naive_times=()
    declare -a tail_times=()
    declare -a iter_times=()
    naive_result=""
    tail_result=""
    iter_result=""

    echo "Performing measurement runs for $INTERPRETER_NAME..."
    for run in $(seq 1 $NUM_RUNS); do
        echo "Run $run of $NUM_RUNS"
        
        output=$($CURRENT_INTERPRETER "$SCRIPT_PATH")
        echo "$output" >> "$BENCHMARK_OUTPUT"
        echo "--- Run $run with $INTERPRETER_NAME ---" >> "$BENCHMARK_OUTPUT"
        
        naive_line=$(echo "$output" | grep "fibonacci_naive")
        tail_line=$(echo "$output" | grep "fibonacci_tail")
        iter_line=$(echo "$output" | grep "fibonacci_iter")
        
        naive_time=$(echo "$naive_line" | grep -o 'time:[ ]*[0-9.]*' | grep -o '[0-9.]*')
        tail_time=$(echo "$tail_line" | grep -o 'time:[ ]*[0-9.]*' | grep -o '[0-9.]*')
        iter_time=$(echo "$iter_line" | grep -o 'time:[ ]*[0-9.]*' | grep -o '[0-9.]*')
        
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

    for time in "${naive_times[@]}"; do
        sum_naive=$(echo "$sum_naive + $time" | bc)
    done

    for time in "${tail_times[@]}"; do
        sum_tail=$(echo "$sum_tail + $time" | bc)
    done

    for time in "${iter_times[@]}"; do
        sum_iter=$(echo "$sum_iter + $time" | bc)
    done

    avg_naive=$(echo "scale=8; $sum_naive / $NUM_RUNS" | bc)
    avg_tail=$(echo "scale=8; $sum_tail / $NUM_RUNS" | bc)
    avg_iter=$(echo "scale=8; $sum_iter / $NUM_RUNS" | bc)

    echo "$TIMESTAMP,$INTERPRETER_NAME,fibonacci_naive,100,30,$avg_naive,$naive_result" >> "$OUTPUT_FILE"
    echo "$TIMESTAMP,$INTERPRETER_NAME,fibonacci_tail,10000000,30,$avg_tail,$tail_result" >> "$OUTPUT_FILE"
    echo "$TIMESTAMP,$INTERPRETER_NAME,fibonacci_iter,25000000,30,$avg_iter,$iter_result" >> "$OUTPUT_FILE"

    echo "Results for $INTERPRETER_NAME saved to $OUTPUT_FILE"
    echo ""
    
    unset naive_times
    unset tail_times
    unset iter_times
done

echo "=================================================="
echo "All benchmarks complete!"
echo "Results saved to $OUTPUT_FILE"
echo "Raw output saved to $BENCHMARK_OUTPUT"
echo "=================================================="

echo "=================================================="
echo "Cleaning up all interpreters..."
echo "=================================================="

for i in "${!BUILD_DIRS[@]}"; do
    INTERPRETER_NAME=$(get_interpreter_name "${LUA_INTERPRETERS[$i]}" $i)
    BUILD_DIR="${BUILD_DIRS[$i]}"
    
    clean_interpreter "$BUILD_DIR" "$INTERPRETER_NAME"
    
    if [ -n "${ADDITIONAL_BUILD_DIRS[$i]}" ]; then
        ADDITIONAL_DIR="${ADDITIONAL_BUILD_DIRS[$i]}"
        
        if [ -n "$ADDITIONAL_DIR" ]; then
            clean_interpreter "$ADDITIONAL_DIR" "$INTERPRETER_NAME (dependency)"
        fi
    fi
done

echo "=================================================="
echo "All done!"
echo "=================================================="