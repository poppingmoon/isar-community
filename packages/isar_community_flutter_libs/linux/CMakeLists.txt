cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "isar_community_flutter_libs")
project(${PROJECT_NAME} LANGUAGES CXX)

include("../cargokit/cmake/cargokit.cmake")
apply_cargokit(${PROJECT_NAME} packages/isar_core_ffi isar "")

# List of absolute paths to libraries that should be bundled with the plugin
set(isar_community_flutter_libs_bundled_libraries
  "${${PROJECT_NAME}_cargokit_lib}"
  PARENT_SCOPE
)
