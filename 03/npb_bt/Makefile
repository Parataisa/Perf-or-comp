# Makefile for NPB BT programs - Run-only version

.PHONY: all run-* gprof-* tracy-run

# Configuration
PROGRAMS := npb_bt_w npb_bt_s npb_bt_a npb_bt_b npb_bt_c

# Default target
all:
	@echo "Available targets:"
	@echo "  run-*      - Run program (e.g., run-w, run-a)"
	@echo "  gprof-*    - Run and profile with gprof (e.g., gprof-w)"
	@echo "  tracy-run  - Note that programs must be built with Tracy"

# Run targets (use standard build)
run-w:
	@echo "Running NPB BT W class..."
	@cd build && ./npb_bt_w

run-s:
	@echo "Running NPB BT S class..."
	@cd build && ./npb_bt_s

run-a:
	@echo "Running NPB BT A class..."
	@cd build && ./npb_bt_a

run-b:
	@echo "Running NPB BT B class..."
	@cd build && ./npb_bt_b

run-c:
	@echo "Running NPB BT C class..."
	@cd build && ./npb_bt_c


gprof-all: gprof-w gprof-s gprof-a gprof-b gprof-c
	@echo "Profiling complete."

# gprof targets (use gprof build)
gprof-w:
	@echo "Profiling NPB BT W class with gprof..."
	@cd build-gprof && rm -f gmon.out && ./npb_bt_w
	@cd build-gprof && if [ -f gmon.out ]; then \
		gprof ./npb_bt_w gmon.out > npb_bt_w_profile.txt && \
		echo "Profile saved to build-gprof/npb_bt_w_profile.txt"; \
	else \
		echo "Error: gmon.out not generated. Profiling failed."; \
	fi

gprof-s:
	@echo "Profiling NPB BT S class with gprof..."
	@cd build-gprof && rm -f gmon.out && ./npb_bt_s
	@cd build-gprof && if [ -f gmon.out ]; then \
		gprof ./npb_bt_s gmon.out > npb_bt_s_profile.txt && \
		echo "Profile saved to build-gprof/npb_bt_s_profile.txt"; \
	else \
		echo "Error: gmon.out not generated. Profiling failed."; \
	fi

gprof-a:
	@echo "Profiling NPB BT A class with gprof..."
	@cd build-gprof && rm -f gmon.out && ./npb_bt_a
	@cd build-gprof && if [ -f gmon.out ]; then \
		gprof ./npb_bt_a gmon.out > npb_bt_a_profile.txt && \
		echo "Profile saved to build-gprof/npb_bt_a_profile.txt"; \
	else \
		echo "Error: gmon.out not generated. Profiling failed."; \
	fi

gprof-b:
	@echo "Profiling NPB BT B class with gprof..."
	@cd build-gprof && rm -f gmon.out && ./npb_bt_b
	@cd build-gprof && if [ -f gmon.out ]; then \
		gprof ./npb_bt_b gmon.out > npb_bt_b_profile.txt && \
		echo "Profile saved to build-gprof/npb_bt_b_profile.txt"; \
	else \
		echo "Error: gmon.out not generated. Profiling failed."; \
	fi

gprof-c:
	@echo "Profiling NPB BT C class with gprof..."
	@cd build-gprof && rm -f gmon.out && ./npb_bt_c
	@cd build-gprof && if [ -f gmon.out ]; then \
		gprof ./npb_bt_c gmon.out > npb_bt_c_profile.txt && \
		echo "Profile saved to build-gprof/npb_bt_c_profile.txt"; \
	else \
		echo "Error: gmon.out not generated. Profiling failed."; \
	fi

# Tracy target (note: requires manual connection)
tracy-run:
	@echo "Programs built with Tracy are in the build-tracy directory."
	@echo "Start the Tracy profiler and then run the program you want to profile."
	@echo "Available programs in build-tracy/: $(PROGRAMS)"