/**
 * LRU stack test program.
 */

#include <stdio.h>
#include "lrustack.h"

int test_num = 1;

/**
 * Function to assert equality for test cases
 * 
 * @param test_num number of this test
 * @param expected the expected value
 * @param actual the actual value
 */
void assert_equal(int test_num, int expected, int actual) {
    if (expected == actual) {
        printf("Test%d Succeeded!\n", test_num);
    } else {
        printf("Test%d Failed: expected %d, but got %d\n", test_num, expected, actual);
    }
}

/**
 * Run checks for the LRU stack implementation.
 */
void run_t_tests() {
    // Initialize LRU stack
    int size = 8;
    lru_stack_t* stack = init_lru_stack(size);

    // For testing, LRU stack is initialized with 0 as MRU and 1 as LRU.
    for (int i = (size - 1); i >= 0; i--) {
        lru_stack_set_mru(stack, i);
    }
    
    // Test whether (size - 1) is the LRU
    assert_equal(test_num++, size - 1, lru_stack_get_lru(stack));

    // Sequentially mark each LRU as MRU and make sure LRU rotates. 
    for (int i = (size - 1); i >= 1; i--) {
        lru_stack_set_mru(stack, i);
        assert_equal(test_num++, i - 1, lru_stack_get_lru(stack));
    }

    // Make sure marking anything MRU works
    lru_stack_set_mru(stack, 4);
    for (int i = 0; i < (size - 1); i++) {
        lru_stack_set_mru(stack, lru_stack_get_lru(stack));
    }
    assert_equal(test_num++, 4, lru_stack_get_lru(stack));
}

/**
 * Function to run tests to test the LRU stack implementation
 */
void run_lru_tests() {
}

int main() {
    printf("------- Running T tests -------\n");
    run_t_tests();
    printf("------- Running LRU tests -------\n");
    run_lru_tests();
    return 0;
}