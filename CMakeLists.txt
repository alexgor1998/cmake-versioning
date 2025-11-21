# The script below is generating version files to be included in the project
cmake_minimum_required(VERSION 3.20)
# In CMake < 3.20 GENERATED property doesn't propagate out of directory scope
# So it should be set manually for all BYPRODUCTS for CMake to correctly configure
project(cmake-versioning)

if(NOT DEFINED version_info_dir)
    set(version_info_dir ${CMAKE_BINARY_DIR}/versioninfo)
endif()

# Use GitVersion.cmake to obtain version info from git tags 
set(version_script GitVersion.cmake)

add_custom_target(version_info ALL
    COMMAND ${CMAKE_COMMAND}
    -DOUTPUT_DIR=${version_info_dir}
    -P ${version_script}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    SOURCES version.h.in
    BYPRODUCTS version.rc version.h
)

target_sources(version_info PRIVATE ${vesion_script})
