cmake_minimum_required(VERSION 3.10)
project(sarbp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ standard to conform to")
set(CMAKE_CXX_STANDARD_REQUIRED YES)
set(CMAKE_CXX_EXTENSIONS NO)

# NOTE: To let the package installed in the system take precedence, use
# PATHS, to have the given path take precedence, use HINTS.
find_package(CASPER REQUIRED PATHS "../../../../compiler")
find_package(FFTW3 REQUIRED)

find_library(CNPY cnpy REQUIRED)
find_path(CNPY_INCLUDE_DIR cnpy.h
          HINTS ${CMAKE_PREFIX_PATH}
          PATH_SUFFIXES include
          REQUIRED)

# Halide tasks (generators) are defined by the upstraem app;
# the CASPER metaprogram replaces only the driver app.
set(H_SAR halide-sar-app)

set(INPUT_DATA_DIR ${H_SAR}/data/AFRL/pass1/HH_npy)

file(GLOB INPUT_DATA_FILES ${INPUT_DATA_DIR}/*)
set(INPUT_DATA_BLD_DIR input_data_dir)
file(MAKE_DIRECTORY ${INPUT_DATA_BLD_DIR})
foreach (f ${INPUT_DATA_FILES})
  get_filename_component(filename ${f} NAME)
  configure_file(${f} ${INPUT_DATA_BLD_DIR}/${filename} COPYONLY)
endforeach()

include_directories(${H_SAR})

add_library(dft ${H_SAR}/dft.cpp)
target_compile_definitions(dft PUBLIC NO_MANGLE)
#target_link_libraries(dft PUBLIC Halide::Halide Halide::ImageIO)

casper_add_exec(sarbp sarbp.meta
  SOURCES
    sarbp.meta.cpp
    ${H_SAR}/backprojection.cpp
    ${H_SAR}/img_output.cpp
    ${H_SAR}/img_plane.cpp
  C_KERNEL_SOURCES
    kern.cpp
    ${H_SAR}/PlatformData.cpp
  EXTRA_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/${H_SAR}
  EXTRA_PACKAGES FFTW3 Halide
  EXTRA_LIBRARIES
    ${CMAKE_CURRENT_BINARY_DIR}/libdft.a
    ${FFTW3_LIBRARIES}
    ${CNPY}
    Halide::Halide
    Halide::ImageIO
  PLATFORM platform.ini
  TUNED_PARAMS tuned-params.ini
)
target_link_libraries(sarbp.meta LINK_PUBLIC ${CNPY})

# TODO: try to expose ${target} as a target
add_dependencies(sarbp.link dft)

# Run the target program (test target)
add_custom_target(sarbp.run
  COMMAND ${sarbp_BUILD_DIR}/sarbp
  DEPENDS ${sarbp_BUILD_DIR}/sarbp)
