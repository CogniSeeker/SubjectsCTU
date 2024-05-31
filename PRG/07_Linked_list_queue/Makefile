HW=hw07
TEST_DIR = testing_files
TARGET = hw07-testopt-stc
REFERENCE_PROGRAM = $(TEST_DIR)/b3b36prg-hw07-testopt-stc
TEST_MODE = opt.stc

CC = clang
CFLAGS = -pedantic -Wall -std=c99 -O3 -g
ZIP=zip

DATA_DIR = $(TEST_DIR)/data/$(TEST_MODE)
MY_OUTPUTS_DIR = $(TEST_DIR)/my_outputs
REFERENCE_OUTPUTS_DIR = $(TEST_DIR)/reference_outputs
DIFFS_DIR = $(TEST_DIR)/diffs
VALGRIND_DIR = $(TEST_DIR)/valgrind_logs

GREP_VALGRIND = grep -E "ERROR SUMMARY|LEAK SUMMARY|defiintely lost|indirectly lost|possibly lost|still reachable"
VALGRIND_OPTS = --leak-check=full --show-leak-kinds=all --track-origins=yes --verbose

.PHONY: all test_random test_data clean valgrind

all: $(TARGET)

$(TARGET): $(TARGET).c
	$(CC) $(CFLAGS) -o $@ $<

zip:
	$(ZIP) $(HW)-brute.zip $(TARGET).c

test: $(TARGET) 
	mkdir -p $(MY_OUTPUTS_DIR)
	mkdir -p $(DIFFS_DIR)
	mkdir -p $(REFERENCE_OUTPUTS_DIR)
	
	for input in $(DATA_DIR)/*.txt; do \
		filename=$$(basename "$$input" .txt); \
		./$(TARGET) < "$$input" \
		> "$(MY_OUTPUTS_DIR)/$$filename.out" 2> "$(MY_OUTPUTS_DIR)/$$filename.err"; \
		./$(REFERENCE_PROGRAM) < "$$input" \
		> "$(REFERENCE_OUTPUTS_DIR)/$$filename.out" 2> "$(REFERENCE_OUTPUTS_DIR)/$$filename.err"; \
		if ! diff -u "$(REFERENCE_OUTPUTS_DIR)/$$filename.out" \
		 "$(MY_OUTPUTS_DIR)/$$filename.out" > "$(DIFFS_DIR)/$$filename.out.diff"; then \
			echo "Differences found in $$filename.out"; \
		else \
			rm "$(DIFFS_DIR)/$$filename.out.diff"; \
		fi; \
	done


valgrind: $(TARGET)
	mkdir -p $(VALGRIND_DIR)
	for input in $(DATA_DIR)/*.txt; do \
		filename=$$(basename "$$input" .txt); \
		valgrind $(VALGRIND_OPTS) --log-file="$(VALGRIND_DIR)/$$filename.log" \
		./$(TARGET) < "$$input" > /dev/null 2>&1; \
		$(GREP_VALGRIND) "$(VALGRIND_DIR)/$$filename.log"; \
	done

clean:
	rm -rf $(REFERENCE_OUTPUTS_DIR) $(TARGET) $(DIFFS_DIR) $(MY_OUTPUTS_DIR) $(VALGRIND_DIR) $(HW)-brute.zip