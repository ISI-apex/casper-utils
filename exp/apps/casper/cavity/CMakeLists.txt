cmake_minimum_required(VERSION 3.10)
project(ch LANGUAGES CXX)

# NOTE: To let the package installed in the system take precedence, use
# PATHS, to have the given path take precedence, use HINTS.
find_package(CASPER REQUIRED PATHS "../../../../compiler")

casper_add_exec(cavity cavity.meta
  SOURCES cavity.meta.cpp
  PLATFORM platform.ini
  TUNED_PARAMS tuned-params.ini
  )

# TODO: workaround: the app has to set Python_SITELIB explicitly.
# The site-packages subdir not appended automatically, even if we import
# 'site' module, and even if wa call site.main() -- double-check the latter
# part, though.
find_package(Python COMPONENTS Interpreter REQUIRED) # for Python_SITELIB

# Run the target program (test target)
add_custom_target(cavity.run COMMAND ${CMAKE_COMMAND} -E env
  EXTRA_PYTHONPATH="${CMAKE_CURRENT_SOURCE_DIR}:${Python_SITELIB}"
  ${cavity_BUILD_DIR}/cavity
  DEPENDS ${cavity_BUILD_DIR}/cavity)
