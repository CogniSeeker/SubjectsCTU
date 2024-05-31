#include <stdio.h>
#include <stdlib.h>

#define EXIT_INPUT 100
#define EXIT_MEM 101

#define MAX_SIZE
// number of symbols [a-z] and [A-Z]
#define NUM_ALPHABET 52
#define IN_ALPHABET(letter) (((letter >= 'a' && letter <= 'z') || \
                              (letter >= 'A' && letter <= 'Z') \
                             ) ? 1 : 0)
#define INIT_SIZE 10

typedef struct {
    unsigned char *str;
    size_t str_len;
    int error;
} LINE;

// main functions
unsigned char* read_and_check_line(size_t *size, int *error);
int compare_lines(unsigned char *line1, unsigned char *line2, size_t size);
void shift(unsigned char *line, size_t size, size_t offset);
char encrypt(unsigned char *letter, size_t offset);
int wagner_fisher(unsigned char *line1, unsigned char *line2);

// additional functions
int min(int a, int b, int c);
size_t str_len(unsigned char *str);
int check_error(int ret1, int ret2);
void print_error(int ret);

int main() {
  int ret = EXIT_SUCCESS;
  LINE ciphered_line = {NULL, INIT_SIZE, EXIT_SUCCESS};
  LINE guessed_line = {NULL, INIT_SIZE, EXIT_SUCCESS};

  ciphered_line.str = read_and_check_line(&ciphered_line.str_len, &ciphered_line.error);
  guessed_line.str = read_and_check_line(&guessed_line.str_len, &guessed_line.error);
  ret = check_error(ciphered_line.error, guessed_line.error);

  if (ret == EXIT_SUCCESS) {
    size_t best_offset = compare_lines(ciphered_line.str, guessed_line.str, ciphered_line.str_len);
    // decipher the ciphered line
    if (best_offset != 0){
      for (int i=0; i< best_offset; i++) {
          shift(ciphered_line.str, ciphered_line.str_len, 1);
      }
    }
    printf("%s\n", ciphered_line.str);
  }

  free(ciphered_line.str);
  free(guessed_line.str);
  print_error(ret);
  return ret;
}
// read one line from input
// (when function is called more times it will read next lines)
unsigned char* read_and_check_line(size_t *size, int *error) {
  unsigned char* line = (unsigned char*)malloc((*size + 1) * sizeof(unsigned char));
  *error = EXIT_SUCCESS;
  size_t i = 0;
  if (line) {
    char r;
    while ((r = getchar()) != EOF) {

      // if does not match conditions
      if (!IN_ALPHABET(r) && (r != '\n')) {
        *error = EXIT_INPUT;
        break;
      }

      // if actual size is larger than thought
      if (*size == i) {
        unsigned char *temp_line = (unsigned char*)realloc(line, (2 * *size + 1) * sizeof(unsigned char));
        if (!temp_line) {
          *error = EXIT_MEM;
          free(line);
          line = NULL;
          break;
        }
        // change origin line to the larger one saving elements
        line = temp_line;
        *size *= 2;
      }
      if (r == '\n') {
        // finish the line and exit loop
        (line)[i++] = '\0';
        break;
      }
      (line)[i++] = r;
    }
  } else {
    *error = EXIT_MEM;
    free(line);
    line = NULL;
  }
  // problem with reading
  if (line && i == 0) {
      free(line);
      line = NULL;
  }
  if (line && i > 0 && i < *size) {
    // delete empty cells in line
    unsigned char *temp_line = (unsigned char*)realloc(line, i * sizeof(unsigned char));
    if (!temp_line) {
        *error = EXIT_MEM;
        free(line);
        line = NULL;
    } else {
      line = temp_line;
      // ignore the last sign '\0'
      *size = i-1;
    }
  }
  return line;
}
// compare ciphered and guessed line
int compare_lines(unsigned char *line1, unsigned char *line2, size_t size) {
  size_t best_offset = 0;
  size_t offset = 0;
  size_t best_count = 10000;
  size_t count = 0;

  // iterate until all letters in the alphabet
  // have been passed
  for (size_t j = 0; j <= NUM_ALPHABET; j++) {
    count = 0;
    if (offset != 0)
      shift(line1, size, 1);
    count = wagner_fisher(line1, line2);
    // save the best match
    if (count < best_count) {
        
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
// Wagner-Fisher algorithm to find the edit distance between two str
// (edit distance - the min number of edits to transform 1 str to 2)
int wagner_fisher(unsigned char *line1, unsigned char *line2) {
    int len_line1 = str_len(line1);
    int len_line2 = str_len(line2);

    int **dist = (int **)malloc((len_line1 + 1) * sizeof(int *));
    for (int i = 0; i <= len_line1; ++i) {
        dist[i] = (int *)malloc((len_line2 + 1) * sizeof(int));
    }

    for (int i = 0; i <= len_line1; ++i) {
        dist[i][0] = i;
    }

    for (int j = 0; j <= len_line2; ++j) {
        dist[0][j] = j;
    }

    for (int i = 1; i <= len_line1; ++i) {
        for (int j = 1; j <= len_line2; ++j) {
            int cost = line1[i - 1] == line2[j - 1] ? 0 : 1;
            dist[i][j] = min(dist[i - 1][j] + 1, dist[i][j - 1] + 1, dist[i - 1][j - 1] + cost);
        }
    }

    int result = dist[len_line1][len_line2];

    for (int i = 0; i <= len_line1; ++i) {
        free(dist[i]);
    }
    free(dist);

    return result;
}
// find min between 3 values
int min(int a, int b, int c) {
    int min_ab = a < b ? a : b;
    return min_ab < c ? min_ab : c;
}
// find length of str
size_t str_len(unsigned char *str) {
    size_t len = 0;
    while (str[len] != '\0') {
        len++;
    }
    return len;
}
// check for errors
int check_error(int ret1, int ret2) {
  int ret = EXIT_SUCCESS;
    if (ret1 != EXIT_SUCCESS)
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
  case EXIT_MEM:
    fprintf(stderr, "Error: Chyba alokace pameti!\n");
  }
}
