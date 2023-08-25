#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <inttypes.h>

#define ERROR_INPUT 100
#define MAX_PRIME 1000000
#define STOP_SIGN 0

int read_and_check_input(int *ret, int64_t **numbers, int *count);
void eratosthenes_sieve(bool prime[], int64_t n);
void prime_factors(int64_t number, const bool *prime);

// print factorization into prime numbers
int main() {
    int64_t *numbers = NULL;
    int count = 0;
    int ret = read_and_check_input(&ret, &numbers, &count);
    if (numbers != NULL) {
        bool prime[MAX_PRIME];
        eratosthenes_sieve(prime, MAX_PRIME);
        for (int i = 0; i < count; i++) {
            prime_factors(numbers[i], prime);
        }
        free(numbers);
    }
    return ret;
}
// read and check input for errors
int read_and_check_input(int *ret, int64_t **numbers, int *count) {
    int64_t number;
    int input_status;
    *ret = EXIT_SUCCESS;
    while (true) {
        input_status = scanf("%" SCNd64, &number);    
        if (number == STOP_SIGN) {
            break;
        } else if (number < 0 || input_status != 1) {
            fprintf(stderr, "Error: Chybny vstup!\n");
            *ret = ERROR_INPUT;
            break;
        } else {
            (*count)++;
            *numbers = realloc(*numbers, (*count) * sizeof(int64_t));
            if (*numbers == NULL) {
                fprintf(stderr, "Error: chyba alokace pameti\n");
                *ret = EXIT_FAILURE;
                break;
            }
            (*numbers)[*count-1] = number;
        }
    }
    return *ret;
}
		
//find all prime numbers from 1 to n using Eratosthenes sieve
void eratosthenes_sieve(bool prime[], int64_t n) {
    memset(prime, true, n * sizeof(bool));
    prime[0] = prime[1] = false;
    // p <= sqrt(n) method to find prime numbers
    for (int64_t i = 2; i * i <= n; i++) {
        if (prime[i]) {
            // example i = 3: j = 9
            // all numbers from 9 to n with step 3 are not prime
            for (int64_t j = i * i; j < n; j += i) {
                prime[j] = false;
            }
        }
    }
}
// print prime factors of number
void prime_factors(int64_t number, const bool *prime) {
    printf("Prvociselny rozklad cisla %" PRId64 " je:\n", number);
    if (number == 1) {
        printf("1\n");
        return;
    }
    int exponent;
    for (int64_t i = 2; i <= number && i < MAX_PRIME; i++) {
        if (prime[i]) {
            exponent = 0;
            while (number % i == 0) {
                exponent++;
                number /= i;
            }
            if (exponent > 0) {
                // print in (2^2 x 3) or (3 x 3) way
                printf("%" PRId64, i);
                if (exponent > 1) {
                    printf("^%d", exponent);
                }
                if (number > 1) {
                    printf(" x ");
                }
            }
        }
    }
    printf("\n");
}
