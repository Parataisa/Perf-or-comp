CC = gcc
CFLAGS = -Wall -Wextra -g -O2 -fPIC
LDFLAGS = -shared

SRC_NONTS = my_malloc.c
OBJ_NONTS = $(SRC_NONTS:.c=.o)
LIB_TARGET = libarena_malloc.so

# Two different test executables
MALLOC_TEST = malloctest
ARENA_TEST = malloctest_arena

.PHONY: all clean

all: $(LIB_TARGET) $(MALLOC_TEST) $(ARENA_TEST)

$(LIB_TARGET): $(OBJ_NONTS)
	$(CC) $(LDFLAGS) -o $@ $^ -ldl

# Standard malloc test
$(MALLOC_TEST): malloctest.c
	$(CC) $(CFLAGS) -o $@ $< -lpthread

# Arena malloc test with ARENA_MALLOC_H defined
$(ARENA_TEST): malloctest.c $(LIB_TARGET)
	$(CC) $(CFLAGS) -DARENA_MALLOC_H -o $@ $< -L. -larena_malloc -lpthread -Wl,-rpath,.

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ_NONTS) $(OBJ_TS) $(LIB_TARGET) $(MALLOC_TEST) $(ARENA_TEST)