cmake_minimum_required(VERSION 3.16)
project(blur)

enable_testing()

# Set up language settings
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED YES)
set(CMAKE_CXX_EXTENSIONS NO)

find_package(Halide REQUIRED)

add_executable(blur_cpu blur_cpu.cpp)
add_executable(blur_gpu blur_gpu.cpp)
set(BLUR_TARGETS blur_cpu blur_gpu)
set(TARGETS fft_cpu ${BLUR_TARGETS})

add_executable(fft_cpu fft.cpp main_fft.cpp)

add_test(NAME test_blur_cpu
    COMMAND blur_cpu 0 1 1 "test_blur_cpu.csv")
add_test(NAME test_blur_gpu
    COMMAND blur_gpu 0 1 "test_blur_gpu.csv")

foreach(target ${BLUR_TARGETS})
    set_tests_properties(test_${target} PROPERTIES
                         PASS_REGULAR_EXPRESSION "Success!"
                         SKIP_REGULAR_EXPRESSION "\\[SKIP\\]")
endforeach()

foreach(target ${TARGETS})
    target_compile_options(${target}
        PRIVATE $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-O2>)

    target_link_libraries(${target}
                          PRIVATE
                          Halide::Halide
                          Halide::Tools
                          )
endforeach()
