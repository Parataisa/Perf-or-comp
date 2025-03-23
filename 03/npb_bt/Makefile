# Makefile for NPB BT programs
# Place this in the same directory as your CMakeLists.txt

.PHONY: all clean build run gprof-all gprof-w gprof-s gprof-a gprof-b gprof-c

# Configuration
BUILD_DIR := build
CMAKE_FLAGS := -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
PROGRAMS := npb_bt_w npb_bt_s npb_bt_a npb_bt_b npb_bt_c

# Build targets
all: build

build:
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && cmake .. $(CMAKE_FLAGS)
	@cd $(BUILD_DIR) && ninja

# Run all programs
run: build
	@echo "Running all NPB BT programs..."
	@for prog in $(PROGRAMS); do \
		echo "\n=== Running $$prog ==="; \
		(cd $(BUILD_DIR) && ./$$prog); \
		echo "=== $$prog completed ==="; \
	done

# Run individual programs
run-w: build
	@echo "Running NPB BT W class..."
	@cd $(BUILD_DIR) && ./npb_bt_w

run-s: build
	@echo "Running NPB BT S class..."
	@cd $(BUILD_DIR) && ./npb_bt_s

run-a: build
	@echo "Running NPB BT A class..."
	@cd $(BUILD_DIR) && ./npb_bt_a

run-b: build
	@echo "Running NPB BT B class..."
	@cd $(BUILD_DIR) && ./npb_bt_b

run-c: build
	@echo "Running NPB BT C class..."
	@cd $(BUILD_DIR) && ./npb_bt_c

# Profiling targets
gprof-all: build
	@echo "Running and profiling all programs..."
	@for prog in $(PROGRAMS); do \
		echo "\n=== Profiling $$prog ==="; \
		(cd $(BUILD_DIR) && ./$$prog && gprof ./$$prog gmon.out > $${prog}_profile.txt); \
		echo "Profile saved to $(BUILD_DIR)/$${prog}_profile.txt"; \
		echo "=== $$prog profiling completed ==="; \
	done

# Individual profiling targets
gprof-w: build
	@echo "Profiling NPB BT W class..."
	@cd $(BUILD_DIR) && ./npb_bt_w && gprof ./npb_bt_w gmon.out > npb_bt_w_profile.txt
	@echo "Profile saved to $(BUILD_DIR)/npb_bt_w_profile.txt"	

gprof-s: build
	@echo "Profiling NPB BT S class..."
	@cd $(BUILD_DIR) && ./npb_bt_s && gprof ./npb_bt_s gmon.out > npb_bt_s_profile.txt
	@echo "Profile saved to $(BUILD_DIR)/npb_bt_s_profile.txt"

gprof-a: build
	@echo "Profiling NPB BT A class..."
	@cd $(BUILD_DIR) && ./npb_bt_a && gprof ./npb_bt_a gmon.out > npb_bt_a_profile.txt
	@echo "Profile saved to $(BUILD_DIR)/npb_bt_a_profile.txt"
	
gprof-b: build
	@echo "Profiling NPB BT B class..."
	@cd $(BUILD_DIR) && ./npb_bt_b && gprof ./npb_bt_b gmon.out > npb_bt_b_profile.txt
	@echo "Profile saved to $(BUILD_DIR)/npb_bt_b_profile.txt"

gprof-c: build
	@echo "Profiling NPB BT C class..."
	@cd $(BUILD_DIR) && ./npb_bt_c && gprof ./npb_bt_c gmon.out > npb_bt_c_profile.txt
	@echo "Profile saved to $(BUILD_DIR)/npb_bt_c_profile.txt"

# Clean everything
clean:
	rm -rf $(BUILD_DIR)