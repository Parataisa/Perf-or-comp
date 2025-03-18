#!/bin/bash
# Functions for submitting and monitoring SLURM jobs

# Submit job to SLURM
submit_job() {
    local job_script=$1
    local job_id
    
    log "INFO" "Submitting job: $job_script"
    job_id=$(sbatch "$job_script" | awk '{print $4}')
    
    if [ -z "$job_id" ]; then
        log "ERROR" "Failed to submit job: $job_script"
        return 1
    fi
    
    log "INFO" "Job submitted with ID: $job_id"
    echo "$job_id"
}

# Wait for a job to complete with timeout and cancellation
wait_for_job() {
    local job_id=$1
    local job_state
    local waited=0
    
    while true; do
        job_state=$(squeue -j "$job_id" -h -o %t 2>/dev/null)
        
        if [ -z "$job_state" ]; then
            # Job not found in queue, assume it has completed
            log "INFO" "Job $job_id has completed."
            return 0
        fi
        
        log "DEBUG" "Job $job_id state: $job_state"
        sleep 5
        waited=$((waited + 5))
        
        # Check for timeout and cancel job if needed
        if [ $waited -ge $MAX_WAIT_TIME ]; then
            log "WARNING" "Job $job_id has exceeded maximum wait time of $MAX_WAIT_TIME seconds. Cancelling job."
            scancel $job_id
            return 1
        fi
    done
}

# Execute performance test on the cluster
run_on_cluster() {
    local program_path=$1
    local params=$2
    local sim_workload=$3
    local program_name=$(basename "$program_path")
    
    log "INFO" "Running on cluster using SLURM with dynamic repetitions..."
    if $sim_workload; then
        log "INFO" "Using simulated workload"
    fi
    
    # Create a unique job name with timestamp
    local job_name="${JOB_NAME_PREFIX}_${program_name}_$(date +%s)"
    
    # Create job script
    local job_script=$(create_job_script "$program_path" "$params" "$job_name" "$sim_workload")
    local output_file="${job_name}_output.log"
    
    local job_id=$(submit_job "$job_script")
    
    if [ -z "$job_id" ]; then
        log "ERROR" "Failed to submit job. Skipping this parameter set."
        return 1
    fi
    
    if ! wait_for_job "$job_id"; then
        log "ERROR" "Job $job_id was cancelled due to timeout."
        return 1
    fi
    
    local result=$(parse_job_output "$output_file")
    
    if [ -z "$result" ]; then
        log "ERROR" "Failed to parse job output. Skipping this parameter set."
        return 1
    fi
    
    if [ "$CLEANUP_JOB_FILES" = "true" ]; then
        log "DEBUG" "Cleaning up job files: $job_script $output_file"
        rm -f "$job_script" "$output_file"
    fi
    
    echo "$result"
}

export -f submit_job wait_for_job run_on_cluster