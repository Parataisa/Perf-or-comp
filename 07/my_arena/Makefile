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

clean:
	rm -f $(OBJ) $(LIB_TARGET) $(MALLOC_TEST)