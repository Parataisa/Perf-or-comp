#!/bin/bash

#=====================================================================
# Timing Measurement Functions
#=====================================================================

# Function to measure CPU times with highest possible precision
measure_cpu_time() {
    local program_path=$1
    local params=$2
    local iterations=$3
    
    # Create a temporary script for the loop
    local temp_script=$(mktemp)
    echo '#!/bin/bash' > "$temp_script"
    echo "for ((i=0; i<$iterations; i++)); do" >> "$temp_script"
    echo "  \"$program_path\" $params > /dev/null 2>&1" >> "$temp_script"
    echo "done" >> "$temp_script"
    chmod +x "$temp_script"
    
    # Check if valgrind is available
    if command -v valgrind &> /dev/null && $USE_VALGRIND; then
        log "DEBUG" "Valgrind available, using for instrumented profiling"
        
        # Run a single execution with valgrind for memory profiling
        local valgrind_output=$(mktemp)
        valgrind --tool=memcheck --leak-check=no --log-file="$valgrind_output" \
                 "$program_path" $params > /dev/null 2>&1
                 
        # Extract memory info if available
        local valgrind_mem=$(grep "total heap usage" "$valgrind_output" | awk '{print $9}' | sed 's/,//')
        log "DEBUG" "Valgrind heap usage: $valgrind_mem KB"
        
        # For CPU time, use time command on multiple iterations
        local temp_file=$(mktemp)
        /usr/bin/time -f "%e,%U,%S,%M" "$temp_script" > /dev/null 2> "$temp_file"
        local loop_metrics=$(cat "$temp_file")
        
        # Extract and normalize metrics
        local real_total=$(echo "$loop_metrics" | cut -d, -f1)
        local user_total=$(echo "$loop_metrics" | cut -d, -f2)
        local sys_total=$(echo "$loop_metrics" | cut -d, -f3)
        
        log "DEBUG" "Raw timing: real=$real_total, user=$user_total, sys=$sys_total, iterations=$iterations"
        
        # Calculate average per iteration
        local user_time=$(echo "scale=9; $user_total / $iterations" | bc -l)
        local sys_time=$(echo "scale=9; $sys_total / $iterations" | bc -l)
        
        # Cleanup temp files
        rm "$valgrind_output" "$temp_file"
    else
        log "DEBUG" "Using /usr/bin/time"

        # Create a temporary file for time output
        local temp_file=$(mktemp)
        
        /usr/bin/time -f "%e,%U,%S,%M" "$temp_script" > /dev/null 2> "$temp_file"
        local loop_metrics=$(cat "$temp_file")
        rm "$temp_file"
        
        # Extract and normalize metrics
        local real_total=$(echo "$loop_metrics" | cut -d, -f1)
        local user_total=$(echo "$loop_metrics" | cut -d, -f2)
        local sys_total=$(echo "$loop_metrics" | cut -d, -f3)
        
        log "DEBUG" "Raw timing: real=$real_total, user=$user_total, sys=$sys_total"
        
        # Calculate average per iteration
        local user_time=$(echo "scale=9; $user_total / $iterations" | bc -l)
        local sys_time=$(echo "scale=9; $sys_total / $iterations" | bc -l)
    fi
    
    # Ensure we have minimal values if the result is zero
    if (( $(echo "$user_time < 0.000000001" | bc -l) )); then
        user_time="0.000000001"
    fi
    if (( $(echo "$sys_time < 0.000000001" | bc -l) )); then
        sys_time="0.000000001"
    fi
    
    # Remove temp script
    rm "$temp_script"
    
    echo "$user_time $sys_time"
}

