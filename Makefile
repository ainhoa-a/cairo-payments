.PHONY: default

# Configuration
ROOT_PROJECT = .
PROJECT_NAME = repay
BUILD_DIR = build

# Default target
default: test

# All relevant targets
all: build run test

# Targets

# Compile the project
build: FORCE
	$(MAKE) clean format
	@echo "Building..."
	cairo-compile . > $(BUILD_DIR)/$(PROJECT_NAME).sierra

# Run the project
run:
	@echo "Running..."
	# TODO: enable when sample main is ready
	#cairo-run $(ROOT_PROJECT)

# Test the project
test:
	@echo "Testing everything..."
	cairo-test $(ROOT_PROJECT)

test-push:
	@echo "Testing repay_push ..."
	cairo-test $(ROOT_PROJECT) --filter repay_push

test-pull:
	@echo "Testing repay_pull ..."
	cairo-test $(ROOT_PROJECT) --filter repay_pull

# Special filter tests targets

# Run tests related to the stack
test-stack:
	@echo "Testing stack..."
	cairo-test $(ROOT_PROJECT) -f stack

# Format the project
format:
	@echo "Formatting everything..."
	cairo-format --recursive --print-parsing-errors $(ROOT_PROJECT)

# Check the formatting of the project
check-format:
	@echo "Checking formatting..."
	cairo-format --recursive --check $(ROOT_PROJECT)

# Clean the project
clean:
	@echo "Cleaning..."
	rm -rf $(BUILD_DIR)/*
	mkdir -p $(BUILD_DIR)


# FORCE is a special target that is always out of date
# It enable to force a target to be executed
FORCE: