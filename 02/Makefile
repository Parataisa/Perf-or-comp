# Makefile for the Performance Testing Framework

# Configuration
CONFIG_FILE := test_config.txt
CC := gcc
CFLAGS := -Wall -O3 -pthread

.PHONY: clean test check-config sample-config test-with-io-load

# Default target
all: check-config $(BINS)

# Check if the config file exists, create a sample one if it doesn't
check-config:
	@if [ ! -f "$(CONFIG_FILE)" ]; then \
		echo "Config file not found. Creating a sample config..."; \
		./performance_test.sh; \
	fi

# Create a sample config file
sample-config:
	@echo "Creating a sample config file..."
	@./performance_test.sh

# Run the tests
test: check-config
	@echo "Running performance tests..."
	@./performance_test.sh $(CONFIG_FILE)


# IO-loadgen
loadgen_io: loadgen_io.c
	$(CC) $(CFLAGS) -o $@ $^

# Run tests with I/O load simulation
test-with-io-load: loadgen_io check-config
	@echo "Running performance tests with IO load simulation..."
	@./run_tests_with_io_load.sh $(CONFIG_FILE)

# Clean up
clean:
	rm -f loadgen_io
	rm -rf io_load