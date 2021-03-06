cmake_minimum_required(VERSION 3.10)
project(ch LANGUAGES CXX C)

# NOTE: To let the package installed in the system take precedence, use
# PATHS, to have the given path take precedence, use HINTS.
find_package(CASPER REQUIRED PATHS "../../../../compiler")

casper_add_exec(ch ch.meta
  SOURCES ch.meta.cpp
  PLATFORM platform.ini
  TUNED_PARAMS tuned-params.ini
  RUNTIME_CFG crt.ini
  )

# TODO: workaround: the app has to set Python_SITELIB explicitly.
# The site-packages subdir not appended automatically, even if we import
# 'site' module, and even if wa call site.main() -- double-check the latter
# part, though.
find_package(Python COMPONENTS Interpreter REQUIRED) # for Python_SITELIB
find_package(PkgConfig REQUIRED)
pkg_search_module(PETSC REQUIRED petsc PETSc)

string(JOIN : EXTRA_PYTHONPATH ${CMAKE_CURRENT_SOURCE_DIR}
  ${CASPER_PYAPI_DIR} ${Python_SITELIB} ${PETSC_LIBDIR})

# Run the target program (test target)
# TODO: burn the EXTRA_PYTHONPATH into the metaprogram somehow
add_custom_target(ch.run
  ${CMAKE_COMMAND} -E env
    XDG_CACHE_HOME=cachedir
    EXTRA_PYTHONPATH="${EXTRA_PYTHONPATH}"
    ${ch_BUILD_DIR}/ch
  DEPENDS ${ch_BUILD_DIR}/ch)
add_custom_target(ch.mpirun
  ${CMAKE_COMMAND} -E env
    XDG_CACHE_HOME=cachedir
    EXTRA_PYTHONPATH="${EXTRA_PYTHONPATH}"
    mpirun -x XDG_CACHE_HOME -x EXTRA_PYTHONPATH
    -n $$\{RANKS:-1\} --map-by $$\{MAPBY:-slot\} ${ch_BUILD_DIR}/ch
  DEPENDS ${ch_BUILD_DIR}/ch)
