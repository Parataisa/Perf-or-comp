cmake_minimum_required(VERSION 3.10)
project(perf_oriented_prog_samples)

set_property(GLOBAL PROPERTY C_STANDARD 11)

if(MSVC)
  add_compile_options(/W4 /WX)
else()
  add_compile_options(-Wall -Wextra -Wpedantic -Werror)
endif()

add_executable(delannoy delannoy/delannoy.c)

add_executable(filegen filegen/filegen.c)

add_executable(filesearch filesearch/filesearch.c)

# For mmul with different sizes
foreach(SIZE 200 500 1000 1500 2000)
  add_executable(mmul${SIZE} mmul/mmul.c)
  target_compile_definitions(mmul${SIZE} PRIVATE S=${SIZE})
  set_target_properties(mmul${SIZE} PROPERTIES OUTPUT_NAME "mmul${SIZE}")
endforeach()

# For nbody with different combinations
function(add_nbody_executable NAME N M L)
  add_executable(nbody${NAME} nbody/nbody.c)
  target_compile_definitions(nbody${NAME} PRIVATE N=${N} M=${M} L=${L})
  set_target_properties(nbody${NAME} PROPERTIES OUTPUT_NAME "nbody${NAME}")
  target_link_libraries(nbody${NAME} m)
endfunction()

add_nbody_executable(500 500 50 500)
add_nbody_executable(1000 1000 100 1000)
add_nbody_executable(2000 2000 150 2000)
add_nbody_executable(1000_200 1000 200 1000)
add_nbody_executable(3000 3000 75 3000)

add_executable(qap qap/qap.c)

