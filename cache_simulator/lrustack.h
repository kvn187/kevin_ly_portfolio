/**
 * LRU stack interface.
 */

#ifndef __LRUSTACK_H
#define __LRUSTACK_H

/**
 * The stack stores cache-block indices from most recently used to least recently used.
 * 
 * The interface exposes two operations:
 *  - get LRU: gets the current index of the LRU block
 *  - set MRU: sets a certain block's index as the MRU. 
 * 
 * This is an ordering structure rather than a traditional LIFO stack.
 */

/**
 * struct to hold a cache set's LRU stack. Note that this stack is currently intended
 * to store the indices of cache blocks in a cache set in an LRU order. Please make
 * sure you understand that this is NOT written to store whole cache blocks. If you
 * want to do the latter, the LRU interface defined in this
 * file.
 */
typedef struct lru_stack_t {
	int size;   // Corresponds to the associativity
    // Added int* array to store way numbers, holding cache block indices LRU ordered
    int* order; // index 0 is most recent
} lru_stack_t;

/**
 * Function to initialize an LRU stack for a cache set with a given <size>. This function
 * creates the LRU stack. 
 * 
 * @param size is the size of the LRU stack to initialize. 
 * @return the dynamically allocated stack. 
 */
lru_stack_t* init_lru_stack(int size);

/**
 * Function to get the index of the least recently used cache block, as indicated by <stack>.
 * This operation should not change/mutate your LRU stack. 
 * 
 * @param stack is the stack to run the operation on.
 * @return the index of the LRU cache block.
 */
int lru_stack_get_lru(lru_stack_t* stack);

/**
 * Function to mark the cache block with index <n> as MRU in <stack>. This operation should
 * change/mutate the LRU stack.
 * 
 * @param stack is the stack to run the operation on.
 * @param n the index to promote to MRU.  
 */
void lru_stack_set_mru(lru_stack_t* stack, int n);

/**
 * Function to free up any memory you dynamically allocated for <stack>
 * 
 * @param stack the stack to free
 */
void lru_stack_cleanup(lru_stack_t* stack);

#endif