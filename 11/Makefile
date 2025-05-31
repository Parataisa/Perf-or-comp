CC = gcc
CFLAGS = -Wall -Wextra -O3

all: delannoy

delannoy: delannoy.c
	$(CC) $(CFLAGS) -o delannoy delannoy.c

run_test: delannoy
	./benchmark.sh
clean:
	rm -f delannoy

.PHONY: all debug clean