CC = gcc
CFLAGS = -Wall -Wextra -g -O2 -fPIC
LDFLAGS = -shared

SRC = my_malloc.c
OBJ = $(SRC:.c=.o)
LIB_TARGET = libarena_malloc.so
MALLOC_TEST = malloctest

.PHONY: all clean test test_default test_arena

all: $(LIB_TARGET) $(MALLOC_TEST)

$(LIB_TARGET): $(OBJ)
	$(CC) $(LDFLAGS) -o $@ $^ -ldl

$(MALLOC_TEST): malloctest.c
	$(CC) $(CFLAGS) -o $@ $^ -lpthread

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Test with default system allocator
test_default: $(MALLOC_TEST)
	@echo "=== Running benchmark with default allocator ==="
	time ./$(MALLOC_TEST) 1 500 1000000 10 1000

# Test with arena allocator
test_arena: $(LIB_TARGET) $(MALLOC_TEST)
	@echo "=== Running benchmark with arena allocator ==="
	time LD_PRELOAD=./$(LIB_TARGET) ./$(MALLOC_TEST) 1 500 1000000 10 1000

# Combined benchmark
benchmark: $(LIB_TARGET) $(MALLOC_TEST)
	@echo "=== Benchmark comparison ==="
	@echo "Default allocator:"
	@time ./$(MALLOC_TEST) 12 500 1000000 10 1000
	@echo "\nArena allocator:"
	@time LD_PRELOAD=./$(LIB_TARGET) ./$(MALLOC_TEST) 12 500 1000000 10 1000

# Smaller test for debugging
debug_test: $(LIB_TARGET) $(MALLOC_TEST)
	LD_PRELOAD=./$(LIB_TARGET) ./$(MALLOC_TEST) 1 5 100 10 1000

clean:
	rm -f $(OBJ) $(LIB_TARGET) $(MALLOC_TEST)