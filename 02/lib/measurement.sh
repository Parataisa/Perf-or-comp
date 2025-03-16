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
            
            # Simulate workload with error handling
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
            # Direct execution with error handling
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
            # Calculate confidence interval for real time
            local real_stats=$(calculate_statistics "${real_times[*]}")
            local mean=$(echo "$real_stats" | awk '{print $1}')
            local stddev=$(echo "$real_stats" | awk '{print $2}')
            
            # t-statistic for 95% confidence with n-1 degrees of freedom
            local t_value=0
            case $run in
                2) t_value=4.303;; # 3 samples
                3) t_value=3.182;; # 4 samples
                4) t_value=2.776;; # 5 samples
                5) t_value=2.571;; # 6 samples
                6) t_value=2.447;; # 7 samples
                7) t_value=2.365;; # 8 samples
                8) t_value=2.306;; # 9 samples
                9) t_value=2.262;; # 10 samples
                *) t_value=1.96;;  # large sample approximation
            esac
            
            # Calculate confidence interval half-width
            local half_width=$(echo "scale=9; $t_value * $stddev / sqrt($run + 1)" | bc -l)
            
            # Calculate relative precision
            local rel_precision=1.0
            if [ $(echo "$mean > 0" | bc -l) -eq 1 ]; then
                rel_precision=$(echo "scale=9; $half_width / $mean" | bc -l)
            fi
            
            log "INFO" "Current relative precision: $rel_precision (target: $TARGET_PRECISION)"
            
            # Check if we've reached target precision
            if [ $(echo "$rel_precision <= $TARGET_PRECISION" | bc -l) -eq 1 ]; then
                confidence_reached=true
                confidence_note="Confidence interval reached after $((run+1)) repetitions"
                log "INFO" "$confidence_note"
            fi
        fi
        
        # Increment run counter
        run=$((run+1))
        
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