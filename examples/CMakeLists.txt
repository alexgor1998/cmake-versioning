cmake_minimum_required(VERSION 3.20)

project(versioning_example)

add_executable(print_version)

target_include_directories(print_version PRIVATE ${CMAKE_BINARY_DIR}/versioninfo)

target_sources(print_version PRIVATE main.cpp)