#!/bin/bash

# Cluster execution configuration
RUN_ON_CLUSTER=true          # Set to true to run on cluster using SLURM
CLUSTER_PARTITION="lva"      # SLURM partition to use
CLUSTER_NTASKS=1             # Number of tasks for SLURM job
CLUSTER_EXCLUSIVE=true       # Whether to request exclusive node allocation
JOB_NAME_PREFIX="perf_test"  # Prefix for SLURM job names
MAX_WAIT_TIME=600            # Maximum wait time in seconds before canceling job
CLEANUP_JOB_FILES=false       # Whether to clean up job files after execution

# Create a SLURM job script
create_job_script() {
    local program_path=$1
    local params=$2
    local job_name=$3
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
EOF

    # Add exclusive flag if enabled
    if $CLUSTER_EXCLUSIVE; then
        echo "#SBATCH --exclusive" >> "$script_file"
    fi
    
    # Add module loading
    cat >> "$script_file" << EOF

# Load modules
module load gcc/12.2.0-gcc-8.5.0-p4pe45v
module load cmake/3.24.3-gcc-8.5.0-svdlhox
module load ninja/1.11.1-python-3.10.8-gcc-8.5.0-2oc4wj6

# Precision mode configuration
VERY_FAST_ITERATIONS=$VERY_FAST_ITERATIONS
FAST_ITERATIONS=$FAST_ITERATIONS
MODERATELY_FAST_ITERATIONS=$MODERATELY_FAST_ITERATIONS
EOF

    # Add measurement functions
    cat >> "$script_file" << 'EOF'
# Function for high-precision measurement
measure_high_precision() {
    local program=$1
    shift
    local params="$@"
    local precision_mode=$PRECISION_MODE
    local iterations=1
    
    # Set iterations based on precision mode
    case $precision_mode in
        "VERY_FAST") iterations=$VERY_FAST_ITERATIONS ;;
        "FAST") iterations=$FAST_ITERATIONS ;;
        "MODERATE") iterations=$MODERATELY_FAST_ITERATIONS ;;
        *) iterations=1 ;;
    esac
    
    local mem_kb=$(ps -o rss= -p $$)
    
    # Time the execution
    local start_time=$(date +%s.%N)
    for ((i=1; i<=iterations; i++)); do
        $program $params >/dev/null 2>&1
    done
    local end_time=$(date +%s.%N)
    
    # Calculate average time
    local real_time=$(echo "scale=9; ($end_time - $start_time) / $iterations" | bc)
    
    # Get CPU time
    local user_time=0.000
    local sys_time=0.000
    if command -v /usr/bin/time &> /dev/null; then
        local time_output=$(/usr/bin/time -f "%U %S" $program $params 2>&1 >/dev/null)
        if [[ "$time_output" =~ [0-9]+(\.[0-9]+)?[[:space:]]+[0-9]+(\.[0-9]+)? ]]; then
            user_time=$(echo "$time_output" | awk '{print $1}')
            sys_time=$(echo "$time_output" | awk '{print $2}')
        fi
    fi
    
    # Format values consistently
    if [[ "$real_time" =~ ^\.[0-9]+ ]]; then real_time="0$real_time"; fi
    if [[ "$user_time" =~ ^\.[0-9]+ ]]; then user_time="0$user_time"; fi
    if [[ "$sys_time" =~ ^\.[0-9]+ ]]; then sys_time="0$sys_time"; fi
    
    # Output results
    echo "$real_time $user_time $sys_time $mem_kb"
}

# Determine precision mode based on execution time
determine_precision_mode() {
    local program=$1
    shift
    local params="$@"
    
    local start=$(date +%s.%N)
    $program $params >/dev/null 2>&1
    local end=$(date +%s.%N)
    local duration=$(echo "$end - $start" | bc)
    
    if (( $(echo "$duration < 0.01" | bc -l) )); then
        echo "VERY_FAST"
    elif (( $(echo "$duration < 0.1" | bc -l) )); then
        echo "FAST"
    elif (( $(echo "$duration < 0.5" | bc -l) )); then
        echo "MODERATE"
    else
        echo "STANDARD"
    fi
}
EOF
    
    # Add performance measurement commands
    cat >> "$script_file" << EOF

# Perform warmup runs
if [ $WARMUP_RUNS -gt 0 ]; then
    echo "Performing $WARMUP_RUNS warmup run(s)..."
    for ((i=1; i<=$WARMUP_RUNS; i++)); do
        $program_path $params > /dev/null 2>&1
    done
fi

# Determine precision mode
PRECISION_MODE=\$(determine_precision_mode $program_path $params)
echo "PRECISION_MODE=\$PRECISION_MODE"

