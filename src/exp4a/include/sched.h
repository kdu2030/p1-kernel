#ifndef _SCHED_H
#define _SCHED_H

#define THREAD_CPU_CONTEXT			0 		// offset of cpu_context in task_struct 

#ifndef __ASSEMBLER__

#define THREAD_SIZE				4096

#define NR_TASKS				64 

#define FIRST_TASK task[0]
#define LAST_TASK task[NR_TASKS-1]

/* a simplified impl. TASK_RUNNING means either RUNNING or READY (as in OS textbook/lectures) */
#define TASK_RUNNING				0
#define TASK_WAITING				1
#define TASK_READY					2
#define TASK_IDLE					3

extern struct task_struct *current;
extern struct task_struct * task[NR_TASKS];
extern int nr_tasks;
extern int num_waiting;

struct cpu_context {
	unsigned long x19;
	unsigned long x20;
	unsigned long x21;
	unsigned long x22;
	unsigned long x23;
	unsigned long x24;
	unsigned long x25;
	unsigned long x26;
	unsigned long x27;
	unsigned long x28;
	unsigned long fp;
	unsigned long sp;
	unsigned long pc;
};

struct task_struct {
	struct cpu_context cpu_context;
	long state;	
	long counter;
	long priority;
	long preempt_count;
};

typedef struct wait_struct {
	struct task_struct* task;
	int secs_remaining;
} wait_struct;

extern wait_struct* waiting_tasks[NR_TASKS];

extern void sleep(int secs);
extern void sched_init(void);
extern void schedule(void);
extern void create_idle_task(void);
//extern void timer_tick(void);
//extern void preempt_disable(void);
//extern void preempt_enable(void);
extern void switch_to(struct task_struct* next);
extern void cpu_switch_to(struct task_struct* prev, struct task_struct* next);

#define INIT_TASK 									\
{ 													\
	{0,0,0,0,0,0,0,0,0,0,0,0,0}, 	/*cpu_context*/	\
	0,	/* state */									\
	0,	/* counter */								\
	1,	/* priority */								\
	0 	/* preempt_count */							\
}

#endif
#endif
