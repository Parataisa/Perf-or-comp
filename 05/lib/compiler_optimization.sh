#!/bin/bash

#=====================================================================
# Compiler Flag Analysis and Autotuning
#=====================================================================

# Key flags that change between -O2 and -O3
# These were determined by running: gcc -Q --help=optimizers -O2 > O2.txt; gcc -Q --help=optimizers -O3 > O3.txt; diff O2.txt O3.txt
O3_SPECIFIC_FLAGS=(
    "-finline-functions"
    "-funswitch-loops"
    "-fgcse-after-reload"
    "-ftree-vectorize"
    "-fipa-cp-clone"
    "-floop-interchange"
    "-floop-unroll-and-jam"
    "-fpredictive-commoning"
    "-ftree-partial-pre"
    "-ftree-loop-distribution"
    "-fsplit-paths"
)

# Function to analyze individual O3 flags impact
analyze_o3_flags() {
    local program_source=$1
    local program_name=$(basename "$program_source" .c)
    local params=$2
    local result_dir="flag_analysis_${program_name}"
    
    mkdir -p "$result_dir"
    local results_file="$result_dir/flag_impact.csv"
    
    echo "Flag,Avg Time (s),Improvement over O2 (%),Degradation from O3 (%)" > "$results_file"
    
    log "INFO" "Analyzing impact of O3-specific flags for $program_name"
    log "INFO" "Parameters: $params"
    
    # Step 1: Get baseline measurements with -O2 and -O3
    log "INFO" "Establishing baselines..."
    
    # Build and measure with -O2
    local o2_program=$(build_program "$program_name" "gcc -O2" "build")
    local o2_metrics=$(measure_program "$o2_program" "$params" "false" "false")
    read -r o2_time o2_user o2_sys o2_mem o2_stddev o2_min o2_max o2_variance o2_notes <<< "$o2_metrics"
    log "INFO" "Baseline -O2: $o2_time seconds"
    
    # Build and measure with -O3
    local o3_program=$(build_program "$program_name" "gcc -O3" "build")
    local o3_metrics=$(measure_program "$o3_program" "$params" "false" "false")
    read -r o3_time o3_user o3_sys o3_mem o3_stddev o3_min o3_max o3_variance o3_notes <<< "$o3_metrics"
    log "INFO" "Baseline -O3: $o3_time seconds"
    
    # Record baselines
    echo "Base -O2,$o2_time,0.00,$(echo "scale=2; 100 * ($o2_time - $o3_time) / $o2_time" | bc -l)" >> "$results_file"
    echo "Base -O3,$o3_time,$(echo "scale=2; 100 * ($o2_time - $o3_time) / $o2_time" | bc -l),0.00" >> "$results_file"
    
    # Step 2: Test each O3-specific flag individually with -O2
    log "INFO" "Testing individual O3 flags with -O2..."
    
    # Array to track flag impacts
    declare -A flag_impacts
    
    for flag in "${O3_SPECIFIC_FLAGS[@]}"; do
        log "INFO" "Testing flag: $flag"
        
        local test_config="-O2 $flag"
        local built_program=$(build_program "$program_name" "gcc $test_config" "build")
        
        if [ ! -f "$built_program" ]; then
            log "WARNING" "Failed to build with $test_config, skipping"
            continue
        fi
        
        # Measure performance
        local metrics=$(measure_program "$built_program" "$params" "false" "false")
        read -r avg_time user_time sys_time avg_mem stddev_time min_time max_time variance_time notes <<< "$metrics"
        
        # Calculate improvements
        local improvement_over_o2=$(echo "scale=2; 100 * ($o2_time - $avg_time) / $o2_time" | bc -l)
        local degradation_from_o3=$(echo "scale=2; 100 * ($avg_time - $o3_time) / $o3_time" | bc -l)
        
        log "INFO" "Result for $flag: $avg_time seconds, Improvement over -O2: $improvement_over_o2%"
        echo "$flag,$avg_time,$improvement_over_o2,$degradation_from_o3" >> "$results_file"
        
        # Store impact for later analysis
        flag_impacts["$flag"]=$improvement_over_o2
    done
    
    # Step 3: Find most impactful flags
    log "INFO" "Analyzing most impactful flags..."
    
    # Sort flags by impact and get top 3
    local sorted_impacts=$(for flag in "${!flag_impacts[@]}"; do 
        echo "$flag ${flag_impacts[$flag]}"
    done | sort -k2 -nr | head -3)
    
    log "INFO" "Top 3 most impactful flags for $program_name:"
    local top_flags=""
    while read -r flag impact; do
        if [ -n "$flag" ] && [ "$(echo "$impact > 0" | bc -l)" -eq 1 ]; then
            log "INFO" "  $flag: $impact% improvement"
            top_flags="$top_flags $flag"
        fi
    done <<< "$sorted_impacts"
    
    # Save top flags for this program
    echo "$program_name:$top_flags" > "$result_dir/top_flags.txt"
    
    log "INFO" "Flag analysis complete for $program_name"
    echo "$results_file"
}

