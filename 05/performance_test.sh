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
source "${SCRIPT_DIR}/lib/compiler_optimization.sh"

# Process command line arguments
CONFIG_FILE="test_config_b.txt"
RUN_OPTIMIZATION=true
OPTIMIZE_ONLY=true
APPLY_OPTIMIZATIONS=false

# Run the performance tests
if [ "$APPLY_OPTIMIZATIONS" = "true" ]; then
    apply_optimal_configurations "$CONFIG_FILE"
elif [ "$OPTIMIZE_ONLY" = "true" ]; then
    search_optimal_configurations "$CONFIG_FILE"
elif [ "$RUN_OPTIMIZATION" = "true" ]; then
    process_config_with_optimization "$CONFIG_FILE"
else
    # Run regular tests only
    process_config "$CONFIG_FILE"
fi

log "INFO" "Performance testing complete!"
log "INFO" "Results saved to $OUTPUT_FILE"
log "INFO" "CSV metrics saved to $CSV_FILE"
exit 0