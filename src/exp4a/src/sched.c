#include "sched.h"
#include "irq.h"
#include "printf.h"
#include "fork.h"

static struct task_struct init_task = INIT_TASK;
struct task_struct *current = &(init_task);
struct task_struct * task[NR_TASKS] = {&(init_task), };
int nr_tasks = 1;

wait_struct* waiting_tasks[NR_TASKS] = {0, };
int num_waiting = 0;

//Will be initialized in kernel_main
int idle_task = 0;

void _schedule(void)
{
	int next, c;
	struct task_struct * p;
	while (1) {
		c = -1;	// the maximum counter found so far
		next = 0;

		// If all the tasks are waiting except init_task and the idle task
		if(num_waiting == (nr_tasks - 2)){
			c = task[idle_task]->counter;
			next = idle_task;
			break;
		}

		/* Iterates over all tasks and tries to find a task in 
		TASK_RUNNING state with the maximum counter. If such 
		a task is found, we immediately break from the while loop 
		and switch to this task. */

		for (int i = 0; i < NR_TASKS; i++){
			p = task[i];
			if (p && (p->state == TASK_RUNNING || p->state == TASK_READY) && p->counter > c) {
				c = p->counter;
				next = i;
			}
		}
		if (c) {
			break;
		}

		/* If no such task is found, this is either because i) no 
		task is in TASK_RUNNING state or ii) all such tasks have 0 counters.
		in our current implemenation which misses TASK_WAIT, only condition ii) is possible. 
		Hence, we recharge counters. Bump counters for all tasks once. */
		for (int i = 0; i < NR_TASKS; i++) {
			p = task[i];
			if (p && p->state != TASK_WAITING) {
				p->counter = (p->counter >> 1) + p->priority; // The increment depends on a task's priority.
			}
		}

		/* loops back to pick the next task */
	}
	switch_to(task[next]);
}

void schedule(void)
{
	current->counter = 0;
	_schedule();
}

void switch_to(struct task_struct * next) 
{
	if (current == next) 
		return;
	struct task_struct * prev = current;
	current = next;
	cpu_switch_to(prev, next);
}

void schedule_tail(void) {
	/* nothing */
}

void sleep(int secs){
	wait_struct new_wait = { .task = current, .secs_remaining = secs};
	for(int i = 0; i < NR_TASKS; i++){
		if(waiting_tasks[i] == 0){
			waiting_tasks[i] = &new_wait;
			break;
		}
	}
	num_waiting++;
	// TODO: Change current task status to waiting and call scheduler
	current->state = TASK_WAITING;
	schedule();
}

void idle_task_body(void){
	while(1){
		printf("Going to WFI \n");
		asm("wfi");
		schedule();
	}
}

void create_idle_task(void){
	copy_process( (unsigned long)&idle_task_body, 0);
	// Note: This will only work if we create the idle task before any other task is created.
	for(int i = 0; i < nr_tasks; i++){
		if(task[i] && task[i]->cpu_context.x19 == (unsigned long)&idle_task_body){
			task[i]->state = TASK_IDLE;
			idle_task = i;
			return;
		}
	}
	return;
}
