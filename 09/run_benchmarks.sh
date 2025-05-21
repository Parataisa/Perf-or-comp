#!/bin/bash

# Color formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Test parameters
CONTAINERS=("array" "linkedlist_seq" "linkedlist_rand")
#INS_DEL_RATIOS=("0.50")
INS_DEL_RATIOS=("0.00" "0.01" "0.10" "0.50")
ELEM_SIZES=("8" "512" "8388608")  # 8B, 512B, 8MB
CONTAINER_SIZES=("10" "1000" "100000" "10000000")
#CONTAINER_SIZES=("1000" "100000" "10000000")
READ_RATIO="0.5"  
TEST_DURATION="3" 

# Output file
RESULTS="results/benchmark_results.csv"
echo "Container,Size,ElemSize,InsDelRatio,OpsPerSecond" > $RESULTS

BENCHMARK_DIR="$(cd "$(dirname "$0")" && pwd)"
BENCHMARK_EXE="$BENCHMARK_DIR/benchmark"

eval make clean -C $BENCHMARK_DIR
eval make -C $BENCHMARK_DIR

echo -e "${BLUE}==== DATA STRUCTURE PERFORMANCE BENCHMARK ====${NC}"

# Run tests
for container in "${CONTAINERS[@]}"; do
    for size in "${CONTAINER_SIZES[@]}"; do
        for elem_size in "${ELEM_SIZES[@]}"; do      
            for ratio in "${INS_DEL_RATIOS[@]}"; do
                echo -e "${BLUE}Testing: $container, $size elements, ${elem_size}B, $ratio ins/del ratio${NC}"
                
                # Run benchmark
                OUTPUT=$($BENCHMARK_EXE $container $size $elem_size $ratio $READ_RATIO $TEST_DURATION)

                # Extract operations per second
                OPS=$(echo "$OUTPUT" | grep "Operations per second" | awk '{print $4}')
                
                if [ -z "$OPS" ]; then
                    echo -e "${RED}Error: Could not extract result${NC}"
                    continue
                fi
                
                echo -e "${GREEN}Result: $OPS ops/second${NC}"
                echo "$container,$size,$elem_size,$ratio,$OPS" >> $RESULTS
            done
        done
    done
done

eval make clean -C $BENCHMARK_DIR
echo -e "${GREEN}Testing completed! Results saved to $RESULTS${NC}"