# Makefile for Load Generator Tools

# Compiler and flags
CC = gcc
CFLAGS = -Wall -Wextra -O3 -fopenmp
LDFLAGS = -fopenmp -lm

# Targets
TARGETS = loadgen loadcapture loadprofile loadtest
BUILD_DIR = ./

# Object files
COMMON_OBJ = loadutils.o
LOADGEN_OBJ = loadgen.o $(COMMON_OBJ)
LOADCAPTURE_OBJ = loadcapture.o $(COMMON_OBJ)
LOADPROFILE_OBJ = loadprofile.o $(COMMON_OBJ)
LOADTEST_OBJ = loadtest.o $(COMMON_OBJ)

# Default target
all: create_build_dir $(TARGETS)

create_build_dir:
	@mkdir -p $(BUILD_DIR)

loadutils.o: loadutils.c loadutils.h
	$(CC) $(CFLAGS) -c $< -o $@

loadgen.o: loadgen.c loadutils.h
	$(CC) $(CFLAGS) -c $< -o $@

loadgen: $(LOADGEN_OBJ)
	$(CC) $(CFLAGS) $^ -o $(BUILD_DIR)/$@ $(LDFLAGS)

loadcapture.o: loadcapture.c loadutils.h
	$(CC) $(CFLAGS) -c $< -o $@

loadcapture: $(LOADCAPTURE_OBJ)
	$(CC) $(CFLAGS) $^ -o $(BUILD_DIR)/$@ $(LDFLAGS)

loadprofile.o: loadprofile.c loadutils.h
	$(CC) $(CFLAGS) -c $< -o $@

loadprofile: $(LOADPROFILE_OBJ)
	$(CC) $(CFLAGS) $^ -o $(BUILD_DIR)/$@ $(LDFLAGS)

loadtest.o: loadtest.c loadutils.h
	$(CC) $(CFLAGS) -c $< -o $@

loadtest: $(LOADTEST_OBJ)
	$(CC) $(CFLAGS) $^ -o $(BUILD_DIR)/$@ $(LDFLAGS)

clean:
	rm -f *.o
	rm -f $(addprefix $(BUILD_DIR)/, $(TARGETS))

install: all
	@mkdir -p $(DESTDIR)/bin
	cp $(addprefix $(BUILD_DIR)/, $(TARGETS)) $(DESTDIR)/bin/

# Phony targets
.PHONY: all clean install create_build_dir