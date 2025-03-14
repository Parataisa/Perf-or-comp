#!/bin/bash

# ANSI color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

#=====================================================================
# Configuration
#=====================================================================
OUTPUT_FILE="performance_results_laptop.md"
CSV_FILE="performance_results_laptop.csv"  # For storing metrics in CSV format
REPETITIONS=4               # Number of test repetitions for statistics
WARMUP_RUNS=2               # Warmup runs to eliminate cold-start effects
PAUSE_SECONDS=1             # Time to pause between runs for system stability
CACHE_CLEARING_ENABLED=true # Enable/disable cache clearing attempts
USE_VALGRIND=false          # Use valgrind for memory profiling if available
DEBUG_LEVEL="INFO"          # Logging level: DEBUG, INFO, WARNING, ERROR

# High precision mode iterations configuration
VERY_FAST_ITERATIONS=1000    # Iterations for very fast programs (<10ms)
FAST_ITERATIONS=100         # Iterations for fast programs (<100ms but >=10ms)
MODERATELY_FAST_ITERATIONS=50    # Iterations for moderately fast programs (<500ms but >=100ms)

#=====================================================================
# Helper Functions
#=====================================================================

# Log messages with timestamp and color
log() {
    local level=$1
    local message=$2
    local color=$NC
    
    # Only print logs at or above the configured debug level
    case $DEBUG_LEVEL in
        "DEBUG")
            ;;
        "INFO")
            if [ "$level" = "DEBUG" ]; then return; fi ;;
        "WARNING")
            if [ "$level" = "DEBUG" ] || [ "$level" = "INFO" ]; then return; fi ;;
        "ERROR")
            if [ "$level" != "ERROR" ]; then return; fi ;;
    esac
    
    case $level in
        "INFO")    color=$GREEN ;;
        "WARNING") color=$YELLOW ;;
        "ERROR")   color=$RED ;;
        "DEBUG")   color=$PURPLE ;;
    esac
    
    # Ensure message is on a single line
    message=$(echo "$message" | tr -d '\n')
    
    # Print timestamp and message to stderr
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${color}${level}${NC}: ${message}" >&2
}

# Function to clear filesystem caches
clear_caches() {
    if ! $CACHE_CLEARING_ENABLED; then
        return 0
    fi
    
    # Only try to clear caches if running as root
    if [ "$EUID" -eq 0 ]; then
        log "INFO" "Clearing file system cache..."
        sync
        echo 3 > /proc/sys/vm/drop_caches
        return 0
    else
        log "WARNING" "Not running as root, cannot clear caches. For best results, consider running with sudo."
        return 1
    fi
}

#=====================================================================
# Formatting Functions
#=====================================================================

# Format a time value for display, using scientific notation for small values
format_time() {
    local value=$1
    
    # Check if the value is effectively zero (very small number)
    if (( $(echo "$value < 0.0000000001" | bc -l) )); then
        echo "1.000e-10"
    elif (( $(echo "$value < 0.001" | bc -l) )); then
        printf "%.3e" "$value"
    elif (( $(echo "$value < 0.1" | bc -l) )); then
        printf "%.7f" "$value"
    else
        printf "%.6f" "$value"
    fi
}

# Calculate statistics from array of measurements
calculate_statistics() {
    local input=$1
    
    local stats=$(echo "$input" | tr ' ' '\n' | awk '
    BEGIN {
        sum=0; 
        sum2=0; 
        min=9999999; 
        max=0; 
        n=0
    } 
    NF > 0 && $1 != "" {
        val=$1+0; 
        sum+=val; 
        sum2+=val*val; 
        if(val<min)min=val; 
        if(val>max)max=val; 
        n++
    } 
    END {
        avg=(n>0)?(sum/n):0; 
        # Calculate variance
        variance=(n>1)?((sum2-(sum*sum)/n)/(n-1)):0;
        stddev=sqrt(variance);
        # Ensure min is never exactly zero
        if(min < 0.0000001) min = 0.0000001;
        printf "%.9f %.9f %.9f %.9f %.9f", avg, stddev, min, max, variance
    }')
    
    echo "$stats"
}