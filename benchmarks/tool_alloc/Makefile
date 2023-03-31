CC      = gcc
CFLAGS  = -g
RM      = rm -f


default: all

all: limit_memory_to_gb block_memory_kb

limit_memory_to_gb: limit_memory_to_gb.c
	$(CC) $(CFLAGS) -o limit_memory_to_gb.bin limit_memory_to_gb.c

block_memory_kb: block_memory_kb.c
	$(CC) $(CFLAGS) -o block_memory_kb.bin block_memory_kb.c

clean veryclean:
	$(RM) limit_memory_to_gb.bin block_memory_kb.bin