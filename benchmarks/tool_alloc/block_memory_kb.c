#include <stdio.h>
#include <stdlib.h>
#include <sys/sysinfo.h>
#include <unistd.h>

int main(int argc, char *argv[]) {

    if( argc < 2 ) {   
        printf("One integer argument (block_gb) needed.\n");
        return 1;
    }

    char *a = argv[1];
    size_t blocking_kb = atoi(a);

    struct sysinfo sys_info;
    sysinfo(&sys_info);

    size_t total_b = sys_info.freeram - sys_info.freeram%4096;
    size_t blocking_b = (blocking_kb*1024);
    blocking_b = blocking_b - blocking_b%4096;

    printf("total_b=%lu\n", total_b);
    printf("blocking_b=%lu\n", blocking_b);

    printf("start blocking\n");
    char* array;
    array = malloc(blocking_b);
    for (size_t i = 0; i < blocking_b; i+=4096) {
        array[i] = 1;
    }
    printf("is blocked\n");

    if( argc != 3 ) {  
        sleep(60*60*24*365);
    }

    return 0;
}