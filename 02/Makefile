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
test: check-config loadgen_io
	@echo "Running performance tests..."
	@./performance_test.sh $(CONFIG_FILE)

# IO-loadgen
loadgen_io: loadgen_io.c
	@mkdir -p build
	$(CC) $(CFLAGS) -o build/$@ $^


# Clean up
clean:
	rm -f loadgen_io
	rm -rf io_load