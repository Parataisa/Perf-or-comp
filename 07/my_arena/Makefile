CC = gcc
CFLAGS = -Wall -Wextra -g -O2 -fPIC
LDFLAGS = -shared

SRC_NONTS = my_malloc.c
OBJ_NONTS = $(SRC_NONTS:.c=.o)
LIB_TARGET = libarena_malloc.so

MALLOC_TEST = malloctest

.PHONY: all clean

all: $(LIB_TARGET) $(MALLOC_TEST)

$(LIB_TARGET): $(OBJ_NONTS)
	$(CC) $(LDFLAGS) -o $@ $^ -ldl

$(MALLOC_TEST): malloctest.c
	$(CC) $(CFLAGS) -o $@ $^ -lpthread

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ_NONTS) $(OBJ_TS) $(LIB_TARGET) $(MALLOC_TEST)