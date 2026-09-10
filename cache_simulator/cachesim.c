/**
 * Cache simulator implementation.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cachesim.h"

counter_t accesses = 0;     // Total number of cache accesses
counter_t hits = 0;         // Total number of cache hits
counter_t misses = 0;       // Total number of cache misses
counter_t writebacks = 0;   // Total number of writebacks

/**
 * Function to perform a very basic log2.
 * 
 * @param x the number we want the log of.
 * @returns floor(log_2(x)).
 */
int simple_log_2(int x) {
    int val = 0;
    while (x > 1) {
        x /= 2;
        val++;
    }
    return val; 
}

cache_set_t* cache;     // Data structure for the cache
int block_size;         // Block size
int cache_size;         // Cache size
int ways;               // Ways
int num_sets;           // Number of sets
int num_offset_bits;    // Number of offset bits
int num_index_bits;     // Number of index bits. 

/**
 * Initialize the cache simulator with the given cache parameters.
 * 
 * @param _block_size is the block size in bytes
 * @param _cache_size is the cache size in bytes
 * @param _ways is the associativity
 */
void cachesim_init(int _block_size, int _cache_size, int _ways) {
    // Store cache geometry and derive address-field widths.
    block_size = _block_size;
    cache_size = _cache_size;
    ways = _ways;

    num_sets = cache_size / (block_size * ways);
    num_offset_bits = simple_log_2(block_size);
    num_index_bits = simple_log_2(num_sets);
    cache = (cache_set_t*) malloc(num_sets * sizeof(cache_set_t));

    for (int i = 0; i < num_sets; i++) {
        cache[i].size = ways;
        cache[i].blocks = (cache_block_t*) malloc(ways * sizeof(cache_block_t));
        cache[i].stack = init_lru_stack(ways);

        for (int j = 0; j < ways; j++) {
            cache[i].blocks[j].tag = 0;
            cache[i].blocks[j].valid = 0;
            cache[i].blocks[j].dirty = 0;
        }
    }

}

/**
 * Process one memory access and update cache state and statistics.
 * 
 * @param physical_addr is the address to use for the memory access. 
 * @param access_type is the type of access - 0 (data read), 1 (data write) or 
 *      2 (instruction read). Use MEMREAD, MEMWRITE, and IFETCH from cachesim.h.
 */
void cachesim_access(addr_t physical_addr, int access_type) {
    accesses++;
    // Split the address into tag, set index, and block offset.
    addr_t block_addr = physical_addr >> num_offset_bits;
    int set_index = block_addr & ((1 << num_index_bits) - 1);
    addr_t tag = block_addr >> num_index_bits;
    cache_set_t* set = &cache[set_index];

    // check valid == 1 && tag matched
    int hit = -1;
    for (int i = 0; i < ways; i++) {
        if (set->blocks[i].valid && set->blocks[i].tag == tag) {
            hit = i;
            break;
        }
    }

    if (hit != -1) {
        hits++;
        if (access_type == MEMWRITE) {
            set->blocks[hit].dirty = 1;
        }
        lru_stack_set_mru(set->stack, hit);
        return;
    }

    misses++;
    int invalid = -1;
    for (int i = 0; i < ways; i++) {
        if (!set->blocks[i].valid) {
            invalid = i;
            break;
        }
    }

    if (invalid == -1) {
        invalid = lru_stack_get_lru(set->stack);
        if (set->blocks[invalid].dirty) {
            writebacks++;
        }
    }

    // Fill an invalid line or replace the least recently used line.
    set->blocks[invalid].tag = tag;
    set->blocks[invalid].valid = 1;
    set->blocks[invalid].dirty = (access_type == MEMWRITE) ? 1 : 0;

    lru_stack_set_mru(set->stack, invalid);
}

/**
 * Function to free up any dynamically allocated memory you allocated
 */
void cachesim_cleanup() {
    for (int i = 0; i < num_sets; i++) {
        free(cache[i].blocks);
        lru_stack_cleanup(cache[i].stack);
    }
    free(cache);

}

/**
 * Print cache statistics in CSV order.
 */
void cachesim_print_stats() {
    printf("%llu, %llu, %llu, %llu\n", accesses, hits, misses, writebacks);  
}

/**
 * Function to open the trace file
 * You do not need to update this function. 
 */
FILE *open_trace(const char *filename) {
    return fopen(filename, "r");
}

/**
 * Read in next line of the trace
 * 
 * @param trace is the file handler for the trace
 * @return 0 when error or EOF and 1 otherwise. 
 */
int next_line(FILE* trace) {
    if (feof(trace) || ferror(trace)) return 0;
    else {
        int t;
        unsigned long long address, instr;
        fscanf(trace, "%d %llx %llx\n", &t, &address, &instr);
        cachesim_access(address, t);
    }
    return 1;
}

/**
 * Main function. See error message for usage. 
 * 
 * @param argc number of arguments
 * @param argv Argument values
 * @returns 0 on success. 
 */
int main(int argc, char **argv) {
    FILE *input;

    if (argc != 5) {
        fprintf(stderr, "Usage:\n  %s <trace> <block size(bytes)>"
                        " <cache size(bytes)> <ways>\n", argv[0]);
        return 1;
    }
    
    input = open_trace(argv[1]);
    cachesim_init(atol(argv[2]), atol(argv[3]), atol(argv[4]));
    while (next_line(input));
    cachesim_print_stats();
    cachesim_cleanup();
    fclose(input);
    return 0;
}

