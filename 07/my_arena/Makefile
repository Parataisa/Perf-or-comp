CC = gcc
CFLAGS = -Wall -Wextra -g -O2 -fPIC
LDFLAGS = -shared

SRC_NONTS = my_malloc.c
OBJ_NONTS = $(SRC_NONTS:.c=.o)
LIB_TARGET_NONTS = libarena_malloc.so

MALLOC_TEST = malloctest

.PHONY: all clean

all: $(LIB_TARGET_NONTS) $(MALLOC_TEST)

# Non-thread-safe version
$(LIB_TARGET_NONTS): $(OBJ_NONTS)
	$(CC) $(LDFLAGS) -o $@ $^ -ldl


$(MALLOC_TEST): malloctest.c
	$(CC) $(CFLAGS) -o $@ $^ -lpthread

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ_NONTS) $(OBJ_TS) $(LIB_TARGET_NONTS) $(MALLOC_TEST)