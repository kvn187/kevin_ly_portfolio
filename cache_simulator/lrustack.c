/**
 * LRU stack implementation.
 */

#include <stdlib.h>
#include "lrustack.h"

/**
 * The stack stores cache-block indices from most recently used to least recently used.
 * 
 * The interface exposes two operations:
 *  - get LRU: gets the current index of the LRU block
 *  - set MRU: sets a certain block's index as the MRU. 
 * This is an ordering structure rather than a traditional LIFO stack.
 */

/**
 * Function to initialize an LRU stack for a cache set with a given <size>. This function
 * creates the LRU stack. 
 * 
 * @param size is the size of the LRU stack to initialize. 
 * @return the dynamically allocated stack. 
 */
lru_stack_t* init_lru_stack(int size) {
	lru_stack_t* stack = (lru_stack_t*) malloc(sizeof(lru_stack_t));
	stack->size = size;
    
    stack->order = (int*) malloc(size * sizeof(int)); // allocate order
    for (int i = 0; i < size; i++) {
        stack->order[i] = i;
    }

	return stack;
}

/**
 * Function to get the index of the least recently used cache block, as indicated by <stack>.
 * This operation should not change/mutate your LRU stack. 
 * 
 * @param stack is the stack to run the operation on.
 * @return the index of the LRU cache block.
 */
int lru_stack_get_lru(lru_stack_t* stack) {
    return stack->order[stack->size - 1]; // last element in LRU
}

/**
 * Function to mark the cache block with index <n> as MRU in <stack>. This operation should
 * change/mutate the LRU stack.
 * 
 * @param stack is the stack to run the operation on.
 * @param n the index to promote to MRU.  
 */
void lru_stack_set_mru(lru_stack_t* stack, int n) {
    int position = -1;
    for (int i = 0; i < stack->size; i++) {
        if (stack->order[i] == n) {
            position = i;
            break;
        }
    }

    if (position == -1) {
        return;
    }
    for (int i = position; i > 0; i--) {
        stack->order[i] = stack->order[i - 1];
    }
    stack->order[0] = n;

}

/**
 * Function to free up any memory you dynamically allocated for <stack>
 * 
 * @param stack the stack to free
 */
void lru_stack_cleanup(lru_stack_t* stack) {
    free(stack->order);

    free(stack);        // Free the stack struct we malloc'd
}