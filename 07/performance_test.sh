#!/bin/bash

module load llvm/15.0.4-python-3.10.8-gcc-8.5.0-bq44zh7

TMPDIR=$(mktemp -d /tmp/benchmark-XXXXX)
echo "Working in temporary directory: $TMPDIR"
cp -r /scratch/cb761222/Perf-or-comp/07/allscale_api $TMPDIR/
cd $TMPDIR/allscale_api

# Create fresh build directory (remove old one if it exists)
rm -rf build
mkdir -p build
cd build

# Run benchmark with default allocator
echo "=== BENCHMARK 1: Default Allocator ==="
# Use fresh CMake configuration to avoid cached paths
cmake -DCMAKE_BUILD_TYPE=Release -G Ninja $TMPDIR/allscale_api/code
/usr/bin/time -v ninja > /dev/null 2> time_default.txt

# Run benchmark with RPMalloc
echo "=== BENCHMARK 2: RPMalloc ==="
ninja clean
LD_PRELOAD=/scratch/cb761222/Perf-or-comp/07/rpmalloc/bin/linux/release/x86-64/librpmalloc.so /usr/bin/time -v ninja > /dev/null 2> time_rpmalloc.txt

# Run benchmark with MiMalloc
echo "=== BENCHMARK 3: MiMalloc ==="
ninja clean
LD_PRELOAD=/scratch/cb761222/Perf-or-comp/07/mimalloc/out/release/libmimalloc.so /usr/bin/time -v ninja > /dev/null 2> time_mimalloc.txt

# Extract results
echo "=== RESULTS ==="
for file in time_*.txt; do
  alloc=$(echo $file | sed 's/time_\(.*\)\.txt/\1/')
  echo "$alloc allocator:"
  grep "User time" $file
  grep "System time" $file
  grep "Elapsed" $file
  grep "Maximum resident" $file
  echo ""
done

# Copy results back to scratch
mkdir -p /scratch/cb761222/Perf-or-comp/07/results
cp time_*.txt /scratch/cb761222/Perf-or-comp/07/results/

# Clean up
cd /scratch/cb761222/Perf-or-comp/07/
rm -rf $TMPDIR
echo "Benchmark complete. Results saved to /scratch/cb761222/Perf-or-comp/07/results/"