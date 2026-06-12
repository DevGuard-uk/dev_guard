# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(devguard_core_library VERSION 0.0.1 LANGUAGES C)

add_library(devguard_core SHARED
  "devguard_core.c"
)

set_target_properties(devguard_core PROPERTIES
  PUBLIC_HEADER devguard_core.h
  OUTPUT_NAME "devguard_core"
)

target_compile_definitions(devguard_core PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(devguard_core PRIVATE "-Wl,-z,max-page-size=16384")
endif()
