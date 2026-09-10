#include "paging.h"
#include "page_splitting.h"
#include "swapops.h"
#include "stats.h"

/* Frame table for simulated physical memory. */
fte_t *frame_table;

/* Initialize the frame table in simulated physical memory. */
void system_init(void) {
    frame_table = (fte_t *) mem;
    memset(mem, 0, PAGE_SIZE);

    frame_table[0].protected = 1;
}

/* Allocate and initialize a page table for a new process. */
void proc_init(pcb_t *proc) {
    pfn_t page_table_pfn = free_frame();
    memset(mem + page_table_pfn * PAGE_SIZE, 0, PAGE_SIZE);


    proc->saved_ptbr = page_table_pfn;
    frame_table[page_table_pfn].protected = 1;
    frame_table[page_table_pfn].mapped = 0;
    frame_table[page_table_pfn].referenced = 0;
    frame_table[page_table_pfn].process = NULL;
    frame_table[page_table_pfn].vpn = 0;

}

/* Switch the active page table to the selected process. */
void context_switch(pcb_t *proc) {
    PTBR = proc->saved_ptbr;
}

/* Translate a virtual address and perform a simulated memory access. */
uint8_t mem_access(vaddr_t address, char rw, uint8_t data) {


    /* Split the address and find the page table entry */

    vpn_t vpn = vaddr_vpn(address);
    uint16_t offset = vaddr_offset(address);
    pte_t *page_table = (pte_t *)(mem + PTBR * PAGE_SIZE);
    pte_t *pte = &page_table[vpn];

    stats.accesses++;

    /* If an entry is invalid, just page fault to allocate a page for the page table. */

    if (!pte->valid) {
        page_fault(address);
    }

    /* Set the "referenced" bit to reduce the page's likelihood of eviction */

    frame_table[pte->pfn].referenced = 1;
    
    /*
        The physical address will be constructed like this:
        -------------------------------------
        |     PFN    |      Offset          |
        -------------------------------------
        where PFN is the value stored in the page table entry.
        We need to calculate the number of bits are in the offset.

        Create the physical address using your offset and the page
        table entry.
    */

    paddr_t physical_address = (paddr_t)(pte->pfn * PAGE_SIZE + offset);

    /* Either read or write the data to the physical address
       depending on 'rw' */
    if (rw == 'r') {
        stats.reads++;
        return mem[physical_address];
    } else {
        stats.writes++;
        pte->dirty = 1;
        mem[physical_address] = data;
        return data;
    }
}

/* Release a process's mapped pages, swap entries, and page table frame. */
void proc_cleanup(pcb_t *proc) {
    /* Look up the process's page table */

    pte_t *page_table = (pte_t *)(mem + proc->saved_ptbr * PAGE_SIZE);

    /* Iterate the page table and clean up each valid page */
    for (size_t i = 0; i < NUM_PAGES; i++) {
        pte_t *pte = &page_table[i];
        if (pte->valid) {
            fte_t *fte = &frame_table[pte->pfn];
            fte->mapped = 0;
            fte->referenced = 0;
            fte->process = NULL;
            fte->vpn = 0;
            pte->valid = 0;
        }
        if (swap_exists(pte)) {
            swap_free(pte);
        }
    }

    /* Free the page table itself in the frame table */
    
    frame_table[proc->saved_ptbr].protected = 0;
    frame_table[proc->saved_ptbr].mapped = 0;
    frame_table[proc->saved_ptbr].referenced = 0;
    frame_table[proc->saved_ptbr].process = NULL;
    frame_table[proc->saved_ptbr].vpn = 0;
}
