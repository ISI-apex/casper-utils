cmake_minimum_required(VERSION 3.10)
project(matrix LANGUAGES CXX C)

# NOTE: To let the package installed in the system take precedence, use
# PATHS, to have the given path take precedence, use HINTS.
find_package(CASPER REQUIRED PATHS "../../../../compiler")
find_package(Halide REQUIRED)

casper_add_exec(matrix matrix.meta
  SOURCES matrix.meta.cpp halide_kern.meta.cpp
  C_KERNEL_SOURCES kern.c
  PLATFORM platform.ini
  TUNED_PARAMS tuned-params.ini
)
target_link_libraries(matrix.meta LINK_PUBLIC Halide::Halide)

# Run the target program (test target)
add_custom_target(matrix.run
  COMMAND ${matrix_BUILD_DIR}/matrix
  DEPENDS ${matrix_BUILD_DIR}/matrix)