# Set note for output
case \$PRECISION_MODE in
    "VERY_FAST") 
        echo "PRECISION_NOTE=High precision mode ($VERY_FAST_ITERATIONS iterations per measurement)" ;;
    "FAST")
        echo "PRECISION_NOTE=High precision mode ($FAST_ITERATIONS iterations per measurement)" ;;
    "MODERATE")
        echo "PRECISION_NOTE=High precision mode ($MODERATELY_FAST_ITERATIONS iterations per measurement)" ;;
    *)
        echo "PRECISION_NOTE=Standard measurement" ;;
esac

# Measure performance
echo "Starting performance measurement..."
EOF

    cat >> "$script_file" << EOF
echo
if [ "\$PRECISION_MODE" != "STANDARD" ]; then
    measure_high_precision $program_path $params
else
    /usr/bin/time -f "%e %U %S %M" $program_path $params 2>&1
fi
echo ""
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
    local real_times=()
    local user_times=()
    local sys_times=()
    local memory_usages=()
    local precision_mode="STANDARD"
    local precision_note=""
    
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
    
    # Extract precision mode and note
    if grep -q "PRECISION_MODE=" "$output_file"; then
        precision_mode=$(grep "PRECISION_MODE=" "$output_file" | head -1 | cut -d= -f2)
        log "DEBUG" "Found precision mode: $precision_mode"
    fi
    
    if grep -q "PRECISION_NOTE=" "$output_file"; then
        precision_note=$(grep "PRECISION_NOTE=" "$output_file" | head -1 | cut -d= -f2)
        log "DEBUG" "Found precision note: $precision_note"
    fi
    
    # Extract performance metrics
    local metrics_lines=$(grep -E '([0-9]*\.?[0-9]+)[[:space:]]+([0-9]*\.?[0-9]+)[[:space:]]+([0-9]*\.?[0-9]+)[[:space:]]+([0-9]+)' "$output_file")
    
    # Parse each metrics line
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            log "DEBUG" "Processing metrics line: $line"
            
            read -r real_time user_time sys_time memory <<< "$line"
            
            # Ensure proper format
            if [[ "$real_time" =~ ^\.[0-9]+ ]]; then real_time="0$real_time"; fi
            if [[ "$user_time" =~ ^\.[0-9]+ ]]; then user_time="0$user_time"; fi
            if [[ "$sys_time" =~ ^\.[0-9]+ ]]; then sys_time="0$sys_time"; fi
            
            # Validate and add metrics
            if [[ "$real_time" =~ ^[0-9]*\.?[0-9]+$ ]] && 
               [[ "$user_time" =~ ^[0-9]*\.?[0-9]+$ ]] && 
               [[ "$sys_time" =~ ^[0-9]*\.?[0-9]+$ ]] && 
               [[ "$memory" =~ ^[0-9]+$ ]]; then
                
                real_times+=("$real_time")
                user_times+=("$user_time")
                sys_times+=("$sys_time")
                memory_usages+=("$memory")
                
                log "DEBUG" "Added metrics: Real=${real_time}s User=${user_time}s Sys=${sys_time}s Mem=${memory}KB"
            else
                log "WARNING" "Invalid metric values detected in line: '$line'"
            fi
        fi
    done <<< "$metrics_lines"
    
    # Fallback extraction if needed
    if [ ${#real_times[@]} -eq 0 ]; then
        log "DEBUG" "Using fallback extraction method"
        
        # Extract from run markers
        local inside_run=false
        local run_output=""
        
        while IFS= read -r line; do
            if [[ "$line" =~ ^Run\ [0-9]+\ of\ [0-9]+:$ ]]; then
                inside_run=true
                run_output=""
                continue
            fi
            
            if $inside_run && [[ -z "$line" || "$line" =~ ^Run\ [0-9]+\ of\ [0-9]+:$ ]]; then
                inside_run=false
                
                if [ -n "$run_output" ]; then
                    # Extract numbers
                    local all_numbers=($(echo "$run_output" | grep -o -E '[0-9]*\.?[0-9]+'))
                    
                    if [ ${#all_numbers[@]} -ge 4 ]; then
                        real_times+=("${all_numbers[0]}")
                        user_times+=("${all_numbers[1]}")
                        sys_times+=("${all_numbers[2]}")
                        memory_usages+=("${all_numbers[3]}")
                    fi
                fi
                
                if [[ "$line" =~ ^Run\ [0-9]+\ of\ [0-9]+:$ ]]; then
                    inside_run=true
                    run_output=""
                fi
            fi
            
            if $inside_run; then
                run_output="$run_output $line"
            fi
        done < "$output_file"
    fi
    # Return results as a single string
    echo "${real_times[*]}|${user_times[*]}|${sys_times[*]}|${memory_usages[*]}|$precision_mode|$precision_note"
}

# Process metrics
process_cluster_metrics() {
    local metrics_str=$1
    
    # Split metrics into separate arrays
    IFS='|' read -ra metrics_parts <<< "$metrics_str"
    
    local real_times=${metrics_parts[0]}
    local user_times=${metrics_parts[1]}
    local sys_times=${metrics_parts[2]}
    local memory_values=${metrics_parts[3]}
    local precision_mode=${metrics_parts[4]}
    local precision_note=${metrics_parts[5]}
    
    # Calculate statistics
    local real_stats=$(calculate_statistics "$real_times")
    local user_stats=$(calculate_statistics "$user_times")
    local sys_stats=$(calculate_statistics "$sys_times")
    local mem_stats=$(calculate_statistics "$memory_values")
    
    # Extract statistics
    local avg_real=$(echo "$real_stats" | awk '{print $1}')
    local stddev_real=$(echo "$real_stats" | awk '{print $2}')
    local min_real=$(echo "$real_stats" | awk '{print $3}')
    local max_real=$(echo "$real_stats" | awk '{print $4}')
    local variance_real=$(echo "$real_stats" | awk '{print $5}')
    
    local avg_user=$(echo "$user_stats" | awk '{print $1}')
    local avg_sys=$(echo "$sys_stats" | awk '{print $1}')
    local avg_mem=$(echo "$mem_stats" | awk '{print $1}')
    
    # Format values
    local formatted_real=$(format_time "$avg_real")
    local formatted_user=$(format_time "$avg_user")
    local formatted_sys=$(format_time "$avg_sys")
    local formatted_stddev=$(format_time "$stddev_real")
    local formatted_min=$(format_time "$min_real")
    local formatted_max=$(format_time "$max_real")
    local formatted_variance=$(format_time "$variance_real")
    
    # Create notes string
    local notes=""
    if [ -n "$precision_note" ]; then
        notes="$precision_note"
    else
        case "$precision_mode" in
            "VERY_FAST") notes="High precision mode ($VERY_FAST_ITERATIONS iterations per measurement)" ;;
            "FAST") notes="High precision mode ($FAST_ITERATIONS iterations per measurement)" ;;
            "MODERATE") notes="High precision mode ($MODERATELY_FAST_ITERATIONS iterations per measurement)" ;;
            *) notes="Standard measurement" ;;
        esac
    fi
    
    # Add cluster execution marker
    notes="$notes, Cluster execution"
    
    # Add cache clearing note if enabled
    if [ "$CACHE_CLEARING_ENABLED" = "true" ]; then
        notes="$notes, Cache cleared"
    fi
    
    # Return formatted metrics
    echo "$formatted_real $formatted_user $formatted_sys $avg_mem $formatted_stddev $formatted_min $formatted_max $formatted_variance $notes"
}

