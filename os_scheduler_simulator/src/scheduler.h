/*
 * Scheduler interface
 * Multithreaded OS scheduler simulation
 *
 *
 */

#ifndef __SCHEDULER_H__
#define __SCHEDULER_H__

#include "os-sim.h"

/* Function declarations */
extern void idle(unsigned int cpu_id);
extern void preempt(unsigned int cpu_id);
extern void yield(unsigned int cpu_id);
extern void terminate(unsigned int cpu_id);
extern void wake_up(pcb_t *process);

#endif /* __SCHEDULER_H__ */
