#!/bin/bash

# Script to run performance tests with I/O load generator in background

CONFIG_FILE=${1:-"test_config.txt"}
IO_THREADS=4
READ_PERCENT=30
DELAY_MS=5
MIN_FILE_SIZE=1024      
MAX_FILE_SIZE=10485760  

IO_LOAD_DIR="/tmp/io_load_$$"

# Ensure the script stops the load generator when exiting
cleanup() {
    echo "Cleaning up..."
    if [ ! -z "$LOADGEN_PID" ]; then
        echo "Stopping I/O load generator (PID: $LOADGEN_PID)"
        kill $LOADGEN_PID 2>/dev/null
        wait $LOADGEN_PID 2>/dev/null
    fi
    
    # Always clean up the temp IO directory
    if [ -d "$IO_LOAD_DIR" ]; then
        echo "Removing I/O load directory: $IO_LOAD_DIR"
        rm -rf "$IO_LOAD_DIR"
    fi
}

trap cleanup EXIT INT TERM

echo "Starting I/O load generator with files in $IO_LOAD_DIR..."
mkdir -p "$IO_LOAD_DIR"

# Start the I/O load generator in the background
./build/loadgen_io $IO_THREADS $READ_PERCENT $DELAY_MS $MIN_FILE_SIZE $MAX_FILE_SIZE 0 "$IO_LOAD_DIR" &
LOADGEN_PID=$!

if [ -z "$LOADGEN_PID" ] || ! kill -0 $LOADGEN_PID 2>/dev/null; then
    echo "Failed to start I/O load generator"
    exit 1
fi

echo "I/O load generator started with PID: $LOADGEN_PID"
echo "Waiting for I/O load to stabilize..."
sleep 5

echo "Running performance tests with I/O load..."
export RUNNING_WITH_IO_LOAD=1
export IO_LOAD_DIR="$IO_LOAD_DIR"

./performance_test.sh "$CONFIG_FILE"