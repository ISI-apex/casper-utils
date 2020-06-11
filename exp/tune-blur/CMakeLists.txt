cmake_minimum_required(VERSION 3.16)
project(blur)

enable_testing()

# Set up language settings
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED YES)
set(CMAKE_CXX_EXTENSIONS NO)

find_package(Halide REQUIRED)

add_executable(blur_cpu blur_cpu.cpp)

target_compile_options(blur_cpu PRIVATE $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-O2>)

target_link_libraries(blur_cpu
                      PRIVATE
                      Halide::Halide
                      Halide::Tools
                      )

add_test(NAME test_blur_cpu COMMAND blur_cpu 1 1 "test_blur_cpu.csv")
set_tests_properties(test_blur_cpu PROPERTIES
                     PASS_REGULAR_EXPRESSION "Success!"
                     SKIP_REGULAR_EXPRESSION "\\[SKIP\\]")
