cmake_minimum_required(VERSION 3.14)
project(right_click_menu_manager LANGUAGES CXX)

set(BINARY_NAME "right_click_menu_manager")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Configure build type
if(NOT CMAKE_BUILD_TYPE OR CMAKE_BUILD_TYPE STREQUAL "")
  set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type" FORCE)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

add_subdirectory("${FLUTTER_MANAGED_DIR}" "${CMAKE_BINARY_DIR}/flutter")

add_subdirectory("runner")

set(PLUGIN_BUNDLED_LIBRARIES "")
foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory("plugins/${plugin}" "${CMAKE_BINARY_DIR}/plugins/${plugin}")
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE ${PLUGIN_BUNDLED_LIBRARIES})

foreach(bundle ${FLUTTER_BUNDLED_LIBRARIES})
  target_link_libraries(${BINARY_NAME} PRIVATE ${bundle})
endforeach(bundle)

if(PLUGIN_BUNDLED_LIBRARIES)
  target_link_libraries(${BINARY_NAME} PRIVATE ${PLUGIN_BUNDLED_LIBRARIES})
endif()

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

set_target_properties(${BINARY_NAME} PROPERTIES
  WIN32_EXECUTABLE TRUE
)

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${INSTALL_BUNDLE_DIR}")
