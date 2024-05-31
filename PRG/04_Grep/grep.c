#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#define ERROR_MEM 102
#define ERROR_OPEN_FILE 103
#define ERROR_CLOSE_FILE 104
#define ERROR_ARG 105

#define INIT_LINE_SIZE 10
#define INIT_NUM_LINE 5

char* REG_EX_PARAMETER = "-E";
char* COLOR_PARAMETER = "--color=always";
const char* RED_COLOR = "\033[01;31m\033[K";
const char* RESET_COLOR = "\033[m\033[K";

void read_arguments(
  char **argv,
  size_t argc,
  int *error,
  size_t *size,
  char **pattern, 
  char ***lines, 
  bool *color,
  bool *reg_ex
  );
char** read_text(FILE* input, int *error, size_t *line_count); 
char* read_line(FILE *input, int *error, size_t *size);
int compare(char* pattern, char* str, bool reg_ex);
size_t print_match_lines(char *pattern, char** lines, size_t size, bool color, bool reg_ex); 
bool equal_strings(char* str1, char* str2);
size_t str_len(const char *str);
void free_lines(size_t line_count, char ***str);


int main(int argc, char *argv[]) {

  // initialize main variables
  int ret = EXIT_SUCCESS;
  size_t num_lines = INIT_NUM_LINE;
  char** lines = NULL;
  char* pattern = NULL;
  bool color = false;
  bool reg_ex = false;
  size_t num_matches = 0;

  read_arguments(argv, argc, &ret, &num_lines, &pattern, &lines, &color, &reg_ex); 

  if (!ret) {
    num_matches = print_match_lines(pattern, lines, num_lines, color, reg_ex);
    if (num_matches == 0)
      ret = EXIT_FAILURE;
  }

  free_lines(num_lines, &lines);
  return ret;
}
// read all arguments, decide which type of program it is and check for errors
void read_arguments(
  char **argv,
  size_t argc,
  int *error,
  size_t *size,
  char **pattern, 
  char ***lines, 
  bool *color,
  bool *reg_ex
  ) {
  size_t line_count = 0;
  if (argc == 2) {
    // read pattern as 1st argument and lines from stdin
    *pattern = argv[1];
    *lines = read_text(stdin, error, &line_count);
  } else if (argc == 3) {
      // if first argument is COLOR_PARAMETER
      if (equal_strings(COLOR_PARAMETER, argv[1])) {
        *color = true;
        *pattern = argv[2];
        *lines = read_text(stdin, error, &line_count);
    } else if(equal_strings(REG_EX_PARAMETER, argv[1])) {
        *reg_ex = true;
        *pattern = argv[2];
        *lines = read_text(stdin, error, &line_count);
    } else {
      // read pattern as 1st argument and lines as 2nd
      *pattern = argv[1];
      const char* filename = argv[2]; 
      FILE* file = fopen(filename, "r");
      if (file) {
        *lines = read_text(file, error, &line_count);
      } else {
        *error = ERROR_OPEN_FILE;
      }
    }
  // if we have 4 parameters and COLOR_PARAMETER
  } else if ((argc == 4) && equal_strings(COLOR_PARAMETER, argv[1])) {
    *color = true;
    *pattern = argv[2];
    const char* filename = argv[3]; 
      FILE* file = fopen(filename, "r");
      if (file) {
        *lines = read_text(file, error, &line_count);
      } else {
        *error = ERROR_OPEN_FILE;
      }
  // if we have 4 parameters and REG_EX_PARAMETER
  } else if ((argc == 4) && equal_strings(REG_EX_PARAMETER, argv[1])) {
    *reg_ex = true;
    *pattern = argv[2];
    const char* filename = argv[3]; 
      FILE* file = fopen(filename, "r");
      if (file) {
        *lines = read_text(file, error, &line_count);
      } else {
        *error = ERROR_OPEN_FILE;
      }
  } else {
    *error = ERROR_ARG;
  }
  *size = line_count;
}
// read all text in file line by line
char** read_text(FILE* input, int *error, size_t *line_count) {
  size_t size = INIT_NUM_LINE;
  char** lines = (char**)malloc(size * sizeof(char*));
  *line_count = 0;
  if (lines) {
      char* str;
      size_t str_size = INIT_LINE_SIZE;
      // read every line using read function until end of file
      while (((str = read_line(input, error, &str_size)) != NULL) && !(*error)) {
          // if str does not contain only "\n"
          if ((str_size > 1) && (size == *line_count)) {
          // allocate twice more memory for lines
          char **t = (char**)realloc(lines, 2 * size * sizeof(char*));
          if (!t) {
              free_lines(*line_count, &lines);
              *error = ERROR_MEM;
              break;
          }
          lines = t;
          size = 2 * size;
          }
          // place new str to lines
          lines[*line_count] = str;
          *line_count += 1;
      }
  } else
      *error = ERROR_MEM;
  if (*error)
      free_lines(*line_count, &lines);
  else {
      // allocate the exact amount of memory for lines
      if (lines && *line_count > 0 && *line_count < size) {
          char **t = (char**)realloc(lines, *line_count * sizeof(char*));
          if (!t) {
              free_lines(*line_count, &lines);
              *error = ERROR_MEM;
          }
          lines = t;
      }
  }
  // if input was from file - close it
  if ((input != stdin) && (fclose(input) == EOF)) {
        *error = ERROR_CLOSE_FILE;
  }
  return lines;
}
// read one line from file with \n in the end
char* read_line(FILE *input, int *error, size_t *size) {
  char* str = (char*)malloc((*size + 1) * sizeof(char));
  // num of characters
  size_t i = 0;
  if (str) {
      char symbol;
      while ((symbol = fgetc(input)) != EOF) {
          if (*size == i) {
            // allocate twice more memory for str
            char *t = (char*)realloc(str, (2**size + 1)* sizeof(char));
            if (!t) {
                free(str);
                str = NULL;
                *error = ERROR_MEM;
                break;
            }
            str = t;
            *size *= 2;
          }

          //place new symbol to str
          str[i++] = symbol;
          if (symbol == '\n')
              break;
      }
  } else {
      free(str);
      str = NULL;
      *error = ERROR_MEM;
  }
  // add '\0' to the end of line
  if (str && i > 0)
      str[i++] = '\0';
  // problem with reading
  if (str && i == 0) {
      free(str);
      str = NULL;
  }
  // allocate the exact amount of memory for line
  if (str  && i > 0 && i < *size) {
      char *t = (char*)realloc(str, i * sizeof(char));
      if (!t) {
          free(str);
          str = NULL;
          *error = ERROR_MEM;
      }
      str = t;
      *size = i;
  }
  return str;
}
// compare two lines whether first is the subline of second
int compare(char*pattern, char *str, bool reg_ex) {
  size_t i = 0, j = 0;
  size_t pattern_length = str_len(pattern);
  size_t line_length = str_len(str);
  char repeated_char = '\0';
  size_t num_repeats = 0, offset_match = 0;

  // while str has not ended and subline <= the remaining str
  while ((str[i] != '\0') && (pattern_length - j <= line_length - i + 1)) {
    if (!reg_ex) {
      // if letter match - increment j
      if (str[i] == pattern[j]) {
          j++;
      } else {
          j = 0;
      }
      i++;
      if (pattern[j] == '\0') {
          // pattern is substr of str
          return true;
      }
      // grep with regular expressions [?,*,+]
    } else if (reg_ex) {
      if (str[i] == pattern[j]) {
          j++;
          i++;
          if (((pattern[j] == '?') && (str[i] != '?')) 
          || ((pattern[j] == '*') && (str[i] != '*'))
          || ((pattern[j] == '+') && (str[i] != '+'))) {
            repeated_char = pattern[j-1];
            while (str[i-1+num_repeats] == repeated_char) {
              num_repeats += 1;
            }
            if ((pattern[j] == '?') && (num_repeats == 1)) {
                offset_match = num_repeats - 1;
                i = i + offset_match;
                j++;
            }
            if (((pattern[j] == '+') || (pattern[j] == '*')) && (num_repeats >= 1)) {
              offset_match = num_repeats - 1;
              i = i + offset_match;
              j++;
            }
          }
      // for num_repeats = 0 case
      } else if((str[i] != pattern[j]) && 
                ((pattern[j+1] == '?') || 
                 (pattern[j+1] == '*'))) {
        repeated_char = pattern[j];
        num_repeats = 0;
        j += 2;

      } else {
        j = 0;
        i++;
      }
      if (pattern[j] == '\0') {
          // pattern is substr of str
          return true;
      }
    }  
  }
  //pattern is not substr of str
  return false;
}
// print line if match and return num of match
size_t print_match_lines(char *pattern, char** lines, size_t size, bool color, bool reg_ex) {
  size_t num_matches = 0;
  for (size_t i = 0; i < size; ++i) {
    if (compare(pattern, lines[i], reg_ex)) {
      num_matches++;
      //colorize pattern in lines[i] if color is true
      if (color) {
        size_t pattern_length = str_len(pattern);
        size_t line_length = str_len(lines[i]);
        size_t j, k;
        
        for (j = 0; j < line_length;) {
          if (lines[i][j] == pattern[0]) {
            bool match = true;
            for (k = 1; k < pattern_length; ++k) {
              if (lines[i][j + k] != pattern[k]) {
                match = false;
                break;
              }
            }
            if (match) {
              printf("%s", RED_COLOR);
              for (k = 0; k < pattern_length; ++k) {
                putchar(lines[i][j + k]);
              }
              printf("%s", RESET_COLOR);
              j += pattern_length;
            } else {
              putchar(lines[i][j]);
              j++;
            }
          } else {
            putchar(lines[i][j]);
            j++;
          }
        }
      } else if (!color) {
        printf("%s", lines[i]);
      }
    } 
  }
  return num_matches;
}
bool equal_strings(char* str1, char* str2) {
    int len1 = str_len(str1);
    int len2 = str_len(str2);
    if (len1 != len2) {
        return false;
    }
    for (int i = 0; i < len1; ++i) {
        if (str1[i] != str2[i]) {
            return false;
        }
    }
    return true;
}
// find the length of a string
size_t str_len(const char *str) {
    size_t len = 0;
    while (str[len] != '\0') {
        len++;
    }
    return len;
}
// print one line separately
void print_line(char *str) {
   size_t i = 0;
   while (str && str[i] != '\0') {
      putchar(str[i++]);
   }
}
// free memory used for all lines from file
void free_lines(size_t line_count, char ***str) {
   if (str && *str) {
      for (int i = 0; i < line_count; ++i) {
	    free((*str)[i]);
      }
      free(*str);
   }
   *str = NULL;
}
//print errors
void print_error(int error) {
  switch (error) {
  case ERROR_OPEN_FILE:
    fprintf(stderr, "Error: otevreni souboru!\n");
  case ERROR_CLOSE_FILE:
    fprintf(stderr, "Error: zavreni souboru!\n");
  case ERROR_MEM:
    fprintf(stderr, "Error: chyba alokace pameti!\n");
  }
}
