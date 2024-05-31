#include <stdio.h>
#include <stdlib.h>

#define EXIT_INPUT 100
#define EXIT_LENGTH 101
#define EXIT_MEM 102

#define MAX_SIZE
// number of symbols [a-z] and [A-Z]
#define NUM_ALPHABET 52
#define IN_ALPHABET(letter) (((letter >= 'a' && letter <= 'z') || \
                              (letter >= 'A' && letter <= 'Z') \
                             ) ? 1 : 0)
#define INIT_SIZE 10

int read_and_check_line(unsigned char **line, size_t *size);
int compare_lines(unsigned char *line1, unsigned char *line2, size_t size);
void shift(unsigned char *line, size_t size, size_t offset);
char encrypt(unsigned char *letter, size_t offset);
int check_error(int ret1, int ret2, size_t size1, size_t size2);
void print_error(int ret);

int main() {
  int ret, ret1, ret2;
  size_t size1 = INIT_SIZE, size2 = INIT_SIZE;
  unsigned char *ciphered_line, *guessed_line;
  ciphered_line = (unsigned char*)malloc((size1 + 1) * sizeof(unsigned char));
  guessed_line = (unsigned char*)malloc((size2 + 1) * sizeof(unsigned char));

  ret1 = read_and_check_line(&ciphered_line, &size1);
  ret2 = read_and_check_line(&guessed_line, &size2);
  ret = check_error(ret1, ret2, size1, size2);

  if (ret == EXIT_SUCCESS) {
    size_t best_offset = compare_lines(ciphered_line, guessed_line, size1);
    // decipher the ciphered line
    if (best_offset != 0){
      for (int i=0; i< best_offset; i++) {
          shift(ciphered_line, size1, 1);
      }
    }
    printf("%s\n", ciphered_line);
  }

  free(ciphered_line);
  free(guessed_line);
  print_error(ret);
  return ret;
}
// read one line from input
// (when function is called more times it will read next lines)
int read_and_check_line(unsigned char **line, size_t *size) {
  int error = EXIT_SUCCESS;
  size_t i = 0;
  if (*line) {
    char r;
    while ((r = getchar()) != EOF) {

      // if does not match conditions
      if (!IN_ALPHABET(r) && (r != '\n'))
        return EXIT_INPUT;

      // if actual size is larger than thought
      if (*size == i) {
        unsigned char *temp_line = (unsigned char*)realloc(*line, (2 * *size + 1) * sizeof(unsigned char));
        if (!temp_line) {
          error = EXIT_MEM;
          free(*line);
          *line = NULL;
          break;
        }
        // change origin line to the larger one saving elements
        *line = temp_line;
        *size *= 2;
      }
      if (r == '\n') {
        // finish the line and exit loop
        (*line)[i++] = '\0';
        break;
      }
      (*line)[i++] = r;
    }
  } else {
    error = EXIT_MEM;
    free(*line);
    *line = NULL;
  }
  // problem with reading
  if (*line && i == 0) {
      free(*line);
      *line = NULL;
  }
  if (*line && i > 0 && i < *size) {
    // delete empty cells in line
    unsigned char *temp_line = (unsigned char*)realloc(*line, i * sizeof(unsigned char));
    if (!temp_line) {
        error = EXIT_MEM;
        free(*line);
        *line = NULL;
    } else {
      *line = temp_line;
      // ignore the last sign '\0'
      *size = i-1;
    }
  }
  return error;
}
// compare ciphered and guessed line
int compare_lines(unsigned char *line1, unsigned char *line2, size_t size) {
  size_t best_offset = 0;
  size_t offset = 0;
  size_t best_count = 0;
  size_t count = 0;

  // iterate until all letters in the alphabet
  // have been passed
  for (size_t j = 0; j <= NUM_ALPHABET; j++) {
    count = 0;
    if (offset != 0)
      shift(line1, size, 1);
    for (size_t i = 0; i < size; i++) {
      if (line1[i] == line2[i]) {
        // increase num of match
        count++;
      }
    }
    // save the best match
    if (count > best_count) {
      best_count = count;
      // save the offset in best match case
      best_offset = offset;
    }
    offset++;
  }
  return best_offset;
}
// encrypt letters using encrypt function
void shift(unsigned char *line, size_t size, size_t offset) {
  for (size_t i = 0; i < size; i++) {
    line[i] = encrypt(&line[i], offset);
  }
}
// Caesar method to encrypt letter
char encrypt(unsigned char *letter, size_t offset) {
  if (*letter == 'z')
      *letter = 'A';
    else if (*letter == 'Z')
      *letter = 'a';
    else if (*letter != '\0')
      *letter += offset;
  return *letter;
}
// check for errors
int check_error(int ret1, int ret2, size_t size1, size_t size2) {
  int ret = EXIT_SUCCESS;
  if ((ret1 == EXIT_SUCCESS) && (ret2 == EXIT_SUCCESS) &&
                                          (size1 != size2)) {
      ret = EXIT_LENGTH;
  } else if (ret1 != EXIT_SUCCESS)
      ret = ret1;
    else if (ret2 != EXIT_SUCCESS)
      ret = ret2;
  return ret;
  }
// print error message in stderr
void print_error(int ret) {
  switch (ret) {
  case EXIT_INPUT:
    fprintf(stderr, "Error: Chybny vstup!\n");
    break;
  case EXIT_LENGTH:
    fprintf(stderr, "Error: Chybna delka vstupu!\n");
    break;
  case EXIT_MEM:
    fprintf(stderr, "Error: Chyba alokace pameti!\n");
  }
}
