HW=hw03
TARGET = main
TEST_DIR = testing_files

CC = clang
CFLAGS = -pedantic -Wall -std=c99 -O3 -g
ZIP=zip

DATA_DIR = $(TEST_DIR)/data
RANDOM_DATA_DIR = $(TEST_DIR)/files
MY_OUTPUTS_DIR = $(TEST_DIR)/my_outputs
DIFFS_DIR = $(TEST_DIR)/diffs
VALGRIND_DIR = $(TEST_DIR)/valgrind_logs

GREP_VALGRIND = grep -E "ERROR SUMMARY|LEAK SUMMARY|definitely lost|indirectly lost|possibly lost|still reachable"
VALGRIND_OPTS = --leak-check=full --show-leak-kinds=all --track-origins=yes --verbose

.PHONY: all test_random test_data clean valgrind

all: $(TARGET)

$(TARGET): $(TARGET).c
	$(CC) $(CFLAGS) -o $@ $<

generate_solutions:
	cd $(TEST_DIR) && ./generate_solutions.sh

zip:
	$(ZIP) $(HW)-brute.zip $(TARGET).c

test_random: $(TARGET) generate_solutions
	mkdir -p $(MY_OUTPUTS_DIR)
	mkdir -p $(DIFFS_DIR)
	
	for input in $(RANDOM_DATA_DIR)/*.in; do \
		filename=$$(basename "$$input" .in); \
		./$(TARGET) < "$$input" > \
		"$(MY_OUTPUTS_DIR)/$$filename.out" 2> "$(MY_OUTPUTS_DIR)/$$filename.err"; \
		if ! diff -u "$(RANDOM_DATA_DIR)/$$filename.out" \
		"$(MY_OUTPUTS_DIR)/$$filename.out" > "$(DIFFS_DIR)/$$filename.out.diff"; then \
			echo "Differences found in $$filename.out"; \
		else \
			rm "$(DIFFS_DIR)/$$filename.out.diff"; \
		fi; \
		if ! diff -u "$(RANDOM_DATA_DIR)/$$filename.err" \
		"$(MY_OUTPUTS_DIR)/$$filename.err" > "$(DIFFS_DIR)/$$filename.err.diff"; then \
			echo "Differences found in $$filename.err"; \
		else \
			rm "$(DIFFS_DIR)/$$filename.err.diff"; \
		fi; \
	done

test_data: $(TARGET) 
	mkdir -p $(MY_OUTPUTS_DIR)
	mkdir -p $(DIFFS_DIR)
	
	for input in $(DATA_DIR)/*.in; do \
		filename=$$(basename "$$input" .in); \
		./$(TARGET) < "$$input" \
		> "$(MY_OUTPUTS_DIR)/$$filename.out" 2> "$(MY_OUTPUTS_DIR)/$$filename.err"; \
		if ! diff -u "$(DATA_DIR)/$$filename.out" \
		 "$(MY_OUTPUTS_DIR)/$$filename.out" > "$(DIFFS_DIR)/$$filename.out.diff"; then \
			echo "Differences found in $$filename.out"; \
		else \
			rm "$(DIFFS_DIR)/$$filename.out.diff"; \
		fi; \
		if ! diff -u "$(DATA_DIR)/$$filename.err" \
		"$(MY_OUTPUTS_DIR)/$$filename.err" > "$(DIFFS_DIR)/$$filename.err.diff"; then \
			echo "Differences found in $$filename.err"; \
		else \
			rm "$(DIFFS_DIR)/$$filename.err.diff"; \
		fi; \
	done

valgrind_random: $(TARGET) generate_solutions
	mkdir -p $(VALGRIND_DIR)
	for input in $(RANDOM_DATA_DIR)/*.in; do \
		filename=$$(basename "$$input" .in); \
		valgrind $(VALGRIND_OPTS) --log-file="$(VALGRIND_DIR)/$$filename.log" \
		./$(TARGET) < "$$input" > /dev/null 2>&1; \
		$(GREP_VALGRIND) "$(VALGRIND_DIR)/$$filename.log"; \
	done

valgrind_data: $(TARGET)
	mkdir -p $(VALGRIND_DIR)
	for input in $(DATA_DIR)/*.in; do \
		filename=$$(basename "$$input" .in); \
		valgrind $(VALGRIND_OPTS) --log-file="$(VALGRIND_DIR)/$$filename.log" \
		./$(TARGET) < "$$input" > /dev/null 2>&1; \
		$(GREP_VALGRIND) "$(VALGRIND_DIR)/$$filename.log"; \
	done

clean:
	rm -rf $(TARGET) $(RANDOM_DATA_DIR) $(DIFFS_DIR) $(MY_OUTPUTS_DIR) $(VALGRIND_DIR) $(HW)-brute.zip