#!/bin/bash
#Functions for creating SLURM job scripts

create_job_script() {
    local program_path=$1
    local params=$2
    local job_name=$3
    local dependency_program=$4
    local dependency_args=$5
    local output_file="${job_name}_output.log"
    local script_file="${job_name}_job.sh"
    
    cat > "$script_file" << EOF
#!/bin/bash
#SBATCH --partition=$CLUSTER_PARTITION
#SBATCH --job-name=$job_name
#SBATCH --output=$output_file
#SBATCH --ntasks=$CLUSTER_NTASKS
#SBATCH --ntasks-per-node=$CLUSTER_NTASKS
#SBATCH --exclusive
EOF
    
    cat >> "$script_file" << EOF

# Load modules
module load gcc/12.2.0-gcc-8.5.0-p4pe45v
module load cmake/3.24.3-gcc-8.5.0-svdlhox
module load ninja/1.11.1-python-3.10.8-gcc-8.5.0-2oc4wj6

# Configuration
VERY_FAST_ITERATIONS=$VERY_FAST_ITERATIONS
FAST_ITERATIONS=$FAST_ITERATIONS
MODERATELY_FAST_ITERATIONS=$MODERATELY_FAST_ITERATIONS
MAX_REPETITIONS=$MAX_REPETITIONS
MIN_REPETITIONS=$MIN_REPETITIONS
TARGET_PRECISION=$TARGET_PRECISION
PAUSE_SECONDS=$PAUSE_SECONDS
USING_CPU_LOAD=$USING_CPU_LOAD
USING_IO_LOAD=$USING_IO_LOAD
EOF

    cat >> "$script_file" << 'EOF'

clear_caches() {
    if command -v sync &> /dev/null && [ -w /proc/sys/vm/drop_caches ]; then
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    fi
}

format_time() {
    local value=$1
    
    # Check if the value is effectively zero (very small number)
    if (( $(echo "$value < 0.0000000001" | bc -l) )); then
        echo "1.000e-10"
    elif (( $(echo "$value < 0.001" | bc -l) )); then
        printf "%.3e" "$value"
    elif (( $(echo "$value < 0.1" | bc -l) )); then
        printf "%.7f" "$value"
    else
        printf "%.6f" "$value"
    fi
}

calculate_statistics() {
    local values="$1"
    local sum=0
    local count=0
    local min=""
    local max=""
    
    for value in $values; do
        sum=$(echo "$sum + $value" | bc -l)
        
        if [ -z "$min" ] || (( $(echo "$value < $min" | bc -l) )); then
            min=$value
        fi
        
        if [ -z "$max" ] || (( $(echo "$value > $max" | bc -l) )); then
            max=$value
        fi
        
        count=$((count + 1))
    done
    
    local mean=0
    local variance=0
    local stddev=0
    
    if [ $count -gt 0 ]; then
        mean=$(echo "scale=9; $sum / $count" | bc -l)
        
        local sum_sq_diff=0
        for value in $values; do
            local diff=$(echo "$value - $mean" | bc -l)
            local sq_diff=$(echo "$diff * $diff" | bc -l)
            sum_sq_diff=$(echo "$sum_sq_diff + $sq_diff" | bc -l)
        done
        
        if [ $count -gt 1 ]; then
            variance=$(echo "scale=9; $sum_sq_diff / $count" | bc -l)
            stddev=$(echo "scale=9; sqrt($variance)" | bc -l)
        fi
    fi
    
    echo "$mean $stddev $min $max $variance"
}

# Calculate confidence interval
calculate_confidence() {
    local values="$1"
    local target_precision="$2"
    
    local -a value_array=($values)
    local count=${#value_array[@]}
    
    # Need at least 3 measurements
    if [ $count -lt 3 ]; then
        echo "0 0 0 false"  # mean, stddev, rel_precision, confidence_reached
        return
    fi
    
    # Calculate mean
    local sum=0
    for value in "${value_array[@]}"; do
        sum=$(echo "$sum + $value" | bc -l)
    done
    local mean=$(echo "scale=10; $sum / $count" | bc -l)
    
    # Calculate sum of squared differences
    local sum_sq_diff=0
    for value in "${value_array[@]}"; do
        local diff=$(echo "$value - $mean" | bc -l)
        local sq_diff=$(echo "$diff * $diff" | bc -l)
        sum_sq_diff=$(echo "$sum_sq_diff + $sq_diff" | bc -l)
    done
    
    # Calculate standard deviation
    local variance=$(echo "scale=10; $sum_sq_diff / ($count - 1)" | bc -l)
    local stddev=$(echo "scale=10; sqrt($variance)" | bc -l)
    
    # Calculate confidence interval half-width (approximately 2*stddev/sqrt(n) for 95% confidence)
    local half_width=$(echo "scale=10; 2 * $stddev / sqrt($count)" | bc -l)
    
    # Calculate relative precision
    local rel_precision
    if (( $(echo "$mean > 0" | bc -l) )); then
        rel_precision=$(echo "scale=10; $half_width / $mean" | bc -l)
    else
        rel_precision="1.0"  # Default to 1.0 if mean is zero or negative
    fi
    
    # Check if confidence target is met
    local confidence_reached="false"
    if (( $(echo "$rel_precision <= $target_precision" | bc -l) )); then
        confidence_reached="true"
    fi
    
    echo "$mean $stddev $rel_precision $confidence_reached"
}

# Main measurement function
measure_program() {
    local program_path=$1
    local params=$2
    
    # Check if this is a fast program
    local start_time=$(date +%s.%N)
    $program_path $params > /dev/null 2>&1
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l)
    
    local iterations=1
    local high_precision_note=""
    
    # Determine if we need high precision mode
    if (( $(echo "$duration < 0.01" | bc -l) )); then
        echo "Very fast program detected ($duration s). Using very fast measurement."
        iterations=$VERY_FAST_ITERATIONS  # Very fast program (<10ms)
        high_precision_note="High precision mode ($iterations iterations per measurement)"
    elif (( $(echo "$duration < 0.1" | bc -l) )); then
        echo "Fast program detected ($duration s). Using fast measurement."
        iterations=$FAST_ITERATIONS  # Fast program (<100ms but >=10ms)
        high_precision_note="High precision mode ($iterations iterations per measurement)"
    elif (( $(echo "$duration < 0.5" | bc -l) )); then
        echo "Moderately fast program detected ($duration s). Using moderately fast measurement."
        iterations=$MODERATELY_FAST_ITERATIONS  # Moderately fast program (<500ms but >=100ms)
        high_precision_note="High precision mode ($iterations iterations per measurement)"
    else
        echo "Standard program detected ($duration s). Using standard measurement."
    fi
    echo "Using $iterations iterations for measurement"
    
    # Arrays to store measurements
    declare -a real_times
    declare -a user_times
    declare -a sys_times
    declare -a memory_values

    local run=0
    local confidence_reached=false
    local confidence_note=""
    
    # Perform measurements with dynamic repetitions
    while [ $run -lt $MAX_REPETITIONS ] && ! $confidence_reached; do
        echo "Run $((run+1)) of maximum $MAX_REPETITIONS"
        
        local temp_file=$(mktemp)
        
        if $USING_CPU_LOAD; then
            # Check if loadgen script exists
            loadgen_script="$(pwd)/load_generator/exec_with_workstation_heavy.sh"
            chmod +x "$loadgen_script"

            echo "Load generator directory contents:"
            #ls -la "$(pwd)/load_generator/"

            if [ ! -x "$loadgen_script" ]; then
                echo "ERROR: Load generator script not found or not executable: $loadgen_script"
                rm -f "$temp_file"
                return 1
            fi
            
            # Simulate workload
            PATH="$(pwd):$(pwd)/load_generator:$PATH" /usr/bin/time -f "%e,%U,%S,%M" bash -c "for ((i=0; i<$iterations; i++)); do 
            \"$program_path\" $params > /dev/null 2>&1 
            exit_code=\$?
            if [ \$exit_code -ne 0 ]; then
                echo \"Program failed with exit code \$exit_code on iteration \$i\" >&2
                continue
            fi
            done" 2> "$temp_file"
            # Check if we got any metrics
            if ! grep -q "[0-9]" "$temp_file"; then
                echo "0.0,0.0,0.0,0" > "$temp_file"
            fi
            echo "Using simulated workload"
        else
            # Direct execution
            /usr/bin/time -f "%e,%U,%S,%M" bash -c "for ((i=0; i<$iterations; i++)); do \"$program_path\" $params > /dev/null 2>&1; done" 2> "$temp_file" || {
                echo "WARNING: Program execution failed for run $((run+1))"
                echo "0.0,0.0,0.0,0" > "$temp_file"
            }
        fi
        
        local loop_metrics=$(cat "$temp_file")
        rm -f "$temp_file"

        # Extract and normalize metrics
        local real_total=$(echo "$loop_metrics" | cut -d, -f1)
        local user_total=$(echo "$loop_metrics" | cut -d, -f2)
        local sys_total=$(echo "$loop_metrics" | cut -d, -f3)
        local memory=$(echo "$loop_metrics" | cut -d, -f4)

        # Calculate average per iteration
        local real_time=$(echo "scale=9; $real_total / $iterations" | bc -l)
        local user_time=$(echo "scale=9; $user_total / $iterations" | bc -l)
        local sys_time=$(echo "scale=9; $sys_total / $iterations" | bc -l)
        
        # Store measurements
        real_times[$run]=$real_time
        user_times[$run]=$user_time
        sys_times[$run]=$sys_time
        memory_values[$run]=$memory
            
        echo "Real time: ${real_times[$run]}s | User: ${user_times[$run]}s | Sys: ${sys_times[$run]}s | Mem: ${memory_values[$run]}KB"
        
        # Calculate confidence after minimum repetitions
        if [ $run -ge $((MIN_REPETITIONS-1)) ]; then
            local conf_result=$(calculate_confidence "${real_times[*]}" "$TARGET_PRECISION")
            local mean=$(echo "$conf_result" | cut -d' ' -f1)
            local stddev=$(echo "$conf_result" | cut -d' ' -f2)
            local rel_precision=$(echo "$conf_result" | cut -d' ' -f3)
            local conf_reached=$(echo "$conf_result" | cut -d' ' -f4)
            
            echo "After $((run+1)) runs: Mean=$mean, StdDev=$stddev, Precision=$rel_precision"
            
            if [ "$conf_reached" = "true" ]; then
                confidence_reached=true
                confidence_note="Target precision of $TARGET_PRECISION reached after $((run+1)) runs"
                echo "$confidence_note"
            fi
        fi
        
        run=$((run+1))
        clear_caches
        sleep $PAUSE_SECONDS
    done
    
    if ! $confidence_reached; then
        confidence_note="Max repetitions ($MAX_REPETITIONS) reached without meeting confidence target"
        echo "$confidence_note"
    fi
    
    # Calculate final statistics
    local real_stats=$(calculate_statistics "${real_times[*]}")
    local user_stats=$(calculate_statistics "${user_times[*]}")
    local sys_stats=$(calculate_statistics "${sys_times[*]}")
    local mem_stats=$(calculate_statistics "${memory_values[*]}")

    # Extract statistics
    local avg_real=$(echo "$real_stats" | awk '{print $1}')
    local stddev_real=$(echo "$real_stats" | awk '{print $2}')
    local min_real=$(echo "$real_stats" | awk '{print $3}')
    local max_real=$(echo "$real_stats" | awk '{print $4}')
    local variance_real=$(echo "$real_stats" | awk '{print $5}')

    local avg_user=$(echo "$user_stats" | awk '{print $1}')
    local stddev_user=$(echo "$user_stats" | awk '{print $2}')
    local min_user=$(echo "$user_stats" | awk '{print $3}')
    local max_user=$(echo "$user_stats" | awk '{print $4}')

    local avg_sys=$(echo "$sys_stats" | awk '{print $1}')
    local stddev_sys=$(echo "$sys_stats" | awk '{print $2}')
    local min_sys=$(echo "$sys_stats" | awk '{print $3}')
    local max_sys=$(echo "$sys_stats" | awk '{print $4}')

    local avg_mem=$(echo "$mem_stats" | awk '{print $1}')

    # Format values for output
    local formatted_real=$(format_time "$avg_real")
    local formatted_user=$(format_time "$avg_user")
    local formatted_sys=$(format_time "$avg_sys")
    local formatted_stddev=$(format_time "$stddev_real")
    local formatted_min=$(format_time "$min_real")
    local formatted_max=$(format_time "$max_real")
    local formatted_variance=$(format_time "$variance_real")
    
    # Final output with confidence note
    local workload_note=""
    if $USING_CPU_LOAD; then
        workload_note="Simulated workload"
    fi
    
    local result="$formatted_real $formatted_user $formatted_sys $formatted_stddev $formatted_min $formatted_max $formatted_variance $avg_mem $high_precision_note $confidence_note $workload_note"
    echo "$result"
}
EOF

cat >> "$script_file" << EOF
# Get the original directory where the job script is running
ORIGINAL_DIR="\$PWD"
# Set up local temporary directory
LOCAL_TEMP_DIR="/tmp/benchmarks/"
mkdir -p "\$LOCAL_TEMP_DIR"
echo "Created temporary directory: \$LOCAL_TEMP_DIR"
chmod 755 "\$LOCAL_TEMP_DIR"
cd "\$LOCAL_TEMP_DIR"

# Copy the executable to the local directory
executable="${program_path##*/}"
cp -r "\$ORIGINAL_DIR/build" "\$LOCAL_TEMP_DIR/"
cp -r "\$ORIGINAL_DIR/load_generator" "\$LOCAL_TEMP_DIR/" 2>/dev/null || true

# Find the actual executable in the build directory
if [ ! -f "\$LOCAL_TEMP_DIR/build/\$executable" ]; then
    echo "WARNING: Executable not found at \$LOCAL_TEMP_DIR/build/\$executable"
    echo "Searching for executable in build directory..."
    FOUND_EXECUTABLE=\$(find "\$LOCAL_TEMP_DIR/build" -type f -perm -111 | head -1)
    if [ -n "\$FOUND_EXECUTABLE" ]; then
        echo "Found executable at \$FOUND_EXECUTABLE"
        executable=\$(basename "\$FOUND_EXECUTABLE")
        program_path="\$LOCAL_TEMP_DIR/build/\$executable"
        chmod +x "\$program_path"
    else
        echo "ERROR: No executable found in build directory!"
        ls -la "\$LOCAL_TEMP_DIR/build"
    fi
else
    program_path="\$LOCAL_TEMP_DIR/build/\$executable"
    chmod +x "\$program_path"
fi
EOF

cat >> "$script_file" << EOF


# Handle dependency programs if specified
if [ -n "$dependency_program" ]; then
    echo "Running dependency program: $dependency_program $dependency_args"
    
    # Process dependency executable path
    dep_executable="${dependency_program##*/}"
    
    # Check if dependency exists in the build directory
    if [ -f "\$LOCAL_TEMP_DIR/build/\$dep_executable" ]; then
        # Make sure it's executable
        chmod +x "\$LOCAL_TEMP_DIR/build/\$dep_executable"
        
        # Make temp directory writable for dependency program
        chmod -R 755 "\$LOCAL_TEMP_DIR"
        
        # Run the dependency from the build directory
        echo "Executing dependency: \$LOCAL_TEMP_DIR/build/\$dep_executable $dependency_args"
        cd "\$LOCAL_TEMP_DIR"
        "\$LOCAL_TEMP_DIR/build/\$dep_executable" $dependency_args
        
        # Show generated files for debugging
        echo "Files generated after dependency execution:"
        find "\$LOCAL_TEMP_DIR" -type d | head -5
        find "\$LOCAL_TEMP_DIR/generated" -type f | head -5 2>/dev/null || echo "No generated files found"
    else
        echo "Error: Dependency \$dep_executable not found in \$LOCAL_TEMP_DIR/build/"
        ls -la "\$LOCAL_TEMP_DIR/build/"
        exit 1
    fi
fi
EOF

cat >> "$script_file" << EOF

# Configure IO load generator if requested
if $USING_IO_LOAD; then
    IO_THREADS=16
    READ_PERCENT=50
    DELAY_MS=5
    MIN_FILE_SIZE=1024
    MAX_FILE_SIZE=10485760
    
    IO_LOAD_DIR="\$LOCAL_TEMP_DIR/io_load"
    
    # Cleanup function for IO load generator
    io_cleanup() {
        echo "Cleaning up IO load generator..."
        if [ ! -z "\$LOADGEN_PID" ]; then
            echo "Stopping I/O load generator (PID: \$LOADGEN_PID)"
            kill \$LOADGEN_PID 2>/dev/null
            wait \$LOADGEN_PID 2>/dev/null
        fi
        
        # Clean up the temp IO directory
        if [ -d "\$IO_LOAD_DIR" ]; then
            echo "Removing I/O load directory: \$IO_LOAD_DIR"
            rm -rf "\$IO_LOAD_DIR"
        fi
    }
    
    # Create IO load directory
    mkdir -p "\$IO_LOAD_DIR"
    echo "Starting I/O load generator with files in \$IO_LOAD_DIR..."
    
    # Start the I/O load generator in the background
    "\$LOCAL_TEMP_DIR/build/loadgen_io" \$IO_THREADS \$READ_PERCENT \$DELAY_MS \$MIN_FILE_SIZE \$MAX_FILE_SIZE 0 "\$IO_LOAD_DIR" &
    LOADGEN_PID=\$!
    
    if [ -z "\$LOADGEN_PID" ] || ! kill -0 \$LOADGEN_PID 2>/dev/null; then
        echo "Failed to start I/O load generator"
        exit 1
    fi
    
    echo "I/O load generator started with PID: \$LOADGEN_PID"
    echo "Waiting for I/O load to stabilize..."
    sleep 5
    
    # Extend the trap to include our IO cleanup
    trap 'io_cleanup; cd /; rm -rf "\$LOCAL_TEMP_DIR"' EXIT
else
    echo "Running without IO load generator"
fi
EOF

    cat >> "$script_file" << EOF

# Perform warmup runs
if [ $WARMUP_RUNS -gt 0 ]; then
    echo "Performing $WARMUP_RUNS warmup run(s)..."
    for ((i=1; i<=$WARMUP_RUNS; i++)); do
        "$program_path" "$params" > /dev/null 2>&1 || true
    done
fi

echo "About to execute program at path: $program_path"
echo "Checking if executable exists and is executable:"
if [ -x "$program_path" ]; then
    echo "✓ Executable exists and has proper permissions"
    echo "Test run of program: $program_path $params"
    $program_path $params || echo "Error: Program test run failed with exit code $?"
else
    echo "✗ Program not found or not executable at $program_path"
    ls -la $(dirname "$program_path")
fi

echo "Starting performance measurement..."
measure_program "$program_path" "$params"
EOF
    
    chmod +x "$script_file"
    echo "$script_file"
}

export -f create_job_script
