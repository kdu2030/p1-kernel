#include "sched.h"
#include "irq.h"
#include "printf.h"
#include "timer.h"

static struct task_struct init_task = INIT_TASK;
struct task_struct *current = &(init_task);
struct task_struct *task[NR_TASKS] = {
	&(init_task),
};
trace_struct traces[MAX_TRACES] = {
	0,
};
trace_struct most_recent[NR_TASKS] = {
	0,
};
int num_traces = 0;
int nr_tasks = 1;

void preempt_disable(void)
{
	current->preempt_count++;
}

void preempt_enable(void)
{
	current->preempt_count--;
}

void _schedule(void)
{
	/* ensure no context happens in the following code region
		we still leave irq on, because irq handler may set a task to be TASK_RUNNING, which
		will be picked up by the scheduler below */
	preempt_disable();
	int next, c;
	struct task_struct *p;
	while (1)
	{
		c = -1; // the maximum counter of all tasks
		next = 0;

		/* Iterates over all tasks and tries to find a task in
		TASK_RUNNING state with the maximum counter. If such
		a task is found, we immediately break from the while loop
		and switch to this task. */

		for (int i = 0; i < NR_TASKS; i++)
		{
			p = task[i];
			if (p && p->state == TASK_RUNNING && p->counter > c)
			{
				c = p->counter;
				next = i;
			}
		}
		if (c)
		{
			break;
		}

		/* If no such task is found, this is either because i) no
		task is in TASK_RUNNING state or ii) all such tasks have 0 counters.
		in our current implemenation which misses TASK_WAIT, only condition ii) is possible.
		Hence, we recharge counters. Bump counters for all tasks once. */

		for (int i = 0; i < NR_TASKS; i++)
		{
			p = task[i];
			if (p)
			{
				p->counter = (p->counter >> 1) + p->priority;
			}
		}
	}
	switch_to(task[next]);
	preempt_enable();
}

void schedule(void)
{
	current->counter = 0;
	_schedule();
}

// int get_pid_from_struct(struct task_struct* target_task){
// 	for(int i = 0; i < nr_tasks; i++){
// 		if(task[i] && task[i] == target_task){
// 			return i;
// 		}
// 	}
// 	return -1;
// }

// trace_struct* get_from_trace(struct task_struct* schedule_out){
// 	for(int i = 0; i < num_traces; i++){
// 		if(traces[i]->id_from == get_pid_from_struct(schedule_out)){
// 			return traces[i];
// 		}
// 	}
// 	return 0;
// }

void initialize_trace_arrays()
{
	trace_struct initial_trace = {
		.id_from = -1,
		.id_to = -1,
		.sp_from = 0,
		.sp_to = 0,
		.pc_from = 0,
		.pc_to = 0};

	for (int i = 0; i < MAX_TRACES; i++)
	{
		traces[i] = initial_trace;
	}

	for (int i = 0; i < NR_TASKS; i++)
	{
		most_recent[i] = initial_trace;
	}
}

void update_new_trace()
{
	int schedule_in_pid = get_pid();
	trace_struct schedule_out_trace = traces[num_traces - 1];
	// Most recent trace of the scheduled in task
	trace_struct most_recent_trace = most_recent[schedule_in_pid];

	schedule_out_trace.id_to = schedule_in_pid;
	// schedule_out_trace.timestamp = get_time_ms();

	if (most_recent_trace.id_from != -1)
	{
		// printf("From %d to %d \n", schedule_out_trace->id_from, most_recent_trace->id_from);
		schedule_out_trace.pc_to = most_recent_trace.pc_from;
		schedule_out_trace.sp_to = most_recent_trace.sp_from;
	}
	else
	{
		// This is the first time that we have run the task
		schedule_out_trace.pc_to = task[schedule_in_pid]->cpu_context.pc;
		schedule_out_trace.sp_to = task[schedule_in_pid]->cpu_context.sp;
	}

	traces[num_traces - 1] = schedule_out_trace;
	// printf("%d from task%d (PC 0x%x SP 0x%x) to task%d (PC 0x%x SP 0x%x) \n", schedule_out_trace.timestamp, schedule_out_trace.id_from, schedule_out_trace.pc_from, schedule_out_trace.sp_from, schedule_out_trace.id_to, schedule_out_trace.pc_to, schedule_out_trace.sp_to);
}

void switch_to(struct task_struct *next)
{
	if (current == next)
		return;
	struct task_struct *prev = current;
	current = next;
	if (num_traces > 0)
	{
		update_new_trace(next);
	}
	cpu_switch_to(prev, next);
}

void schedule_tail(void)
{
	preempt_enable();
}

void print_all_traces()
{
	for (int i = 0; i < MAX_TRACES; i++)
	{
		trace_struct trace = traces[i];
		printf("%d from task%d (PC 0x%x SP 0x%x) to task%d (PC 0x%x SP 0x%x) \n", trace.timestamp, trace.id_from, trace.pc_from, trace.sp_from, trace.id_to, trace.pc_to, trace.sp_to);
	}
}

void initialize_trace()
{
	int current_pid = get_pid();
	unsigned long time = get_time_ms();
	unsigned long current_pc = get_interrupt_pc();
	unsigned long current_sp = get_sp();

	if (current_pid == -1)
	{
		return;
	}

	trace_struct trace = {
		.timestamp = time,
		.id_from = current_pid,
		.pc_from = current_pc,
		.sp_from = current_sp,
		.id_to = -1,
		.pc_to = 0,
		.sp_to = 0,
	};
	most_recent[current_pid] = trace;

	if (num_traces < MAX_TRACES)
	{
		traces[num_traces] = trace;
		num_traces++;
	}
	else {
		print_all_traces();
		traces[0] = trace;
		num_traces = 1;
	}

	
}

void timer_tick()
{
	initialize_trace();
	--current->counter;
	if (current->counter > 0 || current->preempt_count > 0)
	{
		return;
	}
	current->counter = 0;
	enable_irq();
	_schedule();
	disable_irq();
}

int get_pid(void)
{
	for (int i = 0; i < nr_tasks; i++)
	{
		if (task[i] && task[i] == current)
		{
			return i;
		}
	}
	return -1;
}
