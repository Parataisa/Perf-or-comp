#!/bin/bash

# Compiler Flag Analysis

# Key flags that change between -O2 and -O3
O3_FLAGS=(
    "-fgcse-after-reload"
    "-fipa-cp-clone"
    "-floop-interchange"
    "-floop-unroll-and-jam"
    "-fpeel-loops"
    "-fpredictive-commoning"
    "-fsplit-loops"
    "-fsplit-paths"
    "-ftree-loop-distribution"
    "-ftree-partial-pre"
    "-funswitch-loops"
    "-fvect-cost-model=dynamic"
    "-fversion-loops-for-strides"
)

# Build program with given flags
build_with_flags() {
    local program_path=$1     
    local build_dir=$2        
    local build_command=$3    
    local flags=$4            
    
    # Extract program name and directory
    local program_name=$(basename "$program_path")
    local program_dir=$(dirname "$program_path")
    
    log "DEBUG" "Program path: $program_path"
    log "DEBUG" "Program name: $program_name"
    log "DEBUG" "Program dir: $program_dir"
    log "INFO" "Building with flags: $flags"
    
    # Check if this is a CMake project
    if [[ "$build_command" == *"cmake"* ]]; then
        log "INFO" "CMake project detected"
        
        local flag_safe=${flags//[^a-zA-Z0-9]/_}
        local unique_dir="${build_dir}_${flag_safe}"
        
        log "INFO" "Creating build directory: $unique_dir"
        mkdir -p "$unique_dir"
        
        local new_build_cmd="$build_command"
        if [[ "$build_command" == *"CMAKE_C_FLAGS"* ]]; then
            new_build_cmd=$(echo "$build_command" | sed "s|-DCMAKE_C_FLAGS=\"[^\"]*\"|-DCMAKE_C_FLAGS=\"$flags\"|")
        else
            new_build_cmd="$build_command -DCMAKE_C_FLAGS=\"$flags\""
        fi
        
        log "DEBUG" "Modified build command: $new_build_cmd"
        
        # Execute the build
        pushd "$unique_dir" > /dev/null
        log "INFO" "Building in directory: $(pwd)"
        eval "$new_build_cmd" >/dev/null 2>&1
        local build_status=$?
        popd > /dev/null
        
        if [ $build_status -ne 0 ]; then
            log "ERROR" "CMake build failed with status: $build_status"
            return 1
        fi
        
        local executable_path=""
        if [ -f "$unique_dir/$program_name" ]; then
            executable_path="$unique_dir/$program_name"
        else
            executable_path=$(find "$unique_dir" -type f -executable -name "$program_name" 2>/dev/null | head -1)
        fi
        
        if [ -z "$executable_path" ] || [ ! -f "$executable_path" ]; then
            log "ERROR" "Could not find built executable in $unique_dir"
            return 1
        fi
        
        log "INFO" "Built executable: $executable_path"
        echo "$executable_path"
    else
        local source_file=""
        local flag_safe=$(echo "$flags" | tr ' ' '_' | tr -d '-')
        local output_name="${program_name}_${flag_safe}"
        
        if [ -z "$build_dir" ]; then
            build_dir="build"
        fi
        mkdir -p "$build_dir"
        
        if [[ "$program_path" == *.c ]]; then
            source_file="$program_path"
        else
            source_file=$(find . -name "${program_name}.c" | head -1)
        fi
        
        if [ -z "$source_file" ] || [ ! -f "$source_file" ]; then
            log "ERROR" "Could not find source file for $program_name"
            return 1
        fi
        
        log "INFO" "Found source file: $source_file"
        
        local output_path="$build_dir/$output_name"
        log "INFO" "Building with GCC: $flags -o $output_path $source_file"
        gcc $flags -o "$output_path" "$source_file" -lm >/dev/null 2>&1
        
        if [ ! -f "$output_path" ]; then
            log "ERROR" "GCC build failed"
            return 1
        fi
        
        log "INFO" "Built executable: $output_path"
        echo "$output_path"
    fi
}

measure_execution() {
    local program_path=$1
    local program_params=$2
    local runs=$MIN_REPETITIONS
    
    if [ ! -x "$program_path" ]; then
        log "ERROR" "Program not found or not executable: $program_path"
        return 1
    fi
    
    log "INFO" "Measuring performance of $program_path with params: $program_params"
    
    local total_time=0
    
    for ((i=1; i<=runs; i++)); do
        log "DEBUG" "Measurement run $i"
        local start_time=$(date +%s.%N)
        "$program_path" $program_params >/dev/null 2>&1
        local end_time=$(date +%s.%N)
        local run_time=$(echo "$end_time - $start_time" | bc -l)
        
        total_time=$(echo "$total_time + $run_time" | bc -l)
    done
    
    local avg_time=$(echo "scale=6; $total_time / $runs" | bc -l)
    log "INFO" "Average execution time: $avg_time seconds"
    
    echo "$avg_time"
}

# Run compiler flag analysis on programs in config file
analyze_compiler_flags() {
    local config_file=$1
    
    # Create results directory
    mkdir -p "compiler_results"
    local results_file="compiler_results/flag_analysis.csv"
    echo "Program,Flag,O2 Time (s),Flag Time (s),Improvement (%)" > "$results_file"
    
    # Track flag frequency
    declare -A flag_count
    for flag in "${O3_FLAGS[@]}"; do
        flag_count["$flag"]=0
    done
    
    log "INFO" "Starting compiler flag analysis..."
    
    # Process each program in config file
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        
        # Parse the configuration
        local config_data=$(parse_config_options "$line")
        IFS='|' read -r program description depends collect_metrics cleanup build build_dir build_command sim_cpu_load sim_io_load params_str <<< "$config_data"
        
        if [ -z "$program" ] || [ "$collect_metrics" != "true" ]; then
            continue
        fi
        
        log "INFO" "Analyzing compiler flags for $program"
        log "DEBUG" "Build directory: $build_dir"
        log "DEBUG" "Build command: $build_command"
        
        # Get first parameter set for testing
        local first_param=""
        if [ -n "$params_str" ]; then
            IFS='|' read -ra param_array <<< "$params_str"
            first_param="${param_array[0]}"
            log "INFO" "Testing parameters: $first_param"
        fi
        
        # Build and measure with -O2 baseline
        local o2_program=$(build_with_flags "$program" "$build_dir" "$build_command" "-O2")
        if [ -z "$o2_program" ] || [ ! -f "$o2_program" ]; then
            log "ERROR" "Failed to build $program with -O2, skipping"
            continue
        fi
        
        # Measure O2 baseline performance
        local o2_time=$(measure_execution "$o2_program" "$first_param")
        if [ -z "$o2_time" ]; then
            log "ERROR" "Failed to measure $program with -O2, skipping"
            continue
        fi
        log "INFO" "Baseline -O2 time: $o2_time seconds"
        
        # Also build with standard -O3 for comparison
        local o3_program=$(build_with_flags "$program" "$build_dir" "$build_command" "-O3")
        if [ -n "$o3_program" ] && [ -f "$o3_program" ]; then
            local o3_time=$(measure_execution "$o3_program" "$first_param")
            if [ -n "$o3_time" ]; then
                log "INFO" "Baseline -O3 time: $o3_time seconds"
                
                # Record O3 vs O2 comparison
                local o3_impact=$(echo "scale=2; 100 * ($o2_time - $o3_time) / $o2_time" | bc -l)
                echo "$program,-O3 (full),$o2_time,$o3_time,$o3_impact" >> "$results_file"
            fi
        fi
        
        # Test each O3 flag individually
        for flag in "${O3_FLAGS[@]}"; do
            log "INFO" "Testing flag: $flag"
            
            # Build with -O2 + this flag
            local test_config="-O2 $flag"
            local test_program=$(build_with_flags "$program" "$build_dir" "$build_command" "$test_config")
            
            if [ -z "$test_program" ] || [ ! -f "$test_program" ]; then
                log "WARNING" "Failed to build with $test_config, skipping"
                continue
            fi
            
            # Measure performance
            local flag_time=$(measure_execution "$test_program" "$first_param")
            if [ -z "$flag_time" ]; then
                log "WARNING" "Failed to measure with $test_config, skipping"
                continue
            fi
            
            # Calculate impact percentage
            local impact=$(echo "scale=2; 100 * ($o2_time - $flag_time) / $o2_time" | bc -l)
            
            log "INFO" "Impact of $flag: $impact% (time: $flag_time s)"
            echo "$program,$flag,$o2_time,$flag_time,$impact" >> "$results_file"
            
            # Track top flags
            if (( $(echo "$impact > 0" | bc -l) )); then
                flag_count["$flag"]=$((${flag_count["$flag"]} + 1))
                log "INFO" "Improvement found with $flag: $impact%"
            fi
        done
        
        log "INFO" "Completed analysis for $program"
    done < "$config_file"
    
    # Show summary of most impactful flags
    log "INFO" "Flag analysis summary:"
    
    local tmpfile=$(mktemp)
    for flag in "${!flag_count[@]}"; do
        echo "$flag ${flag_count["$flag"]}" >> "$tmpfile"
    done
    
    sort -k2 -nr "$tmpfile" | while read flag count; do
        if [ "$count" -gt 0 ]; then
            log "INFO" "  $flag: appeared in top flags for $count programs"
        fi
    done
    rm "$tmpfile"
    
    log "INFO" "Flag analysis complete. Results saved to $results_file"
}

export -f build_with_flags measure_execution analyze_compiler_flags