# Execute performance test on the cluster
run_on_cluster() {
    local program_path=$1
    local params=$2
    local program_name=$(basename "$program_path")
    
    log "INFO" "Running on cluster using SLURM..."
    
    # Create a unique job name with timestamp
    local job_name="${JOB_NAME_PREFIX}_${program_name}_$(date +%s)"
    
    # Create job script
    local job_script=$(create_job_script "$program_path" "$params" "$job_name")
    local output_file="${job_name}_output.log"
    
    # Submit job
    for ((i=1; i<=REPETITIONS; i++)); do
        local job_id=$(submit_job "$job_script")
        # Wait for job to complete
        if ! wait_for_job "$job_id"; then
            log "ERROR" "Job $job_id was cancelled due to timeout."
            return 1
        fi
    done
    
    if [ -z "$job_id" ]; then
        log "ERROR" "Failed to submit job. Skipping this parameter set."
        return 1
    fi
    
    
    # Parse job output
    local raw_metrics=$(parse_job_output "$output_file")
    
    if [ -z "$raw_metrics" ]; then
        log "ERROR" "Failed to parse job output. Skipping this parameter set."
        return 1
    fi
    
    # Process metrics and return formatted results
    local metrics=$(process_cluster_metrics "$raw_metrics")
    
    # Clean up job files if enabled
    if [ "$CLEANUP_JOB_FILES" = "true" ]; then
        log "DEBUG" "Cleaning up job files: $job_script $output_file"
        rm -f "$job_script" "$output_file"
    fi
    
    echo "$metrics"
}

# Export functions and variables for use in the main script
export -f create_job_script submit_job wait_for_job parse_job_output process_cluster_metrics run_on_cluster
export RUN_ON_CLUSTER CLUSTER_PARTITION CLUSTER_NTASKS CLUSTER_EXCLUSIVE JOB_NAME_PREFIX MAX_WAIT_TIME
export CLEANUP_JOB_FILES