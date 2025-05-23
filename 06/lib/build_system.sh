build_program() {
    local program_path=$1
    local build_command=$2
    local build_dir=$3

    # Extract program name and source directory
    local program_name=$(basename "$program_path")
    local source_dir=$(dirname "$program_path")

    log "INFO" "===== Building $program_path ====="
    log "INFO" "Build command: $build_command"
    log "INFO" "Build directory: $build_dir"

    # Check if program needs to be built
    if [ -f "$program_path" ]; then
        log "INFO" "Program already built. Skipping build."
        echo "$program_path"
        return
    fi

    if [ -z "$build_dir" ]; then
        log "INFO" "Build directory not specified. Using ./build as default."
        build_dir="build"
    fi

    # Check if build directory exists
    if [ ! -d "$build_dir" ]; then
        log "INFO" "Build directory not found. Creating: $build_dir"
        mkdir -p "$build_dir"
    fi

    if [[ "$build_command" == *"cmake"* ]]; then
        log "INFO" "Detected CMake build"
        
        # Get source directory (one level up from build directory)
        local cmake_source_dir=$(dirname "$build_dir")
        
        pushd "$build_dir" > /dev/null
        log "INFO" "Building in directory: $(pwd)"
        log "INFO" "Executing: $build_command"
        
        eval "$build_command" > /dev/null
        local build_status=$?
        popd > /dev/null
        
        if [ $build_status -ne 0 ]; then
            log "ERROR" "Build command failed with status: $build_status"
            log "ERROR" "See build log at ${build_log}"
            return
        fi
        
        program_path="${build_dir}/${program_name}"
        if [ ! -f "$program_path" ]; then
            log "ERROR" "Build succeeded but program not found at expected location: $program_path"
            return
        fi
        
        log "INFO" "Build successful!"
        echo "$program_path"
    else
        # Regular gcc/clang build
        # Store the absolute path to the source file
        local abs_source_dir=$(cd "$(dirname "$source_dir")" && pwd)/$(basename "$source_dir")
        local abs_source_file="$abs_source_dir/$program_name.c"

        if [ -z "$build_command" ]; then
            build_command="gcc -Wall -Wextra -O3 -o $program_name $abs_source_file -lm"
            log "INFO" "Using default build command: $build_command"
        else
            # add source file and program name to build command
            program_name="${program_name}_${build_command// /_}"
            build_command="$build_command -o $program_name $abs_source_file -lm"
            log "INFO" "Using custom build command: $build_command"
        fi

        # Build program
        pushd "$build_dir" > /dev/null
        log "INFO" "Building in directory: $(pwd)"
        log "INFO" "Executing: $build_command"
        
        # Check if source file exists first
        if [ ! -f "$abs_source_file" ]; then
            log "ERROR" "Source file not found: $abs_source_file"
            log "ERROR" "Current directory: $(pwd)"
            popd > /dev/null
            return
        fi
        
        eval "$build_command"
        local build_status=$?
        popd > /dev/null

        # Check build status
        if [ $build_status -ne 0 ]; then
            log "ERROR" "Build command failed with status: $build_status"
            return
        fi

        # Check if build was successful
        local built_program="$build_dir/$program_name"
        if [ ! -f "$built_program" ]; then
            log "ERROR" "Build failed. Program not found: $built_program"
            return
        fi
        
        log "INFO" "Build successful!"
        echo "$built_program"
    fi
}