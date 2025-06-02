CC = gcc
CFLAGS = -Wall -Wextra -O0

all: delannoy

delannoy: delannoy.c
	$(CC) $(CFLAGS) -o delannoy delannoy.c

run_test: delannoy
	bash ./benchmark.sh
	
clean:
	rm -f delannoy

.PHONY: all debug clean