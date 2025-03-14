#!/bin/bash

#=====================================================================
# Reporting Functions
#=====================================================================

# Initialize CSV file with header
initialize_csv_file() {
    echo "Program,Description,Parameters,Avg Time (s),User CPU (s),System CPU (s),Memory (KB),Std Dev (s),Min Time (s),Max Time (s),Variance (s²),Notes" > "$CSV_FILE"
    log "INFO" "Initialized CSV metrics file: $CSV_FILE"
}

# Append a row to the CSV file
append_to_csv() {
    local program_name=$1
    local description=$2
    local params=$3
    local avg_real=$4
    local avg_user=$5
    local avg_sys=$6
    local avg_mem=$7
    local stddev_real=$8
    local min_real=$9
    local max_real=${10}
    local variance_real=${11}
    local notes=${12}
    
    # Quote fields containing commas and escape any existing quotes
    local quoted_description=$(echo "$description" | sed 's/"/""/g')
    local quoted_notes=$(echo "$notes" | sed 's/"/""/g')
    
    # Append the data to the CSV file
    echo "\"$program_name\",\"$quoted_description\",\"$params\",\"$avg_real\",\"$avg_user\",\"$avg_sys\",\"$avg_mem\",\"$stddev_real\",\"$min_real\",\"$max_real\",\"$variance_real\",\"$quoted_notes\"" >> "$CSV_FILE"
    
    log "DEBUG" "Added row to CSV for $program_name with parameters: $params"
}

# Get system information
get_system_info() {
    local os_info
    local cpu_info
    local ram_info
    
    # Get OS information
    if [ -f /etc/os-release ]; then
        os_info=$(grep -m1 PRETTY_NAME /etc/os-release | cut -d'"' -f2)
    else
        os_info="Unknown OS"
    fi
    os_info="${os_info} on $(uname -r)"
    
    # Get CPU information
    if [ -f /proc/cpuinfo ]; then
        cpu_info=$(cat /proc/cpuinfo | grep "model name" | head -n 1 | sed 's/.*: //')
        if [ -z "$cpu_info" ]; then
            cpu_info="Unknown CPU"
        fi
    else
        cpu_info="Unknown CPU"
    fi
    
    # Get RAM information
    if command -v free &> /dev/null; then
        ram_total=$(free -h | grep Mem | awk '{print $2}')
        ram_avail=$(free -h | grep Mem | awk '{print $7}')
        ram_info="${ram_total} total, ${ram_avail} available"
    else
        ram_info="Unknown RAM configuration"
    fi
    
    echo -e "OS:$os_info\nCPU:$cpu_info\nRAM:$ram_info"
}

# Initialize the markdown output file with header and system info
initialize_report() {
    local sys_info=$(get_system_info)
    local os_info=$(echo "$sys_info" | grep "OS:" | cut -d':' -f2-)
    local cpu_info=$(echo "$sys_info" | grep "CPU:" | cut -d':' -f2-)
    local ram_info=$(echo "$sys_info" | grep "RAM:" | cut -d':' -f2-)
    
    cat > $OUTPUT_FILE << EOF
# Performance Test Results

## System Information

- *Date:* $(date "+%Y-%m-%d %H:%M:%S")
- *OS:*$os_info
- *CPU:*$cpu_info
- *RAM:*$ram_info
- *Execution Mode:* $([[ "$RUN_ON_CLUSTER" == "true" ]] && echo "Cluster (SLURM)" || echo "Local")

## Notes on Methodology
- Each test performed $REPETITIONS runs with statistical analysis
- Fast-running programs (<50ms) use high-precision loop timing
- Time measurements in seconds with nanosecond precision where possible
- Standard deviation and variance indicate run-to-run variability
- Memory measurements in kilobytes
- Results available in CSV format at $CSV_FILE 
- Cache clearing ${CACHE_CLEARING_ENABLED:+attempted }between test runs for consistent measurements

EOF
}

# Add a program section to the report
add_program_section() {
    local program_name=$1
    local description=$2
    
    # Add program section to markdown
    cat >> $OUTPUT_FILE << EOF

| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
EOF
}

# Add justification section to the report with parameters
add_justification() {
    local program_name=$1
    local description=$2
    local params=$3
    
    # Format parameter list in a readable way
    local param_list=""
    IFS='|' read -ra param_array <<< "$params"
    for param in "${param_array[@]}"; do
        if [ -n "$param" ]; then
            param_list="${param_list}- \`$param\`\n"
        fi
    done
    
    cat >> $OUTPUT_FILE << EOF
## $program_name

$description

### $program_name parameters justification
- $description
- Selected parameters for this benchmark:
$(echo -e "$param_list")

EOF
}