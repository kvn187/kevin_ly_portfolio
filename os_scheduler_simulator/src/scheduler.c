/*
 * Scheduler implementation
 * Multithreaded OS scheduler simulation
 *
 * This file contains the CPU scheduler for the simulation.
 */

#include <assert.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

#include "os-sim.h"

/** Function prototypes **/
extern void idle(unsigned int cpu_id);
extern void preempt(unsigned int cpu_id);
extern void yield(unsigned int cpu_id);
extern void terminate(unsigned int cpu_id);
extern void wake_up(pcb_t *process);


/*
 * current[] is an array of pointers to the currently running processes.
 * There is one array element corresponding to each CPU in the simulation.
 *
 * current[] is protected by current_mutex because it is accessed by multiple
 * CPU threads.
 */
static pcb_t **current;
static pthread_mutex_t current_mutex;

static pcb_t *ready_head = NULL;
static pcb_t *ready_tail = NULL;
static pthread_mutex_t ready_mutex;
static pthread_cond_t ready_not_empty;

// Time slice = -1 = unlimited CPU time (FIFO), + is RR
static int time_slice = -1; 

// Append a process to the ready queue.
static void enqueue_process(pcb_t *process) {
    process->next = NULL;
    if (ready_tail == NULL) {
        ready_head = process;
        ready_tail = process; 
    } else {
        ready_tail->next = process;
        ready_tail = process;
    }
}

// Remove and return the process at the front of the queue.
static pcb_t *dequeue_process(void) {
    pcb_t *process = ready_head;
    if (process == NULL) {
        return NULL;
    }
    
    ready_head = process->next;
    if (ready_head == NULL) {
        ready_tail = NULL;
    }
    process->next = NULL;
    return process;
}

/*
 * Select the next runnable process and switch the CPU to it.
 */
static void schedule(unsigned int cpu_id)
{
    pcb_t *next_process; // Either PCB selected or NULL
    pthread_mutex_lock(&ready_mutex);
    next_process = dequeue_process();
    pthread_mutex_unlock(&ready_mutex);
    pthread_mutex_lock(&current_mutex);
    current[cpu_id] = next_process;
    if (next_process != NULL) {
        next_process->state = PROCESS_RUNNING;
    }

    pthread_mutex_unlock(&current_mutex);

    // FIFO is non-preemptive = -1
    // RoundRobin time_slice is positive
    // cpu_id = which CPU, next_process = which process
    // time_slice = -1 FIFO, + RR
    context_switch(cpu_id, next_process, time_slice);
}


/*
 * Block until work is available, then schedule the next process.
 */
extern void idle(unsigned int cpu_id)
{
    pthread_mutex_lock(&ready_mutex);
    while (ready_head == NULL) {
        pthread_cond_wait(&ready_not_empty, &ready_mutex);
    }
    
    pthread_mutex_unlock(&ready_mutex); 
    schedule(cpu_id);
}


/*
 * preempt() is the handler called by the simulator when a process is
 * preempted due to its timeslice expiring.
 *
 * This function should place the currently running process back in the
 * ready queue, and call schedule() to select a new runnable process.
 */
extern void preempt(unsigned int cpu_id)
{
    pcb_t *preempted_process;
    pthread_mutex_lock(&current_mutex);
    preempted_process = current[cpu_id];
    current[cpu_id] = NULL;
    pthread_mutex_unlock(&current_mutex);
    if (preempted_process != NULL) {
        pthread_mutex_lock(&ready_mutex);
        preempted_process->state = PROCESS_READY;
        enqueue_process(preempted_process);
        pthread_cond_signal(&ready_not_empty);
        pthread_mutex_unlock(&ready_mutex);
    }

    schedule(cpu_id);
}


/*
 * yield() is the handler called by the simulator when a process yields the
 * CPU to perform an I/O request.
 *
 * It should mark the process as WAITING, then call schedule() to select
 * a new process for the CPU.
 */
extern void yield(unsigned int cpu_id)
{
    pthread_mutex_lock(&current_mutex);
    if (current[cpu_id] != NULL) {
        current[cpu_id]->state = PROCESS_WAITING;
        current[cpu_id] = NULL;
    }

    pthread_mutex_unlock(&current_mutex);
    schedule(cpu_id);
}


/*
 * terminate() is the handler called by the simulator when a process completes.
 * It should mark the process as terminated, then call schedule() to select
 * a new process for the CPU.
 */
extern void terminate(unsigned int cpu_id)
{
    pthread_mutex_lock(&current_mutex);
    if (current[cpu_id] != NULL) {
        current[cpu_id]->state = PROCESS_TERMINATED;
        current[cpu_id] = NULL;
    }


    pthread_mutex_unlock(&current_mutex);
    schedule(cpu_id);
}


/*
 * Mark an I/O-complete process ready and return it to the ready queue.
 */
extern void wake_up(pcb_t *process)
{
    pthread_mutex_lock(&ready_mutex);
    process->state = PROCESS_READY;
    enqueue_process(process);
    pthread_cond_signal(&ready_not_empty);
    pthread_mutex_unlock(&ready_mutex);
}


/*
 * Parse scheduler options and start the simulator.
 */
int main(int argc, char *argv[])
{
    unsigned int cpu_count;

    /* Parse command-line arguments */
    if (argc != 2 && argc != 4)
    {
        fprintf(stderr, "Multithreaded OS Simulator\n"
            "Usage: ./os-sim <# CPUs> [ -l | -r <time slice> ]\n"
            "    Default : FIFO Scheduler\n"
	    "         -l : Longest Remaining Time First Scheduler\n"
            "         -r : Round-Robin Scheduler\n\n");
        return -1;
    }
    cpu_count = strtoul(argv[1], NULL, 0);

    // FIFO default, else RoundRobin
    if (argc == 2) {
        time_slice = -1;
    } else {
        if (argv[2][0] != '-' || argv[2][1] != 'r' || argv[2][2] != '\0') {
            fprintf(stderr, "Invalid scheduling algorithm: %s\n", argv[2]);
            return -1;
        }

        time_slice = (int)strtol(argv[3], NULL, 10);
        if (time_slice <= 0) {
            fprintf(stderr, "Time slice must be greater than zero.\n");
            return -1;
        }
    }

    /* Parse the optional scheduler mode and time slice. */

    // The simulator supports 1-16 CPUs
    if (cpu_count < 1 || cpu_count > 16) {
        fprintf(stderr, "CPU count must be 1 - 16.\n");
        return -1;
    }

    /* Allocate the current[] array and its mutex */
    current = malloc(sizeof(pcb_t*) * cpu_count);
    assert(current != NULL);
    for (unsigned int i = 0; i < cpu_count; i++) {
        current[i] = NULL;
    }

    pthread_mutex_init(&current_mutex, NULL);
    ready_head = NULL;
    ready_tail = NULL;
    pthread_mutex_init(&ready_mutex, NULL);
    pthread_cond_init(&ready_not_empty, NULL);

    /* Start the simulator in the library */
    start_simulator(cpu_count);

    return 0;
}


