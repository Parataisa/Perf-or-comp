#!/bin/bash

#=====================================================================
# Main Test Functions
#=====================================================================

# Run tests for a specific program with given parameters
run_tests() {
    local program_path=$1
    local description=$2
    local depends=$3
    local sim_cpu_load=$4
    local sim_io_load=$5
    shift 5
    local parameter_sets=("$@")

    log "DEBUG" "Simulated CPU load: $sim_cpu_load"
    log "DEBUG" "Simulated I/O load: $sim_io_load"

    local program_name=$(basename "$program_path")
    # Clean up parameter sets (remove trailing pipes)
    for i in "${!parameter_sets[@]}"; do
        parameter_sets[$i]="${parameter_sets[$i]%|}"
    done

    log "INFO" "===== Testing $program_name ====="

    local dependency_note=""
    [ "$depends" != "none" ] && dependency_note="Depends on: $depends"

    # If no parameters, run once with no parameters
    if [ ${#parameter_sets[@]} -eq 0 ] || [[ -z "${parameter_sets[*]// }" ]]; then
        parameter_sets=("")
    fi

    local io_load_active=false
    local io_load_pid=""
    local io_load_dir=""
    
    # Start I/O load if needed
    if $sim_io_load; then
        log "INFO" "Starting I/O load generator for tests..."
        mkdir -p "$IO_LOAD_DIR"
        log "DEBUG" "I/O load directory: $IO_LOAD_DIR"
        log "DEBUG" "I/O load parameters: threads=$IO_THREADS, read_percent=$READ_PERCENT, delay=$DELAY_MS, min_size=$MIN_FILE_SIZE, max_size=$MAX_FILE_SIZE, duration=$RUN_DURATION"
        
        # Start the I/O load generator in background the 
        ./build/loadgen_io $IO_THREADS $READ_PERCENT $DELAY_MS $MIN_FILE_SIZE $MAX_FILE_SIZE $RUN_DURATION "$IO_LOAD_DIR" &
        io_load_pid=$!
        
        if [ -n "$io_load_pid" ] && kill -0 $io_load_pid 2>/dev/null; then
            io_load_active=true
            log "INFO" "I/O load generator started with PID: $io_load_pid"
            sleep 1  # Wait for I/O load to stabilize
        else
            log "WARNING" "Failed to start I/O load generator"
        fi
    fi

    for params in "${parameter_sets[@]}"; do
        log "INFO" "--------------------------------------------------"
        log "INFO" "Running with parameters: $params"
        log "INFO" "--------------------------------------------------"

        local metrics
        if $RUN_ON_CLUSTER; then
            if ! type run_on_cluster > /dev/null 2>&1; then
                log "ERROR" "Cluster functions not loaded. Cannot run on cluster."
                continue
            fi
            local dep_program dep_args
            if [ "$depends" != "none" ] && [ -n "$depends" ]; then
                read -r dep_program dep_args <<< "$depends"
                log "DEBUG" "Dependency split: program='$dep_program', args='$dep_args'"
            else
                dep_program=""
                dep_args=""
            fi
            metrics=$(run_on_cluster "$program_path" "$params" "$dep_program" "$dep_args" "$sim_cpu_load" "$sim_io_load")
        else
            [ $WARMUP_RUNS -gt 0 ] && log "DEBUG" "Performing $WARMUP_RUNS warmup run(s)..."
            for ((i = 1; i <= WARMUP_RUNS; i++)); do
                $program_path $params > /dev/null 2>&1
            done
            metrics=$(measure_program "$program_path" "$params" "$sim_cpu_load" "$sim_io_load")
        fi

        if [ -z "$metrics" ]; then
            log "ERROR" "Failed to get metrics. Skipping."
            continue
        fi

        # Parse and compute statistics
        read -r avg_real avg_user avg_sys avg_mem stddev_real min_real max_real variance_real notes <<< "$metrics"
        [ $CACHE_CLEARING_ENABLED ] && notes="${notes:+$notes, }Cache cleared"
        [ -n "$dependency_note" ] && notes="${notes:+$notes, }$dependency_note"
        [ "$io_load_active" = true ] && notes="${notes:+$notes, }With I/O load"

        # Log and save results
        printf "| \`%s\` | %s | %s | %s | %.0f | %s | %s | %s | %s | %s |\n" \
            "$params" "$avg_real" "$avg_user" "$avg_sys" "$avg_mem" \
            "$stddev_real" "$min_real" "$max_real" "$variance_real" "$notes" >> $OUTPUT_FILE

        append_to_csv "$program_name" "$description" "$params" "$avg_real" "$avg_user" \
            "$avg_sys" "$avg_mem" "$stddev_real" "$min_real" "$max_real" "$variance_real" "$notes"
    done

    # Clean up I/O load generator if it was started
    if [ "$io_load_active" = true ] && [ -n "$io_load_pid" ]; then
        log "INFO" "Stopping I/O load generator (PID: $io_load_pid)"
        kill $io_load_pid 2>/dev/null
        wait $io_load_pid 2>/dev/null
        
        if [ -d "$io_load_dir" ]; then
            log "DEBUG" "Removing I/O load directory: $io_load_dir"
            rm -rf "$io_load_dir"
        fi
    fi
}

# Process each program defined in the config file with options
process_config() {
    local config_file=$1
    
    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        log "WARNING" "Config file $config_file not found."
        create_sample_config "$config_file"
        exit 1
    fi
    
    # Initialize report and CSV file
    initialize_report
    initialize_csv_file
    
    # Process each program defined in the config file
    log "INFO" "Processing programs from config file..."
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        log "DEBUG" "Processing config line: $line"
        
        # Parse the configuration
        local config_data=$(parse_config_options "$line")
        IFS='|' read -r program description depends collect_metrics cleanup build build_dir build_command sim_cpu_load sim_io_load params_str <<< "$config_data"
        
        # Trim whitespace
        program=$(echo "$program" | xargs)
        description=$(echo "$description" | xargs)
        
        # Skip if program name is empty
        if [ -z "$program" ]; then
            log "WARNING" "Skipping invalid config line: $line"
            continue
        fi

        log "INFO" "Processing program: $program"
        log "DEBUG" "Description: $description"
        log "DEBUG" "Depends on: $depends"
        log "DEBUG" "Collect metrics: $collect_metrics"
        log "DEBUG" "Cleanup action: $cleanup"
        log "DEBUG" "Build program: $build"
        log "DEBUG" "Build directory: $build_dir"
        log "DEBUG" "Build command: $build_command"
        log "DEBUG" "Parameters: $params_str"
        log "DEBUG" "Simulated workload: $sim_cpu_load"
        log "DEBUG" "Simulated I/O load: $sim_io_load"
        
        # build the program based on test configuration
        local program_path
        if [ "$build" = "true" ]; then
            program_path=$(build_program "$program" "$build_command" "$build_dir")
        else 
            program_path="./build/$program"
        fi

        log "DEBUG" "Program path: $program_path"

        # Determine program path 
        if [ ! -f $program_path ]; then
            log "WARNING" "Program not found: $program"
            continue
        fi

        # Run dependency if specified
        if [ "$depends" != "none" ]; then
            if ! run_dependency "$depends"; then
                log "ERROR" "Failed to run dependency for $program. Skipping."
                continue
            fi
        fi
        
        declare -a param_array
        if [ -n "$params_str" ]; then
            # Split by pipe character to get each parameter set
            IFS='|' read -ra param_array <<< "$params_str"
            log "DEBUG" "Parsed parameters: $(printf "'%s' " "${param_array[@]}")"
        fi
                
        # Only add to report and collect metrics if specified
        if [ "$collect_metrics" = "true" ]; then
            add_justification "$program" "$description" "$(echo "${params_str[@]}")"
            add_program_section "$program" "$description"

            if [ ${#param_array[@]} -le 1 ]; then
                log "DEBUG" "Single parameter set: ${param_array[0]:-}"
                run_tests "$program_path" "$description" "$depends" "$sim_cpu_load" "$sim_io_load" "${param_array[0]}"
            else
                log "DEBUG" "Multiple parameter sets: ${#param_array[@]}"
                for param_set in "${param_array[@]}"; do
                    log "DEBUG" "Running with parameters: $param_set"
                    run_tests "$program_path" "$description" "$depends" "$sim_cpu_load" "$sim_io_load" "$param_set"
                done
            fi
        else
            # Just run the program without metrics collection
            log "INFO" "Running $program without metrics collection"
            
            for params in "${param_array[@]}"; do
                log "INFO" "Executing: $program_path $params"
                $program_path $params
                
                local status=$?
                if [ $status -ne 0 ]; then
                    log "WARNING" "Program execution returned status: $status"
                fi
            done
        fi
        
        # Perform cleanup if specified
        if [ "$cleanup" != "none" ]; then
            run_cleanup "$cleanup"
        fi
        log "INFO" "Finished processing $program"
        
    done < "$config_file"
}