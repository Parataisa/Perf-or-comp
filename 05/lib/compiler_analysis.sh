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
    local program=$1
    local build_dir=$2
    local build_command=$3
    local flags=$4
    local program_name=$(basename "$program")
    
    log "INFO" "Building $program_name with flags: $flags"
    
    # Check if this is a CMake project
    if [[ "$build_command" == *"cmake"* ]]; then
        log "INFO" "CMake project detected"
        
        # Create a unique directory for this flag combination
        local flag_safe=${flags//[^a-zA-Z0-9]/_}
        local unique_dir="${build_dir}_${flag_safe}"
        
        # Create a clean build directory
        if [ -d "$unique_dir" ]; then
            rm -rf "$unique_dir"
        fi
        mkdir -p "$unique_dir"
        
        # Create the CMake command with the new flags
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
        
        local program_path=""
        program_path="$unique_dir/$program_name"
        
        if [ -z "$program_path" ] || [ ! -f "$program_path" ]; then
            log "ERROR" "Could not find built executable in $unique_dir"
            return 1
        fi
        
        log "INFO" "Built executable: $program_path"
        echo "$program_path"
    else
        # Standard GCC build 
        local output_name="${program_name}_${flags//[^a-zA-Z0-9]/_}"
        local built_program=$(build_program "$output_name" "gcc $flags" "$build_dir")
        
        # If the build failed, try to find the source file and build directly
        if [ ! -f "$built_program" ]; then
            log "WARNING" "Standard build failed, trying direct compilation"
            
            mkdir -p "$build_dir"

            local source_file=""
            source_file="${program}.c"
          
            if [ -z "$source_file" ]; then
                log "ERROR" "Could not find source file for $program_name"
                return 1
            fi
            
            # Build directly with gcc
            local output_path="$build_dir/$output_name"
            gcc $flags -o "$output_path" "$source_file" >/dev/null 2>&1
            
            if [ ! -f "$output_path" ]; then
                log "ERROR" "Direct compilation failed"
                return 1
            fi
            
            built_program="$output_path"
        fi
        
        log "INFO" "Built executable: $built_program"
        echo "$built_program"
    fi
}

