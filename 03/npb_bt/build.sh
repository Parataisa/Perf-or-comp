#!/bin/bash
# build.sh

MODE=$1

# Load the required modules on the cluster
#module load gcc/12.2.0-gcc-8.5.0-p4pe45v # a newer version of gcc
#module load cmake/3.24.3-gcc-8.5.0-svdlhox # a newer version of cmake
#module load ninja/1.11.1-python-3.10.8-gcc-8.5.0-2oc4wj6 # the ninja build system

case $MODE in
  tracy)
    BUILD_DIR="build-tracy"
    CMAKE_OPTIONS="-ENABLE_TRACY=ON -ENABLE_GPROF=OFF"
    ;;
  gprof)
    BUILD_DIR="build-gprof"
    CMAKE_OPTIONS="-ENABLE_TRACY=OFF -ENABLE_GPROF=ON"
    ;;
  both)
    BUILD_DIR="build-both"
    CMAKE_OPTIONS="-ENABLE_TRACY=ON -ENABLE_GPROF=ON"
    ;;
  *)
    BUILD_DIR="build"
    CMAKE_OPTIONS="-ENABLE_TRACY=OFF -ENABLE_GPROF=OFF"
    ;;
esac

# Make sure build directory exists
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Configure with the right options
cmake .. -G Ninja $CMAKE_OPTIONS

# Check if build.ninja exists
if [ ! -f "build.ninja" ]; then
  echo "Error: build.ninja file not found. CMake configuration may have failed."
  exit 1
fi

# Force a rebuild by touching the source files
find ../src -name "*.c" -exec touch {} \;

# Build the project
ninja

echo "Build completed in $BUILD_DIR directory"
echo "Use make to run and analyze programs"