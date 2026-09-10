#include "paging.h"
#include "stats.h"

/* The stats. See the definition in stats.h. */
stats_t stats;

/* Calculate average access time from the accumulated simulation statistics. */
void compute_stats() {
    if (stats.accesses == 0) {
        stats.aat = 0.0;
        return;
    }

    stats.aat = ((double) MEMORY_READ_TIME * stats.accesses + (double) DISK_PAGE_READ_TIME * stats.page_faults + (double) DISK_PAGE_WRITE_TIME * stats.writebacks) / stats.accesses;
}
