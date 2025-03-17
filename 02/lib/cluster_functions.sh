#!/bin/bash
# Create a SLURM job script
create_job_script() {
    local program_path=$1
    local params=$2
    local job_name=$3
    local sim_workload=$4
    local output_file="${job_name}_output.log"
    local script_file="${job_name}_job.sh"
    
    # Create basic SLURM header
    cat > "$script_file" << EOF
#!/bin/bash
#SBATCH --partition=$CLUSTER_PARTITION
#SBATCH --job-name=$job_name
#SBATCH --output=$output_file
#SBATCH --ntasks=$CLUSTER_NTASKS
#SBATCH --ntasks-per-node=$CLUSTER_NTASKS
#SBATCH --exclusive
EOF
    
    # Add module loading and configuration
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
EOF

    cat >> "$script_file" << 'EOF'

# Ensure bc command is available
if ! command -v bc &> /dev/null; then
    echo "Error: bc command not found. Please load required module." >&2
    # Try to load a math module if available
    module load bc 2>/dev/null || true
fi

# Helper function for safe bc operations
safe_bc() {
    local expression="$1"
    local default_value="${2:-0}"
    
    # Sanitize input to avoid syntax errors
    expression=$(echo "$expression" | tr -d '\r')
    
    # Run bc with error handling
    result=$(echo "$expression" | bc -l 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$result" ]; then
        echo "$default_value"
    else
        echo "$result"
    fi
}

# Helper function for safe comparisons
safe_compare() {
    local left="$1"
    local op="$2"
    local right="$3"
    local default="${4:-false}"
    
    # Ensure numeric values
    if ! [[ "$left" =~ ^[+-]?[0-9]*\.?[0-9]+$ ]] || ! [[ "$right" =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
        # Not valid numbers, return default
        [ "$default" = "true" ] && return 0 || return 1
    fi
    
    local result
    result=$(safe_bc "$left $op $right" 0)
    
    # Check result (1 for true, 0 for false in bc)
    if [ "$result" = "1" ]; then
        return 0  # Success/true
    else
        return 1  # Failure/false
    fi
}

clear_caches() {
    if command -v sync &> /dev/null && [ -w /proc/sys/vm/drop_caches ]; then
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    fi
}

format_time() {
    local time_value="$1"
    if [[ "$time_value" =~ ^\.[0-9]+ ]]; then
        time_value="0$time_value"
    fi
    echo "$time_value"
}

calculate_statistics() {
    local values="$1"
    local sum=0
    local count=0
    local min=""
    local max=""
    
    for value in $values; do
        # Skip invalid values
        if ! [[ "$value" =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
            echo "WARNING: Skipping invalid value: $value" >&2
            continue
        fi
        
        sum=$(safe_bc "$sum + $value")
        
        if [ -z "$min" ] || safe_compare "$value" "<" "$min"; then
            min=$value
        fi
        
        if [ -z "$max" ] || safe_compare "$value" ">" "$max"; then
            max=$value
        fi
        
        count=$((count + 1))
    done
    
    local mean=0
    local variance=0
    local stddev=0
    
    if [ $count -gt 0 ]; then
        mean=$(safe_bc "scale=9; $sum / $count")
        
        local sum_sq_diff=0
        for value in $values; do
            # Skip invalid values
            if ! [[ "$value" =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
                continue
            fi
            
            local diff=$(safe_bc "$value - $mean")
            local sq_diff=$(safe_bc "$diff * $diff")
            sum_sq_diff=$(safe_bc "$sum_sq_diff + $sq_diff")
        done
        
        if [ $count -gt 1 ]; then
            variance=$(safe_bc "scale=9; $sum_sq_diff / $count")
            stddev=$(safe_bc "scale=9; sqrt($variance)")
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
    for val in $values; do
        sum=$(safe_bc "$sum + $val")
    done
    local mean=$(safe_bc "$sum / $count")
    
    # Calculate standard deviation
    local sum_sq_diff=0
    for val in $values; do
        local diff=$(safe_bc "$val - $mean")
        local sq_diff=$(safe_bc "$diff * $diff")
        sum_sq_diff=$(safe_bc "$sum_sq_diff + $sq_diff")
    done
    
    local stddev=0
    if [ $count -gt 1 ]; then
        stddev=$(safe_bc "sqrt($sum_sq_diff / ($count - 1))")
    fi
    
    local half_width=0
    if [ $count -gt 0 ]; then
        half_width=$(safe_bc "scale=9; 2 * $stddev / sqrt($count)")
    fi
    
    # Calculate relative precision
    local rel_precision=1.0
    if safe_compare "$mean" ">" "0.000001"; then
        rel_precision=$(safe_bc "scale=9; $half_width / $mean")
    fi
    
    # Check if confidence target is met
    local confidence_reached=false
    if safe_compare "$rel_precision" "<=" "$target_precision"; then
        confidence_reached=true
    fi
    
    echo "$mean $stddev $rel_precision $confidence_reached"
}

# Main measurement function
measure_program() {
    local program_path=$1
    local params=$2
    
    # Check if this is a fast program
    local start_time=$(date +%s.%N)
    "$program_path" $params > /dev/null 2>&1 || true
    local end_time=$(date +%s.%N)
    local duration=$(safe_bc "$end_time - $start_time")
    
    local iterations=1
    local high_precision_note=""
    
    # Determine if we need high precision mode
    if safe_compare "$duration" "<" "0.01"; then
        iterations=$VERY_FAST_ITERATIONS  # Very fast program (<10ms)
        high_precision_note="High precision mode ($iterations iterations per measurement)"
    elif safe_compare "$duration" "<" "0.1"; then
        iterations=$FAST_ITERATIONS  # Fast program (<100ms but >=10ms)
        high_precision_note="High precision mode ($iterations iterations per measurement)"
    elif safe_compare "$duration" "<" "0.5"; then
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
        /usr/bin/time -f "%e,%U,%S,%M" bash -c "for ((i=0; i<$iterations; i++)); do \"$program_path\" $params > /dev/null 2>&1 || true; done" 2> "$temp_file" || true
        
        # Check if time command succeeded
        if [ ! -s "$temp_file" ]; then
            echo "Warning: time command failed to produce output" >&2
            rm -f "$temp_file"
            run=$((run+1))
            continue
        fi
        
        local loop_metrics=$(cat "$temp_file")
        rm -f "$temp_file"

        # Extract and normalize metrics
        if ! echo "$loop_metrics" | grep -q "," ; then
            echo "Warning: Invalid time output format: $loop_metrics" >&2
            continue
        else
            local real_total=$(echo "$loop_metrics" | cut -d, -f1)
            local user_total=$(echo "$loop_metrics" | cut -d, -f2)
            local sys_total=$(echo "$loop_metrics" | cut -d, -f3)
            local memory=$(echo "$loop_metrics" | cut -d, -f4)
            
            # Validate metrics
            if ! [[ "$real_total" =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
                echo "Warning: Invalid real time: $real_total, using default" >&2
                real_total="0.01"
            fi
            if ! [[ "$user_total" =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
                echo "Warning: Invalid user time: $user_total, using default" >&2
                user_total="0.005"
            fi
            if ! [[ "$sys_total" =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
                echo "Warning: Invalid sys time: $sys_total, using default" >&2
                sys_total="0.005"
            fi
            if ! [[ "$memory" =~ ^[0-9]+$ ]]; then
                echo "Warning: Invalid memory value: $memory, using default" >&2
                memory="1000"
            fi
        fi

        # Calculate average per iteration
        local real_time=$(safe_bc "scale=9; $real_total / $iterations")
        local user_time=$(safe_bc "scale=9; $user_total / $iterations")
        local sys_time=$(safe_bc "scale=9; $sys_total / $iterations")
        
        # Store measurements
        real_times[$run]=$real_time
        user_times[$run]=$user_time
        sys_times[$run]=$sys_time
        memory_values[$run]=$memory
            
        echo "Real time: ${real_times[$run]}s | User: ${user_times[$run]}s | Sys: ${sys_times[$run]}s | Mem: ${memory_values[$run]}KB"
        
        # Calculate confidence after minimum repetitions
        if [ $run -ge $((MIN_REPETITIONS-1)) ]; then
            local real_times_joined="${real_times[*]}"
            local conf_result=$(calculate_confidence "$real_times_joined" "$TARGET_PRECISION")
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
    
    # Join array elements into space-separated strings for statistics calculation
    local real_times_joined="${real_times[*]}"
    local user_times_joined="${user_times[*]}"
    local sys_times_joined="${sys_times[*]}"
    local memory_values_joined="${memory_values[*]}"
    
    # Calculate final statistics
    local real_stats=$(calculate_statistics "$real_times_joined")
    local user_stats=$(calculate_statistics "$user_times_joined")
    local sys_stats=$(calculate_statistics "$sys_times_joined")
    local mem_stats=$(calculate_statistics "$memory_values_joined")
    
    # Extract statistics
    local avg_real=$(echo "$real_stats" | awk '{print $1}')
    local stddev_real=$(echo "$real_stats" | awk '{print $2}')
    local min_real=$(echo "$real_stats" | awk '{print $3}')
    local max_real=$(echo "$real_stats" | awk '{print $4}')
    local variance_real=$(echo "$real_stats" | awk '{print $5}')
    
    local avg_user=$(echo "$user_stats" | awk '{print $1}')
    local avg_sys=$(echo "$sys_stats" | awk '{print $1}')
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
    local result="$formatted_real $formatted_user $formatted_sys $avg_mem $formatted_stddev $formatted_min $formatted_max $formatted_variance $high_precision_note $confidence_note"
    echo "$result"
}
EOF
    
    cat >> "$script_file" << EOF

# Perform warmup runs
if [ $WARMUP_RUNS -gt 0 ]; then
    echo "Performing $WARMUP_RUNS warmup run(s)..."
    for ((i=1; i<=$WARMUP_RUNS; i++)); do
        $program_path $params > /dev/null 2>&1
    done
fi

echo "Starting performance measurement..."
measure_program $program_path $params
EOF
    
    chmod +x "$script_file"
    echo "$script_file"
}

# Submit job to SLURM
submit_job() {
    local job_script=$1
    local job_id
    
    log "INFO" "Submitting job: $job_script"
    job_id=$(sbatch "$job_script" | awk '{print $4}')
    
    if [ -z "$job_id" ]; then
        log "ERROR" "Failed to submit job: $job_script"
        return 1
    fi
    
    log "INFO" "Job submitted with ID: $job_id"
    echo "$job_id"
}

# Wait for a job to complete with timeout and cancellation
wait_for_job() {
    local job_id=$1
    local job_state
    local waited=0
    
    while true; do
        job_state=$(squeue -j "$job_id" -h -o %t 2>/dev/null)
        
        if [ -z "$job_state" ]; then
            # Job not found in queue, assume it has completed
            log "INFO" "Job $job_id has completed."
            return 0
        fi
        
        log "DEBUG" "Job $job_id state: $job_state"
        sleep 5
        waited=$((waited + 5))
        
        # Check for timeout and cancel job if needed
        if [ $waited -ge $MAX_WAIT_TIME ]; then
            log "WARNING" "Job $job_id has exceeded maximum wait time of $MAX_WAIT_TIME seconds. Cancelling job."
            scancel $job_id
            return 1
        fi
    done
}

# Parse job output
parse_job_output() {
    local output_file=$1
    
    # Wait for output file
    local max_wait=30
    local waited=0
    while [ ! -f "$output_file" ]; do
        log "DEBUG" "Waiting for job output file: $output_file"
        sleep 1
        waited=$((waited + 1))
        if [ $waited -ge $max_wait ]; then
            log "ERROR" "Timeout waiting for output file: $output_file"
            return 1
        fi
    done
    
    # Extract notes (precision + confidence)
    local notes=""
    if grep -q "High precision mode" "$output_file"; then
        local precision_note=$(grep "High precision mode" "$output_file" | tail -1)
        notes="$precision_note"
    fi
    
    if grep -q "Target precision of" "$output_file"; then
        local confidence_note=$(grep "Target precision of" "$output_file" | tail -1)
        if [ -n "$notes" ]; then
            notes="$notes, $confidence_note"
        else
            notes="$confidence_note"
        fi
    elif grep -q "Max repetitions" "$output_file"; then
        local max_rep_note=$(grep "Max repetitions" "$output_file" | tail -1)
        if [ -n "$notes" ]; then
            notes="$notes, $max_rep_note"
        else
            notes="$max_rep_note"
        fi
    fi
    
    # Get the last line which should contain the numeric results
    local last_line=$(tail -1 "$output_file")
    
    # Extract just the numeric fields (first 8 fields)
    local result_line=$(echo "$last_line" | awk '{print $1, $2, $3, $4, $5, $6, $7, $8}')
    
    if [ -z "$result_line" ]; then
        log "ERROR" "Could not find a valid measurement result in the output file"
        return 1
    fi
    
    log "DEBUG" "Found measurement result: $result_line"
    echo "$result_line $notes"
}

# Execute performance test on the cluster
run_on_cluster() {
    local program_path=$1
    local params=$2
    local program_name=$(basename "$program_path")
    
    log "INFO" "Running on cluster using SLURM with dynamic repetitions..."
    
    # Create a unique job name with timestamp
    local job_name="${JOB_NAME_PREFIX}_${program_name}_$(date +%s)"
    
    # Create job script
    local job_script=$(create_job_script "$program_path" "$params" "$job_name")
    local output_file="${job_name}_output.log"
    
    local job_id=$(submit_job "$job_script")
    
    if [ -z "$job_id" ]; then
        log "ERROR" "Failed to submit job. Skipping this parameter set."
        return 1
    fi
    
    if ! wait_for_job "$job_id"; then
        log "ERROR" "Job $job_id was cancelled due to timeout."
        return 1
    fi
    
    # Get the last line of output which contains our metrics
    local last_line=$(tail -1 "$output_file")
    
    # Extract just the first 8 numeric values for the metrics
    local metrics=$(echo "$last_line" | awk '{print $1, $2, $3, $4, $5, $6, $7, $8}')
    
    if [ -z "$metrics" ]; then
        log "ERROR" "Failed to parse job output. Skipping this parameter set."
        return 1
    fi
    
    # Extract notes separately
    local notes=""
    if grep -q "High precision mode" "$output_file"; then
        notes="High precision mode"
    fi
    
    if grep -q "Target precision of" "$output_file"; then
        if [ -n "$notes" ]; then
            notes="$notes, Target precision reached"
        else
            notes="Target precision reached" 
        fi
    elif grep -q "Max repetitions" "$output_file"; then
        if [ -n "$notes" ]; then
            notes="$notes, Max repetitions reached"
        else
            notes="Max repetitions reached"
        fi
    fi
    
    if [ "$CLEANUP_JOB_FILES" = "true" ]; then
        log "DEBUG" "Cleaning up job files: $job_script $output_file"
        rm -f "$job_script" "$output_file"
    fi
    
    # Combine metrics and notes
    local result="$metrics"
    if [ -n "$notes" ]; then
        result="$result $notes, Cluster execution"
    else
        result="$result Cluster execution"
    fi
    
    echo "$result"
}
# Export functions and variables for use in the main script
export -f create_job_script submit_job wait_for_job parse_job_output run_on_cluster
export RUN_ON_CLUSTER CLUSTER_PARTITION CLUSTER_NTASKS CLUSTER_EXCLUSIVE JOB_NAME_PREFIX MAX_WAIT_TIME
export CLEANUP_JOB_FILES