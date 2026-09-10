#include "paging.h"
#include "swapops.h"
#include "stats.h"

/* Resolve a page fault by mapping and initializing a physical frame. */
void page_fault(vaddr_t address) {
    /* Locate the page table entry for the faulting address. */
   
   vpn_t vpn = vaddr_vpn(address);
   pte_t *page_table = (pte_t *)(mem + PTBR * PAGE_SIZE);
   pte_t *pte = &page_table[vpn];

   stats.page_faults++;
   pfn_t pfn = free_frame();


   pte->valid = 1;
   pte->dirty = 0;
   pte->pfn = pfn;

   frame_table[pfn].protected = 0;
   frame_table[pfn].mapped = 1;
   frame_table[pfn].referenced = 0;
   frame_table[pfn].process = current_process;
   frame_table[pfn].vpn = vpn;

    /* Restore swapped data or initialize a new page with zeros. */
   
   void *frame_start = (mem + pfn * PAGE_SIZE);

    if (swap_exists(pte)) {
        swap_read(pte, frame_start);
    } else {
        memset(frame_start, 0, PAGE_SIZE);
    }
}
