cmake_minimum_required(VERSION 3.11)
project(perf_prog_npb_bt)

set_property(GLOBAL PROPERTY C_STANDARD 11)

# Define profiling options
set(ENABLE_TRACY OFF CACHE BOOL "Enable Tracy profiler" FORCE)
option(ENABLE_TRACY "Enable Tracy profiler" OFF)

set(ENABLE_GPROF OFF CACHE BOOL "Enable gprof profiler" FORCE)
option(ENABLE_GPROF "Enable gprof profiler" OFF)

# Base compiler options
add_compile_options(-Wall -Wextra -Wno-unknown-pragmas -Wno-unused-parameter)

# gprof setup
if(ENABLE_GPROF)
  add_compile_options(-pg)
  add_link_options(-pg)
endif()

file(GLOB_RECURSE SOURCE_FILES CONFIGURE_DEPENDS src/*.c src/*.h)

# Tracy setup
if(ENABLE_TRACY)
  # Add Tracy subdirectory to use its CMake configuration
  add_subdirectory(tracy EXCLUDE_FROM_ALL)
  
  # Add TracyClient.cpp to the build
  list(APPEND SOURCE_FILES "${CMAKE_CURRENT_SOURCE_DIR}/tracy/public/TracyClient.cpp")
  
  # Define the Tracy macros for the build
  add_compile_definitions(TRACY_ENABLE TRACY_NO_BROADCAST TRACY_ONLY_IPV4)

  # Link with required libraries for Tracy on Unix-like systems
  if(UNIX)
    link_libraries(pthread dl)
    if(${CMAKE_SYSTEM_NAME} MATCHES "BSD")
      link_libraries(execinfo)
    endif()
  endif()
endif()

link_libraries(m)

# Define all the targets
add_executable(npb_bt_w ${SOURCE_FILES})
target_include_directories(npb_bt_w PRIVATE src/w)
if(ENABLE_TRACY)
  target_include_directories(npb_bt_w PRIVATE tracy/public)
endif()

add_executable(npb_bt_s ${SOURCE_FILES})
target_include_directories(npb_bt_s PRIVATE src/s)
if(ENABLE_TRACY)
  target_include_directories(npb_bt_s PRIVATE tracy/public)
endif()

add_executable(npb_bt_a ${SOURCE_FILES})
target_include_directories(npb_bt_a PRIVATE src/a)
if(ENABLE_TRACY)
  target_include_directories(npb_bt_a PRIVATE tracy/public)
endif()

add_executable(npb_bt_b ${SOURCE_FILES})
target_include_directories(npb_bt_b PRIVATE src/b)
if(ENABLE_TRACY)
  target_include_directories(npb_bt_b PRIVATE tracy/public)
endif()

add_executable(npb_bt_c ${SOURCE_FILES})
target_include_directories(npb_bt_c PRIVATE src/c)
if(ENABLE_TRACY)
  target_include_directories(npb_bt_c PRIVATE tracy/public)
endif()