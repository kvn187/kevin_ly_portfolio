#pragma once

#include "paging.h"

/* Get the virtual page number from a virtual address. */
static inline vpn_t vaddr_vpn(vaddr_t addr) {
    return (vpn_t)(addr / PAGE_SIZE);
}

/* Get the offset into the page from a virtual address. */
static inline uint16_t vaddr_offset(vaddr_t addr) {
    return (uint16_t)(addr % PAGE_SIZE);
}
