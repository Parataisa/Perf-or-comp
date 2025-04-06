#!/bin/bash
# Functions for parsing and processing job outputs

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
    
    # Read the file content
    local file_content=$(cat "$output_file")
    
    # Extract the measurement result line
    local result_line=$(echo "$file_content" | grep -E "^[0-9]+\.[0-9]+" | tail -1)
    
    if [ -z "$result_line" ]; then
        log "ERROR" "Could not find a valid measurement result in the output file"
        return 1
    fi
    
    log "DEBUG" "Found measurement result: $result_line"
    
    # Extract the measurements from the result line
    local avg_real=$(echo "$result_line" | awk '{print $1}')
    local stddev_real=$(echo "$result_line" | awk '{print $2}')
    local min_real=$(echo "$result_line" | awk '{print $3}')
    local max_real=$(echo "$result_line" | awk '{print $4}')
    local variance_real=$(echo "$result_line" | awk '{print $5}')
    
    # Find the last timing line to extract CPU and memory info
    local last_timing=$(echo "$file_content" | grep -E "Real time:.*\| User:.*\| Sys:.*\| Mem:" | tail -1)
    local user_time="0.000000000"
    local sys_time="0.000000000"
    local avg_mem="0"
    
    if [ -n "$last_timing" ]; then
        user_time=$(echo "$last_timing" | sed -n 's/.*User: \([0-9.]*\)s.*/\1/p')
        if [ -z "$user_time" ]; then
            user_time=$(echo "$last_timing" | sed -n 's/.*User: \([0-9.]*\).*/\1/p')
        fi
        sys_time=$(echo "$last_timing" | sed -n 's/.*Sys: \([0-9.]*\)s.*/\1/p')
        if [ -z "$sys_time" ]; then
            sys_time=$(echo "$last_timing" | sed -n 's/.*Sys: \([0-9.]*\).*/\1/p')
        fi
        avg_mem=$(echo "$last_timing" | sed -n 's/.*Mem: \([0-9]*\)KB.*/\1/p')
        if [ -z "$avg_mem" ]; then
            avg_mem=$(echo "$last_timing" | sed -n 's/.*Mem: \([0-9]*\).*/\1/p')
        fi
        
        # Set defaults if still empty
        [ -z "$user_time" ] && user_time="0.000000000"
        [ -z "$sys_time" ] && sys_time="0.000000000"
        [ -z "$avg_mem" ] && avg_mem="0"
    fi
    
    log "DEBUG" "Extracted values - User: $user_time, Sys: $sys_time, Mem: $avg_mem"
    
    local notes=""
    if echo "$result_line" | grep -q "High precision mode"; then
        notes=$(echo "$result_line" | sed -n 's/.*\(High precision mode.*\)/\1/p')
    elif echo "$result_line" | grep -q "Target precision of"; then
        notes=$(echo "$result_line" | sed -n 's/.*\(Target precision of.*\)/\1/p')
    elif echo "$result_line" | grep -q "Max repetitions"; then
        notes=$(echo "$result_line" | sed -n 's/.*\(Max repetitions.*\)/\1/p')
    fi
    
    if [ -z "$notes" ] && grep -q "High precision mode" "$output_file"; then
        local high_precision=$(grep "High precision mode" "$output_file" | head -1)
        notes="$high_precision"
    fi
    if [ -z "$notes" ] && grep -q "Target precision of" "$output_file"; then
        if [ -n "$notes" ]; then
            notes="$notes, $(grep "Target precision of" "$output_file" | tail -1)"
        else
            notes="$(grep "Target precision of" "$output_file" | tail -1)"
        fi
    elif [ -z "$notes" ] && grep -q "Max repetitions" "$output_file"; then
        if [ -n "$notes" ]; then
            notes="$notes, $(grep "Max repetitions" "$output_file" | tail -1)"
        else
            notes="$(grep "Max repetitions" "$output_file" | tail -1)"
        fi
    fi
    if grep -q "Using simulated workload" "$output_file"; then
        notes="$notes, Simulated workload"
    fi
    if [ -n "$notes" ]; then
        notes="$notes, Cluster execution"
    fi
    
    notes=$(echo "$notes" | sed 's/  */ /g' | sed 's/, ,/,/g')
    
    log "DEBUG" "Extracted notes: $notes"
    
    local result="$avg_real $user_time $sys_time $avg_mem $stddev_real $min_real $max_real $variance_real $notes"
    
    log "DEBUG" "Final parsed result: $result"
    echo "$result"
}

export -f parse_job_output