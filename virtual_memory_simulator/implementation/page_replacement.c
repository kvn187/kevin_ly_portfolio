#include "types.h"
#include "pagesim.h"
#include "paging.h"
#include "swapops.h"
#include "stats.h"
#include "util.h"

pfn_t select_victim_frame(void);


/* Select a frame and evict its current mapping when necessary. */
pfn_t free_frame(void) {
    pfn_t victim_pfn;

    victim_pfn = select_victim_frame();
    fte_t *victim = &frame_table[victim_pfn];


    /* Write back dirty data before invalidating the old mapping. */
    if (victim->mapped) {
        pte_t *victim_page_table = (pte_t *)(mem + victim->process->saved_ptbr * PAGE_SIZE);
        pte_t *victim_pte = &victim_page_table[victim->vpn];

        if (victim_pte->dirty) {
            swap_write(victim_pte, mem + victim_pfn * PAGE_SIZE);
            stats.writebacks++;
            victim_pte->dirty = 0;
        }

        victim_pte->valid = 0;
        victim->mapped = 0;
        victim->referenced = 0;
        victim->process = NULL;
        victim->vpn = 0;
    }

    return victim_pfn;
}



pfn_t select_victim_frame() {
    /* See if there are any free frames first */
    size_t num_entries = MEM_SIZE / PAGE_SIZE;
    for (size_t i = 0; i < num_entries; i++) {
        if (!frame_table[i].protected && !frame_table[i].mapped) {
            return i;
        }
    }

    if (replacement == RANDOM) {
        /* Randomly choose among unprotected frames. */
        pfn_t last_unprotected = NUM_FRAMES;
        for (pfn_t i = 0; i < num_entries; i++) {
            if (!frame_table[i].protected) {
                last_unprotected = i;
                if (prng_rand() % 2) {
                    return i;
                }
            }
        }
        /* Fall back to the last unprotected frame seen. */
        if (last_unprotected < NUM_FRAMES) {
            return last_unprotected;
        }
    } 

    /* Every frame is protected, so the simulated system is out of memory. */
    panic("System ran out of memory\n");
    exit(1);
}
