#!/bin/bash

#=====================================================================
# Configuration Parsing Functions
#=====================================================================

# Create a sample configuration file
create_sample_config() {
    local file=$1
    log "INFO" "Creating a sample config file at: ${file}"
    
    cat > "$file" << EOF
# Performance Test Configuration
#
# Format: program_name|description|[options]|param_set1|param_set2|...
#
# Available options:
# - depends=program_name args     # Dependency program to run first with its arguments
# - collect=true/false            # Whether to collect metrics for this run (default: true)
# - cleanup=command or path       # Cleanup command or path pattern to remove after execution
# Examples:

filegen|File generation benchmark|cleanup=rm -rf ./generated|1 10 512 512|1 20 512 512|

filesearch|File search benchmark|depends=filegen 50 20 512 8192|cleanup=rm -rf ./generated|collect=true|
filesearch|File search benchmark|depends=filegen 10 50 512 1048576|cleanup=rm -rf ./generated|collect=false|

EOF
    
    log "INFO" "Sample config file created: $file"
    chmod 666 "$file"
    
    # If running with sudo, make sure the original user owns the file
    if [ -n "$SUDO_USER" ]; then
        chown $SUDO_USER:$(id -gn $SUDO_USER) "$file"
        log "DEBUG" "Changed ownership to $SUDO_USER"
    fi
    
    log "INFO" "Please edit it to match your programs and parameters, then run this script again."
}

# Parse options from a config line
parse_config_options() {
    local config_line=$1
    local program=""
    local description=""
    local depends="none"
    local collect_metrics=true
    local cleanup="none"
    local build="true"
    local build_dir=""
    local build_command=""
    local sim_cpu_load="false"
    local sim_io_load="false"
    local params=""

    # Helper function to remove surrounding double quotes if present
    strip_quotes() {
        local str="$1"
        if [[ "${str:0:1}" == "\"" && "${str: -1}" == "\"" ]]; then
            echo "${str:1:${#str}-2}"
        else
            echo "$str"
        fi
    }

    # Split the line by pipe separator
    IFS='|' read -ra parts <<< "$config_line"

    # Extract program and description (first two fields), stripping quotes if needed
    program=$(strip_quotes "${parts[0]}")
    description=$(strip_quotes "${parts[1]}")

    # Starting index for parameter sets (skip program and description)
    local param_start=2

    # Process options
    for ((i=2; i<${#parts[@]}; i++)); do
        local part=$(strip_quotes "${parts[$i]}")
        # If the part is empty, skip it
        [ -z "$part" ] && continue

        if [[ "$part" =~ ^depends= ]]; then
            depends="${part#depends=}"
            param_start=$((i+1))
        elif [[ "$part" =~ ^collect= ]]; then
            collect_metrics="${part#collect=}"
            param_start=$((i+1))
        elif [[ "$part" =~ ^cleanup= ]]; then
            cleanup="${part#cleanup=}"
            param_start=$((i+1))
        elif [[ "$part" =~ ^build= ]]; then
            build="${part#build=}"
            param_start=$((i+1))
        elif [[ "$part" =~ ^build_dir= ]]; then
            build_dir="${part#build_dir=}"
            param_start=$((i+1))
        elif [[ "$part" =~ ^sim_cpu_load= ]]; then
            sim_cpu_load="${part#sim_cpu_load=}"
            param_start=$((i+1))
        elif [[ "$part" =~ ^sim_io_load= ]]; then
            sim_io_load="${part#sim_io_load=}"
            param_start=$((i+1))
        elif [[ "$part" =~ ^build_command= ]]; then
            build_command="${part#build_command=}"
            param_start=$((i+1))
        else
            break
        fi
    done

    # Collect all remaining parts as parameter sets, joining them with a pipe delimiter
    for ((i=param_start; i<${#parts[@]}; i++)); do
        local part=$(strip_quotes "${parts[$i]}")
        if [ -z "$params" ]; then
            params="$part"
        else
            params="$params|$part"
        fi
    done

    # Output as a pipe-separated string for downstream processing
    echo "$program|$description|$depends|$collect_metrics|$cleanup|$build|$build_dir|$build_command|$sim_cpu_load|$sim_io_load|$params"
}

# Execute dependency program if needed
run_dependency() {
    local dependency=$1
    local in_cluster=$2 
    
    # Skip if no dependency defined
    if [ "$dependency" = "none" ]; then
        return 0
    fi
    
    # Parse program name and arguments
    read -r dep_program dep_args <<< "$dependency"
    
    # Find the program path
    local program_path
    if [ -f "./build/$dep_program" ]; then
        program_path="./build/$dep_program"
    else
        log "ERROR" "Dependency program not found: $dep_program"
        return 1
    fi
    
    # Run the dependency
    log "INFO" "Executing dependency: $program_path $dep_args"
    # If dep_args is surrounded by double quotes, remove them
    if [[ "$dep_args" =~ ^\"(.*)\"$ ]]; then
        dep_args="${BASH_REMATCH[1]}"
    fi
    
    # If running on cluster, let the cluster job script handle dependencies
    if [ "$in_cluster" = "true" ]; then
        # Store dependency info for cluster job script
        export DEPENDENCY_PROGRAM="$dep_program"
        export DEPENDENCY_ARGS="$dep_args"
        log "INFO" "Dependency info stored for cluster job"
        return 0
    else
        # Run directly if not on cluster
        $program_path $dep_args
        local status=$?
        
        if [ $status -ne 0 ]; then
            log "ERROR" "Dependency execution failed with status: $status"
            return $status
        fi
    fi
    
    log "INFO" "Dependency successfully executed"
    return 0
}

# Perform cleanup after a program run
run_cleanup() {
    local cleanup_action=$1
    
    # Skip if no cleanup defined
    if [ "$cleanup_action" = "none" ]; then
        return 0
    fi
    
    log "INFO" "Performing cleanup: $cleanup_action"
    
    # Check if it's a simple file/dir pattern or a command
    if [[ "$cleanup_action" =~ ^(rm|find|mv|cp)\ .*$ ]]; then
        # It's a command, execute it directly
        eval "$cleanup_action"
    else
        # Assume it's a file or directory pattern to remove
        rm -rf "$cleanup_action"
    fi
    
    local status=$?
    if [ $status -ne 0 ]; then
        log "WARNING" "Cleanup action returned non-zero status: $status"
    fi
    
    return $status
}