# Helper function to capture a single time measurement run
measure_single_run() {
    local program_path=$1
    local params=$2
    
    # Create a temporary file for time output
    local temp_file=$(mktemp)
    if ! $USE_VALGRIND; then
        /usr/bin/time -f "%e,%U,%S,%M" $program_path $params > /dev/null 2> "$temp_file"
    else
        valgrind --tool=memcheck --leak-check=no --log-file="$temp_file" \
                 $program_path $params > /dev/null 2>&1
    fi
    local output=$(cat "$temp_file")
    rm "$temp_file"
    
    echo "$output"
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
    
    local is_fast=false
    local iterations=1
    local high_precision_note=""
    
    # Determine if we need high precision mode
    if (( $(echo "$duration < 0.01" | bc -l) )); then
        is_fast=true
        iterations=$VERY_FAST_ITERATIONS  # Very fast program (<10ms)
        high_precision_note="High precision mode ($iterations iterations per measurement)"
    elif (( $(echo "$duration < 0.1" | bc -l) )); then
        is_fast=true
        iterations=$FAST_ITERATIONS  # Fast program (<100ms but >=10ms)
        high_precision_note="High precision mode ($iterations iterations per measurement)"
    elif (( $(echo "$duration < 0.5" | bc -l) )); then
        is_fast=true
        iterations=$MODERATELY_FAST_ITERATIONS  # Moderately fast program (<500ms but >=100ms)
        high_precision_note="High precision mode ($iterations iterations per measurement)"
    else
        log "DEBUG" "Standard program detected ($duration s). Using standard measurement."
    fi
    
    # Arrays to store measurements
    declare -a real_times
    declare -a user_times
    declare -a sys_times
    declare -a memory_values
    
    # Perform measurements
    for ((run=0; run<REPETITIONS; run++)); do
        log "DEBUG" "Run $((run+1)) of $REPETITIONS"
        
        if $is_fast; then
            # HIGH PRECISION MODE
            
            # First get single run metrics for CPU and memory
            local single_metrics=$(measure_single_run "$program_path" "$params")
            local real_single=$(echo "$single_metrics" | cut -d, -f1)
            local user_single=$(echo "$single_metrics" | cut -d, -f2)
            local sys_single=$(echo "$single_metrics" | cut -d, -f3)
            local memory=$(echo "$single_metrics" | cut -d, -f4)
            
            # Measure multiple iterations for more precise real time
            local loop_start=$(date +%s.%N)
            for ((i=0; i<iterations; i++)); do
                $program_path $params > /dev/null 2>&1
            done
            local loop_end=$(date +%s.%N)
            
            # Calculate average time per iteration
            local total_real=$(echo "$loop_end - $loop_start" | bc -l)
            local real_time=$(echo "scale=9; $total_real / $iterations" | bc -l)
            
            # Measure CPU time for multiple iterations
            local cpu_times=$(measure_cpu_time "$program_path" "$params" "$iterations")
            local user_time=$(echo "$cpu_times" | awk '{print $1}')
            local sys_time=$(echo "$cpu_times" | awk '{print $2}')
            
            # Store measurements
            real_times[$run]=$real_time
            user_times[$run]=$user_time
            sys_times[$run]=$sys_time
            memory_values[$run]=$memory
            
        else
            # STANDARD MODE - Direct measurement
            local metrics=$(measure_single_run "$program_path" "$params")
            
            # Parse metrics
            local real_time=$(echo "$metrics" | cut -d, -f1)
            local user_time=$(echo "$metrics" | cut -d, -f2)
            local sys_time=$(echo "$metrics" | cut -d, -f3)
            local memory=$(echo "$metrics" | cut -d, -f4)
            
            # Store measurements
            real_times[$run]=$real_time
            user_times[$run]=$user_time
            sys_times[$run]=$sys_time
            memory_values[$run]=$memory
        fi
        
        log "INFO" "Real time: ${real_times[$run]}s | User: ${user_times[$run]}s | Sys: ${sys_times[$run]}s | Mem: ${memory_values[$run]}KB"
        
        # Clear caches and pause between runs
        clear_caches
        sleep $PAUSE_SECONDS
    done
    
    # Create the raw data for this run
    local real_times_str=$(printf "'%s' " "${real_times[@]}")
    local user_times_str=$(printf "'%s' " "${user_times[@]}")
    local sys_times_str=$(printf "'%s' " "${sys_times[@]}")
    local memory_values_str=$(printf "'%s' " "${memory_values[@]}")
    
    # Calculate statistics
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
    local variance_user=$(echo "$user_stats" | awk '{print $5}')
    
    local avg_sys=$(echo "$sys_stats" | awk '{print $1}')
    local stddev_sys=$(echo "$sys_stats" | awk '{print $2}')
    local variance_sys=$(echo "$sys_stats" | awk '{print $5}')
    
    local avg_mem=$(echo "$mem_stats" | awk '{print $1}')
    local stddev_mem=$(echo "$mem_stats" | awk '{print $2}')
    local variance_mem=$(echo "$mem_stats" | awk '{print $5}')
    
    # Format values for output
    local formatted_real=$(format_time "$avg_real")
    local formatted_user=$(format_time "$avg_user")
    local formatted_sys=$(format_time "$avg_sys")
    local formatted_stddev=$(format_time "$stddev_real")
    local formatted_min=$(format_time "$min_real")
    local formatted_max=$(format_time "$max_real")
    local formatted_variance=$(format_time "$variance_real")
    
    local result="$formatted_real $formatted_user $formatted_sys $avg_mem $formatted_stddev $formatted_min $formatted_max $formatted_variance $high_precision_note"
    
    echo "$result"
}