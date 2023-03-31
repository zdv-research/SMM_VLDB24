#include <sys/mman.h>
#include <iostream>
#include <fcntl.h>
#include <cassert>

#include "thread_private_mmap.h"

char* dev = "/dev/nullb0";
size_t file_size_kb = 2048;

int main(int argc, char **argv)
{
    // Default mmap
    {
        int fd = open(dev, O_RDONLY);
        assert(fd != -1);
        char* mapping = (char*)mmap(nullptr, file_size_kb * 1024, PROT_READ, MAP_PRIVATE, fd, 0);
        munmap(mapping, file_size_kb * 1024);
    }


    // Thread private mmap
    {
        int fd = open(dev, O_RDONLY);
        assert(fd != -1);
        char* mapping = (char*)mmap(nullptr, file_size_kb * 1024, PROT_READ, MAP_PRIVATE | MAP_SMM , fd, 0);
        munmap(mapping, file_size_kb * 1024);
    }

    std::cout << "SUCCESS" << std::endl;
}