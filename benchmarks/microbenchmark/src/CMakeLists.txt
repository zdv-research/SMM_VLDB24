set(SOURCE_FILES bench.cpp)

add_executable(bench ${SOURCE_FILES})

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
target_link_libraries(bench PRIVATE Threads::Threads)

FIND_PACKAGE( TBB REQUIRED )
target_link_libraries(bench PRIVATE tbb)

install(TARGETS bench DESTINATION ${INSTALL_BIN_DIR})