CC = gcc
CFLAGS = -Wall -O2 -I. -Idata_structure -Ilib
LDFLAGS = 

# Source files
SRCS = benchmark.c lib/args_parser.c lib/container_registry.c
DS_SRCS = data_structure/array_container.c data_structure/linkedlist_sequential.c data_structure/linkedlist_random.c data_structure/unrolled_linkedlist.c
OBJS = $(SRCS:.c=.o) $(DS_SRCS:.c=.o)

# Target executable
TARGET = benchmark

# Default target
all: $(TARGET)

# Build the target
$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) $(OBJS) -o $(TARGET)

# Compile source files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean up
clean:
	rm -f $(OBJS) $(TARGET)

# Test targets
test-array:
	./$(TARGET) array 1000 1000 0.5 5

test-linkedlist-seq:
	./$(TARGET) linkedlist_seq 1000 8 0.2 5 

test-linkedlist-rand:
	./$(TARGET) linkedlist_rand 1000 8 0.2 5

test-unrolledlist:
	./$(TARGET) unrolled_linkedlist 1000 8 0.6 5

test-all: test-array test-linkedlist-seq test-linkedlist-rand

.PHONY: all clean test-array test-linkedlist-seq test-linkedlist-rand test-all