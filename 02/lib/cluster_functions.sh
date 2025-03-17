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
SIM_WORKLOAD=$sim_workload
EOF

    cat >> "$script_file" << 'EOF'

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
    local sim_workload=$3
    
    # Check if this is a fast program
    local start_time=$(date +%s.%N)
    $program_path $params > /dev/null 2>&1
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l)
    
    local iterations=1
    local high_precision_note=""
    
    # Determine if we need high precision mode
    if (( $(echo "$duration < 0.01" | bc -l) )); then
        iterations=$VERY_FAST_ITERATIONS  # Very fast program (<10ms)
        high_precision_note="High precision mode ($iterations iterations per measurement)"
    elif (( $(echo "$duration < 0.1" | bc -l) )); then
        iterations=$FAST_ITERATIONS  # Fast program (<100ms but >=10ms)
        high_precision_note="High precision mode ($iterations iterations per measurement)"
    elif (( $(echo "$duration < 0.5" | bc -l) )); then
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
        
        if $sim_workload; then
            # Check if loadgen script exists
            loadgen_script="$(pwd)/load_generator/exec_with_workstation_heavy.sh"
            chmod +x "$loadgen_script"
            if [ ! -x "$loadgen_script" ]; then
                echo "ERROR: Load generator script not found or not executable: $loadgen_script"
                rm -f "$temp_file"
                return 1
            fi
            
            # Simulate workload
            /usr/bin/time -f "%e,%U,%S,%M" bash -c "for ((i=0; i<$iterations; i++)); do 
                \"$loadgen_script\" \"$program_path\" $params > /dev/null 2>&1 
                exit_code=\$?
                if [ \$exit_code -ne 0 ]; then
                    echo \"Program failed with exit code \$exit_code on iteration \$i\" >&2
                    continue
                fi
                done" 2> "$temp_file" || {
                echo "WARNING: Workload simulation failed for run $((run+1))"
                # Check if we got any metrics
                if ! grep -q "[0-9]" "$temp_file"; then
                    echo "0.0,0.0,0.0,0" > "$temp_file"
                fi
            }
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
    if $sim_workload; then
        workload_note="Simulated workload"
    fi
    
    local result="$formatted_real $formatted_user $formatted_sys $avg_mem $formatted_stddev $formatted_min $formatted_max $formatted_variance $high_precision_note $confidence_note $workload_note"
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
measure_program "$program_path" "$params" $sim_workload
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
    
    log "DEBUG" "Output file found, parsing contents..."
    
    # Debug: Print file contents for troubleshooting
    log "DEBUG" "File contents of $output_file:"
    log "DEBUG" "$(cat "$output_file" | tail -20)"
    
    # Extract the measurement result line
    local result_line=$(grep -E "^[0-9]+\.[0-9]+" "$output_file" | tail -1)
    
    if [ -z "$result_line" ]; then
        log "ERROR" "Could not find a valid measurement result in the output file"
        return 1
    fi
    
    log "DEBUG" "Found measurement result: $result_line"
    
    # Extract just the first 5 numeric values from the result
    local values=($(echo "$result_line" | awk '{print $1,$2,$3,$4,$5}'))
    
    if [ ${#values[@]} -lt 5 ]; then
        log "ERROR" "Measurement result line does not contain enough values"
        return 1
    fi
    
    local avg_real="${values[0]}"
    local stddev_real="${values[1]}"
    local min_real="${values[2]}"
    local max_real="${values[3]}"
    local variance_real="${values[4]}"
    
    # Extract just the textual notes (everything after the 5th value)
    local extracted_notes=$(echo "$result_line" | awk '{for(i=6;i<=NF;i++) printf "%s ", $i}' | sed 's/ $//')
    
    # Reconstruct the result for return
    local basic_result="$avg_real 0.000000000 0.000000000 0 $stddev_real $min_real $max_real $variance_real"
    
    # Build the final notes string
    local notes="$extracted_notes, Cluster execution"
    
    local result="$basic_result $notes"
    log "DEBUG" "Parsed result: $result"
    echo "$result"
}

# Execute performance test on the cluster
run_on_cluster() {
    local program_path=$1
    local params=$2
    local sim_workload=$3
    local program_name=$(basename "$program_path")
    
    log "INFO" "Running on cluster using SLURM with dynamic repetitions..."
    if $sim_workload; then
        log "INFO" "Using simulated workload"
    fi
    
    # Create a unique job name with timestamp
    local job_name="${JOB_NAME_PREFIX}_${program_name}_$(date +%s)"
    
    # Create job script
    local job_script=$(create_job_script "$program_path" "$params" "$job_name" "$sim_workload")
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
    
    local result=$(parse_job_output "$output_file")
    
    if [ -z "$result" ]; then
        log "ERROR" "Failed to parse job output. Skipping this parameter set."
        return 1
    fi
    
    if [ "$CLEANUP_JOB_FILES" = "true" ]; then
        log "DEBUG" "Cleaning up job files: $job_script $output_file"
        rm -f "$job_script" "$output_file"
    fi
    
    result="$result, Cluster execution"
    
    echo "$result"
}

# Export functions and variables for use in the main script
export -f create_job_script submit_job wait_for_job parse_job_output run_on_cluster
export RUN_ON_CLUSTER CLUSTER_PARTITION CLUSTER_NTASKS CLUSTER_EXCLUSIVE JOB_NAME_PREFIX MAX_WAIT_TIME
export CLEANUP_JOB_FILES