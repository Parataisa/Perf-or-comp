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
source "${SCRIPT_DIR}/lib/cluster_functions.sh"
source "${SCRIPT_DIR}/lib/build_system.sh"

# Process command line arguments
CONFIG_FILE="test_config.txt"

# Run the performance tests
process_config "$CONFIG_FILE"

log "INFO" "Performance testing complete!"
log "INFO" "Results saved to $OUTPUT_FILE"
log "INFO" "CSV metrics saved to $CSV_FILE"
exit 0