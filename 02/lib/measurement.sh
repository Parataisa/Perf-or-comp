#!/bin/bash

#=====================================================================
# Timing Measurement Functions
#=====================================================================

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
        log "DEBUG" "Standard program detected ($duration s). Using standard measurement."
    fi
    log "INFO" "Using $iterations iterations for measurement"
    
    # Arrays to store measurements
    declare -a real_times
    declare -a user_times
    declare -a sys_times
    declare -a memory_values

    local run=0
    local confidence_reached=false
    local confidence_note=""
    
    # Perform measurements
    while [ $run -lt $MAX_REPETITIONS ] && ! $confidence_reached; do
        log "INFO" "Run $((run+1)) of maximum $MAX_REPETITIONS"

        trap 'log "WARNING" "Measurement interrupted"; rm -f "$temp_file"; return 1' INT TERM
        
        local temp_file=$(mktemp)
        if $sim_workload; then
            # Check if loadgen script exists
            loadgen_script="$(pwd)/load_generator/exec_with_workstation_heavy.sh"
            chmod +x "$loadgen_script"
            if [ ! -x "$loadgen_script" ]; then
                log "ERROR" "Load generator script not found or not executable: $loadgen_script"
                rm -f "$temp_file"
                return 1
            fi
            
            # Simulate workload
            if ! /usr/bin/time -f "%e,%U,%S,%M" bash -c "for ((i=0; i<$iterations; i++)); do 
                \"$loadgen_script\" \"$program_path\" $params > /dev/null 2>&1 
                exit_code=\$?
                if [ \$exit_code -ne 0 ]; then
                    echo \"Program failed with exit code \$exit_code on iteration \$i\" >&2
                    continue
                fi
                done" 2> "$temp_file"; then
                log "WARNING" "Workload simulation failed for run $((run+1))"
                # Check if we got any metrics
                if ! grep -q "[0-9]" "$temp_file"; then
                    echo "0.0,0.0,0.0,0" > "$temp_file"
                fi
            fi
            log "DEBUG" "Raw metrics: $(cat "$temp_file")"
        else
            # Direct execution
            if ! /usr/bin/time -f "%e,%U,%S,%M" bash -c "for ((i=0; i<$iterations; i++)); do \"$program_path\" $params > /dev/null 2>&1; done" 2> "$temp_file"; then
                log "WARNING" "Program execution failed for run $((run+1))"
                echo "0.0,0.0,0.0,0" > "$temp_file"
            fi
        fi
        
        trap - INT TERM

        local loop_metrics=$(cat "$temp_file")
        rm "$temp_file"

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
            
        log "INFO" "Real time: ${real_times[$run]}s | User: ${user_times[$run]}s | Sys: ${sys_times[$run]}s | Mem: ${memory_values[$run]}KB"
        
        if [ $run -ge $((MIN_REPETITIONS-1)) ]; then
            local conf_result=$(calculate_confidence "${real_times[*]}" "$TARGET_PRECISION")
            local mean=$(echo "$conf_result" | cut -d' ' -f1)
            local stddev=$(echo "$conf_result" | cut -d' ' -f2)
            local rel_precision=$(echo "$conf_result" | cut -d' ' -f3)
            local conf_reached=$(echo "$conf_result" | cut -d' ' -f4)
            
            log "INFO" "After $((run+1)) runs: Mean=$mean, StdDev=$stddev, Precision=$rel_precision"
            
            if [ "$conf_reached" = "true" ]; then
                confidence_reached=true
                confidence_note="Target precision of $TARGET_PRECISION reached after $((run+1)) runs"
                log "INFO" "$confidence_note"
            fi
        fi
        
        run=$((run+1))
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
    
    local mean=$(echo "$values" | awk '{ sum = 0; for (i = 1; i <= NF; i++) sum += $i; print sum / NF }')
    local stddev=$(echo "$values" | awk -v mean="$mean" '{
        sum_sq_diff = 0;
        for (i = 1; i <= NF; i++) {
            diff = $i - mean;
            sum_sq_diff += diff * diff;
        }
        print sqrt(sum_sq_diff / (NF - 1));
    }')
    
    # Approximate confidence interval half-width as 2*stddev/sqrt(n)
    local half_width=$(echo "scale=9; 2 * $stddev / sqrt($count)" | bc -l)
    
    # Calculate relative precision
    local rel_precision=1.0
    if (( $(echo "$mean > 0" | bc -l) )); then
        rel_precision=$(echo "scale=9; $half_width / $mean" | bc -l)
    fi
    
    local confidence_reached=false
    if (( $(echo "$rel_precision <= $target_precision" | bc -l) )); then
        confidence_reached=true
    fi
    
    echo "$mean $stddev $rel_precision $confidence_reached"
}