CC = gcc
CFLAGS = -Wall -Wextra -g -O2 -fPIC
LDFLAGS = -shared

# Non-thread-safe version
SRC_NONTS = my_malloc.c
OBJ_NONTS = $(SRC_NONTS:.c=.o)
LIB_TARGET_NONTS = libarena_malloc.so

# Thread-safe version
SRC_TS = my_malloc_threadsave.c
OBJ_TS = $(SRC_TS:.c=.o)
LIB_TARGET_TS = libarena_malloc_ts.so

MALLOC_TEST = malloctest

.PHONY: all clean

all: $(LIB_TARGET_NONTS) $(LIB_TARGET_TS) $(MALLOC_TEST)

# Non-thread-safe version
$(LIB_TARGET_NONTS): $(OBJ_NONTS)
	$(CC) $(LDFLAGS) -o $@ $^ -ldl

# Thread-safe version
$(LIB_TARGET_TS): $(OBJ_TS)
	$(CC) $(LDFLAGS) -o $@ $^ -ldl -lpthread

$(MALLOC_TEST): malloctest.c
	$(CC) $(CFLAGS) -o $@ $^ -lpthread

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ_NONTS) $(OBJ_TS) $(LIB_TARGET_NONTS) $(LIB_TARGET_TS) $(MALLOC_TEST)