cmake_minimum_required(VERSION 3.10)
project(blur LANGUAGES CXX C)

# NOTE: To let the package installed in the system take precedence, use
# PATHS, to have the given path take precedence, use HINTS.
find_package(CASPER REQUIRED PATHS "../../../../compiler")

# Input image (pick one) (ordered by size)
set(INPUT_IMG
  casper-256x200.bmp
  #casper.bmp
  #casper-tiled10.bmp
)
configure_file(../../../data/images/${INPUT_IMG} casper.bmp COPYONLY)

casper_add_exec(blur blur.meta
  SOURCES blur.meta.cpp halide_kern.meta.cpp
  C_KERNEL_SOURCES kern.c
  PLATFORM platform.ini
  INPUT_DESC input.ini
  TUNED_PARAMS tuned-params.ini

  TRAIN_ARGS
    --test-set-fraction=0.25
    --layers=2
    --features=6
    --tolerance=0.01
    --steps=10

  # TODO: eventually these will be generated by the compilation flow
  # (i.e. will be intermediate artifacts not to be mentioned here.
  # Until then, we have mock artifacts, specified here.
  CANDIDATES blur.candidates.csv
)

# Run the target program (test target)
add_custom_target(blur.run
  COMMAND ${blur_BUILD_DIR}/blur
  DEPENDS ${blur_BUILD_DIR}/blur)
