#!/bin/bash

# Performance testing framework - Main script
# This is the entry point for the performance testing framework

# Import all modules
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/parsing.sh"
source "${SCRIPT_DIR}/lib/measurement.sh"
source "${SCRIPT_DIR}/lib/reporting.sh"
source "${SCRIPT_DIR}/lib/test_runner.sh"
source "${SCRIPT_DIR}/lib/build_system.sh"
source "${SCRIPT_DIR}/lib/job_creation.sh"
source "${SCRIPT_DIR}/lib/job_management.sh"
source "${SCRIPT_DIR}/lib/result_processing.sh"
source "${SCRIPT_DIR}/lib/compiler_analysis.sh"

# Configuration 
CONFIG_FILE="test_config_b.txt"
MODE="analyze"  # Options: "analyze", "autotune", "both", or "standard"

# Log which mode we're running
log "INFO" "Running performance tests with mode: $MODE"

# Run based on selected mode
if [ "$MODE" = "analyze" ]; then
    analyze_compiler_flags "$CONFIG_FILE"
elif [ "$MODE" = "autotune" ]; then
    find_best_configs "$CONFIG_FILE"
elif [ "$MODE" = "both" ]; then
    analyze_compiler_flags "$CONFIG_FILE"
    find_best_configs "$CONFIG_FILE"
    apply_best_configs "$CONFIG_FILE"
else
    process_config "$CONFIG_FILE"
fi

log "INFO" "Performance testing complete!"
log "INFO" "Results saved to $OUTPUT_FILE"
log "INFO" "CSV metrics saved to $CSV_FILE"
if [ "$MODE" != "standard" ]; then
    log "INFO" "Compiler optimization results saved to compiler_results/"
fi
exit 0