# Function to perform autotuning using knowledge from flag analysis
autotune_compiler_config() {
    local program_source=$1
    local program_name=$(basename "$program_source" .c)
    local params=$2
    local result_dir="autotune_${program_name}"
    
    mkdir -p "$result_dir"
    local results_file="$result_dir/autotune_results.csv"
    
    echo "Configuration,Avg Time (s),Improvement (%)" > "$results_file"
    
    log "INFO" "Starting autotuning for $program_name"
    
    # Step 1: Get baseline measurements for O2 and O3
    local o2_program=$(build_program "$program_name" "gcc -O2" "build")
    local o2_metrics=$(measure_program "$o2_program" "$params" "false" "false")
    read -r o2_time o2_user o2_sys o2_mem o2_stddev o2_min o2_max o2_variance o2_notes <<< "$o2_metrics"
    
    local o3_program=$(build_program "$program_name" "gcc -O3" "build")
    local o3_metrics=$(measure_program "$o3_program" "$params" "false" "false")
    read -r o3_time o3_user o3_sys o3_mem o3_stddev o3_min o3_max o3_variance o3_notes <<< "$o3_metrics"
    
    local best_baseline_time
    local best_baseline
    if (( $(echo "$o2_time < $o3_time" | bc -l) )); then
        best_baseline_time=$o2_time
        best_baseline="-O2"
    else
        best_baseline_time=$o3_time
        best_baseline="-O3"
    fi
    
    log "INFO" "Baseline -O2: $o2_time seconds"
    log "INFO" "Baseline -O3: $o3_time seconds"
    log "INFO" "Best baseline: $best_baseline ($best_baseline_time seconds)"
    
    echo "-O2,$o2_time,baseline" >> "$results_file"
    echo "-O3,$o3_time,$(echo "scale=2; 100 * ($o2_time - $o3_time) / $o2_time" | bc -l)" >> "$results_file"
    
    # Step 2: Try combinations of effective flags from analysis
    if [ -f "flag_analysis_${program_name}/top_flags.txt" ]; then
        log "INFO" "Using program-specific flag analysis results"
        top_flags=$(cat "flag_analysis_${program_name}/top_flags.txt" | cut -d':' -f2)
    else
        log "INFO" "No program-specific analysis available, using default flags"
        top_flags="-finline-functions -ftree-vectorize -fpredictive-commoning"
    fi
    
    # Try -O2 with the top flags
    log "INFO" "Testing -O2 with top flags: $top_flags"
    local test_config="-O2 $top_flags"
    local built_program=$(build_program "$program_name" "gcc $test_config" "build")
    
    if [ -f "$built_program" ]; then
        local metrics=$(measure_program "$built_program" "$params" "false" "false")
        read -r avg_time user_time sys_time avg_mem stddev_time min_time max_time variance_time notes <<< "$metrics"
        
        local improvement=$(echo "scale=2; 100 * ($best_baseline_time - $avg_time) / $best_baseline_time" | bc -l)
        log "INFO" "Result for $test_config: $avg_time seconds, Improvement: $improvement%"
        echo "$test_config,$avg_time,$improvement" >> "$results_file"
        
        if (( $(echo "$avg_time < $best_baseline_time" | bc -l) )); then
            best_baseline_time=$avg_time
            best_baseline=$test_config
        fi
    fi
    
    # Try some additional promising combinations
    local additional_configs=(
        "-O2 -finline-functions -ftree-vectorize"
        "-O2 -funswitch-loops -fpredictive-commoning" 
        "-O3 -fno-inline-functions" # Sometimes disabling a flag helps
        "-Ofast" # Try aggressive optimizations
        "-O3 -march=native" # Architecture-specific optimizations
    )
    
    for config in "${additional_configs[@]}"; do
        log "INFO" "Testing configuration: $config"
        local built_program=$(build_program "$program_name" "gcc $config" "build")
        
        if [ ! -f "$built_program" ]; then
            log "WARNING" "Failed to build with $config, skipping"
            continue
        fi
        
        local metrics=$(measure_program "$built_program" "$params" "false" "false")
        read -r avg_time user_time sys_time avg_mem stddev_time min_time max_time variance_time notes <<< "$metrics"
        
        local improvement=$(echo "scale=2; 100 * ($best_baseline_time - $avg_time) / $best_baseline_time" | bc -l)
        log "INFO" "Result for $config: $avg_time seconds, Improvement: $improvement%"
        echo "$config,$avg_time,$improvement" >> "$results_file"
        
        if (( $(echo "$avg_time < $best_baseline_time" | bc -l) )); then
            best_baseline_time=$avg_time
            best_baseline=$config
        fi
    done
    
    # Check if we found a better configuration
    if [ "$best_baseline" != "-O2" ] && [ "$best_baseline" != "-O3" ]; then
        log "INFO" "Found better configuration: $best_baseline"
        log "INFO" "Improvement over -O2: $(echo "scale=2; 100 * ($o2_time - $best_baseline_time) / $o2_time" | bc -l)%"
        log "INFO" "Improvement over -O3: $(echo "scale=2; 100 * ($o3_time - $best_baseline_time) / $o3_time" | bc -l)%"
    else
        log "INFO" "No configuration found that outperforms the baseline optimizations"
    fi
    
    # Return the best configuration found
    echo "$best_baseline"
}

