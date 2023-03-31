cmake_minimum_required(VERSION 3.2)

project(microbenchmark)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_BUILD_TYPE Release)
set(CMAKE_CXX_FLAGS "-Wall -Wextra")
set(CMAKE_CXX_FLAGS_RELEASE "-std=c++14 -O3")

set(CMAKE_INSTALL_PREFIX ${PROJECT_SOURCE_DIR})

set(INSTALL_BIN_DIR ${PROJECT_SOURCE_DIR}/bin)

add_subdirectory(src)