# Measure execution time more reliably
measure_execution() {
    local program_path=$1
    local program_params=$2
    local runs=$MIN_REPETITIONS 
    
    # Check if program exists and is executable
    if [ ! -x "$program_path" ]; then
        log "ERROR" "Program not found or not executable: $program_path"
        return 1
    fi
    
    log "INFO" "Measuring $program_path with params: $program_params"
    local total_time=0
    
    for ((i=1; i<=runs; i++)); do
        log "DEBUG" "Measurement run $i"
        
        # Use the time command for more accurate measurement
        local start_time=$(date +%s.%N)
        "$program_path" $program_params >/dev/null 2>&1
        local end_time=$(date +%s.%N)
        local run_time=$(echo "$end_time - $start_time" | bc -l)
        
        total_time=$(echo "$total_time + $run_time" | bc -l)
    done
    
    # Calculate average
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
        log "INFO" "Build directory: $build_dir"
        log "INFO" "Build command: $build_command"
        
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
    
    # Simple sorting of flag counts
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

# Find best compiler configurations
find_best_configs() {
    local config_file=$1
    
    # Create results directory
    mkdir -p "compiler_results"
    local results_file="compiler_results/autotuning.csv"
    echo "Program,Best Config,O2 Time,O3 Time,Best Time,Imp O2 (%),Imp O3 (%)" > "$results_file"
    
    log "INFO" "Starting compiler autotuning..."
    
    # Process each program in config file
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        
        # Parse the configuration
        local config_data=$(parse_config_options "$line")
        IFS='|' read -r program description depends collect_metrics cleanup build build_dir build_command sim_cpu_load sim_io_load params_str <<< "$config_data"
        
        # Skip if program name is empty or metrics not collected
        if [ -z "$program" ] || [ "$collect_metrics" != "true" ]; then
            continue
        fi
        
        log "INFO" "Finding best compiler config for $program"
        
        # Get first parameter set for testing
        local first_param=""
        if [ -n "$params_str" ]; then
            IFS='|' read -ra param_array <<< "$params_str"
            first_param="${param_array[0]}"
        fi
        
        # Build and measure with -O2 and -O3
        local o2_program=$(build_with_flags "$program" "$build_dir" "$build_command" "-O2")
        if [ -z "$o2_program" ] || [ ! -f "$o2_program" ]; then
            log "ERROR" "Failed to build $program with -O2, skipping"
            continue
        fi
        
        local o2_time=$(measure_execution "$o2_program" "$first_param")
        if [ -z "$o2_time" ]; then
            log "ERROR" "Failed to measure $program with -O2, skipping"
            continue
        fi
        log "INFO" "Baseline -O2: $o2_time seconds"
        
        local o3_program=$(build_with_flags "$program" "$build_dir" "$build_command" "-O3")
        if [ -z "$o3_program" ] || [ ! -f "$o3_program" ]; then
            log "WARNING" "Failed to build $program with -O3, using O2 as baseline"
            o3_time=$o2_time
        else
            local o3_time=$(measure_execution "$o3_program" "$first_param")
            if [ -z "$o3_time" ]; then
                log "WARNING" "Failed to measure $program with -O3, using O2 as baseline"
                o3_time=$o2_time
            else 
                log "INFO" "Baseline -O3: $o3_time seconds"
            fi
        fi
        
        # Track best configuration
        local best_config best_time
        if (( $(echo "$o2_time <= $o3_time" | bc -l) )); then
            best_config="-O2"
            best_time=$o2_time
        else
            best_config="-O3"
            best_time=$o3_time
        fi
        
        # Try some promising configurations
        local configs=(
            "-O2 -finline-functions -ftree-vectorize"
            "-O3 -march=native"
            "-Ofast"
        )
        
        for config in "${configs[@]}"; do
            log "INFO" "Testing config: $config"
            
            local test_program=$(build_with_flags "$program" "$build_dir" "$build_command" "$config")
            if [ -z "$test_program" ] || [ ! -f "$test_program" ]; then
                log "WARNING" "Failed to build with $config, skipping"
                continue
            fi
            
            # Measure performance
            local config_time=$(measure_execution "$test_program" "$first_param")
            if [ -z "$config_time" ]; then
                log "WARNING" "Failed to measure with $config, skipping"
                continue
            fi
            
            # Check if this is better than our best so far
            if (( $(echo "$config_time < $best_time" | bc -l) )); then
                best_time=$config_time
                best_config=$config
                log "INFO" "New best: $config ($config_time seconds)"
            fi
        done
        
        # Calculate improvements
        local imp_o2=$(echo "scale=2; 100 * ($o2_time - $best_time) / $o2_time" | bc -l)
        local imp_o3=$(echo "scale=2; 100 * ($o3_time - $best_time) / $o3_time" | bc -l)
        
        log "INFO" "Best config: $best_config (time: $best_time s)"
        log "INFO" "Improvement over -O2: $imp_o2%, over -O3: $imp_o3%"
        
        # Add to results
        echo "$program,$best_config,$o2_time,$o3_time,$best_time,$imp_o2,$imp_o3" >> "$results_file"
    done < "$config_file"
    
    # Check for significant improvements
    log "INFO" "Checking for significant improvements..."
    
    local found_significant=false
    tail -n +2 "$results_file" | while IFS=, read -r program config o2_time o3_time best_time imp_o2 imp_o3; do
        if (( $(echo "$imp_o3 > 3.0" | bc -l) )); then
            log "INFO" "Found significant improvement for $program: $imp_o3% better than -O3 with config: $config"
            found_significant=true
        elif (( $(echo "$imp_o2 > 3.0" | bc -l) )); then
            log "INFO" "Found significant improvement for $program: $imp_o2% better than -O2 with config: $config"
            found_significant=true
        fi
    done
    
    if ! $found_significant; then
        log "INFO" "No significant improvements found over standard optimizations"
    fi
    
    log "INFO" "Autotuning complete. Results saved to $results_file"
}

# Apply best compiler configurations to config file
apply_best_configs() {
    local config_file=$1
    local output_config="${config_file%.*}_optimized.txt"
    
    # Create a copy of the original config file
    cp "$config_file" "$output_config"
    
    log "INFO" "Applying optimized configurations to: $output_config"
    
    # Process the autotuning results
    if [ -f "compiler_results/autotuning.csv" ]; then
        # Skip header
        tail -n +2 "compiler_results/autotuning.csv" | while IFS=, read -r program config o2_time o3_time best_time imp_o2 imp_o3; do
            # Only apply if meaningful improvement (>2%)
            if (( $(echo "$imp_o3 > 2.0" | bc -l) )); then
                log "INFO" "Applying optimized config for $program: $config"
                
                # Find the line in the config file
                local line_in_config=$(grep "^$program" "$output_config")
                if [ -n "$line_in_config" ]; then
                    # Check if the line has a build_command
                    if [[ "$line_in_config" == *"build_command="* ]]; then
                        if [[ "$line_in_config" == *"cmake"* ]]; then
                            # For CMake, we need to update the CMAKE_C_FLAGS parameter
                            sed -i "s|-DCMAKE_C_FLAGS=\"[^\"]*\"|-DCMAKE_C_FLAGS=\"$config\"|" "$output_config"
                        else
                            # For GCC, replace the entire build command
                            sed -i "s|build_command=[^|]*|build_command=gcc $config|" "$output_config"
                        fi
                    else
                        # Add build command if not present
                        sed -i "s|^$program|$program|build_command=gcc $config|" "$output_config"
                    fi
                fi
            fi
        done
        
        log "INFO" "Optimized configuration saved to: $output_config"
    else
        log "WARNING" "Autotuning results not found. Cannot apply optimizations."
    fi
}