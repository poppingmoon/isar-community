cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "isar_community_flutter_libs")
project(${PROJECT_NAME} LANGUAGES CXX)

include("../cargokit/cmake/cargokit.cmake")
apply_cargokit(${PROJECT_NAME} packages/isar_core_ffi isar "")

add_custom_command(
  TARGET ${PROJECT_NAME}_cargokit POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy
    "${${PROJECT_NAME}_cargokit_lib}"
    "${CMAKE_CURRENT_SOURCE_DIR}/libisar.dll"
)

# List of absolute paths to libraries that should be bundled with the plugin
set(isar_community_flutter_libs_bundled_libraries
  "${CMAKE_CURRENT_SOURCE_DIR}/libisar.dll"
  PARENT_SCOPE
)
