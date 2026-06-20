cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

set(BINARY_NAME "right_click_menu_manager")

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/../runner_resource.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/Runner.rc"
)

target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")
target_compile_definitions(${BINARY_NAME} PRIVATE "UNICODE")
target_compile_definitions(${BINARY_NAME} PRIVATE "_UNICODE")

target_link_libraries(${BINARY_NAME} PRIVATE
  flutter_wrapper
  "dwmapi.lib"
)

target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_SOURCE_DIR}"
)

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${INSTALL_BUNDLE_DIR}")
