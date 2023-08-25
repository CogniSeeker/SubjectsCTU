/*This program prints out the house based on
 the parameters in scanf: width, height and 
 height of fence (certain conditions)*/

#include <stdio.h>
#include <stdlib.h>

//EXIT
#define EXIT_INPUT 100
#define EXIT_RANGE 101
#define EXIT_NOT_ODD 102
#define EXIT_FENCE 103

#define MIN_VALUE 3
#define MAX_VALUE 69
#define CORRECT_INPUT(num) (num == 2 ? 1 : 0)
#define NUM_IS_ODD(num) (num % 2 != 0 ? 1 : 0)
#define CORRECT_HOUSE_RANGE(w, h) (((w >= MIN_VALUE) && (h >= MIN_VALUE) && \
                                   (w <= MAX_VALUE) && (h <= MAX_VALUE)) \
                                     ? 1 : 0)
#define CORRECT_FENCE_RANGE(f) (((f < *height) && (f > 0)) ? 1 : 0)
#define MY_SPACE ' ' 
#define MY_X 'X'
#define FENCE_STICK '|'
#define FENCE_PARTITION '-'
#define FILL_SYMBOL1 'o'
#define FILL_SYMBOL2 '*'

int read_input(int *ret, int *width, int *height, int *fence);
void print_house(int width, int height, int fence);
void print_roof(int width);
void print_emplty_rectangle(int width, int height);
void print_rectangle_with_fence(int width, int height, int fence);
void print_fence_pattern(int fence, int width, int height, int position);
void print_error(int ret);

int main() {
  int width, height, fence;
  int ret;
  ret = read_input(&ret, &width, &height, &fence);
  if (ret == EXIT_SUCCESS)
    print_house(width, height, fence);
  print_error(ret);
  return ret; 
} 
// function reads, checks input value and return success or error code
int read_input(int *ret, int *width, int *height, int *fence) {
  *ret = EXIT_SUCCESS;
  int num_inputs = scanf("%d %d", &*width, &*height);
  if (CORRECT_INPUT(num_inputs)) {
    if (!CORRECT_HOUSE_RANGE(*width, *height))
      *ret = EXIT_RANGE;
    else if (!NUM_IS_ODD(*width))
      *ret = EXIT_NOT_ODD;
    else if (*width == *height) {
      //read the 3rd value to build a fence
      int fence_input = scanf("%d", &*fence); 
      if (!fence_input)
        *ret = EXIT_INPUT;
      else if (!CORRECT_FENCE_RANGE(*fence))
        *ret = EXIT_FENCE;
    }
  }
  else
    *ret = EXIT_INPUT;
  return *ret;
}
//function prints the house
void print_house(int width, int height, int fence) {
  print_roof(width);
  if (fence)
    print_rectangle_with_fence(width, height, fence);
  else
    print_emplty_rectangle(width, height);
}
//function prints the roof of house
void print_roof(int width) {
  for (int i = 0; i < width / 2; ++i) {
      for (int j = width / 2 - i; j > 0; --j)
        putchar(MY_SPACE);
      putchar(MY_X);
      if (i == 0)
        printf("\n");
      else {
        for (int k = width - i*2+1; k < width; k++)
          putchar(MY_SPACE);
        putchar(MY_X);
        printf("\n");
      }
  }
}
// function prints the empty rectangle
void print_emplty_rectangle(int width, int height) {
  for (int i = 0; i < height; i++) {
    if (i == 0 || i == height-1) {
      // on the line below (j) goes to (width-1) because the last MY_X is printed later
      for (int j = 0; j < width-1; j++) 
        putchar(MY_X);
    }
    else {
      putchar(MY_X); 
      for (int j = 0; j < width - 2; j++)
        putchar(MY_SPACE);
    }
    putchar(MY_X); // print last MY_X symbol
    printf("\n");
  }
}
// function prints the rectangle with fence
void print_rectangle_with_fence(int width, int height, int fence) {
    for (int i = 0; i < height; i++) {
      putchar(MY_X);
      for (int j = 0; j < width - 2; j++) {
        // build top and bottom of house
        if (i == 0 || i == height - 1)
          putchar(MY_X);
        else {  
          // fill the house inside with symbols
          if ((j + i) % 2 == 1)
            putchar(FILL_SYMBOL1);
          else
            putchar(FILL_SYMBOL2);
        }
      }
      putchar(MY_X);
    // print fence pattern that depends on the current value i
    print_fence_pattern(fence, width, height, i);
    printf("\n");
  }
}
// function provides and prints a fence pattern
void print_fence_pattern(int fence, int width, int height, int position) {
  char first_symbol = FENCE_PARTITION;
  char second_symbol = FENCE_STICK;
  if (NUM_IS_ODD(fence)) {
    first_symbol = FENCE_STICK;
    second_symbol = FENCE_PARTITION;
  }
  // build top and bottom of fence
  if ((fence == height - position) || (position == height-1)) {
    for (int i = 0; i < fence-1; i+=2) {
      putchar(first_symbol);
      putchar(second_symbol);
    }
    if (first_symbol == FENCE_STICK)
      putchar(first_symbol);
  }
  // build the rest of the fence
  else if (fence > height - position) {
    if (NUM_IS_ODD(fence))
      second_symbol = MY_SPACE;
    else
      first_symbol = MY_SPACE;
    for (int i = 0; i < fence-1; i+=2) {
      putchar(first_symbol);
      putchar(second_symbol);
    }
    if (first_symbol == FENCE_STICK)
      putchar(first_symbol);
  }
}
//function prints error messages in stderr
void print_error(int ret) {
  switch (ret) {
  case EXIT_INPUT:
    fprintf(stderr, "Error: Chybny vstup!\n");
    break;
  case EXIT_RANGE:
    fprintf(stderr, "Error: Vstup mimo interval!\n");
    break;
  case EXIT_NOT_ODD:
    fprintf(stderr, "Error: Sirka neni liche cislo!\n");
    break;
  case EXIT_FENCE:
    fprintf(stderr, "Error: Neplatna velikost plotu!\n");
    break;
  }
}
