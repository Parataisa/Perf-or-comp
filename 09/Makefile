CC = gcc 
CFLAGS = -Wall -O2 -I. -Idata_structure
LDFLAGS = 

SRCS = benchmark.c lib/args_parser.c lib/container_registry.c
DS_SRCS = data_structure/array_container.c data_structure/linkedlist_container.c
CUSTOM_SRCS = 
OBJS = $(SRCS:.c=.o) $(DS_SRCS:.c=.o) $(CUSTOM_SRCS:.c=.o)

TARGET = benchmark
all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) $(OBJS) -o $(TARGET)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

list:
	./$(TARGET) --list-containers

test-array: $(TARGET)
	./$(TARGET) array 100 4 0.2 0.5 1

test-linkedlist-seq: $(TARGET)
	./$(TARGET) linkedlist_seq 100 4 0.2 0.5 1

test-linkedlist-rand: $(TARGET)
	./$(TARGET) linkedlist_rand 100 4 0.2 0.5 1

test-all: test-array test-linkedlist-seq test-linkedlist-rand 

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean list test-array test-linkedlist-seq test-linkedlist-rand test-all