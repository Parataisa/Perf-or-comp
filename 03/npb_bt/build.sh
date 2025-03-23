#!/bin/bash
# build.sh

MODE=$1
BUILD_DIR="build"

mkdir -p $BUILD_DIR
cd $BUILD_DIR

case $MODE in
  tracy)
    cmake .. -DENABLE_TRACY=ON -DENABLE_GPROF=OFF
    ;;
  gprof)
    cmake .. -DENABLE_TRACY=OFF -DENABLE_GPROF=ON
    ;;
  both)
    cmake .. -DENABLE_TRACY=ON -DENABLE_GPROF=ON
    ;;
  *)
    cmake .. -DENABLE_TRACY=OFF -DENABLE_GPROF=OFF
    ;;
esac

# Force a rebuild by touching the source files
find ../src -name "*.c" -exec touch {} \;

cmake --build .