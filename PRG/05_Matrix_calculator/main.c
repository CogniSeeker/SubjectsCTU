#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>
 
#define ERROR_INPUT 100
#define ERROR_MEM 101
 
#define CORRECT_operation(operation) (((operation == '+')   \
                                    || (operation == '-')   \
                                    || (operation == '*'))  \
                                    ? 1 : 0)
#define PLUS_operation '+'
#define MINUS_operation '-'
#define MULTIPLY_operation '*'
 
// initialize Matrix structure
typedef struct {
    int32_t **data;
    size_t rows;
    size_t columns;
} Matrix;
 
int read_input_matrix(Matrix *matrix);
int read_math_operation(char *math_operation);
Matrix add_or_subtract_matrices(Matrix *matrix_1, Matrix *matrix_2, char operation);
Matrix multiply_matrices(Matrix *matrix_1, Matrix *matrix_2);
void print_matrix(Matrix *matrix);
void free_matrix(Matrix *matrix);
void print_error(int ret);
 
// read two matrices and math_operation from input
// and do math operation, then print it out
int main() {
    int ret = EXIT_SUCCESS;
    Matrix matrix_1 = {NULL, 0, 0};
    Matrix matrix_2 = {NULL, 0, 0};
    Matrix result_matrix = {NULL, 0, 0};
 
    char math_operation = '\0';
 
    if ((ret = read_input_matrix(&matrix_1)) != EXIT_SUCCESS) {
        free_matrix(&matrix_1);
        print_error(ret);
        return ret;
    }
 
    if ((ret = read_math_operation(&math_operation)) != EXIT_SUCCESS) {
        free_matrix(&matrix_1);
        print_error(ret);
        return ret;
    }
 
    if ((ret = read_input_matrix(&matrix_2)) != EXIT_SUCCESS) {
        free_matrix(&matrix_1);
        free_matrix(&matrix_2);
        print_error(ret);
        return ret;
    }
 
    switch (math_operation) {
        case PLUS_operation:
            result_matrix = add_or_subtract_matrices(&matrix_1, &matrix_2, math_operation);
            break;
        case MINUS_operation:
            result_matrix = add_or_subtract_matrices(&matrix_1, &matrix_2, math_operation);
            break;
        case MULTIPLY_operation:
            result_matrix = multiply_matrices(&matrix_1, &matrix_2);
            break;
    }
 
    if (result_matrix.data != NULL) {
        printf("%zu %zu\n", result_matrix.rows, result_matrix.columns);
        print_matrix(&result_matrix);
    } else {
        ret = ERROR_INPUT;
    }
 
    print_error(ret);
 
    free_matrix(&matrix_1);
    free_matrix(&matrix_2);
    free_matrix(&result_matrix);
 
    return ret;
}
// read one matrix from stdin
int read_input_matrix(Matrix *matrix) {
    int error = EXIT_SUCCESS;
    int check_input;
    int num_inputs = scanf("%zd %zd", &(matrix->rows), &(matrix->columns));
 
    if (num_inputs != 2) {
        error = ERROR_INPUT;
        return error;
    }
 
    matrix->data = (int32_t **)malloc(matrix->rows * sizeof(int32_t *));
    if (!matrix->data) {
        error = ERROR_MEM;
        return error;
    }
    for (size_t i = 0; i < matrix->rows; ++i) {
        matrix->data[i] = (int32_t *)malloc(matrix->columns * sizeof(int32_t));
        if (!matrix->data[i]) {
            error = ERROR_MEM;
            return error;
        }
        // fill the matrix
        for (size_t j = 0; j < matrix->columns; ++j) {
            check_input = scanf("%" PRId32, &(matrix->data[i][j]));
            if (check_input != 1) {
                error = ERROR_INPUT;
                return error;
            }
        }
    }
    // check whether actual size of matrix corresponds to declared
    char operation;
    check_input = scanf("%*c%c", &operation);
    if (check_input == -1) {
        operation = EOF;
    }
    if ((operation != EOF) && !(CORRECT_operation(operation))) {
        error = ERROR_INPUT;
        return error;
    }
    // unread the operation value
    ungetc(operation, stdin);
 
    return error;
}// read a math operation sign from stdin
int read_math_operation(char *math_operation) {
    int error = EXIT_SUCCESS;
    int num_inputs;
    num_inputs = scanf("\n%c", math_operation);
    if ((num_inputs != 1) || (!CORRECT_operation(*math_operation))) {
        error = ERROR_INPUT;
        return error;
    }
    return error;
}
// make operation add or substract two matrices depending on math_operator
Matrix add_or_subtract_matrices(Matrix *matrix_1, Matrix *matrix_2, char operation) {
    Matrix result_matrix = {NULL, 0, 0};
 
    if (matrix_1->rows == matrix_2->rows && matrix_1->columns == matrix_2->columns) {
        result_matrix.rows = matrix_1->rows;
        result_matrix.columns = matrix_1->columns;
        result_matrix.data = (int32_t **)malloc(result_matrix.rows * sizeof(int32_t *));
 
        if (!result_matrix.data) {
            return result_matrix;
        }
 
        for (size_t i = 0; i < result_matrix.rows; ++i) {
            result_matrix.data[i] = (int32_t *)malloc(result_matrix.columns * sizeof(int32_t));
            if (!result_matrix.data[i]) {
                return result_matrix;
            }
            for (size_t j = 0; j < result_matrix.columns; ++j) {
                if (operation == PLUS_operation) {
                    result_matrix.data[i][j] = matrix_1->data[i][j] + matrix_2->data[i][j];
                } else if (operation == MINUS_operation) {
                    result_matrix.data[i][j] = matrix_1->data[i][j] - matrix_2->data[i][j];
                }
            }
        }
    }
 
    return result_matrix;
}
// make operation multiply two matrices
Matrix multiply_matrices(Matrix *matrix_1, Matrix *matrix_2) {
    Matrix result_matrix = {NULL, 0, 0};
 
    if (matrix_1->columns == matrix_2->rows) {
        result_matrix.rows = matrix_1->rows;
        result_matrix.columns = matrix_2->columns;
        result_matrix.data = (int32_t **)malloc(result_matrix.rows * sizeof(int32_t *));
 
        if (!result_matrix.data) {
            return result_matrix;
        }
 
        for (size_t i = 0; i < result_matrix.rows; ++i) {
            result_matrix.data[i] = (int32_t *)malloc(result_matrix.columns * sizeof(int32_t));
            if (!result_matrix.data[i]) {
                return result_matrix;
            }
            for (size_t j = 0; j < result_matrix.columns; ++j) {
                result_matrix.data[i][j] = 0;
                for (size_t k = 0; k < matrix_1->columns; ++k) {
                    result_matrix.data[i][j] += matrix_1->data[i][k] * matrix_2->data[k][j];
                }
            }
        }
    }
 
    return result_matrix;
}
// print the matrix
void print_matrix(Matrix *matrix) {
    for (size_t i = 0; i < matrix->rows; ++i) {
        for (size_t j = 0; j < matrix->columns; ++j) {
            printf("%" PRId32, matrix->data[i][j]);
 
            // for the last number in row do not place space after that
            if (j != matrix->columns - 1) {
              printf(" ");
            }
        }
        printf("\n");
    }
}
// free the matrix
void free_matrix(Matrix *matrix) {
    for (size_t i = 0; i < matrix->rows; ++i) {
        free(matrix->data[i]);
    }
    free(matrix->data);
}
// print error if needed
void print_error(int ret) {
    switch (ret) {
        case ERROR_INPUT:
            fprintf(stderr, "Error: Chybny vstup!\n");
            break;
        case ERROR_MEM:
            fprintf(stderr, "Error: Chyba alokace pameti!\n");
            break;
        default:
            break;
    }
}