# Function to analyze all programs in a config file
analyze_all_programs() {
    local config_file=$1
    local mode=$2  # "analyze" or "autotune" or "both"
    
    # Create result directories
    local analysis_dir="flag_analysis_results"
    local autotune_dir="autotune_results"
    mkdir -p "$analysis_dir" "$autotune_dir"
    
    # Create summary files
    local analysis_summary="$analysis_dir/flag_impact_summary.csv"
    local autotune_summary="$autotune_dir/autotune_summary.csv"
    
    echo "Program,Top Flags,Impact" > "$analysis_summary"
    echo "Program,Best Config,O2 Time,O3 Time,Best Time,Improvement over O2 (%),Improvement over O3 (%)" > "$autotune_summary"
    
    # Process each program defined in the config file
    log "INFO" "Processing programs from config file..."
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        
        # Parse the configuration
        local config_data=$(parse_config_options "$line")
        IFS='|' read -r program description depends collect_metrics cleanup build build_dir build_command sim_cpu_load sim_io_load params_str <<< "$config_data"
        
        # Skip if program name is empty or metrics not collected
        if [ -z "$program" ] || [ "$collect_metrics" != "true" ]; then
            continue
        fi
        
        log "INFO" "Processing program: $program"
        
        # Find the program source
        local program_source=""
        if [ -f "$program.c" ]; then
            program_source="$program.c"
        elif [ -f "src/$program.c" ]; then
            program_source="src/$program.c"
        elif [ -f "small_samples/$program.c" ]; then
            program_source="small_samples/$program.c"
        fi
        
        if [ -z "$program_source" ]; then
            log "WARNING" "Source file not found for $program, skipping"
            continue
        fi
        
        # Get first parameter set for testing
        local first_param=""
        if [ -n "$params_str" ]; then
            IFS='|' read -ra param_array <<< "$params_str"
            first_param="${param_array[0]}"
        fi
        
        # Run flag analysis
        if [ "$mode" == "analyze" ] || [ "$mode" == "both" ]; then
            log "INFO" "Analyzing flags for $program with params: $first_param"
            local results_file=$(analyze_o3_flags "$program_source" "$first_param")
            
            # Add to summary
            if [ -f "flag_analysis_${program}/top_flags.txt" ]; then
                local top_flags=$(cat "flag_analysis_${program}/top_flags.txt" | cut -d':' -f2)
                echo "$program,$top_flags,$(grep "$top_flags" "$results_file" | cut -d',' -f3)%" >> "$analysis_summary"
            fi
        fi
        
        # Run autotuning
        if [ "$mode" == "autotune" ] || [ "$mode" == "both" ]; then
            log "INFO" "Autotuning $program with params: $first_param"
            local best_config=$(autotune_compiler_config "$program_source" "$first_param")
            
            # Build with -O2 and -O3 for comparison
            local o2_program=$(build_program "$program" "gcc -O2" "build")
            local o2_metrics=$(measure_program "$o2_program" "$first_param" "false" "false")
            read -r o2_time o2_user o2_sys o2_mem o2_stddev o2_min o2_max o2_variance o2_notes <<< "$o2_metrics"
            
            local o3_program=$(build_program "$program" "gcc -O3" "build")
            local o3_metrics=$(measure_program "$o3_program" "$first_param" "false" "false")
            read -r o3_time o3_user o3_sys o3_mem o3_stddev o3_min o3_max o3_variance o3_notes <<< "$o3_metrics"
            
            # Build with best config
            local best_program=$(build_program "$program" "gcc $best_config" "build")
            local best_metrics=$(measure_program "$best_program" "$first_param" "false" "false")
            read -r best_time best_user best_sys best_mem best_stddev best_min best_max best_variance best_notes <<< "$best_metrics"
            
            # Calculate improvements
            local improvement_over_o2=$(echo "scale=2; 100 * ($o2_time - $best_time) / $o2_time" | bc -l)
            local improvement_over_o3=$(echo "scale=2; 100 * ($o3_time - $best_time) / $o3_time" | bc -l)
            
            # Add to summary
            echo "$program,$best_config,$o2_time,$o3_time,$best_time,$improvement_over_o2,$improvement_over_o3" >> "$autotune_summary"
        fi
    done < "$config_file"
    
    log "INFO" "Processing complete. Results saved to $analysis_dir and $autotune_dir."
    
    if [ "$mode" == "analyze" ] || [ "$mode" == "both" ]; then
        # Generate overall flag impact report
        log "INFO" "Generating overall flag impact report..."
        
        # Initialize counts for each flag
        declare -A flag_count
        for flag in "${O3_SPECIFIC_FLAGS[@]}"; do
            flag_count["$flag"]=0
        done
        
        # Count appearances in top flags across all programs
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ "$line" =~ ^Program.* ]] && continue  # Skip header
            
            local program_flags=$(echo "$line" | cut -d',' -f2)
            for flag in "${O3_SPECIFIC_FLAGS[@]}"; do
                if [[ "$program_flags" == *"$flag"* ]]; then
                    flag_count["$flag"]=$((flag_count["$flag"] + 1))
                fi
            done
        done < "$analysis_summary"
        
        # Sort and display top flags
        log "INFO" "Overall most impactful flags across all programs:"
        local sorted_flags=$(for flag in "${!flag_count[@]}"; do 
            echo "$flag ${flag_count[$flag]}"
        done | sort -k2 -nr)
        
        local top_three_flags=""
        local count=0
        while read -r flag impact; do
            if [ -n "$flag" ] && [ $impact -gt 0 ]; then
                log "INFO" "  $flag: appeared in top flags for $impact programs"
                top_three_flags="$top_three_flags $flag"
                count=$((count + 1))
                [ $count -eq 3 ] && break
            fi
        done <<< "$sorted_flags"
        
        log "INFO" "Top 3 most impactful flags across all programs: $top_three_flags"
        log "INFO" "Flag descriptions:"
        log "INFO" "  -finline-functions: Integrates simple functions into their callers to reduce call overhead and enable more optimizations."
        log "INFO" "  -ftree-vectorize: Performs loop vectorization, allowing multiple data operations in a single instruction (SIMD)."
        log "INFO" "  -fpredictive-commoning: Reuses computations from earlier iterations in later ones to reduce redundant calculations."
    fi
    
    if [ "$mode" == "autotune" ] || [ "$mode" == "both" ]; then
        # Check for statistically significant improvements
        log "INFO" "Checking for statistically significant improvements over baseline optimizations..."
        
        local found_significant=false
        while IFS=, read -r program config o2_time o3_time best_time imp_o2 imp_o3; do
            [[ "$program" =~ ^Program.* ]] && continue  # Skip header
            
            # Check for meaningful improvement (>3% and consistent across measurements)
            if (( $(echo "$imp_o3 > 3.0" | bc -l) )); then
                log "INFO" "Found significant improvement for $program: $imp_o3% better than -O3 with config: $config"
                found_significant=true
            fi
        done < "$autotune_summary"
        
        if ! $found_significant; then
            log "INFO" "No statistically significant improvements found over baseline optimizations."
        fi
    fi
}

# Modified process_config to include flag analysis and autotuning
process_config_with_flag_analysis() {
    local config_file=$1
    local mode=$2  # "analyze", "autotune", or "both"
    
    # Run standard processing first
    process_config "$config_file"
    
    # Run flag analysis and/or autotuning
    analyze_all_programs "$config_file" "$mode"
}

export -f analyze_o3_flags autotune_compiler_config analyze_all_programs process_config_with_flag_analysis