#ifndef	_TIMER_H
#define	_TIMER_H

void timer_init ( void );
void handle_timer_irq ( void );

void generic_timer_init ( void );
void handle_generic_timer_irq ( void );

extern void gen_timer_init();
extern void gen_timer_reset();

extern int get_timer_freq(void);
extern unsigned long get_sys_count(void);
extern unsigned long get_time_ms(void);

#endif  /*_TIMER_H */
