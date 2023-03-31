cmake_minimum_required(VERSION 3.2)

project(test)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_BUILD_TYPE Release)
set(CMAKE_CXX_FLAGS "-Wall -Wextra")
set(CMAKE_CXX_FLAGS_RELEASE "-std=c++14 -O3")

set(CMAKE_INSTALL_PREFIX ${PROJECT_SOURCE_DIR})
set(INSTALL_BIN_DIR ${PROJECT_SOURCE_DIR}/bin)

set(SOURCE_FILES main.cpp)

add_executable(main ${SOURCE_FILES})

install(TARGETS main DESTINATION ${INSTALL_BIN_DIR})
