
build/kernel8.elf:     file format elf64-littleaarch64


Disassembly of section .text.boot:

0000000000080000 <_start>:

.section ".text.boot"

.globl _start
_start:
	mrs	x0, mpidr_el1		
   80000:	d53800a0 	mrs	x0, mpidr_el1
	and	x0, x0,#0xFF		// Check processor id
   80004:	92401c00 	and	x0, x0, #0xff
	cbz	x0, master		// Hang for all non-primary CPU
   80008:	b4000060 	cbz	x0, 80014 <master>
	b	proc_hang
   8000c:	14000001 	b	80010 <proc_hang>

0000000000080010 <proc_hang>:

proc_hang: 
	b 	proc_hang
   80010:	14000000 	b	80010 <proc_hang>

0000000000080014 <master>:

master:
	ldr	x0, =SCTLR_VALUE_MMU_DISABLED // System control register
   80014:	58000220 	ldr	x0, 80058 <el1_entry+0x20>
	msr	sctlr_el1, x0		
   80018:	d5181000 	msr	sctlr_el1, x0

	ldr	x0, =HCR_VALUE  	// Hypervisor Configuration (EL2) 
   8001c:	58000220 	ldr	x0, 80060 <el1_entry+0x28>
	msr	hcr_el2, x0  
   80020:	d51c1100 	msr	hcr_el2, x0

#ifdef USE_QEMU 		// xzl: qemu boots from EL2. cannot do things to EL3			
	ldr	x0, =SPSR_VALUE	
   80024:	58000220 	ldr	x0, 80068 <el1_entry+0x30>
	msr	spsr_el2, x0
   80028:	d51c4000 	msr	spsr_el2, x0

	adr	x0, el1_entry		
   8002c:	10000060 	adr	x0, 80038 <el1_entry>
	msr	elr_el2, x0
   80030:	d51c4020 	msr	elr_el2, x0

	adr	x0, el1_entry		
	msr	elr_el3, x0
#endif
  
	eret				
   80034:	d69f03e0 	eret

0000000000080038 <el1_entry>:

el1_entry:
	adr	x0, bss_begin
   80038:	10020f00 	adr	x0, 84218 <mem_map>
	adr	x1, bss_end
   8003c:	10419721 	adr	x1, 103320 <bss_end>
	sub	x1, x1, x0
   80040:	cb000021 	sub	x1, x1, x0
	bl 	memzero
   80044:	94000d7c 	bl	83634 <memzero>

	mov	sp, #LOW_MEMORY
   80048:	b26a03ff 	mov	sp, #0x400000              	// #4194304
	bl	kernel_main
   8004c:	94000843 	bl	82158 <kernel_main>
	b 	proc_hang		// should never come here
   80050:	17fffff0 	b	80010 <proc_hang>
   80054:	00000000 	.inst	0x00000000 ; undefined
   80058:	30d00800 	.word	0x30d00800
   8005c:	00000000 	.word	0x00000000
   80060:	80000000 	.word	0x80000000
   80064:	00000000 	.word	0x00000000
   80068:	000001c5 	.word	0x000001c5
   8006c:	00000000 	.word	0x00000000

Disassembly of section .text:

0000000000080800 <enable_interrupt_controller>:
    "FIQ_INVALID_EL0_32",		
    "ERROR_INVALID_EL0_32"	
};

void enable_interrupt_controller()
{
   80800:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   80804:	910003fd 	mov	x29, sp
    // Enables Core 0 Timers interrupt control for the generic timer 
    put32(TIMER_INT_CTRL_0, TIMER_INT_CTRL_0_VALUE);
   80808:	52800041 	mov	w1, #0x2                   	// #2
   8080c:	d2800800 	mov	x0, #0x40                  	// #64
   80810:	f2a80000 	movk	x0, #0x4000, lsl #16
   80814:	94000ba7 	bl	836b0 <put32>
}
   80818:	d503201f 	nop
   8081c:	a8c17bfd 	ldp	x29, x30, [sp], #16
   80820:	d65f03c0 	ret

0000000000080824 <show_invalid_entry_message>:

void show_invalid_entry_message(int type, unsigned long esr, unsigned long address)
{
   80824:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   80828:	910003fd 	mov	x29, sp
   8082c:	b9002fe0 	str	w0, [sp, #44]
   80830:	f90013e1 	str	x1, [sp, #32]
   80834:	f9000fe2 	str	x2, [sp, #24]
    printf("%s, ESR: %x, address: %x\r\n", entry_error_messages[type], esr, address);
   80838:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   8083c:	913d2000 	add	x0, x0, #0xf48
   80840:	b9802fe1 	ldrsw	x1, [sp, #44]
   80844:	f8617800 	ldr	x0, [x0, x1, lsl #3]
   80848:	f9400fe3 	ldr	x3, [sp, #24]
   8084c:	f94013e2 	ldr	x2, [sp, #32]
   80850:	aa0003e1 	mov	x1, x0
   80854:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80858:	91214000 	add	x0, x0, #0x850
   8085c:	940005bb 	bl	81f48 <tfp_printf>
}
   80860:	d503201f 	nop
   80864:	a8c37bfd 	ldp	x29, x30, [sp], #48
   80868:	d65f03c0 	ret

000000000008086c <handle_irq>:

void handle_irq(void)
{
   8086c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   80870:	910003fd 	mov	x29, sp
    // Each Core has its own pending local intrrupts register
    unsigned int sp = get_sp() + S_FRAME_SIZE + 32;
   80874:	94000b8a 	bl	8369c <get_sp>
   80878:	1104c000 	add	w0, w0, #0x130
   8087c:	b9001fe0 	str	w0, [sp, #28]
    unsigned int time = get_time_ms();
   80880:	9400033d 	bl	81574 <get_time_ms>
   80884:	b9001be0 	str	w0, [sp, #24]
    unsigned int pc = get_interrupt_pc();
   80888:	94000b83 	bl	83694 <get_interrupt_pc>
   8088c:	b90017e0 	str	w0, [sp, #20]


    unsigned int irq = get32(INT_SOURCE_0);
   80890:	d2800c00 	mov	x0, #0x60                  	// #96
   80894:	f2a80000 	movk	x0, #0x4000, lsl #16
   80898:	94000b88 	bl	836b8 <get32>
   8089c:	b90013e0 	str	w0, [sp, #16]
    switch (irq) {
   808a0:	b94013e0 	ldr	w0, [sp, #16]
   808a4:	7100081f 	cmp	w0, #0x2
   808a8:	540000e1 	b.ne	808c4 <handle_irq+0x58>  // b.any
        case (GENERIC_TIMER_INTERRUPT):
            init_trace(time, pc, sp);
   808ac:	b9401be0 	ldr	w0, [sp, #24]
   808b0:	b94017e1 	ldr	w1, [sp, #20]
   808b4:	b9401fe2 	ldr	w2, [sp, #28]
   808b8:	94000271 	bl	8127c <init_trace>
            handle_generic_timer_irq();
   808bc:	94000324 	bl	8154c <handle_generic_timer_irq>
            break;
   808c0:	14000006 	b	808d8 <handle_irq+0x6c>
        default:
            printf("Unknown pending irq: %x\r\n", irq);
   808c4:	b94013e1 	ldr	w1, [sp, #16]
   808c8:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   808cc:	9121c000 	add	x0, x0, #0x870
   808d0:	9400059e 	bl	81f48 <tfp_printf>
    }
   808d4:	d503201f 	nop
   808d8:	d503201f 	nop
   808dc:	a8c27bfd 	ldp	x29, x30, [sp], #32
   808e0:	d65f03c0 	ret

00000000000808e4 <get_free_page>:
#include "mm.h"

static unsigned short mem_map [ PAGING_PAGES ] = {0,};

unsigned long get_free_page()
{
   808e4:	d10043ff 	sub	sp, sp, #0x10
	for (int i = 0; i < PAGING_PAGES; i++){
   808e8:	b9000fff 	str	wzr, [sp, #12]
   808ec:	14000014 	b	8093c <get_free_page+0x58>
		if (mem_map[i] == 0){
   808f0:	90000020 	adrp	x0, 84000 <task+0x30>
   808f4:	91086000 	add	x0, x0, #0x218
   808f8:	b9800fe1 	ldrsw	x1, [sp, #12]
   808fc:	78617800 	ldrh	w0, [x0, x1, lsl #1]
   80900:	7100001f 	cmp	w0, #0x0
   80904:	54000161 	b.ne	80930 <get_free_page+0x4c>  // b.any
			mem_map[i] = 1;
   80908:	90000020 	adrp	x0, 84000 <task+0x30>
   8090c:	91086000 	add	x0, x0, #0x218
   80910:	b9800fe1 	ldrsw	x1, [sp, #12]
   80914:	52800022 	mov	w2, #0x1                   	// #1
   80918:	78217802 	strh	w2, [x0, x1, lsl #1]
			return LOW_MEMORY + i*PAGE_SIZE;
   8091c:	b9400fe0 	ldr	w0, [sp, #12]
   80920:	11100000 	add	w0, w0, #0x400
   80924:	53144c00 	lsl	w0, w0, #12
   80928:	93407c00 	sxtw	x0, w0
   8092c:	1400000a 	b	80954 <get_free_page+0x70>
	for (int i = 0; i < PAGING_PAGES; i++){
   80930:	b9400fe0 	ldr	w0, [sp, #12]
   80934:	11000400 	add	w0, w0, #0x1
   80938:	b9000fe0 	str	w0, [sp, #12]
   8093c:	b9400fe1 	ldr	w1, [sp, #12]
   80940:	529d7fe0 	mov	w0, #0xebff                	// #60415
   80944:	72a00060 	movk	w0, #0x3, lsl #16
   80948:	6b00003f 	cmp	w1, w0
   8094c:	54fffd2d 	b.le	808f0 <get_free_page+0xc>
		}
	}
	return 0;
   80950:	d2800000 	mov	x0, #0x0                   	// #0
}
   80954:	910043ff 	add	sp, sp, #0x10
   80958:	d65f03c0 	ret

000000000008095c <free_page>:

void free_page(unsigned long p){
   8095c:	d10043ff 	sub	sp, sp, #0x10
   80960:	f90007e0 	str	x0, [sp, #8]
	mem_map[(p - LOW_MEMORY) / PAGE_SIZE] = 0;
   80964:	f94007e0 	ldr	x0, [sp, #8]
   80968:	d1500000 	sub	x0, x0, #0x400, lsl #12
   8096c:	d34cfc01 	lsr	x1, x0, #12
   80970:	90000020 	adrp	x0, 84000 <task+0x30>
   80974:	91086000 	add	x0, x0, #0x218
   80978:	7821781f 	strh	wzr, [x0, x1, lsl #1]
}
   8097c:	d503201f 	nop
   80980:	910043ff 	add	sp, sp, #0x10
   80984:	d65f03c0 	ret

0000000000080988 <uart_send>:
#include "utils.h"
#include "peripherals/mini_uart.h"
#include "peripherals/gpio.h"

void uart_send ( char c )
{
   80988:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   8098c:	910003fd 	mov	x29, sp
   80990:	39007fe0 	strb	w0, [sp, #31]
	while(1) {
		if(get32(AUX_MU_LSR_REG)&0x20) 
   80994:	d28a0a80 	mov	x0, #0x5054                	// #20564
   80998:	f2a7e420 	movk	x0, #0x3f21, lsl #16
   8099c:	94000b47 	bl	836b8 <get32>
   809a0:	121b0000 	and	w0, w0, #0x20
   809a4:	7100001f 	cmp	w0, #0x0
   809a8:	54000041 	b.ne	809b0 <uart_send+0x28>  // b.any
   809ac:	17fffffa 	b	80994 <uart_send+0xc>
			break;
   809b0:	d503201f 	nop
	}
	put32(AUX_MU_IO_REG,c);
   809b4:	39407fe0 	ldrb	w0, [sp, #31]
   809b8:	2a0003e1 	mov	w1, w0
   809bc:	d28a0800 	mov	x0, #0x5040                	// #20544
   809c0:	f2a7e420 	movk	x0, #0x3f21, lsl #16
   809c4:	94000b3b 	bl	836b0 <put32>
}
   809c8:	d503201f 	nop
   809cc:	a8c27bfd 	ldp	x29, x30, [sp], #32
   809d0:	d65f03c0 	ret

00000000000809d4 <uart_recv>:

char uart_recv ( void )
{
   809d4:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   809d8:	910003fd 	mov	x29, sp
	while(1) {
		if(get32(AUX_MU_LSR_REG)&0x01) 
   809dc:	d28a0a80 	mov	x0, #0x5054                	// #20564
   809e0:	f2a7e420 	movk	x0, #0x3f21, lsl #16
   809e4:	94000b35 	bl	836b8 <get32>
   809e8:	12000000 	and	w0, w0, #0x1
   809ec:	7100001f 	cmp	w0, #0x0
   809f0:	54000041 	b.ne	809f8 <uart_recv+0x24>  // b.any
   809f4:	17fffffa 	b	809dc <uart_recv+0x8>
			break;
   809f8:	d503201f 	nop
	}
	return(get32(AUX_MU_IO_REG)&0xFF);
   809fc:	d28a0800 	mov	x0, #0x5040                	// #20544
   80a00:	f2a7e420 	movk	x0, #0x3f21, lsl #16
   80a04:	94000b2d 	bl	836b8 <get32>
   80a08:	12001c00 	and	w0, w0, #0xff
}
   80a0c:	a8c17bfd 	ldp	x29, x30, [sp], #16
   80a10:	d65f03c0 	ret

0000000000080a14 <uart_send_string>:

void uart_send_string(char* str)
{
   80a14:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   80a18:	910003fd 	mov	x29, sp
   80a1c:	f9000fe0 	str	x0, [sp, #24]
	for (int i = 0; str[i] != '\0'; i ++) {
   80a20:	b9002fff 	str	wzr, [sp, #44]
   80a24:	14000009 	b	80a48 <uart_send_string+0x34>
		uart_send((char)str[i]);
   80a28:	b9802fe0 	ldrsw	x0, [sp, #44]
   80a2c:	f9400fe1 	ldr	x1, [sp, #24]
   80a30:	8b000020 	add	x0, x1, x0
   80a34:	39400000 	ldrb	w0, [x0]
   80a38:	97ffffd4 	bl	80988 <uart_send>
	for (int i = 0; str[i] != '\0'; i ++) {
   80a3c:	b9402fe0 	ldr	w0, [sp, #44]
   80a40:	11000400 	add	w0, w0, #0x1
   80a44:	b9002fe0 	str	w0, [sp, #44]
   80a48:	b9802fe0 	ldrsw	x0, [sp, #44]
   80a4c:	f9400fe1 	ldr	x1, [sp, #24]
   80a50:	8b000020 	add	x0, x1, x0
   80a54:	39400000 	ldrb	w0, [x0]
   80a58:	7100001f 	cmp	w0, #0x0
   80a5c:	54fffe61 	b.ne	80a28 <uart_send_string+0x14>  // b.any
	}
}
   80a60:	d503201f 	nop
   80a64:	d503201f 	nop
   80a68:	a8c37bfd 	ldp	x29, x30, [sp], #48
   80a6c:	d65f03c0 	ret

0000000000080a70 <uart_init>:

void uart_init ( void )
{
   80a70:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   80a74:	910003fd 	mov	x29, sp
	unsigned int selector;

	selector = get32(GPFSEL1);
   80a78:	d2800080 	mov	x0, #0x4                   	// #4
   80a7c:	f2a7e400 	movk	x0, #0x3f20, lsl #16
   80a80:	94000b0e 	bl	836b8 <get32>
   80a84:	b9001fe0 	str	w0, [sp, #28]
	selector &= ~(7<<12);                   // clean gpio14
   80a88:	b9401fe0 	ldr	w0, [sp, #28]
   80a8c:	12117000 	and	w0, w0, #0xffff8fff
   80a90:	b9001fe0 	str	w0, [sp, #28]
	selector |= 2<<12;                      // set alt5 for gpio14
   80a94:	b9401fe0 	ldr	w0, [sp, #28]
   80a98:	32130000 	orr	w0, w0, #0x2000
   80a9c:	b9001fe0 	str	w0, [sp, #28]
	selector &= ~(7<<15);                   // clean gpio15
   80aa0:	b9401fe0 	ldr	w0, [sp, #28]
   80aa4:	120e7000 	and	w0, w0, #0xfffc7fff
   80aa8:	b9001fe0 	str	w0, [sp, #28]
	selector |= 2<<15;                      // set alt5 for gpio15
   80aac:	b9401fe0 	ldr	w0, [sp, #28]
   80ab0:	32100000 	orr	w0, w0, #0x10000
   80ab4:	b9001fe0 	str	w0, [sp, #28]
	put32(GPFSEL1,selector);
   80ab8:	b9401fe1 	ldr	w1, [sp, #28]
   80abc:	d2800080 	mov	x0, #0x4                   	// #4
   80ac0:	f2a7e400 	movk	x0, #0x3f20, lsl #16
   80ac4:	94000afb 	bl	836b0 <put32>

	put32(GPPUD,0);
   80ac8:	52800001 	mov	w1, #0x0                   	// #0
   80acc:	d2801280 	mov	x0, #0x94                  	// #148
   80ad0:	f2a7e400 	movk	x0, #0x3f20, lsl #16
   80ad4:	94000af7 	bl	836b0 <put32>
	delay(150);
   80ad8:	d28012c0 	mov	x0, #0x96                  	// #150
   80adc:	94000af9 	bl	836c0 <delay>
	put32(GPPUDCLK0,(1<<14)|(1<<15));
   80ae0:	52980001 	mov	w1, #0xc000                	// #49152
   80ae4:	d2801300 	mov	x0, #0x98                  	// #152
   80ae8:	f2a7e400 	movk	x0, #0x3f20, lsl #16
   80aec:	94000af1 	bl	836b0 <put32>
	delay(150);
   80af0:	d28012c0 	mov	x0, #0x96                  	// #150
   80af4:	94000af3 	bl	836c0 <delay>
	put32(GPPUDCLK0,0);
   80af8:	52800001 	mov	w1, #0x0                   	// #0
   80afc:	d2801300 	mov	x0, #0x98                  	// #152
   80b00:	f2a7e400 	movk	x0, #0x3f20, lsl #16
   80b04:	94000aeb 	bl	836b0 <put32>

	put32(AUX_ENABLES,1);                   //Enable mini uart (this also enables access to it registers)
   80b08:	52800021 	mov	w1, #0x1                   	// #1
   80b0c:	d28a0080 	mov	x0, #0x5004                	// #20484
   80b10:	f2a7e420 	movk	x0, #0x3f21, lsl #16
   80b14:	94000ae7 	bl	836b0 <put32>
	put32(AUX_MU_CNTL_REG,0);               //Disable auto flow control and disable receiver and transmitter (for now)
   80b18:	52800001 	mov	w1, #0x0                   	// #0
   80b1c:	d28a0c00 	mov	x0, #0x5060                	// #20576
   80b20:	f2a7e420 	movk	x0, #0x3f21, lsl #16
   80b24:	94000ae3 	bl	836b0 <put32>
	put32(AUX_MU_IER_REG,0);                //Disable receive and transmit interrupts
   80b28:	52800001 	mov	w1, #0x0                   	// #0
   80b2c:	d28a0880 	mov	x0, #0x5044                	// #20548
   80b30:	f2a7e420 	movk	x0, #0x3f21, lsl #16
   80b34:	94000adf 	bl	836b0 <put32>
	put32(AUX_MU_LCR_REG,3);                //Enable 8 bit mode
   80b38:	52800061 	mov	w1, #0x3                   	// #3
   80b3c:	d28a0980 	mov	x0, #0x504c                	// #20556
   80b40:	f2a7e420 	movk	x0, #0x3f21, lsl #16
   80b44:	94000adb 	bl	836b0 <put32>
	put32(AUX_MU_MCR_REG,0);                //Set RTS line to be always high
   80b48:	52800001 	mov	w1, #0x0                   	// #0
   80b4c:	d28a0a00 	mov	x0, #0x5050                	// #20560
   80b50:	f2a7e420 	movk	x0, #0x3f21, lsl #16
   80b54:	94000ad7 	bl	836b0 <put32>
	put32(AUX_MU_BAUD_REG,270);             //Set baud rate to 115200
   80b58:	528021c1 	mov	w1, #0x10e                 	// #270
   80b5c:	d28a0d00 	mov	x0, #0x5068                	// #20584
   80b60:	f2a7e420 	movk	x0, #0x3f21, lsl #16
   80b64:	94000ad3 	bl	836b0 <put32>

	put32(AUX_MU_CNTL_REG,3);               //Finally, enable transmitter and receiver
   80b68:	52800061 	mov	w1, #0x3                   	// #3
   80b6c:	d28a0c00 	mov	x0, #0x5060                	// #20576
   80b70:	f2a7e420 	movk	x0, #0x3f21, lsl #16
   80b74:	94000acf 	bl	836b0 <put32>
}
   80b78:	d503201f 	nop
   80b7c:	a8c27bfd 	ldp	x29, x30, [sp], #32
   80b80:	d65f03c0 	ret

0000000000080b84 <putc>:


// This function is required by printf function
void putc ( void* p, char c)
{
   80b84:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   80b88:	910003fd 	mov	x29, sp
   80b8c:	f9000fe0 	str	x0, [sp, #24]
   80b90:	39005fe1 	strb	w1, [sp, #23]
	uart_send(c);
   80b94:	39405fe0 	ldrb	w0, [sp, #23]
   80b98:	97ffff7c 	bl	80988 <uart_send>
}
   80b9c:	d503201f 	nop
   80ba0:	a8c27bfd 	ldp	x29, x30, [sp], #32
   80ba4:	d65f03c0 	ret

0000000000080ba8 <preempt_disable>:
int num_traces = 0;
int nr_tasks = 1;

void preempt_disable(void)
{
	current->preempt_count++;
   80ba8:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80bac:	913f2000 	add	x0, x0, #0xfc8
   80bb0:	f9400000 	ldr	x0, [x0]
   80bb4:	f9404001 	ldr	x1, [x0, #128]
   80bb8:	91000421 	add	x1, x1, #0x1
   80bbc:	f9004001 	str	x1, [x0, #128]
}
   80bc0:	d503201f 	nop
   80bc4:	d65f03c0 	ret

0000000000080bc8 <preempt_enable>:

void preempt_enable(void)
{
	current->preempt_count--;
   80bc8:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80bcc:	913f2000 	add	x0, x0, #0xfc8
   80bd0:	f9400000 	ldr	x0, [x0]
   80bd4:	f9404001 	ldr	x1, [x0, #128]
   80bd8:	d1000421 	sub	x1, x1, #0x1
   80bdc:	f9004001 	str	x1, [x0, #128]
}
   80be0:	d503201f 	nop
   80be4:	d65f03c0 	ret

0000000000080be8 <_schedule>:

void _schedule(void)
{
   80be8:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   80bec:	910003fd 	mov	x29, sp
	/* ensure no context happens in the following code region
		we still leave irq on, because irq handler may set a task to be TASK_RUNNING, which
		will be picked up by the scheduler below */
	preempt_disable();
   80bf0:	97ffffee 	bl	80ba8 <preempt_disable>
	int next, c;
	struct task_struct *p;
	while (1)
	{
		c = -1; // the maximum counter of all tasks
   80bf4:	12800000 	mov	w0, #0xffffffff            	// #-1
   80bf8:	b9002be0 	str	w0, [sp, #40]
		next = 0;
   80bfc:	b9002fff 	str	wzr, [sp, #44]
		/* Iterates over all tasks and tries to find a task in
		TASK_RUNNING state with the maximum counter. If such
		a task is found, we immediately break from the while loop
		and switch to this task. */

		for (int i = 0; i < NR_TASKS; i++)
   80c00:	b90027ff 	str	wzr, [sp, #36]
   80c04:	1400001a 	b	80c6c <_schedule+0x84>
		{
			p = task[i];
   80c08:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80c0c:	913f4000 	add	x0, x0, #0xfd0
   80c10:	b98027e1 	ldrsw	x1, [sp, #36]
   80c14:	f8617800 	ldr	x0, [x0, x1, lsl #3]
   80c18:	f9000fe0 	str	x0, [sp, #24]
			if (p && p->state == TASK_RUNNING && p->counter > c)
   80c1c:	f9400fe0 	ldr	x0, [sp, #24]
   80c20:	f100001f 	cmp	x0, #0x0
   80c24:	540001e0 	b.eq	80c60 <_schedule+0x78>  // b.none
   80c28:	f9400fe0 	ldr	x0, [sp, #24]
   80c2c:	f9403400 	ldr	x0, [x0, #104]
   80c30:	f100001f 	cmp	x0, #0x0
   80c34:	54000161 	b.ne	80c60 <_schedule+0x78>  // b.any
   80c38:	f9400fe0 	ldr	x0, [sp, #24]
   80c3c:	f9403801 	ldr	x1, [x0, #112]
   80c40:	b9802be0 	ldrsw	x0, [sp, #40]
   80c44:	eb00003f 	cmp	x1, x0
   80c48:	540000cd 	b.le	80c60 <_schedule+0x78>
			{
				c = p->counter;
   80c4c:	f9400fe0 	ldr	x0, [sp, #24]
   80c50:	f9403800 	ldr	x0, [x0, #112]
   80c54:	b9002be0 	str	w0, [sp, #40]
				next = i;
   80c58:	b94027e0 	ldr	w0, [sp, #36]
   80c5c:	b9002fe0 	str	w0, [sp, #44]
		for (int i = 0; i < NR_TASKS; i++)
   80c60:	b94027e0 	ldr	w0, [sp, #36]
   80c64:	11000400 	add	w0, w0, #0x1
   80c68:	b90027e0 	str	w0, [sp, #36]
   80c6c:	b94027e0 	ldr	w0, [sp, #36]
   80c70:	7100fc1f 	cmp	w0, #0x3f
   80c74:	54fffcad 	b.le	80c08 <_schedule+0x20>
			}
		}
		if (c)
   80c78:	b9402be0 	ldr	w0, [sp, #40]
   80c7c:	7100001f 	cmp	w0, #0x0
   80c80:	54000341 	b.ne	80ce8 <_schedule+0x100>  // b.any
		/* If no such task is found, this is either because i) no
		task is in TASK_RUNNING state or ii) all such tasks have 0 counters.
		in our current implemenation which misses TASK_WAIT, only condition ii) is possible.
		Hence, we recharge counters. Bump counters for all tasks once. */

		for (int i = 0; i < NR_TASKS; i++)
   80c84:	b90023ff 	str	wzr, [sp, #32]
   80c88:	14000014 	b	80cd8 <_schedule+0xf0>
		{
			p = task[i];
   80c8c:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80c90:	913f4000 	add	x0, x0, #0xfd0
   80c94:	b98023e1 	ldrsw	x1, [sp, #32]
   80c98:	f8617800 	ldr	x0, [x0, x1, lsl #3]
   80c9c:	f9000fe0 	str	x0, [sp, #24]
			if (p)
   80ca0:	f9400fe0 	ldr	x0, [sp, #24]
   80ca4:	f100001f 	cmp	x0, #0x0
   80ca8:	54000120 	b.eq	80ccc <_schedule+0xe4>  // b.none
			{
				p->counter = (p->counter >> 1) + p->priority;
   80cac:	f9400fe0 	ldr	x0, [sp, #24]
   80cb0:	f9403800 	ldr	x0, [x0, #112]
   80cb4:	9341fc01 	asr	x1, x0, #1
   80cb8:	f9400fe0 	ldr	x0, [sp, #24]
   80cbc:	f9403c00 	ldr	x0, [x0, #120]
   80cc0:	8b000021 	add	x1, x1, x0
   80cc4:	f9400fe0 	ldr	x0, [sp, #24]
   80cc8:	f9003801 	str	x1, [x0, #112]
		for (int i = 0; i < NR_TASKS; i++)
   80ccc:	b94023e0 	ldr	w0, [sp, #32]
   80cd0:	11000400 	add	w0, w0, #0x1
   80cd4:	b90023e0 	str	w0, [sp, #32]
   80cd8:	b94023e0 	ldr	w0, [sp, #32]
   80cdc:	7100fc1f 	cmp	w0, #0x3f
   80ce0:	54fffd6d 	b.le	80c8c <_schedule+0xa4>
		c = -1; // the maximum counter of all tasks
   80ce4:	17ffffc4 	b	80bf4 <_schedule+0xc>
			break;
   80ce8:	d503201f 	nop
			}
		}
	}
	switch_to(task[next]);
   80cec:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80cf0:	913f4000 	add	x0, x0, #0xfd0
   80cf4:	b9802fe1 	ldrsw	x1, [sp, #44]
   80cf8:	f8617800 	ldr	x0, [x0, x1, lsl #3]
   80cfc:	940000a9 	bl	80fa0 <switch_to>
	preempt_enable();
   80d00:	97ffffb2 	bl	80bc8 <preempt_enable>
}
   80d04:	d503201f 	nop
   80d08:	a8c37bfd 	ldp	x29, x30, [sp], #48
   80d0c:	d65f03c0 	ret

0000000000080d10 <schedule>:

void schedule(void)
{
   80d10:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   80d14:	910003fd 	mov	x29, sp
	current->counter = 0;
   80d18:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80d1c:	913f2000 	add	x0, x0, #0xfc8
   80d20:	f9400000 	ldr	x0, [x0]
   80d24:	f900381f 	str	xzr, [x0, #112]
	_schedule();
   80d28:	97ffffb0 	bl	80be8 <_schedule>
}
   80d2c:	d503201f 	nop
   80d30:	a8c17bfd 	ldp	x29, x30, [sp], #16
   80d34:	d65f03c0 	ret

0000000000080d38 <initialize_trace_arrays>:
// 	}
// 	return 0;
// }

void initialize_trace_arrays()
{
   80d38:	d10103ff 	sub	sp, sp, #0x40
	trace_struct initial_trace = {
   80d3c:	a9007fff 	stp	xzr, xzr, [sp]
   80d40:	a9017fff 	stp	xzr, xzr, [sp, #16]
   80d44:	a9027fff 	stp	xzr, xzr, [sp, #32]
   80d48:	f9001bff 	str	xzr, [sp, #48]
   80d4c:	12800000 	mov	w0, #0xffffffff            	// #-1
   80d50:	b9000be0 	str	w0, [sp, #8]
   80d54:	12800000 	mov	w0, #0xffffffff            	// #-1
   80d58:	b90023e0 	str	w0, [sp, #32]
		.sp_from = 0,
		.sp_to = 0,
		.pc_from = 0,
		.pc_to = 0};

	for (int i = 0; i < MAX_TRACES; i++)
   80d5c:	b9003fff 	str	wzr, [sp, #60]
   80d60:	14000016 	b	80db8 <initialize_trace_arrays+0x80>
	{
		traces[i] = initial_trace;
   80d64:	b0000400 	adrp	x0, 101000 <mem_map+0x7cde8>
   80d68:	91286002 	add	x2, x0, #0xa18
   80d6c:	b9803fe1 	ldrsw	x1, [sp, #60]
   80d70:	aa0103e0 	mov	x0, x1
   80d74:	d37df000 	lsl	x0, x0, #3
   80d78:	cb010000 	sub	x0, x0, x1
   80d7c:	d37df000 	lsl	x0, x0, #3
   80d80:	8b000040 	add	x0, x2, x0
   80d84:	aa0003e1 	mov	x1, x0
   80d88:	910003e0 	mov	x0, sp
   80d8c:	a9400c02 	ldp	x2, x3, [x0]
   80d90:	a9000c22 	stp	x2, x3, [x1]
   80d94:	a9410c02 	ldp	x2, x3, [x0, #16]
   80d98:	a9010c22 	stp	x2, x3, [x1, #16]
   80d9c:	a9420c02 	ldp	x2, x3, [x0, #32]
   80da0:	a9020c22 	stp	x2, x3, [x1, #32]
   80da4:	f9401800 	ldr	x0, [x0, #48]
   80da8:	f9001820 	str	x0, [x1, #48]
	for (int i = 0; i < MAX_TRACES; i++)
   80dac:	b9403fe0 	ldr	w0, [sp, #60]
   80db0:	11000400 	add	w0, w0, #0x1
   80db4:	b9003fe0 	str	w0, [sp, #60]
   80db8:	b9403fe0 	ldr	w0, [sp, #60]
   80dbc:	7100c41f 	cmp	w0, #0x31
   80dc0:	54fffd2d 	b.le	80d64 <initialize_trace_arrays+0x2c>
	}

	for (int i = 0; i < NR_TASKS; i++)
   80dc4:	b9003bff 	str	wzr, [sp, #56]
   80dc8:	14000016 	b	80e20 <initialize_trace_arrays+0xe8>
	{
		most_recent[i] = initial_trace;
   80dcc:	d0000400 	adrp	x0, 102000 <traces+0x5e8>
   80dd0:	91142002 	add	x2, x0, #0x508
   80dd4:	b9803be1 	ldrsw	x1, [sp, #56]
   80dd8:	aa0103e0 	mov	x0, x1
   80ddc:	d37df000 	lsl	x0, x0, #3
   80de0:	cb010000 	sub	x0, x0, x1
   80de4:	d37df000 	lsl	x0, x0, #3
   80de8:	8b000040 	add	x0, x2, x0
   80dec:	aa0003e1 	mov	x1, x0
   80df0:	910003e0 	mov	x0, sp
   80df4:	a9400c02 	ldp	x2, x3, [x0]
   80df8:	a9000c22 	stp	x2, x3, [x1]
   80dfc:	a9410c02 	ldp	x2, x3, [x0, #16]
   80e00:	a9010c22 	stp	x2, x3, [x1, #16]
   80e04:	a9420c02 	ldp	x2, x3, [x0, #32]
   80e08:	a9020c22 	stp	x2, x3, [x1, #32]
   80e0c:	f9401800 	ldr	x0, [x0, #48]
   80e10:	f9001820 	str	x0, [x1, #48]
	for (int i = 0; i < NR_TASKS; i++)
   80e14:	b9403be0 	ldr	w0, [sp, #56]
   80e18:	11000400 	add	w0, w0, #0x1
   80e1c:	b9003be0 	str	w0, [sp, #56]
   80e20:	b9403be0 	ldr	w0, [sp, #56]
   80e24:	7100fc1f 	cmp	w0, #0x3f
   80e28:	54fffd2d 	b.le	80dcc <initialize_trace_arrays+0x94>
	}
}
   80e2c:	d503201f 	nop
   80e30:	d503201f 	nop
   80e34:	910103ff 	add	sp, sp, #0x40
   80e38:	d65f03c0 	ret

0000000000080e3c <update_new_trace>:

void update_new_trace()
{
   80e3c:	a9b77bfd 	stp	x29, x30, [sp, #-144]!
   80e40:	910003fd 	mov	x29, sp
	int schedule_in_pid = get_pid();
   80e44:	9400018c 	bl	81474 <get_pid>
   80e48:	b9008fe0 	str	w0, [sp, #140]
	trace_struct schedule_out_trace = traces[num_traces - 1];
   80e4c:	f0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   80e50:	910c2000 	add	x0, x0, #0x308
   80e54:	b9400000 	ldr	w0, [x0]
   80e58:	51000401 	sub	w1, w0, #0x1
   80e5c:	b0000400 	adrp	x0, 101000 <mem_map+0x7cde8>
   80e60:	91286002 	add	x2, x0, #0xa18
   80e64:	93407c21 	sxtw	x1, w1
   80e68:	aa0103e0 	mov	x0, x1
   80e6c:	d37df000 	lsl	x0, x0, #3
   80e70:	cb010000 	sub	x0, x0, x1
   80e74:	d37df000 	lsl	x0, x0, #3
   80e78:	8b000041 	add	x1, x2, x0
   80e7c:	910143e0 	add	x0, sp, #0x50
   80e80:	a9400c22 	ldp	x2, x3, [x1]
   80e84:	a9000c02 	stp	x2, x3, [x0]
   80e88:	a9410c22 	ldp	x2, x3, [x1, #16]
   80e8c:	a9010c02 	stp	x2, x3, [x0, #16]
   80e90:	a9420c22 	ldp	x2, x3, [x1, #32]
   80e94:	a9020c02 	stp	x2, x3, [x0, #32]
   80e98:	f9401821 	ldr	x1, [x1, #48]
   80e9c:	f9001801 	str	x1, [x0, #48]
	// Most recent trace of the scheduled in task
	trace_struct most_recent_trace = most_recent[schedule_in_pid];
   80ea0:	d0000400 	adrp	x0, 102000 <traces+0x5e8>
   80ea4:	91142002 	add	x2, x0, #0x508
   80ea8:	b9808fe1 	ldrsw	x1, [sp, #140]
   80eac:	aa0103e0 	mov	x0, x1
   80eb0:	d37df000 	lsl	x0, x0, #3
   80eb4:	cb010000 	sub	x0, x0, x1
   80eb8:	d37df000 	lsl	x0, x0, #3
   80ebc:	8b000041 	add	x1, x2, x0
   80ec0:	910063e0 	add	x0, sp, #0x18
   80ec4:	a9400c22 	ldp	x2, x3, [x1]
   80ec8:	a9000c02 	stp	x2, x3, [x0]
   80ecc:	a9410c22 	ldp	x2, x3, [x1, #16]
   80ed0:	a9010c02 	stp	x2, x3, [x0, #16]
   80ed4:	a9420c22 	ldp	x2, x3, [x1, #32]
   80ed8:	a9020c02 	stp	x2, x3, [x0, #32]
   80edc:	f9401821 	ldr	x1, [x1, #48]
   80ee0:	f9001801 	str	x1, [x0, #48]

	schedule_out_trace.id_to = schedule_in_pid;
   80ee4:	b9408fe0 	ldr	w0, [sp, #140]
   80ee8:	b90073e0 	str	w0, [sp, #112]
	// schedule_out_trace.timestamp = get_time_ms();

	if (most_recent_trace.id_from != -1)
   80eec:	b94023e0 	ldr	w0, [sp, #32]
   80ef0:	3100041f 	cmn	w0, #0x1
   80ef4:	540000c0 	b.eq	80f0c <update_new_trace+0xd0>  // b.none
	{
		// printf("From %d to %d \n", schedule_out_trace->id_from, most_recent_trace->id_from);
		schedule_out_trace.pc_to = most_recent_trace.pc_from;
   80ef8:	f94017e0 	ldr	x0, [sp, #40]
   80efc:	f9003fe0 	str	x0, [sp, #120]
		schedule_out_trace.sp_to = most_recent_trace.sp_from;
   80f00:	f9401be0 	ldr	x0, [sp, #48]
   80f04:	f90043e0 	str	x0, [sp, #128]
   80f08:	1400000d 	b	80f3c <update_new_trace+0x100>
	}
	else
	{
		// This is the first time that we have run the task
		schedule_out_trace.pc_to = task[schedule_in_pid]->cpu_context.pc;
   80f0c:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80f10:	913f4000 	add	x0, x0, #0xfd0
   80f14:	b9808fe1 	ldrsw	x1, [sp, #140]
   80f18:	f8617800 	ldr	x0, [x0, x1, lsl #3]
   80f1c:	f9403000 	ldr	x0, [x0, #96]
   80f20:	f9003fe0 	str	x0, [sp, #120]
		schedule_out_trace.sp_to = task[schedule_in_pid]->cpu_context.sp;
   80f24:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80f28:	913f4000 	add	x0, x0, #0xfd0
   80f2c:	b9808fe1 	ldrsw	x1, [sp, #140]
   80f30:	f8617800 	ldr	x0, [x0, x1, lsl #3]
   80f34:	f9402c00 	ldr	x0, [x0, #88]
   80f38:	f90043e0 	str	x0, [sp, #128]
	}

	traces[num_traces - 1] = schedule_out_trace;
   80f3c:	f0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   80f40:	910c2000 	add	x0, x0, #0x308
   80f44:	b9400000 	ldr	w0, [x0]
   80f48:	51000401 	sub	w1, w0, #0x1
   80f4c:	b0000400 	adrp	x0, 101000 <mem_map+0x7cde8>
   80f50:	91286002 	add	x2, x0, #0xa18
   80f54:	93407c21 	sxtw	x1, w1
   80f58:	aa0103e0 	mov	x0, x1
   80f5c:	d37df000 	lsl	x0, x0, #3
   80f60:	cb010000 	sub	x0, x0, x1
   80f64:	d37df000 	lsl	x0, x0, #3
   80f68:	8b000040 	add	x0, x2, x0
   80f6c:	aa0003e1 	mov	x1, x0
   80f70:	910143e0 	add	x0, sp, #0x50
   80f74:	a9400c02 	ldp	x2, x3, [x0]
   80f78:	a9000c22 	stp	x2, x3, [x1]
   80f7c:	a9410c02 	ldp	x2, x3, [x0, #16]
   80f80:	a9010c22 	stp	x2, x3, [x1, #16]
   80f84:	a9420c02 	ldp	x2, x3, [x0, #32]
   80f88:	a9020c22 	stp	x2, x3, [x1, #32]
   80f8c:	f9401800 	ldr	x0, [x0, #48]
   80f90:	f9001820 	str	x0, [x1, #48]
	// printf("%d from task%d (PC 0x%x SP 0x%x) to task%d (PC 0x%x SP 0x%x) \n", schedule_out_trace.timestamp, schedule_out_trace.id_from, schedule_out_trace.pc_from, schedule_out_trace.sp_from, schedule_out_trace.id_to, schedule_out_trace.pc_to, schedule_out_trace.sp_to);
}
   80f94:	d503201f 	nop
   80f98:	a8c97bfd 	ldp	x29, x30, [sp], #144
   80f9c:	d65f03c0 	ret

0000000000080fa0 <switch_to>:

void switch_to(struct task_struct *next)
{
   80fa0:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   80fa4:	910003fd 	mov	x29, sp
   80fa8:	f9000fe0 	str	x0, [sp, #24]
	if (current == next)
   80fac:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80fb0:	913f2000 	add	x0, x0, #0xfc8
   80fb4:	f9400000 	ldr	x0, [x0]
   80fb8:	f9400fe1 	ldr	x1, [sp, #24]
   80fbc:	eb00003f 	cmp	x1, x0
   80fc0:	54000280 	b.eq	81010 <switch_to+0x70>  // b.none
		return;
	struct task_struct *prev = current;
   80fc4:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80fc8:	913f2000 	add	x0, x0, #0xfc8
   80fcc:	f9400000 	ldr	x0, [x0]
   80fd0:	f90017e0 	str	x0, [sp, #40]
	current = next;
   80fd4:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80fd8:	913f2000 	add	x0, x0, #0xfc8
   80fdc:	f9400fe1 	ldr	x1, [sp, #24]
   80fe0:	f9000001 	str	x1, [x0]
	if (num_traces > 0)
   80fe4:	f0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   80fe8:	910c2000 	add	x0, x0, #0x308
   80fec:	b9400000 	ldr	w0, [x0]
   80ff0:	7100001f 	cmp	w0, #0x0
   80ff4:	5400006d 	b.le	81000 <switch_to+0x60>
	{
		update_new_trace(next);
   80ff8:	f9400fe0 	ldr	x0, [sp, #24]
   80ffc:	97ffff90 	bl	80e3c <update_new_trace>
	}
	cpu_switch_to(prev, next);
   81000:	f9400fe1 	ldr	x1, [sp, #24]
   81004:	f94017e0 	ldr	x0, [sp, #40]
   81008:	9400098f 	bl	83644 <cpu_switch_to>
   8100c:	14000002 	b	81014 <switch_to+0x74>
		return;
   81010:	d503201f 	nop
}
   81014:	a8c37bfd 	ldp	x29, x30, [sp], #48
   81018:	d65f03c0 	ret

000000000008101c <schedule_tail>:

void schedule_tail(void)
{
   8101c:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   81020:	910003fd 	mov	x29, sp
	preempt_enable();
   81024:	97fffee9 	bl	80bc8 <preempt_enable>
}
   81028:	d503201f 	nop
   8102c:	a8c17bfd 	ldp	x29, x30, [sp], #16
   81030:	d65f03c0 	ret

0000000000081034 <print_all_traces>:

void print_all_traces()
{
   81034:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
   81038:	910003fd 	mov	x29, sp
	for (int i = 0; i < MAX_TRACES; i++)
   8103c:	b9004fff 	str	wzr, [sp, #76]
   81040:	14000026 	b	810d8 <print_all_traces+0xa4>
	{
		trace_struct trace = traces[i];
   81044:	90000400 	adrp	x0, 101000 <mem_map+0x7cde8>
   81048:	91286002 	add	x2, x0, #0xa18
   8104c:	b9804fe1 	ldrsw	x1, [sp, #76]
   81050:	aa0103e0 	mov	x0, x1
   81054:	d37df000 	lsl	x0, x0, #3
   81058:	cb010000 	sub	x0, x0, x1
   8105c:	d37df000 	lsl	x0, x0, #3
   81060:	8b000041 	add	x1, x2, x0
   81064:	910043e0 	add	x0, sp, #0x10
   81068:	a9400c22 	ldp	x2, x3, [x1]
   8106c:	a9000c02 	stp	x2, x3, [x0]
   81070:	a9410c22 	ldp	x2, x3, [x1, #16]
   81074:	a9010c02 	stp	x2, x3, [x0, #16]
   81078:	a9420c22 	ldp	x2, x3, [x1, #32]
   8107c:	a9020c02 	stp	x2, x3, [x0, #32]
   81080:	f9401821 	ldr	x1, [x1, #48]
   81084:	f9001801 	str	x1, [x0, #48]
		printf("%d from task%d (PC 0x%x SP 0x%x) to task%d (PC 0x%x SP 0x%x) \n", trace.timestamp, trace.id_from, trace.pc_from, trace.sp_from, trace.id_to, trace.pc_to, trace.sp_to);
   81088:	f9400be0 	ldr	x0, [sp, #16]
   8108c:	b9401be1 	ldr	w1, [sp, #24]
   81090:	f94013e2 	ldr	x2, [sp, #32]
   81094:	f94017e3 	ldr	x3, [sp, #40]
   81098:	b94033e4 	ldr	w4, [sp, #48]
   8109c:	f9401fe5 	ldr	x5, [sp, #56]
   810a0:	f94023e6 	ldr	x6, [sp, #64]
   810a4:	aa0603e7 	mov	x7, x6
   810a8:	aa0503e6 	mov	x6, x5
   810ac:	2a0403e5 	mov	w5, w4
   810b0:	aa0303e4 	mov	x4, x3
   810b4:	aa0203e3 	mov	x3, x2
   810b8:	2a0103e2 	mov	w2, w1
   810bc:	aa0003e1 	mov	x1, x0
   810c0:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   810c4:	91224000 	add	x0, x0, #0x890
   810c8:	940003a0 	bl	81f48 <tfp_printf>
	for (int i = 0; i < MAX_TRACES; i++)
   810cc:	b9404fe0 	ldr	w0, [sp, #76]
   810d0:	11000400 	add	w0, w0, #0x1
   810d4:	b9004fe0 	str	w0, [sp, #76]
   810d8:	b9404fe0 	ldr	w0, [sp, #76]
   810dc:	7100c41f 	cmp	w0, #0x31
   810e0:	54fffb2d 	b.le	81044 <print_all_traces+0x10>
	}
}
   810e4:	d503201f 	nop
   810e8:	d503201f 	nop
   810ec:	a8c57bfd 	ldp	x29, x30, [sp], #80
   810f0:	d65f03c0 	ret

00000000000810f4 <initialize_trace>:

void initialize_trace()
{
   810f4:	a9b97bfd 	stp	x29, x30, [sp, #-112]!
   810f8:	910003fd 	mov	x29, sp
	int current_pid = get_pid();
   810fc:	940000de 	bl	81474 <get_pid>
   81100:	b9006fe0 	str	w0, [sp, #108]
	unsigned long time = get_time_ms();
   81104:	9400011c 	bl	81574 <get_time_ms>
   81108:	f90033e0 	str	x0, [sp, #96]
	unsigned long current_pc = get_interrupt_pc();
   8110c:	94000962 	bl	83694 <get_interrupt_pc>
   81110:	f9002fe0 	str	x0, [sp, #88]
	unsigned long current_sp = get_sp();
   81114:	94000962 	bl	8369c <get_sp>
   81118:	f9002be0 	str	x0, [sp, #80]

	if (current_pid == -1)
   8111c:	b9406fe0 	ldr	w0, [sp, #108]
   81120:	3100041f 	cmn	w0, #0x1
   81124:	54000a60 	b.eq	81270 <initialize_trace+0x17c>  // b.none
	{
		return;
	}

	trace_struct trace = {
   81128:	f94033e0 	ldr	x0, [sp, #96]
   8112c:	f9000fe0 	str	x0, [sp, #24]
   81130:	b9406fe0 	ldr	w0, [sp, #108]
   81134:	b90023e0 	str	w0, [sp, #32]
   81138:	f9402fe0 	ldr	x0, [sp, #88]
   8113c:	f90017e0 	str	x0, [sp, #40]
   81140:	f9402be0 	ldr	x0, [sp, #80]
   81144:	f9001be0 	str	x0, [sp, #48]
   81148:	12800000 	mov	w0, #0xffffffff            	// #-1
   8114c:	b9003be0 	str	w0, [sp, #56]
   81150:	f90023ff 	str	xzr, [sp, #64]
   81154:	f90027ff 	str	xzr, [sp, #72]
		.sp_from = current_sp,
		.id_to = -1,
		.pc_to = 0,
		.sp_to = 0,
	};
	most_recent[current_pid] = trace;
   81158:	b0000400 	adrp	x0, 102000 <traces+0x5e8>
   8115c:	91142002 	add	x2, x0, #0x508
   81160:	b9806fe1 	ldrsw	x1, [sp, #108]
   81164:	aa0103e0 	mov	x0, x1
   81168:	d37df000 	lsl	x0, x0, #3
   8116c:	cb010000 	sub	x0, x0, x1
   81170:	d37df000 	lsl	x0, x0, #3
   81174:	8b000040 	add	x0, x2, x0
   81178:	aa0003e1 	mov	x1, x0
   8117c:	910063e0 	add	x0, sp, #0x18
   81180:	a9400c02 	ldp	x2, x3, [x0]
   81184:	a9000c22 	stp	x2, x3, [x1]
   81188:	a9410c02 	ldp	x2, x3, [x0, #16]
   8118c:	a9010c22 	stp	x2, x3, [x1, #16]
   81190:	a9420c02 	ldp	x2, x3, [x0, #32]
   81194:	a9020c22 	stp	x2, x3, [x1, #32]
   81198:	f9401800 	ldr	x0, [x0, #48]
   8119c:	f9001820 	str	x0, [x1, #48]

	if (num_traces < MAX_TRACES)
   811a0:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   811a4:	910c2000 	add	x0, x0, #0x308
   811a8:	b9400000 	ldr	w0, [x0]
   811ac:	7100c41f 	cmp	w0, #0x31
   811b0:	540003cc 	b.gt	81228 <initialize_trace+0x134>
	{
		traces[num_traces] = trace;
   811b4:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   811b8:	910c2000 	add	x0, x0, #0x308
   811bc:	b9400001 	ldr	w1, [x0]
   811c0:	90000400 	adrp	x0, 101000 <mem_map+0x7cde8>
   811c4:	91286002 	add	x2, x0, #0xa18
   811c8:	93407c21 	sxtw	x1, w1
   811cc:	aa0103e0 	mov	x0, x1
   811d0:	d37df000 	lsl	x0, x0, #3
   811d4:	cb010000 	sub	x0, x0, x1
   811d8:	d37df000 	lsl	x0, x0, #3
   811dc:	8b000040 	add	x0, x2, x0
   811e0:	aa0003e1 	mov	x1, x0
   811e4:	910063e0 	add	x0, sp, #0x18
   811e8:	a9400c02 	ldp	x2, x3, [x0]
   811ec:	a9000c22 	stp	x2, x3, [x1]
   811f0:	a9410c02 	ldp	x2, x3, [x0, #16]
   811f4:	a9010c22 	stp	x2, x3, [x1, #16]
   811f8:	a9420c02 	ldp	x2, x3, [x0, #32]
   811fc:	a9020c22 	stp	x2, x3, [x1, #32]
   81200:	f9401800 	ldr	x0, [x0, #48]
   81204:	f9001820 	str	x0, [x1, #48]
		num_traces++;
   81208:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   8120c:	910c2000 	add	x0, x0, #0x308
   81210:	b9400000 	ldr	w0, [x0]
   81214:	11000401 	add	w1, w0, #0x1
   81218:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   8121c:	910c2000 	add	x0, x0, #0x308
   81220:	b9000001 	str	w1, [x0]
   81224:	14000014 	b	81274 <initialize_trace+0x180>
	}
	else {
		print_all_traces();
   81228:	97ffff83 	bl	81034 <print_all_traces>
		traces[0] = trace;
   8122c:	90000400 	adrp	x0, 101000 <mem_map+0x7cde8>
   81230:	91286000 	add	x0, x0, #0xa18
   81234:	aa0003e1 	mov	x1, x0
   81238:	910063e0 	add	x0, sp, #0x18
   8123c:	a9400c02 	ldp	x2, x3, [x0]
   81240:	a9000c22 	stp	x2, x3, [x1]
   81244:	a9410c02 	ldp	x2, x3, [x0, #16]
   81248:	a9010c22 	stp	x2, x3, [x1, #16]
   8124c:	a9420c02 	ldp	x2, x3, [x0, #32]
   81250:	a9020c22 	stp	x2, x3, [x1, #32]
   81254:	f9401800 	ldr	x0, [x0, #48]
   81258:	f9001820 	str	x0, [x1, #48]
		num_traces = 1;
   8125c:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81260:	910c2000 	add	x0, x0, #0x308
   81264:	52800021 	mov	w1, #0x1                   	// #1
   81268:	b9000001 	str	w1, [x0]
   8126c:	14000002 	b	81274 <initialize_trace+0x180>
		return;
   81270:	d503201f 	nop
	}
}
   81274:	a8c77bfd 	ldp	x29, x30, [sp], #112
   81278:	d65f03c0 	ret

000000000008127c <init_trace>:

void init_trace(unsigned long time, unsigned long interrupt_pc, unsigned long interrupt_sp){
   8127c:	a9b97bfd 	stp	x29, x30, [sp, #-112]!
   81280:	910003fd 	mov	x29, sp
   81284:	f90017e0 	str	x0, [sp, #40]
   81288:	f90013e1 	str	x1, [sp, #32]
   8128c:	f9000fe2 	str	x2, [sp, #24]
	int current_pid = get_pid();
   81290:	94000079 	bl	81474 <get_pid>
   81294:	b9006fe0 	str	w0, [sp, #108]
	if (current_pid == -1)
   81298:	b9406fe0 	ldr	w0, [sp, #108]
   8129c:	3100041f 	cmn	w0, #0x1
   812a0:	54000a60 	b.eq	813ec <init_trace+0x170>  // b.none
	{
		return;
	}

	trace_struct trace = {
   812a4:	f94017e0 	ldr	x0, [sp, #40]
   812a8:	f9001be0 	str	x0, [sp, #48]
   812ac:	b9406fe0 	ldr	w0, [sp, #108]
   812b0:	b9003be0 	str	w0, [sp, #56]
   812b4:	f94013e0 	ldr	x0, [sp, #32]
   812b8:	f90023e0 	str	x0, [sp, #64]
   812bc:	f9400fe0 	ldr	x0, [sp, #24]
   812c0:	f90027e0 	str	x0, [sp, #72]
   812c4:	12800000 	mov	w0, #0xffffffff            	// #-1
   812c8:	b90053e0 	str	w0, [sp, #80]
   812cc:	f9002fff 	str	xzr, [sp, #88]
   812d0:	f90033ff 	str	xzr, [sp, #96]
		.sp_from = interrupt_sp,
		.id_to = -1,
		.pc_to = 0,
		.sp_to = 0,
	};
	most_recent[current_pid] = trace;
   812d4:	b0000400 	adrp	x0, 102000 <traces+0x5e8>
   812d8:	91142002 	add	x2, x0, #0x508
   812dc:	b9806fe1 	ldrsw	x1, [sp, #108]
   812e0:	aa0103e0 	mov	x0, x1
   812e4:	d37df000 	lsl	x0, x0, #3
   812e8:	cb010000 	sub	x0, x0, x1
   812ec:	d37df000 	lsl	x0, x0, #3
   812f0:	8b000040 	add	x0, x2, x0
   812f4:	aa0003e1 	mov	x1, x0
   812f8:	9100c3e0 	add	x0, sp, #0x30
   812fc:	a9400c02 	ldp	x2, x3, [x0]
   81300:	a9000c22 	stp	x2, x3, [x1]
   81304:	a9410c02 	ldp	x2, x3, [x0, #16]
   81308:	a9010c22 	stp	x2, x3, [x1, #16]
   8130c:	a9420c02 	ldp	x2, x3, [x0, #32]
   81310:	a9020c22 	stp	x2, x3, [x1, #32]
   81314:	f9401800 	ldr	x0, [x0, #48]
   81318:	f9001820 	str	x0, [x1, #48]

	if (num_traces < MAX_TRACES)
   8131c:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81320:	910c2000 	add	x0, x0, #0x308
   81324:	b9400000 	ldr	w0, [x0]
   81328:	7100c41f 	cmp	w0, #0x31
   8132c:	540003cc 	b.gt	813a4 <init_trace+0x128>
	{
		traces[num_traces] = trace;
   81330:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81334:	910c2000 	add	x0, x0, #0x308
   81338:	b9400001 	ldr	w1, [x0]
   8133c:	90000400 	adrp	x0, 101000 <mem_map+0x7cde8>
   81340:	91286002 	add	x2, x0, #0xa18
   81344:	93407c21 	sxtw	x1, w1
   81348:	aa0103e0 	mov	x0, x1
   8134c:	d37df000 	lsl	x0, x0, #3
   81350:	cb010000 	sub	x0, x0, x1
   81354:	d37df000 	lsl	x0, x0, #3
   81358:	8b000040 	add	x0, x2, x0
   8135c:	aa0003e1 	mov	x1, x0
   81360:	9100c3e0 	add	x0, sp, #0x30
   81364:	a9400c02 	ldp	x2, x3, [x0]
   81368:	a9000c22 	stp	x2, x3, [x1]
   8136c:	a9410c02 	ldp	x2, x3, [x0, #16]
   81370:	a9010c22 	stp	x2, x3, [x1, #16]
   81374:	a9420c02 	ldp	x2, x3, [x0, #32]
   81378:	a9020c22 	stp	x2, x3, [x1, #32]
   8137c:	f9401800 	ldr	x0, [x0, #48]
   81380:	f9001820 	str	x0, [x1, #48]
		num_traces++;
   81384:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81388:	910c2000 	add	x0, x0, #0x308
   8138c:	b9400000 	ldr	w0, [x0]
   81390:	11000401 	add	w1, w0, #0x1
   81394:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81398:	910c2000 	add	x0, x0, #0x308
   8139c:	b9000001 	str	w1, [x0]
   813a0:	14000014 	b	813f0 <init_trace+0x174>
	}
	else {
		print_all_traces();
   813a4:	97ffff24 	bl	81034 <print_all_traces>
		traces[0] = trace;
   813a8:	90000400 	adrp	x0, 101000 <mem_map+0x7cde8>
   813ac:	91286000 	add	x0, x0, #0xa18
   813b0:	aa0003e1 	mov	x1, x0
   813b4:	9100c3e0 	add	x0, sp, #0x30
   813b8:	a9400c02 	ldp	x2, x3, [x0]
   813bc:	a9000c22 	stp	x2, x3, [x1]
   813c0:	a9410c02 	ldp	x2, x3, [x0, #16]
   813c4:	a9010c22 	stp	x2, x3, [x1, #16]
   813c8:	a9420c02 	ldp	x2, x3, [x0, #32]
   813cc:	a9020c22 	stp	x2, x3, [x1, #32]
   813d0:	f9401800 	ldr	x0, [x0, #48]
   813d4:	f9001820 	str	x0, [x1, #48]
		num_traces = 1;
   813d8:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   813dc:	910c2000 	add	x0, x0, #0x308
   813e0:	52800021 	mov	w1, #0x1                   	// #1
   813e4:	b9000001 	str	w1, [x0]
   813e8:	14000002 	b	813f0 <init_trace+0x174>
		return;
   813ec:	d503201f 	nop
	}
}
   813f0:	a8c77bfd 	ldp	x29, x30, [sp], #112
   813f4:	d65f03c0 	ret

00000000000813f8 <timer_tick>:

void timer_tick()
{
   813f8:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   813fc:	910003fd 	mov	x29, sp
	//initialize_trace();
	--current->counter;
   81400:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81404:	913f2000 	add	x0, x0, #0xfc8
   81408:	f9400000 	ldr	x0, [x0]
   8140c:	f9403801 	ldr	x1, [x0, #112]
   81410:	d1000421 	sub	x1, x1, #0x1
   81414:	f9003801 	str	x1, [x0, #112]
	if (current->counter > 0 || current->preempt_count > 0)
   81418:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   8141c:	913f2000 	add	x0, x0, #0xfc8
   81420:	f9400000 	ldr	x0, [x0]
   81424:	f9403800 	ldr	x0, [x0, #112]
   81428:	f100001f 	cmp	x0, #0x0
   8142c:	540001ec 	b.gt	81468 <timer_tick+0x70>
   81430:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81434:	913f2000 	add	x0, x0, #0xfc8
   81438:	f9400000 	ldr	x0, [x0]
   8143c:	f9404000 	ldr	x0, [x0, #128]
   81440:	f100001f 	cmp	x0, #0x0
   81444:	5400012c 	b.gt	81468 <timer_tick+0x70>
	{
		return;
	}
	current->counter = 0;
   81448:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   8144c:	913f2000 	add	x0, x0, #0xfc8
   81450:	f9400000 	ldr	x0, [x0]
   81454:	f900381f 	str	xzr, [x0, #112]
	enable_irq();
   81458:	94000873 	bl	83624 <enable_irq>
	_schedule();
   8145c:	97fffde3 	bl	80be8 <_schedule>
	disable_irq();
   81460:	94000873 	bl	8362c <disable_irq>
   81464:	14000002 	b	8146c <timer_tick+0x74>
		return;
   81468:	d503201f 	nop
}
   8146c:	a8c17bfd 	ldp	x29, x30, [sp], #16
   81470:	d65f03c0 	ret

0000000000081474 <get_pid>:

int get_pid(void)
{
   81474:	d10043ff 	sub	sp, sp, #0x10
	for (int i = 0; i < nr_tasks; i++)
   81478:	b9000fff 	str	wzr, [sp, #12]
   8147c:	14000015 	b	814d0 <get_pid+0x5c>
	{
		if (task[i] && task[i] == current)
   81480:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81484:	913f4000 	add	x0, x0, #0xfd0
   81488:	b9800fe1 	ldrsw	x1, [sp, #12]
   8148c:	f8617800 	ldr	x0, [x0, x1, lsl #3]
   81490:	f100001f 	cmp	x0, #0x0
   81494:	54000180 	b.eq	814c4 <get_pid+0x50>  // b.none
   81498:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   8149c:	913f4000 	add	x0, x0, #0xfd0
   814a0:	b9800fe1 	ldrsw	x1, [sp, #12]
   814a4:	f8617801 	ldr	x1, [x0, x1, lsl #3]
   814a8:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   814ac:	913f2000 	add	x0, x0, #0xfc8
   814b0:	f9400000 	ldr	x0, [x0]
   814b4:	eb00003f 	cmp	x1, x0
   814b8:	54000061 	b.ne	814c4 <get_pid+0x50>  // b.any
		{
			return i;
   814bc:	b9400fe0 	ldr	w0, [sp, #12]
   814c0:	1400000b 	b	814ec <get_pid+0x78>
	for (int i = 0; i < nr_tasks; i++)
   814c4:	b9400fe0 	ldr	w0, [sp, #12]
   814c8:	11000400 	add	w0, w0, #0x1
   814cc:	b9000fe0 	str	w0, [sp, #12]
   814d0:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   814d4:	913d0000 	add	x0, x0, #0xf40
   814d8:	b9400000 	ldr	w0, [x0]
   814dc:	b9400fe1 	ldr	w1, [sp, #12]
   814e0:	6b00003f 	cmp	w1, w0
   814e4:	54fffceb 	b.lt	81480 <get_pid+0xc>  // b.tstop
		}
	}
	return -1;
   814e8:	12800000 	mov	w0, #0xffffffff            	// #-1
}
   814ec:	910043ff 	add	sp, sp, #0x10
   814f0:	d65f03c0 	ret

00000000000814f4 <generic_timer_init>:
/* 	These are for Arm generic timer. 
	They are fully functional on both QEMU and Rpi3 
	Recommended.
*/
void generic_timer_init ( void )
{
   814f4:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   814f8:	910003fd 	mov	x29, sp
	printf("Frequency is set to: %d\n", get_timer_freq());
   814fc:	9400036b 	bl	822a8 <get_timer_freq>
   81500:	2a0003e1 	mov	w1, w0
   81504:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81508:	91234000 	add	x0, x0, #0x8d0
   8150c:	9400028f 	bl	81f48 <tfp_printf>
	printf("interval is set to: %u\r\n", interval);
   81510:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81514:	913d1000 	add	x0, x0, #0xf44
   81518:	b9400000 	ldr	w0, [x0]
   8151c:	2a0003e1 	mov	w1, w0
   81520:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81524:	9123c000 	add	x0, x0, #0x8f0
   81528:	94000288 	bl	81f48 <tfp_printf>
	gen_timer_init();
   8152c:	9400035a 	bl	82294 <gen_timer_init>
	gen_timer_reset(interval);
   81530:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81534:	913d1000 	add	x0, x0, #0xf44
   81538:	b9400000 	ldr	w0, [x0]
   8153c:	94000359 	bl	822a0 <gen_timer_reset>
}
   81540:	d503201f 	nop
   81544:	a8c17bfd 	ldp	x29, x30, [sp], #16
   81548:	d65f03c0 	ret

000000000008154c <handle_generic_timer_irq>:

void handle_generic_timer_irq( void ) 
{
   8154c:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   81550:	910003fd 	mov	x29, sp
	gen_timer_reset(interval);
   81554:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81558:	913d1000 	add	x0, x0, #0xf44
   8155c:	b9400000 	ldr	w0, [x0]
   81560:	94000350 	bl	822a0 <gen_timer_reset>
    timer_tick();
   81564:	97ffffa5 	bl	813f8 <timer_tick>
}
   81568:	d503201f 	nop
   8156c:	a8c17bfd 	ldp	x29, x30, [sp], #16
   81570:	d65f03c0 	ret

0000000000081574 <get_time_ms>:


unsigned long get_time_ms(void){
   81574:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   81578:	910003fd 	mov	x29, sp
	unsigned long sys_count = get_sys_count();
   8157c:	9400034d 	bl	822b0 <get_sys_count>
   81580:	f9000fe0 	str	x0, [sp, #24]
	return (unsigned long) sys_count / 62500;
   81584:	f9400fe1 	ldr	x1, [sp, #24]
   81588:	d2869b60 	mov	x0, #0x34db                	// #13531
   8158c:	f2baf6c0 	movk	x0, #0xd7b6, lsl #16
   81590:	f2dbd040 	movk	x0, #0xde82, lsl #32
   81594:	f2e86360 	movk	x0, #0x431b, lsl #48
   81598:	9bc07c20 	umulh	x0, x1, x0
   8159c:	d34efc00 	lsr	x0, x0, #14
}
   815a0:	a8c27bfd 	ldp	x29, x30, [sp], #32
   815a4:	d65f03c0 	ret

00000000000815a8 <timer_init>:
	https://fxlin.github.io/p1-kernel/exp3/rpi-os/#fyi-other-timers-on-rpi3
*/
unsigned int curVal = 0;

void timer_init ( void )
{
   815a8:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   815ac:	910003fd 	mov	x29, sp
	curVal = get32(TIMER_CLO);
   815b0:	d2860080 	mov	x0, #0x3004                	// #12292
   815b4:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   815b8:	94000840 	bl	836b8 <get32>
   815bc:	2a0003e1 	mov	w1, w0
   815c0:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   815c4:	910c3000 	add	x0, x0, #0x30c
   815c8:	b9000001 	str	w1, [x0]
	curVal += interval;
   815cc:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   815d0:	910c3000 	add	x0, x0, #0x30c
   815d4:	b9400001 	ldr	w1, [x0]
   815d8:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   815dc:	913d1000 	add	x0, x0, #0xf44
   815e0:	b9400000 	ldr	w0, [x0]
   815e4:	0b000021 	add	w1, w1, w0
   815e8:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   815ec:	910c3000 	add	x0, x0, #0x30c
   815f0:	b9000001 	str	w1, [x0]
	put32(TIMER_C1, curVal);
   815f4:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   815f8:	910c3000 	add	x0, x0, #0x30c
   815fc:	b9400000 	ldr	w0, [x0]
   81600:	2a0003e1 	mov	w1, w0
   81604:	d2860200 	mov	x0, #0x3010                	// #12304
   81608:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   8160c:	94000829 	bl	836b0 <put32>
}
   81610:	d503201f 	nop
   81614:	a8c17bfd 	ldp	x29, x30, [sp], #16
   81618:	d65f03c0 	ret

000000000008161c <handle_timer_irq>:

void handle_timer_irq( void ) 
{
   8161c:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   81620:	910003fd 	mov	x29, sp
	curVal += interval;
   81624:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81628:	910c3000 	add	x0, x0, #0x30c
   8162c:	b9400001 	ldr	w1, [x0]
   81630:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81634:	913d1000 	add	x0, x0, #0xf44
   81638:	b9400000 	ldr	w0, [x0]
   8163c:	0b000021 	add	w1, w1, w0
   81640:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81644:	910c3000 	add	x0, x0, #0x30c
   81648:	b9000001 	str	w1, [x0]
	put32(TIMER_C1, curVal);
   8164c:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81650:	910c3000 	add	x0, x0, #0x30c
   81654:	b9400000 	ldr	w0, [x0]
   81658:	2a0003e1 	mov	w1, w0
   8165c:	d2860200 	mov	x0, #0x3010                	// #12304
   81660:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   81664:	94000813 	bl	836b0 <put32>
	put32(TIMER_CS, TIMER_CS_M1);
   81668:	52800041 	mov	w1, #0x2                   	// #2
   8166c:	d2860000 	mov	x0, #0x3000                	// #12288
   81670:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   81674:	9400080f 	bl	836b0 <put32>
	timer_tick();
   81678:	97ffff60 	bl	813f8 <timer_tick>
   8167c:	d503201f 	nop
   81680:	a8c17bfd 	ldp	x29, x30, [sp], #16
   81684:	d65f03c0 	ret

0000000000081688 <copy_process>:
#include "mm.h"
#include "sched.h"
#include "entry.h"

int copy_process(unsigned long fn, unsigned long arg)
{
   81688:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   8168c:	910003fd 	mov	x29, sp
   81690:	f9000fe0 	str	x0, [sp, #24]
   81694:	f9000be1 	str	x1, [sp, #16]
	preempt_disable();
   81698:	97fffd44 	bl	80ba8 <preempt_disable>
	struct task_struct *p;

	p = (struct task_struct *) get_free_page();
   8169c:	97fffc92 	bl	808e4 <get_free_page>
   816a0:	f90017e0 	str	x0, [sp, #40]
	if (!p)
   816a4:	f94017e0 	ldr	x0, [sp, #40]
   816a8:	f100001f 	cmp	x0, #0x0
   816ac:	54000061 	b.ne	816b8 <copy_process+0x30>  // b.any
		return 1;
   816b0:	52800020 	mov	w0, #0x1                   	// #1
   816b4:	1400002d 	b	81768 <copy_process+0xe0>
	p->priority = current->priority;
   816b8:	f0000000 	adrp	x0, 84000 <task+0x30>
   816bc:	f940ec00 	ldr	x0, [x0, #472]
   816c0:	f9400000 	ldr	x0, [x0]
   816c4:	f9403c01 	ldr	x1, [x0, #120]
   816c8:	f94017e0 	ldr	x0, [sp, #40]
   816cc:	f9003c01 	str	x1, [x0, #120]
	p->state = TASK_RUNNING;
   816d0:	f94017e0 	ldr	x0, [sp, #40]
   816d4:	f900341f 	str	xzr, [x0, #104]
	p->counter = p->priority;
   816d8:	f94017e0 	ldr	x0, [sp, #40]
   816dc:	f9403c01 	ldr	x1, [x0, #120]
   816e0:	f94017e0 	ldr	x0, [sp, #40]
   816e4:	f9003801 	str	x1, [x0, #112]
	p->preempt_count = 1; //disable preemtion until schedule_tail
   816e8:	f94017e0 	ldr	x0, [sp, #40]
   816ec:	d2800021 	mov	x1, #0x1                   	// #1
   816f0:	f9004001 	str	x1, [x0, #128]

	p->cpu_context.x19 = fn;
   816f4:	f94017e0 	ldr	x0, [sp, #40]
   816f8:	f9400fe1 	ldr	x1, [sp, #24]
   816fc:	f9000001 	str	x1, [x0]
	p->cpu_context.x20 = arg;
   81700:	f94017e0 	ldr	x0, [sp, #40]
   81704:	f9400be1 	ldr	x1, [sp, #16]
   81708:	f9000401 	str	x1, [x0, #8]
	p->cpu_context.pc = (unsigned long)ret_from_fork;
   8170c:	f0000000 	adrp	x0, 84000 <task+0x30>
   81710:	f940fc01 	ldr	x1, [x0, #504]
   81714:	f94017e0 	ldr	x0, [sp, #40]
   81718:	f9003001 	str	x1, [x0, #96]
	p->cpu_context.sp = (unsigned long)p + THREAD_SIZE;
   8171c:	f94017e0 	ldr	x0, [sp, #40]
   81720:	91400401 	add	x1, x0, #0x1, lsl #12
   81724:	f94017e0 	ldr	x0, [sp, #40]
   81728:	f9002c01 	str	x1, [x0, #88]
	int pid = nr_tasks++;
   8172c:	f0000000 	adrp	x0, 84000 <task+0x30>
   81730:	f940f000 	ldr	x0, [x0, #480]
   81734:	b9400000 	ldr	w0, [x0]
   81738:	11000402 	add	w2, w0, #0x1
   8173c:	f0000001 	adrp	x1, 84000 <task+0x30>
   81740:	f940f021 	ldr	x1, [x1, #480]
   81744:	b9000022 	str	w2, [x1]
   81748:	b90027e0 	str	w0, [sp, #36]
	task[pid] = p;	
   8174c:	f0000000 	adrp	x0, 84000 <task+0x30>
   81750:	f940f400 	ldr	x0, [x0, #488]
   81754:	b98027e1 	ldrsw	x1, [sp, #36]
   81758:	f94017e2 	ldr	x2, [sp, #40]
   8175c:	f8217802 	str	x2, [x0, x1, lsl #3]
	preempt_enable();
   81760:	97fffd1a 	bl	80bc8 <preempt_enable>
	return 0;
   81764:	52800000 	mov	w0, #0x0                   	// #0
}
   81768:	a8c37bfd 	ldp	x29, x30, [sp], #48
   8176c:	d65f03c0 	ret

0000000000081770 <ui2a>:
    }

#endif

static void ui2a(unsigned int num, unsigned int base, int uc,char * bf)
    {
   81770:	d100c3ff 	sub	sp, sp, #0x30
   81774:	b9001fe0 	str	w0, [sp, #28]
   81778:	b9001be1 	str	w1, [sp, #24]
   8177c:	b90017e2 	str	w2, [sp, #20]
   81780:	f90007e3 	str	x3, [sp, #8]
    int n=0;
   81784:	b9002fff 	str	wzr, [sp, #44]
    unsigned int d=1;
   81788:	52800020 	mov	w0, #0x1                   	// #1
   8178c:	b9002be0 	str	w0, [sp, #40]
    while (num/d >= base)
   81790:	14000005 	b	817a4 <ui2a+0x34>
        d*=base;
   81794:	b9402be1 	ldr	w1, [sp, #40]
   81798:	b9401be0 	ldr	w0, [sp, #24]
   8179c:	1b007c20 	mul	w0, w1, w0
   817a0:	b9002be0 	str	w0, [sp, #40]
    while (num/d >= base)
   817a4:	b9401fe1 	ldr	w1, [sp, #28]
   817a8:	b9402be0 	ldr	w0, [sp, #40]
   817ac:	1ac00820 	udiv	w0, w1, w0
   817b0:	b9401be1 	ldr	w1, [sp, #24]
   817b4:	6b00003f 	cmp	w1, w0
   817b8:	54fffee9 	b.ls	81794 <ui2a+0x24>  // b.plast
    while (d!=0) {
   817bc:	1400002f 	b	81878 <ui2a+0x108>
        int dgt = num / d;
   817c0:	b9401fe1 	ldr	w1, [sp, #28]
   817c4:	b9402be0 	ldr	w0, [sp, #40]
   817c8:	1ac00820 	udiv	w0, w1, w0
   817cc:	b90027e0 	str	w0, [sp, #36]
        num%= d;
   817d0:	b9401fe0 	ldr	w0, [sp, #28]
   817d4:	b9402be1 	ldr	w1, [sp, #40]
   817d8:	1ac10802 	udiv	w2, w0, w1
   817dc:	b9402be1 	ldr	w1, [sp, #40]
   817e0:	1b017c41 	mul	w1, w2, w1
   817e4:	4b010000 	sub	w0, w0, w1
   817e8:	b9001fe0 	str	w0, [sp, #28]
        d/=base;
   817ec:	b9402be1 	ldr	w1, [sp, #40]
   817f0:	b9401be0 	ldr	w0, [sp, #24]
   817f4:	1ac00820 	udiv	w0, w1, w0
   817f8:	b9002be0 	str	w0, [sp, #40]
        if (n || dgt>0 || d==0) {
   817fc:	b9402fe0 	ldr	w0, [sp, #44]
   81800:	7100001f 	cmp	w0, #0x0
   81804:	540000e1 	b.ne	81820 <ui2a+0xb0>  // b.any
   81808:	b94027e0 	ldr	w0, [sp, #36]
   8180c:	7100001f 	cmp	w0, #0x0
   81810:	5400008c 	b.gt	81820 <ui2a+0xb0>
   81814:	b9402be0 	ldr	w0, [sp, #40]
   81818:	7100001f 	cmp	w0, #0x0
   8181c:	540002e1 	b.ne	81878 <ui2a+0x108>  // b.any
            *bf++ = dgt+(dgt<10 ? '0' : (uc ? 'A' : 'a')-10);
   81820:	b94027e0 	ldr	w0, [sp, #36]
   81824:	7100241f 	cmp	w0, #0x9
   81828:	5400010d 	b.le	81848 <ui2a+0xd8>
   8182c:	b94017e0 	ldr	w0, [sp, #20]
   81830:	7100001f 	cmp	w0, #0x0
   81834:	54000060 	b.eq	81840 <ui2a+0xd0>  // b.none
   81838:	528006e0 	mov	w0, #0x37                  	// #55
   8183c:	14000004 	b	8184c <ui2a+0xdc>
   81840:	52800ae0 	mov	w0, #0x57                  	// #87
   81844:	14000002 	b	8184c <ui2a+0xdc>
   81848:	52800600 	mov	w0, #0x30                  	// #48
   8184c:	b94027e1 	ldr	w1, [sp, #36]
   81850:	12001c22 	and	w2, w1, #0xff
   81854:	f94007e1 	ldr	x1, [sp, #8]
   81858:	91000423 	add	x3, x1, #0x1
   8185c:	f90007e3 	str	x3, [sp, #8]
   81860:	0b020000 	add	w0, w0, w2
   81864:	12001c00 	and	w0, w0, #0xff
   81868:	39000020 	strb	w0, [x1]
            ++n;
   8186c:	b9402fe0 	ldr	w0, [sp, #44]
   81870:	11000400 	add	w0, w0, #0x1
   81874:	b9002fe0 	str	w0, [sp, #44]
    while (d!=0) {
   81878:	b9402be0 	ldr	w0, [sp, #40]
   8187c:	7100001f 	cmp	w0, #0x0
   81880:	54fffa01 	b.ne	817c0 <ui2a+0x50>  // b.any
            }
        }
    *bf=0;
   81884:	f94007e0 	ldr	x0, [sp, #8]
   81888:	3900001f 	strb	wzr, [x0]
    }
   8188c:	d503201f 	nop
   81890:	9100c3ff 	add	sp, sp, #0x30
   81894:	d65f03c0 	ret

0000000000081898 <i2a>:

static void i2a (int num, char * bf)
    {
   81898:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   8189c:	910003fd 	mov	x29, sp
   818a0:	b9001fe0 	str	w0, [sp, #28]
   818a4:	f9000be1 	str	x1, [sp, #16]
    if (num<0) {
   818a8:	b9401fe0 	ldr	w0, [sp, #28]
   818ac:	7100001f 	cmp	w0, #0x0
   818b0:	5400012a 	b.ge	818d4 <i2a+0x3c>  // b.tcont
        num=-num;
   818b4:	b9401fe0 	ldr	w0, [sp, #28]
   818b8:	4b0003e0 	neg	w0, w0
   818bc:	b9001fe0 	str	w0, [sp, #28]
        *bf++ = '-';
   818c0:	f9400be0 	ldr	x0, [sp, #16]
   818c4:	91000401 	add	x1, x0, #0x1
   818c8:	f9000be1 	str	x1, [sp, #16]
   818cc:	528005a1 	mov	w1, #0x2d                  	// #45
   818d0:	39000001 	strb	w1, [x0]
        }
    ui2a(num,10,0,bf);
   818d4:	b9401fe0 	ldr	w0, [sp, #28]
   818d8:	f9400be3 	ldr	x3, [sp, #16]
   818dc:	52800002 	mov	w2, #0x0                   	// #0
   818e0:	52800141 	mov	w1, #0xa                   	// #10
   818e4:	97ffffa3 	bl	81770 <ui2a>
    }
   818e8:	d503201f 	nop
   818ec:	a8c27bfd 	ldp	x29, x30, [sp], #32
   818f0:	d65f03c0 	ret

00000000000818f4 <a2d>:

static int a2d(char ch)
    {
   818f4:	d10043ff 	sub	sp, sp, #0x10
   818f8:	39003fe0 	strb	w0, [sp, #15]
    if (ch>='0' && ch<='9')
   818fc:	39403fe0 	ldrb	w0, [sp, #15]
   81900:	7100bc1f 	cmp	w0, #0x2f
   81904:	540000e9 	b.ls	81920 <a2d+0x2c>  // b.plast
   81908:	39403fe0 	ldrb	w0, [sp, #15]
   8190c:	7100e41f 	cmp	w0, #0x39
   81910:	54000088 	b.hi	81920 <a2d+0x2c>  // b.pmore
        return ch-'0';
   81914:	39403fe0 	ldrb	w0, [sp, #15]
   81918:	5100c000 	sub	w0, w0, #0x30
   8191c:	14000014 	b	8196c <a2d+0x78>
    else if (ch>='a' && ch<='f')
   81920:	39403fe0 	ldrb	w0, [sp, #15]
   81924:	7101801f 	cmp	w0, #0x60
   81928:	540000e9 	b.ls	81944 <a2d+0x50>  // b.plast
   8192c:	39403fe0 	ldrb	w0, [sp, #15]
   81930:	7101981f 	cmp	w0, #0x66
   81934:	54000088 	b.hi	81944 <a2d+0x50>  // b.pmore
        return ch-'a'+10;
   81938:	39403fe0 	ldrb	w0, [sp, #15]
   8193c:	51015c00 	sub	w0, w0, #0x57
   81940:	1400000b 	b	8196c <a2d+0x78>
    else if (ch>='A' && ch<='F')
   81944:	39403fe0 	ldrb	w0, [sp, #15]
   81948:	7101001f 	cmp	w0, #0x40
   8194c:	540000e9 	b.ls	81968 <a2d+0x74>  // b.plast
   81950:	39403fe0 	ldrb	w0, [sp, #15]
   81954:	7101181f 	cmp	w0, #0x46
   81958:	54000088 	b.hi	81968 <a2d+0x74>  // b.pmore
        return ch-'A'+10;
   8195c:	39403fe0 	ldrb	w0, [sp, #15]
   81960:	5100dc00 	sub	w0, w0, #0x37
   81964:	14000002 	b	8196c <a2d+0x78>
    else return -1;
   81968:	12800000 	mov	w0, #0xffffffff            	// #-1
    }
   8196c:	910043ff 	add	sp, sp, #0x10
   81970:	d65f03c0 	ret

0000000000081974 <a2i>:

static char a2i(char ch, char** src,int base,int* nump)
    {
   81974:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   81978:	910003fd 	mov	x29, sp
   8197c:	3900bfe0 	strb	w0, [sp, #47]
   81980:	f90013e1 	str	x1, [sp, #32]
   81984:	b9002be2 	str	w2, [sp, #40]
   81988:	f9000fe3 	str	x3, [sp, #24]
    char* p= *src;
   8198c:	f94013e0 	ldr	x0, [sp, #32]
   81990:	f9400000 	ldr	x0, [x0]
   81994:	f9001fe0 	str	x0, [sp, #56]
    int num=0;
   81998:	b90037ff 	str	wzr, [sp, #52]
    int digit;
    while ((digit=a2d(ch))>=0) {
   8199c:	14000010 	b	819dc <a2i+0x68>
        if (digit>base) break;
   819a0:	b94033e1 	ldr	w1, [sp, #48]
   819a4:	b9402be0 	ldr	w0, [sp, #40]
   819a8:	6b00003f 	cmp	w1, w0
   819ac:	5400026c 	b.gt	819f8 <a2i+0x84>
        num=num*base+digit;
   819b0:	b94037e1 	ldr	w1, [sp, #52]
   819b4:	b9402be0 	ldr	w0, [sp, #40]
   819b8:	1b007c20 	mul	w0, w1, w0
   819bc:	b94033e1 	ldr	w1, [sp, #48]
   819c0:	0b000020 	add	w0, w1, w0
   819c4:	b90037e0 	str	w0, [sp, #52]
        ch=*p++;
   819c8:	f9401fe0 	ldr	x0, [sp, #56]
   819cc:	91000401 	add	x1, x0, #0x1
   819d0:	f9001fe1 	str	x1, [sp, #56]
   819d4:	39400000 	ldrb	w0, [x0]
   819d8:	3900bfe0 	strb	w0, [sp, #47]
    while ((digit=a2d(ch))>=0) {
   819dc:	3940bfe0 	ldrb	w0, [sp, #47]
   819e0:	97ffffc5 	bl	818f4 <a2d>
   819e4:	b90033e0 	str	w0, [sp, #48]
   819e8:	b94033e0 	ldr	w0, [sp, #48]
   819ec:	7100001f 	cmp	w0, #0x0
   819f0:	54fffd8a 	b.ge	819a0 <a2i+0x2c>  // b.tcont
   819f4:	14000002 	b	819fc <a2i+0x88>
        if (digit>base) break;
   819f8:	d503201f 	nop
        }
    *src=p;
   819fc:	f94013e0 	ldr	x0, [sp, #32]
   81a00:	f9401fe1 	ldr	x1, [sp, #56]
   81a04:	f9000001 	str	x1, [x0]
    *nump=num;
   81a08:	f9400fe0 	ldr	x0, [sp, #24]
   81a0c:	b94037e1 	ldr	w1, [sp, #52]
   81a10:	b9000001 	str	w1, [x0]
    return ch;
   81a14:	3940bfe0 	ldrb	w0, [sp, #47]
    }
   81a18:	a8c47bfd 	ldp	x29, x30, [sp], #64
   81a1c:	d65f03c0 	ret

0000000000081a20 <putchw>:

static void putchw(void* putp,putcf putf,int n, char z, char* bf)
    {
   81a20:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   81a24:	910003fd 	mov	x29, sp
   81a28:	f90017e0 	str	x0, [sp, #40]
   81a2c:	f90013e1 	str	x1, [sp, #32]
   81a30:	b9001fe2 	str	w2, [sp, #28]
   81a34:	39006fe3 	strb	w3, [sp, #27]
   81a38:	f9000be4 	str	x4, [sp, #16]
    char fc=z? '0' : ' ';
   81a3c:	39406fe0 	ldrb	w0, [sp, #27]
   81a40:	7100001f 	cmp	w0, #0x0
   81a44:	54000060 	b.eq	81a50 <putchw+0x30>  // b.none
   81a48:	52800600 	mov	w0, #0x30                  	// #48
   81a4c:	14000002 	b	81a54 <putchw+0x34>
   81a50:	52800400 	mov	w0, #0x20                  	// #32
   81a54:	3900dfe0 	strb	w0, [sp, #55]
    char ch;
    char* p=bf;
   81a58:	f9400be0 	ldr	x0, [sp, #16]
   81a5c:	f9001fe0 	str	x0, [sp, #56]
    while (*p++ && n > 0)
   81a60:	14000004 	b	81a70 <putchw+0x50>
        n--;
   81a64:	b9401fe0 	ldr	w0, [sp, #28]
   81a68:	51000400 	sub	w0, w0, #0x1
   81a6c:	b9001fe0 	str	w0, [sp, #28]
    while (*p++ && n > 0)
   81a70:	f9401fe0 	ldr	x0, [sp, #56]
   81a74:	91000401 	add	x1, x0, #0x1
   81a78:	f9001fe1 	str	x1, [sp, #56]
   81a7c:	39400000 	ldrb	w0, [x0]
   81a80:	7100001f 	cmp	w0, #0x0
   81a84:	54000120 	b.eq	81aa8 <putchw+0x88>  // b.none
   81a88:	b9401fe0 	ldr	w0, [sp, #28]
   81a8c:	7100001f 	cmp	w0, #0x0
   81a90:	54fffeac 	b.gt	81a64 <putchw+0x44>
    while (n-- > 0)
   81a94:	14000005 	b	81aa8 <putchw+0x88>
        putf(putp,fc);
   81a98:	f94013e2 	ldr	x2, [sp, #32]
   81a9c:	3940dfe1 	ldrb	w1, [sp, #55]
   81aa0:	f94017e0 	ldr	x0, [sp, #40]
   81aa4:	d63f0040 	blr	x2
    while (n-- > 0)
   81aa8:	b9401fe0 	ldr	w0, [sp, #28]
   81aac:	51000401 	sub	w1, w0, #0x1
   81ab0:	b9001fe1 	str	w1, [sp, #28]
   81ab4:	7100001f 	cmp	w0, #0x0
   81ab8:	54ffff0c 	b.gt	81a98 <putchw+0x78>
    while ((ch= *bf++))
   81abc:	14000005 	b	81ad0 <putchw+0xb0>
        putf(putp,ch);
   81ac0:	f94013e2 	ldr	x2, [sp, #32]
   81ac4:	3940dbe1 	ldrb	w1, [sp, #54]
   81ac8:	f94017e0 	ldr	x0, [sp, #40]
   81acc:	d63f0040 	blr	x2
    while ((ch= *bf++))
   81ad0:	f9400be0 	ldr	x0, [sp, #16]
   81ad4:	91000401 	add	x1, x0, #0x1
   81ad8:	f9000be1 	str	x1, [sp, #16]
   81adc:	39400000 	ldrb	w0, [x0]
   81ae0:	3900dbe0 	strb	w0, [sp, #54]
   81ae4:	3940dbe0 	ldrb	w0, [sp, #54]
   81ae8:	7100001f 	cmp	w0, #0x0
   81aec:	54fffea1 	b.ne	81ac0 <putchw+0xa0>  // b.any
    }
   81af0:	d503201f 	nop
   81af4:	d503201f 	nop
   81af8:	a8c47bfd 	ldp	x29, x30, [sp], #64
   81afc:	d65f03c0 	ret

0000000000081b00 <tfp_format>:

void tfp_format(void* putp,putcf putf,char *fmt, va_list va)
    {
   81b00:	a9ba7bfd 	stp	x29, x30, [sp, #-96]!
   81b04:	910003fd 	mov	x29, sp
   81b08:	f9000bf3 	str	x19, [sp, #16]
   81b0c:	f9001fe0 	str	x0, [sp, #56]
   81b10:	f9001be1 	str	x1, [sp, #48]
   81b14:	f90017e2 	str	x2, [sp, #40]
   81b18:	aa0303f3 	mov	x19, x3
    char bf[12];

    char ch;


    while ((ch=*(fmt++))) {
   81b1c:	140000ef 	b	81ed8 <tfp_format+0x3d8>
        if (ch!='%')
   81b20:	39417fe0 	ldrb	w0, [sp, #95]
   81b24:	7100941f 	cmp	w0, #0x25
   81b28:	540000c0 	b.eq	81b40 <tfp_format+0x40>  // b.none
            putf(putp,ch);
   81b2c:	f9401be2 	ldr	x2, [sp, #48]
   81b30:	39417fe1 	ldrb	w1, [sp, #95]
   81b34:	f9401fe0 	ldr	x0, [sp, #56]
   81b38:	d63f0040 	blr	x2
   81b3c:	140000e7 	b	81ed8 <tfp_format+0x3d8>
        else {
            char lz=0;
   81b40:	39017bff 	strb	wzr, [sp, #94]
#ifdef  PRINTF_LONG_SUPPORT
            char lng=0;
#endif
            int w=0;
   81b44:	b9004fff 	str	wzr, [sp, #76]
            ch=*(fmt++);
   81b48:	f94017e0 	ldr	x0, [sp, #40]
   81b4c:	91000401 	add	x1, x0, #0x1
   81b50:	f90017e1 	str	x1, [sp, #40]
   81b54:	39400000 	ldrb	w0, [x0]
   81b58:	39017fe0 	strb	w0, [sp, #95]
            if (ch=='0') {
   81b5c:	39417fe0 	ldrb	w0, [sp, #95]
   81b60:	7100c01f 	cmp	w0, #0x30
   81b64:	54000101 	b.ne	81b84 <tfp_format+0x84>  // b.any
                ch=*(fmt++);
   81b68:	f94017e0 	ldr	x0, [sp, #40]
   81b6c:	91000401 	add	x1, x0, #0x1
   81b70:	f90017e1 	str	x1, [sp, #40]
   81b74:	39400000 	ldrb	w0, [x0]
   81b78:	39017fe0 	strb	w0, [sp, #95]
                lz=1;
   81b7c:	52800020 	mov	w0, #0x1                   	// #1
   81b80:	39017be0 	strb	w0, [sp, #94]
                }
            if (ch>='0' && ch<='9') {
   81b84:	39417fe0 	ldrb	w0, [sp, #95]
   81b88:	7100bc1f 	cmp	w0, #0x2f
   81b8c:	54000189 	b.ls	81bbc <tfp_format+0xbc>  // b.plast
   81b90:	39417fe0 	ldrb	w0, [sp, #95]
   81b94:	7100e41f 	cmp	w0, #0x39
   81b98:	54000128 	b.hi	81bbc <tfp_format+0xbc>  // b.pmore
                ch=a2i(ch,&fmt,10,&w);
   81b9c:	910133e1 	add	x1, sp, #0x4c
   81ba0:	9100a3e0 	add	x0, sp, #0x28
   81ba4:	aa0103e3 	mov	x3, x1
   81ba8:	52800142 	mov	w2, #0xa                   	// #10
   81bac:	aa0003e1 	mov	x1, x0
   81bb0:	39417fe0 	ldrb	w0, [sp, #95]
   81bb4:	97ffff70 	bl	81974 <a2i>
   81bb8:	39017fe0 	strb	w0, [sp, #95]
            if (ch=='l') {
                ch=*(fmt++);
                lng=1;
            }
#endif
            switch (ch) {
   81bbc:	39417fe0 	ldrb	w0, [sp, #95]
   81bc0:	7101e01f 	cmp	w0, #0x78
   81bc4:	54000be0 	b.eq	81d40 <tfp_format+0x240>  // b.none
   81bc8:	7101e01f 	cmp	w0, #0x78
   81bcc:	5400184c 	b.gt	81ed4 <tfp_format+0x3d4>
   81bd0:	7101d41f 	cmp	w0, #0x75
   81bd4:	54000300 	b.eq	81c34 <tfp_format+0x134>  // b.none
   81bd8:	7101d41f 	cmp	w0, #0x75
   81bdc:	540017cc 	b.gt	81ed4 <tfp_format+0x3d4>
   81be0:	7101cc1f 	cmp	w0, #0x73
   81be4:	54001360 	b.eq	81e50 <tfp_format+0x350>  // b.none
   81be8:	7101cc1f 	cmp	w0, #0x73
   81bec:	5400174c 	b.gt	81ed4 <tfp_format+0x3d4>
   81bf0:	7101901f 	cmp	w0, #0x64
   81bf4:	54000660 	b.eq	81cc0 <tfp_format+0x1c0>  // b.none
   81bf8:	7101901f 	cmp	w0, #0x64
   81bfc:	540016cc 	b.gt	81ed4 <tfp_format+0x3d4>
   81c00:	71018c1f 	cmp	w0, #0x63
   81c04:	54000f00 	b.eq	81de4 <tfp_format+0x2e4>  // b.none
   81c08:	71018c1f 	cmp	w0, #0x63
   81c0c:	5400164c 	b.gt	81ed4 <tfp_format+0x3d4>
   81c10:	7101601f 	cmp	w0, #0x58
   81c14:	54000960 	b.eq	81d40 <tfp_format+0x240>  // b.none
   81c18:	7101601f 	cmp	w0, #0x58
   81c1c:	540015cc 	b.gt	81ed4 <tfp_format+0x3d4>
   81c20:	7100001f 	cmp	w0, #0x0
   81c24:	540016c0 	b.eq	81efc <tfp_format+0x3fc>  // b.none
   81c28:	7100941f 	cmp	w0, #0x25
   81c2c:	540014c0 	b.eq	81ec4 <tfp_format+0x3c4>  // b.none
                    putchw(putp,putf,w,0,va_arg(va, char*));
                    break;
                case '%' :
                    putf(putp,ch);
                default:
                    break;
   81c30:	140000a9 	b	81ed4 <tfp_format+0x3d4>
                    ui2a(va_arg(va, unsigned int),10,0,bf);
   81c34:	b9401a61 	ldr	w1, [x19, #24]
   81c38:	f9400260 	ldr	x0, [x19]
   81c3c:	7100003f 	cmp	w1, #0x0
   81c40:	540000ab 	b.lt	81c54 <tfp_format+0x154>  // b.tstop
   81c44:	91002c01 	add	x1, x0, #0xb
   81c48:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81c4c:	f9000261 	str	x1, [x19]
   81c50:	1400000d 	b	81c84 <tfp_format+0x184>
   81c54:	11002022 	add	w2, w1, #0x8
   81c58:	b9001a62 	str	w2, [x19, #24]
   81c5c:	b9401a62 	ldr	w2, [x19, #24]
   81c60:	7100005f 	cmp	w2, #0x0
   81c64:	540000ad 	b.le	81c78 <tfp_format+0x178>
   81c68:	91002c01 	add	x1, x0, #0xb
   81c6c:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81c70:	f9000261 	str	x1, [x19]
   81c74:	14000004 	b	81c84 <tfp_format+0x184>
   81c78:	f9400662 	ldr	x2, [x19, #8]
   81c7c:	93407c20 	sxtw	x0, w1
   81c80:	8b000040 	add	x0, x2, x0
   81c84:	b9400000 	ldr	w0, [x0]
   81c88:	910143e1 	add	x1, sp, #0x50
   81c8c:	aa0103e3 	mov	x3, x1
   81c90:	52800002 	mov	w2, #0x0                   	// #0
   81c94:	52800141 	mov	w1, #0xa                   	// #10
   81c98:	97fffeb6 	bl	81770 <ui2a>
                    putchw(putp,putf,w,lz,bf);
   81c9c:	b9404fe0 	ldr	w0, [sp, #76]
   81ca0:	910143e1 	add	x1, sp, #0x50
   81ca4:	aa0103e4 	mov	x4, x1
   81ca8:	39417be3 	ldrb	w3, [sp, #94]
   81cac:	2a0003e2 	mov	w2, w0
   81cb0:	f9401be1 	ldr	x1, [sp, #48]
   81cb4:	f9401fe0 	ldr	x0, [sp, #56]
   81cb8:	97ffff5a 	bl	81a20 <putchw>
                    break;
   81cbc:	14000087 	b	81ed8 <tfp_format+0x3d8>
                    i2a(va_arg(va, int),bf);
   81cc0:	b9401a61 	ldr	w1, [x19, #24]
   81cc4:	f9400260 	ldr	x0, [x19]
   81cc8:	7100003f 	cmp	w1, #0x0
   81ccc:	540000ab 	b.lt	81ce0 <tfp_format+0x1e0>  // b.tstop
   81cd0:	91002c01 	add	x1, x0, #0xb
   81cd4:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81cd8:	f9000261 	str	x1, [x19]
   81cdc:	1400000d 	b	81d10 <tfp_format+0x210>
   81ce0:	11002022 	add	w2, w1, #0x8
   81ce4:	b9001a62 	str	w2, [x19, #24]
   81ce8:	b9401a62 	ldr	w2, [x19, #24]
   81cec:	7100005f 	cmp	w2, #0x0
   81cf0:	540000ad 	b.le	81d04 <tfp_format+0x204>
   81cf4:	91002c01 	add	x1, x0, #0xb
   81cf8:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81cfc:	f9000261 	str	x1, [x19]
   81d00:	14000004 	b	81d10 <tfp_format+0x210>
   81d04:	f9400662 	ldr	x2, [x19, #8]
   81d08:	93407c20 	sxtw	x0, w1
   81d0c:	8b000040 	add	x0, x2, x0
   81d10:	b9400000 	ldr	w0, [x0]
   81d14:	910143e1 	add	x1, sp, #0x50
   81d18:	97fffee0 	bl	81898 <i2a>
                    putchw(putp,putf,w,lz,bf);
   81d1c:	b9404fe0 	ldr	w0, [sp, #76]
   81d20:	910143e1 	add	x1, sp, #0x50
   81d24:	aa0103e4 	mov	x4, x1
   81d28:	39417be3 	ldrb	w3, [sp, #94]
   81d2c:	2a0003e2 	mov	w2, w0
   81d30:	f9401be1 	ldr	x1, [sp, #48]
   81d34:	f9401fe0 	ldr	x0, [sp, #56]
   81d38:	97ffff3a 	bl	81a20 <putchw>
                    break;
   81d3c:	14000067 	b	81ed8 <tfp_format+0x3d8>
                    ui2a(va_arg(va, unsigned int),16,(ch=='X'),bf);
   81d40:	b9401a61 	ldr	w1, [x19, #24]
   81d44:	f9400260 	ldr	x0, [x19]
   81d48:	7100003f 	cmp	w1, #0x0
   81d4c:	540000ab 	b.lt	81d60 <tfp_format+0x260>  // b.tstop
   81d50:	91002c01 	add	x1, x0, #0xb
   81d54:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81d58:	f9000261 	str	x1, [x19]
   81d5c:	1400000d 	b	81d90 <tfp_format+0x290>
   81d60:	11002022 	add	w2, w1, #0x8
   81d64:	b9001a62 	str	w2, [x19, #24]
   81d68:	b9401a62 	ldr	w2, [x19, #24]
   81d6c:	7100005f 	cmp	w2, #0x0
   81d70:	540000ad 	b.le	81d84 <tfp_format+0x284>
   81d74:	91002c01 	add	x1, x0, #0xb
   81d78:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81d7c:	f9000261 	str	x1, [x19]
   81d80:	14000004 	b	81d90 <tfp_format+0x290>
   81d84:	f9400662 	ldr	x2, [x19, #8]
   81d88:	93407c20 	sxtw	x0, w1
   81d8c:	8b000040 	add	x0, x2, x0
   81d90:	b9400004 	ldr	w4, [x0]
   81d94:	39417fe0 	ldrb	w0, [sp, #95]
   81d98:	7101601f 	cmp	w0, #0x58
   81d9c:	1a9f17e0 	cset	w0, eq  // eq = none
   81da0:	12001c00 	and	w0, w0, #0xff
   81da4:	2a0003e1 	mov	w1, w0
   81da8:	910143e0 	add	x0, sp, #0x50
   81dac:	aa0003e3 	mov	x3, x0
   81db0:	2a0103e2 	mov	w2, w1
   81db4:	52800201 	mov	w1, #0x10                  	// #16
   81db8:	2a0403e0 	mov	w0, w4
   81dbc:	97fffe6d 	bl	81770 <ui2a>
                    putchw(putp,putf,w,lz,bf);
   81dc0:	b9404fe0 	ldr	w0, [sp, #76]
   81dc4:	910143e1 	add	x1, sp, #0x50
   81dc8:	aa0103e4 	mov	x4, x1
   81dcc:	39417be3 	ldrb	w3, [sp, #94]
   81dd0:	2a0003e2 	mov	w2, w0
   81dd4:	f9401be1 	ldr	x1, [sp, #48]
   81dd8:	f9401fe0 	ldr	x0, [sp, #56]
   81ddc:	97ffff11 	bl	81a20 <putchw>
                    break;
   81de0:	1400003e 	b	81ed8 <tfp_format+0x3d8>
                    putf(putp,(char)(va_arg(va, int)));
   81de4:	b9401a61 	ldr	w1, [x19, #24]
   81de8:	f9400260 	ldr	x0, [x19]
   81dec:	7100003f 	cmp	w1, #0x0
   81df0:	540000ab 	b.lt	81e04 <tfp_format+0x304>  // b.tstop
   81df4:	91002c01 	add	x1, x0, #0xb
   81df8:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81dfc:	f9000261 	str	x1, [x19]
   81e00:	1400000d 	b	81e34 <tfp_format+0x334>
   81e04:	11002022 	add	w2, w1, #0x8
   81e08:	b9001a62 	str	w2, [x19, #24]
   81e0c:	b9401a62 	ldr	w2, [x19, #24]
   81e10:	7100005f 	cmp	w2, #0x0
   81e14:	540000ad 	b.le	81e28 <tfp_format+0x328>
   81e18:	91002c01 	add	x1, x0, #0xb
   81e1c:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81e20:	f9000261 	str	x1, [x19]
   81e24:	14000004 	b	81e34 <tfp_format+0x334>
   81e28:	f9400662 	ldr	x2, [x19, #8]
   81e2c:	93407c20 	sxtw	x0, w1
   81e30:	8b000040 	add	x0, x2, x0
   81e34:	b9400000 	ldr	w0, [x0]
   81e38:	12001c00 	and	w0, w0, #0xff
   81e3c:	f9401be2 	ldr	x2, [sp, #48]
   81e40:	2a0003e1 	mov	w1, w0
   81e44:	f9401fe0 	ldr	x0, [sp, #56]
   81e48:	d63f0040 	blr	x2
                    break;
   81e4c:	14000023 	b	81ed8 <tfp_format+0x3d8>
                    putchw(putp,putf,w,0,va_arg(va, char*));
   81e50:	b9404fe5 	ldr	w5, [sp, #76]
   81e54:	b9401a61 	ldr	w1, [x19, #24]
   81e58:	f9400260 	ldr	x0, [x19]
   81e5c:	7100003f 	cmp	w1, #0x0
   81e60:	540000ab 	b.lt	81e74 <tfp_format+0x374>  // b.tstop
   81e64:	91003c01 	add	x1, x0, #0xf
   81e68:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81e6c:	f9000261 	str	x1, [x19]
   81e70:	1400000d 	b	81ea4 <tfp_format+0x3a4>
   81e74:	11002022 	add	w2, w1, #0x8
   81e78:	b9001a62 	str	w2, [x19, #24]
   81e7c:	b9401a62 	ldr	w2, [x19, #24]
   81e80:	7100005f 	cmp	w2, #0x0
   81e84:	540000ad 	b.le	81e98 <tfp_format+0x398>
   81e88:	91003c01 	add	x1, x0, #0xf
   81e8c:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81e90:	f9000261 	str	x1, [x19]
   81e94:	14000004 	b	81ea4 <tfp_format+0x3a4>
   81e98:	f9400662 	ldr	x2, [x19, #8]
   81e9c:	93407c20 	sxtw	x0, w1
   81ea0:	8b000040 	add	x0, x2, x0
   81ea4:	f9400000 	ldr	x0, [x0]
   81ea8:	aa0003e4 	mov	x4, x0
   81eac:	52800003 	mov	w3, #0x0                   	// #0
   81eb0:	2a0503e2 	mov	w2, w5
   81eb4:	f9401be1 	ldr	x1, [sp, #48]
   81eb8:	f9401fe0 	ldr	x0, [sp, #56]
   81ebc:	97fffed9 	bl	81a20 <putchw>
                    break;
   81ec0:	14000006 	b	81ed8 <tfp_format+0x3d8>
                    putf(putp,ch);
   81ec4:	f9401be2 	ldr	x2, [sp, #48]
   81ec8:	39417fe1 	ldrb	w1, [sp, #95]
   81ecc:	f9401fe0 	ldr	x0, [sp, #56]
   81ed0:	d63f0040 	blr	x2
                    break;
   81ed4:	d503201f 	nop
    while ((ch=*(fmt++))) {
   81ed8:	f94017e0 	ldr	x0, [sp, #40]
   81edc:	91000401 	add	x1, x0, #0x1
   81ee0:	f90017e1 	str	x1, [sp, #40]
   81ee4:	39400000 	ldrb	w0, [x0]
   81ee8:	39017fe0 	strb	w0, [sp, #95]
   81eec:	39417fe0 	ldrb	w0, [sp, #95]
   81ef0:	7100001f 	cmp	w0, #0x0
   81ef4:	54ffe161 	b.ne	81b20 <tfp_format+0x20>  // b.any
                }
            }
        }
    abort:;
   81ef8:	14000002 	b	81f00 <tfp_format+0x400>
                    goto abort;
   81efc:	d503201f 	nop
    }
   81f00:	d503201f 	nop
   81f04:	f9400bf3 	ldr	x19, [sp, #16]
   81f08:	a8c67bfd 	ldp	x29, x30, [sp], #96
   81f0c:	d65f03c0 	ret

0000000000081f10 <init_printf>:


void init_printf(void* putp,void (*putf) (void*,char))
    {
   81f10:	d10043ff 	sub	sp, sp, #0x10
   81f14:	f90007e0 	str	x0, [sp, #8]
   81f18:	f90003e1 	str	x1, [sp]
    stdout_putf=putf;
   81f1c:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81f20:	910c4000 	add	x0, x0, #0x310
   81f24:	f94003e1 	ldr	x1, [sp]
   81f28:	f9000001 	str	x1, [x0]
    stdout_putp=putp;
   81f2c:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81f30:	910c6000 	add	x0, x0, #0x318
   81f34:	f94007e1 	ldr	x1, [sp, #8]
   81f38:	f9000001 	str	x1, [x0]
    }
   81f3c:	d503201f 	nop
   81f40:	910043ff 	add	sp, sp, #0x10
   81f44:	d65f03c0 	ret

0000000000081f48 <tfp_printf>:

void tfp_printf(char *fmt, ...)
    {
   81f48:	a9b67bfd 	stp	x29, x30, [sp, #-160]!
   81f4c:	910003fd 	mov	x29, sp
   81f50:	f9001fe0 	str	x0, [sp, #56]
   81f54:	f90037e1 	str	x1, [sp, #104]
   81f58:	f9003be2 	str	x2, [sp, #112]
   81f5c:	f9003fe3 	str	x3, [sp, #120]
   81f60:	f90043e4 	str	x4, [sp, #128]
   81f64:	f90047e5 	str	x5, [sp, #136]
   81f68:	f9004be6 	str	x6, [sp, #144]
   81f6c:	f9004fe7 	str	x7, [sp, #152]
    va_list va;
    va_start(va,fmt);
   81f70:	910283e0 	add	x0, sp, #0xa0
   81f74:	f90023e0 	str	x0, [sp, #64]
   81f78:	910283e0 	add	x0, sp, #0xa0
   81f7c:	f90027e0 	str	x0, [sp, #72]
   81f80:	910183e0 	add	x0, sp, #0x60
   81f84:	f9002be0 	str	x0, [sp, #80]
   81f88:	128006e0 	mov	w0, #0xffffffc8            	// #-56
   81f8c:	b9005be0 	str	w0, [sp, #88]
   81f90:	b9005fff 	str	wzr, [sp, #92]
    tfp_format(stdout_putp,stdout_putf,fmt,va);
   81f94:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81f98:	910c6000 	add	x0, x0, #0x318
   81f9c:	f9400004 	ldr	x4, [x0]
   81fa0:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81fa4:	910c4000 	add	x0, x0, #0x310
   81fa8:	f9400005 	ldr	x5, [x0]
   81fac:	910043e2 	add	x2, sp, #0x10
   81fb0:	910103e3 	add	x3, sp, #0x40
   81fb4:	a9400460 	ldp	x0, x1, [x3]
   81fb8:	a9000440 	stp	x0, x1, [x2]
   81fbc:	a9410460 	ldp	x0, x1, [x3, #16]
   81fc0:	a9010440 	stp	x0, x1, [x2, #16]
   81fc4:	910043e0 	add	x0, sp, #0x10
   81fc8:	aa0003e3 	mov	x3, x0
   81fcc:	f9401fe2 	ldr	x2, [sp, #56]
   81fd0:	aa0503e1 	mov	x1, x5
   81fd4:	aa0403e0 	mov	x0, x4
   81fd8:	97fffeca 	bl	81b00 <tfp_format>
    va_end(va);
    }
   81fdc:	d503201f 	nop
   81fe0:	a8ca7bfd 	ldp	x29, x30, [sp], #160
   81fe4:	d65f03c0 	ret

0000000000081fe8 <putcp>:

static void putcp(void* p,char c)
    {
   81fe8:	d10043ff 	sub	sp, sp, #0x10
   81fec:	f90007e0 	str	x0, [sp, #8]
   81ff0:	39001fe1 	strb	w1, [sp, #7]
    *(*((char**)p))++ = c;
   81ff4:	f94007e0 	ldr	x0, [sp, #8]
   81ff8:	f9400000 	ldr	x0, [x0]
   81ffc:	91000402 	add	x2, x0, #0x1
   82000:	f94007e1 	ldr	x1, [sp, #8]
   82004:	f9000022 	str	x2, [x1]
   82008:	39401fe1 	ldrb	w1, [sp, #7]
   8200c:	39000001 	strb	w1, [x0]
    }
   82010:	d503201f 	nop
   82014:	910043ff 	add	sp, sp, #0x10
   82018:	d65f03c0 	ret

000000000008201c <tfp_sprintf>:



void tfp_sprintf(char* s,char *fmt, ...)
    {
   8201c:	a9b77bfd 	stp	x29, x30, [sp, #-144]!
   82020:	910003fd 	mov	x29, sp
   82024:	f9001fe0 	str	x0, [sp, #56]
   82028:	f9001be1 	str	x1, [sp, #48]
   8202c:	f90033e2 	str	x2, [sp, #96]
   82030:	f90037e3 	str	x3, [sp, #104]
   82034:	f9003be4 	str	x4, [sp, #112]
   82038:	f9003fe5 	str	x5, [sp, #120]
   8203c:	f90043e6 	str	x6, [sp, #128]
   82040:	f90047e7 	str	x7, [sp, #136]
    va_list va;
    va_start(va,fmt);
   82044:	910243e0 	add	x0, sp, #0x90
   82048:	f90023e0 	str	x0, [sp, #64]
   8204c:	910243e0 	add	x0, sp, #0x90
   82050:	f90027e0 	str	x0, [sp, #72]
   82054:	910183e0 	add	x0, sp, #0x60
   82058:	f9002be0 	str	x0, [sp, #80]
   8205c:	128005e0 	mov	w0, #0xffffffd0            	// #-48
   82060:	b9005be0 	str	w0, [sp, #88]
   82064:	b9005fff 	str	wzr, [sp, #92]
    tfp_format(&s,putcp,fmt,va);
   82068:	910043e2 	add	x2, sp, #0x10
   8206c:	910103e3 	add	x3, sp, #0x40
   82070:	a9400460 	ldp	x0, x1, [x3]
   82074:	a9000440 	stp	x0, x1, [x2]
   82078:	a9410460 	ldp	x0, x1, [x3, #16]
   8207c:	a9010440 	stp	x0, x1, [x2, #16]
   82080:	910043e0 	add	x0, sp, #0x10
   82084:	9100e3e4 	add	x4, sp, #0x38
   82088:	aa0003e3 	mov	x3, x0
   8208c:	f9401be2 	ldr	x2, [sp, #48]
   82090:	f0ffffe0 	adrp	x0, 81000 <switch_to+0x60>
   82094:	913fa001 	add	x1, x0, #0xfe8
   82098:	aa0403e0 	mov	x0, x4
   8209c:	97fffe99 	bl	81b00 <tfp_format>
    putcp(&s,0);
   820a0:	9100e3e0 	add	x0, sp, #0x38
   820a4:	52800001 	mov	w1, #0x0                   	// #0
   820a8:	97ffffd0 	bl	81fe8 <putcp>
    va_end(va);
    }
   820ac:	d503201f 	nop
   820b0:	a8c97bfd 	ldp	x29, x30, [sp], #144
   820b4:	d65f03c0 	ret

00000000000820b8 <process>:
#include "fork.h"
#include "sched.h"
#include "mini_uart.h"

void process(char *array)
{
   820b8:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   820bc:	910003fd 	mov	x29, sp
   820c0:	f9000fe0 	str	x0, [sp, #24]
	while (1) {
		for (int i = 0; i < 5; i++){
   820c4:	b9002fff 	str	wzr, [sp, #44]
   820c8:	1400000c 	b	820f8 <process+0x40>
			uart_send(array[i]);
   820cc:	b9802fe0 	ldrsw	x0, [sp, #44]
   820d0:	f9400fe1 	ldr	x1, [sp, #24]
   820d4:	8b000020 	add	x0, x1, x0
   820d8:	39400000 	ldrb	w0, [x0]
   820dc:	97fffa2b 	bl	80988 <uart_send>
			delay(5000000);
   820e0:	d2896800 	mov	x0, #0x4b40                	// #19264
   820e4:	f2a00980 	movk	x0, #0x4c, lsl #16
   820e8:	94000576 	bl	836c0 <delay>
		for (int i = 0; i < 5; i++){
   820ec:	b9402fe0 	ldr	w0, [sp, #44]
   820f0:	11000400 	add	w0, w0, #0x1
   820f4:	b9002fe0 	str	w0, [sp, #44]
   820f8:	b9402fe0 	ldr	w0, [sp, #44]
   820fc:	7100101f 	cmp	w0, #0x4
   82100:	54fffe6d 	b.le	820cc <process+0x14>
   82104:	17fffff0 	b	820c4 <process+0xc>

0000000000082108 <process2>:
		}
	}
}

void process2(char *array)
{
   82108:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   8210c:	910003fd 	mov	x29, sp
   82110:	f9000fe0 	str	x0, [sp, #24]
	while (1) {
		for (int i = 0; i < 5; i++){
   82114:	b9002fff 	str	wzr, [sp, #44]
   82118:	1400000c 	b	82148 <process2+0x40>
			uart_send(array[i]);
   8211c:	b9802fe0 	ldrsw	x0, [sp, #44]
   82120:	f9400fe1 	ldr	x1, [sp, #24]
   82124:	8b000020 	add	x0, x1, x0
   82128:	39400000 	ldrb	w0, [x0]
   8212c:	97fffa17 	bl	80988 <uart_send>
			delay(5000000);
   82130:	d2896800 	mov	x0, #0x4b40                	// #19264
   82134:	f2a00980 	movk	x0, #0x4c, lsl #16
   82138:	94000562 	bl	836c0 <delay>
		for (int i = 0; i < 5; i++){
   8213c:	b9402fe0 	ldr	w0, [sp, #44]
   82140:	11000400 	add	w0, w0, #0x1
   82144:	b9002fe0 	str	w0, [sp, #44]
   82148:	b9402fe0 	ldr	w0, [sp, #44]
   8214c:	7100101f 	cmp	w0, #0x4
   82150:	54fffe6d 	b.le	8211c <process2+0x14>
   82154:	17fffff0 	b	82114 <process2+0xc>

0000000000082158 <kernel_main>:
	}
}


void kernel_main(void)
{
   82158:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   8215c:	910003fd 	mov	x29, sp
	uart_init();
   82160:	97fffa44 	bl	80a70 <uart_init>
	init_printf(0, putc);
   82164:	d0000000 	adrp	x0, 84000 <task+0x30>
   82168:	f940f801 	ldr	x1, [x0, #496]
   8216c:	d2800000 	mov	x0, #0x0                   	// #0
   82170:	97ffff68 	bl	81f10 <init_printf>

	printf("kernel boots\n");
   82174:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   82178:	91244000 	add	x0, x0, #0x910
   8217c:	97ffff73 	bl	81f48 <tfp_printf>

	irq_vector_init();
   82180:	94000526 	bl	83618 <irq_vector_init>
	generic_timer_init();
   82184:	97fffcdc 	bl	814f4 <generic_timer_init>
	enable_interrupt_controller();
   82188:	97fff99e 	bl	80800 <enable_interrupt_controller>
	enable_irq();
   8218c:	94000526 	bl	83624 <enable_irq>

	initialize_trace_arrays();
   82190:	97fffaea 	bl	80d38 <initialize_trace_arrays>

	int res = copy_process((unsigned long)&process, (unsigned long)"12345");
   82194:	90000000 	adrp	x0, 82000 <putcp+0x18>
   82198:	9102e002 	add	x2, x0, #0xb8
   8219c:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   821a0:	91248000 	add	x0, x0, #0x920
   821a4:	aa0003e1 	mov	x1, x0
   821a8:	aa0203e0 	mov	x0, x2
   821ac:	97fffd37 	bl	81688 <copy_process>
   821b0:	b9001fe0 	str	w0, [sp, #28]
	if (res != 0) {
   821b4:	b9401fe0 	ldr	w0, [sp, #28]
   821b8:	7100001f 	cmp	w0, #0x0
   821bc:	540000a0 	b.eq	821d0 <kernel_main+0x78>  // b.none
		printf("error while starting process 1");
   821c0:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   821c4:	9124a000 	add	x0, x0, #0x928
   821c8:	97ffff60 	bl	81f48 <tfp_printf>
		return;
   821cc:	14000030 	b	8228c <kernel_main+0x134>
	}
	res = copy_process((unsigned long)&process2, (unsigned long)"abcde");
   821d0:	90000000 	adrp	x0, 82000 <putcp+0x18>
   821d4:	91042002 	add	x2, x0, #0x108
   821d8:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   821dc:	91252000 	add	x0, x0, #0x948
   821e0:	aa0003e1 	mov	x1, x0
   821e4:	aa0203e0 	mov	x0, x2
   821e8:	97fffd28 	bl	81688 <copy_process>
   821ec:	b9001fe0 	str	w0, [sp, #28]
	if (res != 0) {
   821f0:	b9401fe0 	ldr	w0, [sp, #28]
   821f4:	7100001f 	cmp	w0, #0x0
   821f8:	540000a0 	b.eq	8220c <kernel_main+0xb4>  // b.none
		printf("error while starting process 2");
   821fc:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   82200:	91254000 	add	x0, x0, #0x950
   82204:	97ffff51 	bl	81f48 <tfp_printf>
		return;
   82208:	14000021 	b	8228c <kernel_main+0x134>
	}
	res = copy_process((unsigned long) &process, (unsigned long) "Hello");
   8220c:	90000000 	adrp	x0, 82000 <putcp+0x18>
   82210:	9102e002 	add	x2, x0, #0xb8
   82214:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   82218:	9125c000 	add	x0, x0, #0x970
   8221c:	aa0003e1 	mov	x1, x0
   82220:	aa0203e0 	mov	x0, x2
   82224:	97fffd19 	bl	81688 <copy_process>
   82228:	b9001fe0 	str	w0, [sp, #28]
	if (res != 0){
   8222c:	b9401fe0 	ldr	w0, [sp, #28]
   82230:	7100001f 	cmp	w0, #0x0
   82234:	540000a0 	b.eq	82248 <kernel_main+0xf0>  // b.none
		printf("Error while starting process 3");
   82238:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   8223c:	9125e000 	add	x0, x0, #0x978
   82240:	97ffff42 	bl	81f48 <tfp_printf>
		return;
   82244:	14000012 	b	8228c <kernel_main+0x134>
	}
	res = copy_process((unsigned long) &process, (unsigned long) "there");
   82248:	90000000 	adrp	x0, 82000 <putcp+0x18>
   8224c:	9102e002 	add	x2, x0, #0xb8
   82250:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   82254:	91266000 	add	x0, x0, #0x998
   82258:	aa0003e1 	mov	x1, x0
   8225c:	aa0203e0 	mov	x0, x2
   82260:	97fffd0a 	bl	81688 <copy_process>
   82264:	b9001fe0 	str	w0, [sp, #28]
	if(res != 0){
   82268:	b9401fe0 	ldr	w0, [sp, #28]
   8226c:	7100001f 	cmp	w0, #0x0
   82270:	540000a0 	b.eq	82284 <kernel_main+0x12c>  // b.none
		printf("Error while starting process 4");
   82274:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   82278:	91268000 	add	x0, x0, #0x9a0
   8227c:	97ffff33 	bl	81f48 <tfp_printf>
		return;
   82280:	14000003 	b	8228c <kernel_main+0x134>
	}

	while (1){
		schedule();
   82284:	97fffaa3 	bl	80d10 <schedule>
   82288:	17ffffff 	b	82284 <kernel_main+0x12c>
	}	
}
   8228c:	a8c27bfd 	ldp	x29, x30, [sp], #32
   82290:	d65f03c0 	ret

0000000000082294 <gen_timer_init>:
 *  https://developer.arm.com/docs/ddi0487/ca/arm-architecture-reference-manual-armv8-for-armv8-a-architecture-profile
 */

.globl gen_timer_init
gen_timer_init:
	mov x0, #1
   82294:	d2800020 	mov	x0, #0x1                   	// #1
	msr CNTP_CTL_EL0, x0
   82298:	d51be220 	msr	cntp_ctl_el0, x0
	ret
   8229c:	d65f03c0 	ret

00000000000822a0 <gen_timer_reset>:

.globl gen_timer_reset
gen_timer_reset:
#    mov x0, #1
#	lsl x0, x0, #24 
	msr CNTP_TVAL_EL0, x0
   822a0:	d51be200 	msr	cntp_tval_el0, x0
    ret
   822a4:	d65f03c0 	ret

00000000000822a8 <get_timer_freq>:

.globl get_timer_freq
get_timer_freq:
	mrs x0, CNTFRQ_EL0
   822a8:	d53be000 	mrs	x0, cntfrq_el0
	ret
   822ac:	d65f03c0 	ret

00000000000822b0 <get_sys_count>:

.globl get_sys_count
get_sys_count:
	mrs x0, CNTPCT_EL0
   822b0:	d53be020 	mrs	x0, cntpct_el0
   822b4:	d65f03c0 	ret
	...

0000000000082800 <vectors>:
 * Exception vectors.
 */
.align	11
.globl vectors 
vectors:
	ventry	sync_invalid_el1t			// Synchronous EL1t
   82800:	140001e1 	b	82f84 <sync_invalid_el1t>
   82804:	d503201f 	nop
   82808:	d503201f 	nop
   8280c:	d503201f 	nop
   82810:	d503201f 	nop
   82814:	d503201f 	nop
   82818:	d503201f 	nop
   8281c:	d503201f 	nop
   82820:	d503201f 	nop
   82824:	d503201f 	nop
   82828:	d503201f 	nop
   8282c:	d503201f 	nop
   82830:	d503201f 	nop
   82834:	d503201f 	nop
   82838:	d503201f 	nop
   8283c:	d503201f 	nop
   82840:	d503201f 	nop
   82844:	d503201f 	nop
   82848:	d503201f 	nop
   8284c:	d503201f 	nop
   82850:	d503201f 	nop
   82854:	d503201f 	nop
   82858:	d503201f 	nop
   8285c:	d503201f 	nop
   82860:	d503201f 	nop
   82864:	d503201f 	nop
   82868:	d503201f 	nop
   8286c:	d503201f 	nop
   82870:	d503201f 	nop
   82874:	d503201f 	nop
   82878:	d503201f 	nop
   8287c:	d503201f 	nop
	ventry	irq_invalid_el1t			// IRQ EL1t
   82880:	140001da 	b	82fe8 <irq_invalid_el1t>
   82884:	d503201f 	nop
   82888:	d503201f 	nop
   8288c:	d503201f 	nop
   82890:	d503201f 	nop
   82894:	d503201f 	nop
   82898:	d503201f 	nop
   8289c:	d503201f 	nop
   828a0:	d503201f 	nop
   828a4:	d503201f 	nop
   828a8:	d503201f 	nop
   828ac:	d503201f 	nop
   828b0:	d503201f 	nop
   828b4:	d503201f 	nop
   828b8:	d503201f 	nop
   828bc:	d503201f 	nop
   828c0:	d503201f 	nop
   828c4:	d503201f 	nop
   828c8:	d503201f 	nop
   828cc:	d503201f 	nop
   828d0:	d503201f 	nop
   828d4:	d503201f 	nop
   828d8:	d503201f 	nop
   828dc:	d503201f 	nop
   828e0:	d503201f 	nop
   828e4:	d503201f 	nop
   828e8:	d503201f 	nop
   828ec:	d503201f 	nop
   828f0:	d503201f 	nop
   828f4:	d503201f 	nop
   828f8:	d503201f 	nop
   828fc:	d503201f 	nop
	ventry	fiq_invalid_el1t			// FIQ EL1t
   82900:	140001d3 	b	8304c <fiq_invalid_el1t>
   82904:	d503201f 	nop
   82908:	d503201f 	nop
   8290c:	d503201f 	nop
   82910:	d503201f 	nop
   82914:	d503201f 	nop
   82918:	d503201f 	nop
   8291c:	d503201f 	nop
   82920:	d503201f 	nop
   82924:	d503201f 	nop
   82928:	d503201f 	nop
   8292c:	d503201f 	nop
   82930:	d503201f 	nop
   82934:	d503201f 	nop
   82938:	d503201f 	nop
   8293c:	d503201f 	nop
   82940:	d503201f 	nop
   82944:	d503201f 	nop
   82948:	d503201f 	nop
   8294c:	d503201f 	nop
   82950:	d503201f 	nop
   82954:	d503201f 	nop
   82958:	d503201f 	nop
   8295c:	d503201f 	nop
   82960:	d503201f 	nop
   82964:	d503201f 	nop
   82968:	d503201f 	nop
   8296c:	d503201f 	nop
   82970:	d503201f 	nop
   82974:	d503201f 	nop
   82978:	d503201f 	nop
   8297c:	d503201f 	nop
	ventry	error_invalid_el1t			// Error EL1t
   82980:	140001cc 	b	830b0 <error_invalid_el1t>
   82984:	d503201f 	nop
   82988:	d503201f 	nop
   8298c:	d503201f 	nop
   82990:	d503201f 	nop
   82994:	d503201f 	nop
   82998:	d503201f 	nop
   8299c:	d503201f 	nop
   829a0:	d503201f 	nop
   829a4:	d503201f 	nop
   829a8:	d503201f 	nop
   829ac:	d503201f 	nop
   829b0:	d503201f 	nop
   829b4:	d503201f 	nop
   829b8:	d503201f 	nop
   829bc:	d503201f 	nop
   829c0:	d503201f 	nop
   829c4:	d503201f 	nop
   829c8:	d503201f 	nop
   829cc:	d503201f 	nop
   829d0:	d503201f 	nop
   829d4:	d503201f 	nop
   829d8:	d503201f 	nop
   829dc:	d503201f 	nop
   829e0:	d503201f 	nop
   829e4:	d503201f 	nop
   829e8:	d503201f 	nop
   829ec:	d503201f 	nop
   829f0:	d503201f 	nop
   829f4:	d503201f 	nop
   829f8:	d503201f 	nop
   829fc:	d503201f 	nop

	ventry	sync_invalid_el1h			// Synchronous EL1h
   82a00:	140001c5 	b	83114 <sync_invalid_el1h>
   82a04:	d503201f 	nop
   82a08:	d503201f 	nop
   82a0c:	d503201f 	nop
   82a10:	d503201f 	nop
   82a14:	d503201f 	nop
   82a18:	d503201f 	nop
   82a1c:	d503201f 	nop
   82a20:	d503201f 	nop
   82a24:	d503201f 	nop
   82a28:	d503201f 	nop
   82a2c:	d503201f 	nop
   82a30:	d503201f 	nop
   82a34:	d503201f 	nop
   82a38:	d503201f 	nop
   82a3c:	d503201f 	nop
   82a40:	d503201f 	nop
   82a44:	d503201f 	nop
   82a48:	d503201f 	nop
   82a4c:	d503201f 	nop
   82a50:	d503201f 	nop
   82a54:	d503201f 	nop
   82a58:	d503201f 	nop
   82a5c:	d503201f 	nop
   82a60:	d503201f 	nop
   82a64:	d503201f 	nop
   82a68:	d503201f 	nop
   82a6c:	d503201f 	nop
   82a70:	d503201f 	nop
   82a74:	d503201f 	nop
   82a78:	d503201f 	nop
   82a7c:	d503201f 	nop
	ventry	el1_irq					// IRQ EL1h
   82a80:	140002b8 	b	83560 <el1_irq>
   82a84:	d503201f 	nop
   82a88:	d503201f 	nop
   82a8c:	d503201f 	nop
   82a90:	d503201f 	nop
   82a94:	d503201f 	nop
   82a98:	d503201f 	nop
   82a9c:	d503201f 	nop
   82aa0:	d503201f 	nop
   82aa4:	d503201f 	nop
   82aa8:	d503201f 	nop
   82aac:	d503201f 	nop
   82ab0:	d503201f 	nop
   82ab4:	d503201f 	nop
   82ab8:	d503201f 	nop
   82abc:	d503201f 	nop
   82ac0:	d503201f 	nop
   82ac4:	d503201f 	nop
   82ac8:	d503201f 	nop
   82acc:	d503201f 	nop
   82ad0:	d503201f 	nop
   82ad4:	d503201f 	nop
   82ad8:	d503201f 	nop
   82adc:	d503201f 	nop
   82ae0:	d503201f 	nop
   82ae4:	d503201f 	nop
   82ae8:	d503201f 	nop
   82aec:	d503201f 	nop
   82af0:	d503201f 	nop
   82af4:	d503201f 	nop
   82af8:	d503201f 	nop
   82afc:	d503201f 	nop
	ventry	fiq_invalid_el1h			// FIQ EL1h
   82b00:	1400019e 	b	83178 <fiq_invalid_el1h>
   82b04:	d503201f 	nop
   82b08:	d503201f 	nop
   82b0c:	d503201f 	nop
   82b10:	d503201f 	nop
   82b14:	d503201f 	nop
   82b18:	d503201f 	nop
   82b1c:	d503201f 	nop
   82b20:	d503201f 	nop
   82b24:	d503201f 	nop
   82b28:	d503201f 	nop
   82b2c:	d503201f 	nop
   82b30:	d503201f 	nop
   82b34:	d503201f 	nop
   82b38:	d503201f 	nop
   82b3c:	d503201f 	nop
   82b40:	d503201f 	nop
   82b44:	d503201f 	nop
   82b48:	d503201f 	nop
   82b4c:	d503201f 	nop
   82b50:	d503201f 	nop
   82b54:	d503201f 	nop
   82b58:	d503201f 	nop
   82b5c:	d503201f 	nop
   82b60:	d503201f 	nop
   82b64:	d503201f 	nop
   82b68:	d503201f 	nop
   82b6c:	d503201f 	nop
   82b70:	d503201f 	nop
   82b74:	d503201f 	nop
   82b78:	d503201f 	nop
   82b7c:	d503201f 	nop
	ventry	error_invalid_el1h			// Error EL1h
   82b80:	14000197 	b	831dc <error_invalid_el1h>
   82b84:	d503201f 	nop
   82b88:	d503201f 	nop
   82b8c:	d503201f 	nop
   82b90:	d503201f 	nop
   82b94:	d503201f 	nop
   82b98:	d503201f 	nop
   82b9c:	d503201f 	nop
   82ba0:	d503201f 	nop
   82ba4:	d503201f 	nop
   82ba8:	d503201f 	nop
   82bac:	d503201f 	nop
   82bb0:	d503201f 	nop
   82bb4:	d503201f 	nop
   82bb8:	d503201f 	nop
   82bbc:	d503201f 	nop
   82bc0:	d503201f 	nop
   82bc4:	d503201f 	nop
   82bc8:	d503201f 	nop
   82bcc:	d503201f 	nop
   82bd0:	d503201f 	nop
   82bd4:	d503201f 	nop
   82bd8:	d503201f 	nop
   82bdc:	d503201f 	nop
   82be0:	d503201f 	nop
   82be4:	d503201f 	nop
   82be8:	d503201f 	nop
   82bec:	d503201f 	nop
   82bf0:	d503201f 	nop
   82bf4:	d503201f 	nop
   82bf8:	d503201f 	nop
   82bfc:	d503201f 	nop

	ventry	sync_invalid_el0_64			// Synchronous 64-bit EL0
   82c00:	14000190 	b	83240 <sync_invalid_el0_64>
   82c04:	d503201f 	nop
   82c08:	d503201f 	nop
   82c0c:	d503201f 	nop
   82c10:	d503201f 	nop
   82c14:	d503201f 	nop
   82c18:	d503201f 	nop
   82c1c:	d503201f 	nop
   82c20:	d503201f 	nop
   82c24:	d503201f 	nop
   82c28:	d503201f 	nop
   82c2c:	d503201f 	nop
   82c30:	d503201f 	nop
   82c34:	d503201f 	nop
   82c38:	d503201f 	nop
   82c3c:	d503201f 	nop
   82c40:	d503201f 	nop
   82c44:	d503201f 	nop
   82c48:	d503201f 	nop
   82c4c:	d503201f 	nop
   82c50:	d503201f 	nop
   82c54:	d503201f 	nop
   82c58:	d503201f 	nop
   82c5c:	d503201f 	nop
   82c60:	d503201f 	nop
   82c64:	d503201f 	nop
   82c68:	d503201f 	nop
   82c6c:	d503201f 	nop
   82c70:	d503201f 	nop
   82c74:	d503201f 	nop
   82c78:	d503201f 	nop
   82c7c:	d503201f 	nop
	ventry	irq_invalid_el0_64			// IRQ 64-bit EL0
   82c80:	14000189 	b	832a4 <irq_invalid_el0_64>
   82c84:	d503201f 	nop
   82c88:	d503201f 	nop
   82c8c:	d503201f 	nop
   82c90:	d503201f 	nop
   82c94:	d503201f 	nop
   82c98:	d503201f 	nop
   82c9c:	d503201f 	nop
   82ca0:	d503201f 	nop
   82ca4:	d503201f 	nop
   82ca8:	d503201f 	nop
   82cac:	d503201f 	nop
   82cb0:	d503201f 	nop
   82cb4:	d503201f 	nop
   82cb8:	d503201f 	nop
   82cbc:	d503201f 	nop
   82cc0:	d503201f 	nop
   82cc4:	d503201f 	nop
   82cc8:	d503201f 	nop
   82ccc:	d503201f 	nop
   82cd0:	d503201f 	nop
   82cd4:	d503201f 	nop
   82cd8:	d503201f 	nop
   82cdc:	d503201f 	nop
   82ce0:	d503201f 	nop
   82ce4:	d503201f 	nop
   82ce8:	d503201f 	nop
   82cec:	d503201f 	nop
   82cf0:	d503201f 	nop
   82cf4:	d503201f 	nop
   82cf8:	d503201f 	nop
   82cfc:	d503201f 	nop
	ventry	fiq_invalid_el0_64			// FIQ 64-bit EL0
   82d00:	14000182 	b	83308 <fiq_invalid_el0_64>
   82d04:	d503201f 	nop
   82d08:	d503201f 	nop
   82d0c:	d503201f 	nop
   82d10:	d503201f 	nop
   82d14:	d503201f 	nop
   82d18:	d503201f 	nop
   82d1c:	d503201f 	nop
   82d20:	d503201f 	nop
   82d24:	d503201f 	nop
   82d28:	d503201f 	nop
   82d2c:	d503201f 	nop
   82d30:	d503201f 	nop
   82d34:	d503201f 	nop
   82d38:	d503201f 	nop
   82d3c:	d503201f 	nop
   82d40:	d503201f 	nop
   82d44:	d503201f 	nop
   82d48:	d503201f 	nop
   82d4c:	d503201f 	nop
   82d50:	d503201f 	nop
   82d54:	d503201f 	nop
   82d58:	d503201f 	nop
   82d5c:	d503201f 	nop
   82d60:	d503201f 	nop
   82d64:	d503201f 	nop
   82d68:	d503201f 	nop
   82d6c:	d503201f 	nop
   82d70:	d503201f 	nop
   82d74:	d503201f 	nop
   82d78:	d503201f 	nop
   82d7c:	d503201f 	nop
	ventry	error_invalid_el0_64			// Error 64-bit EL0
   82d80:	1400017b 	b	8336c <error_invalid_el0_64>
   82d84:	d503201f 	nop
   82d88:	d503201f 	nop
   82d8c:	d503201f 	nop
   82d90:	d503201f 	nop
   82d94:	d503201f 	nop
   82d98:	d503201f 	nop
   82d9c:	d503201f 	nop
   82da0:	d503201f 	nop
   82da4:	d503201f 	nop
   82da8:	d503201f 	nop
   82dac:	d503201f 	nop
   82db0:	d503201f 	nop
   82db4:	d503201f 	nop
   82db8:	d503201f 	nop
   82dbc:	d503201f 	nop
   82dc0:	d503201f 	nop
   82dc4:	d503201f 	nop
   82dc8:	d503201f 	nop
   82dcc:	d503201f 	nop
   82dd0:	d503201f 	nop
   82dd4:	d503201f 	nop
   82dd8:	d503201f 	nop
   82ddc:	d503201f 	nop
   82de0:	d503201f 	nop
   82de4:	d503201f 	nop
   82de8:	d503201f 	nop
   82dec:	d503201f 	nop
   82df0:	d503201f 	nop
   82df4:	d503201f 	nop
   82df8:	d503201f 	nop
   82dfc:	d503201f 	nop

	ventry	sync_invalid_el0_32			// Synchronous 32-bit EL0
   82e00:	14000174 	b	833d0 <sync_invalid_el0_32>
   82e04:	d503201f 	nop
   82e08:	d503201f 	nop
   82e0c:	d503201f 	nop
   82e10:	d503201f 	nop
   82e14:	d503201f 	nop
   82e18:	d503201f 	nop
   82e1c:	d503201f 	nop
   82e20:	d503201f 	nop
   82e24:	d503201f 	nop
   82e28:	d503201f 	nop
   82e2c:	d503201f 	nop
   82e30:	d503201f 	nop
   82e34:	d503201f 	nop
   82e38:	d503201f 	nop
   82e3c:	d503201f 	nop
   82e40:	d503201f 	nop
   82e44:	d503201f 	nop
   82e48:	d503201f 	nop
   82e4c:	d503201f 	nop
   82e50:	d503201f 	nop
   82e54:	d503201f 	nop
   82e58:	d503201f 	nop
   82e5c:	d503201f 	nop
   82e60:	d503201f 	nop
   82e64:	d503201f 	nop
   82e68:	d503201f 	nop
   82e6c:	d503201f 	nop
   82e70:	d503201f 	nop
   82e74:	d503201f 	nop
   82e78:	d503201f 	nop
   82e7c:	d503201f 	nop
	ventry	irq_invalid_el0_32			// IRQ 32-bit EL0
   82e80:	1400016d 	b	83434 <irq_invalid_el0_32>
   82e84:	d503201f 	nop
   82e88:	d503201f 	nop
   82e8c:	d503201f 	nop
   82e90:	d503201f 	nop
   82e94:	d503201f 	nop
   82e98:	d503201f 	nop
   82e9c:	d503201f 	nop
   82ea0:	d503201f 	nop
   82ea4:	d503201f 	nop
   82ea8:	d503201f 	nop
   82eac:	d503201f 	nop
   82eb0:	d503201f 	nop
   82eb4:	d503201f 	nop
   82eb8:	d503201f 	nop
   82ebc:	d503201f 	nop
   82ec0:	d503201f 	nop
   82ec4:	d503201f 	nop
   82ec8:	d503201f 	nop
   82ecc:	d503201f 	nop
   82ed0:	d503201f 	nop
   82ed4:	d503201f 	nop
   82ed8:	d503201f 	nop
   82edc:	d503201f 	nop
   82ee0:	d503201f 	nop
   82ee4:	d503201f 	nop
   82ee8:	d503201f 	nop
   82eec:	d503201f 	nop
   82ef0:	d503201f 	nop
   82ef4:	d503201f 	nop
   82ef8:	d503201f 	nop
   82efc:	d503201f 	nop
	ventry	fiq_invalid_el0_32			// FIQ 32-bit EL0
   82f00:	14000166 	b	83498 <fiq_invalid_el0_32>
   82f04:	d503201f 	nop
   82f08:	d503201f 	nop
   82f0c:	d503201f 	nop
   82f10:	d503201f 	nop
   82f14:	d503201f 	nop
   82f18:	d503201f 	nop
   82f1c:	d503201f 	nop
   82f20:	d503201f 	nop
   82f24:	d503201f 	nop
   82f28:	d503201f 	nop
   82f2c:	d503201f 	nop
   82f30:	d503201f 	nop
   82f34:	d503201f 	nop
   82f38:	d503201f 	nop
   82f3c:	d503201f 	nop
   82f40:	d503201f 	nop
   82f44:	d503201f 	nop
   82f48:	d503201f 	nop
   82f4c:	d503201f 	nop
   82f50:	d503201f 	nop
   82f54:	d503201f 	nop
   82f58:	d503201f 	nop
   82f5c:	d503201f 	nop
   82f60:	d503201f 	nop
   82f64:	d503201f 	nop
   82f68:	d503201f 	nop
   82f6c:	d503201f 	nop
   82f70:	d503201f 	nop
   82f74:	d503201f 	nop
   82f78:	d503201f 	nop
   82f7c:	d503201f 	nop
	ventry	error_invalid_el0_32			// Error 32-bit EL0
   82f80:	1400015f 	b	834fc <error_invalid_el0_32>

0000000000082f84 <sync_invalid_el1t>:

sync_invalid_el1t:
	handle_invalid_entry  SYNC_INVALID_EL1t
   82f84:	d10443ff 	sub	sp, sp, #0x110
   82f88:	a90007e0 	stp	x0, x1, [sp]
   82f8c:	a9010fe2 	stp	x2, x3, [sp, #16]
   82f90:	a90217e4 	stp	x4, x5, [sp, #32]
   82f94:	a9031fe6 	stp	x6, x7, [sp, #48]
   82f98:	a90427e8 	stp	x8, x9, [sp, #64]
   82f9c:	a9052fea 	stp	x10, x11, [sp, #80]
   82fa0:	a90637ec 	stp	x12, x13, [sp, #96]
   82fa4:	a9073fee 	stp	x14, x15, [sp, #112]
   82fa8:	a90847f0 	stp	x16, x17, [sp, #128]
   82fac:	a9094ff2 	stp	x18, x19, [sp, #144]
   82fb0:	a90a57f4 	stp	x20, x21, [sp, #160]
   82fb4:	a90b5ff6 	stp	x22, x23, [sp, #176]
   82fb8:	a90c67f8 	stp	x24, x25, [sp, #192]
   82fbc:	a90d6ffa 	stp	x26, x27, [sp, #208]
   82fc0:	a90e77fc 	stp	x28, x29, [sp, #224]
   82fc4:	d5384036 	mrs	x22, elr_el1
   82fc8:	d5384017 	mrs	x23, spsr_el1
   82fcc:	a90f5bfe 	stp	x30, x22, [sp, #240]
   82fd0:	f90083f7 	str	x23, [sp, #256]
   82fd4:	d2800000 	mov	x0, #0x0                   	// #0
   82fd8:	d5385201 	mrs	x1, esr_el1
   82fdc:	d5384022 	mrs	x2, elr_el1
   82fe0:	97fff611 	bl	80824 <show_invalid_entry_message>
   82fe4:	1400018c 	b	83614 <err_hang>

0000000000082fe8 <irq_invalid_el1t>:

irq_invalid_el1t:
	handle_invalid_entry  IRQ_INVALID_EL1t
   82fe8:	d10443ff 	sub	sp, sp, #0x110
   82fec:	a90007e0 	stp	x0, x1, [sp]
   82ff0:	a9010fe2 	stp	x2, x3, [sp, #16]
   82ff4:	a90217e4 	stp	x4, x5, [sp, #32]
   82ff8:	a9031fe6 	stp	x6, x7, [sp, #48]
   82ffc:	a90427e8 	stp	x8, x9, [sp, #64]
   83000:	a9052fea 	stp	x10, x11, [sp, #80]
   83004:	a90637ec 	stp	x12, x13, [sp, #96]
   83008:	a9073fee 	stp	x14, x15, [sp, #112]
   8300c:	a90847f0 	stp	x16, x17, [sp, #128]
   83010:	a9094ff2 	stp	x18, x19, [sp, #144]
   83014:	a90a57f4 	stp	x20, x21, [sp, #160]
   83018:	a90b5ff6 	stp	x22, x23, [sp, #176]
   8301c:	a90c67f8 	stp	x24, x25, [sp, #192]
   83020:	a90d6ffa 	stp	x26, x27, [sp, #208]
   83024:	a90e77fc 	stp	x28, x29, [sp, #224]
   83028:	d5384036 	mrs	x22, elr_el1
   8302c:	d5384017 	mrs	x23, spsr_el1
   83030:	a90f5bfe 	stp	x30, x22, [sp, #240]
   83034:	f90083f7 	str	x23, [sp, #256]
   83038:	d2800020 	mov	x0, #0x1                   	// #1
   8303c:	d5385201 	mrs	x1, esr_el1
   83040:	d5384022 	mrs	x2, elr_el1
   83044:	97fff5f8 	bl	80824 <show_invalid_entry_message>
   83048:	14000173 	b	83614 <err_hang>

000000000008304c <fiq_invalid_el1t>:

fiq_invalid_el1t:
	handle_invalid_entry  FIQ_INVALID_EL1t
   8304c:	d10443ff 	sub	sp, sp, #0x110
   83050:	a90007e0 	stp	x0, x1, [sp]
   83054:	a9010fe2 	stp	x2, x3, [sp, #16]
   83058:	a90217e4 	stp	x4, x5, [sp, #32]
   8305c:	a9031fe6 	stp	x6, x7, [sp, #48]
   83060:	a90427e8 	stp	x8, x9, [sp, #64]
   83064:	a9052fea 	stp	x10, x11, [sp, #80]
   83068:	a90637ec 	stp	x12, x13, [sp, #96]
   8306c:	a9073fee 	stp	x14, x15, [sp, #112]
   83070:	a90847f0 	stp	x16, x17, [sp, #128]
   83074:	a9094ff2 	stp	x18, x19, [sp, #144]
   83078:	a90a57f4 	stp	x20, x21, [sp, #160]
   8307c:	a90b5ff6 	stp	x22, x23, [sp, #176]
   83080:	a90c67f8 	stp	x24, x25, [sp, #192]
   83084:	a90d6ffa 	stp	x26, x27, [sp, #208]
   83088:	a90e77fc 	stp	x28, x29, [sp, #224]
   8308c:	d5384036 	mrs	x22, elr_el1
   83090:	d5384017 	mrs	x23, spsr_el1
   83094:	a90f5bfe 	stp	x30, x22, [sp, #240]
   83098:	f90083f7 	str	x23, [sp, #256]
   8309c:	d2800040 	mov	x0, #0x2                   	// #2
   830a0:	d5385201 	mrs	x1, esr_el1
   830a4:	d5384022 	mrs	x2, elr_el1
   830a8:	97fff5df 	bl	80824 <show_invalid_entry_message>
   830ac:	1400015a 	b	83614 <err_hang>

00000000000830b0 <error_invalid_el1t>:

error_invalid_el1t:
	handle_invalid_entry  ERROR_INVALID_EL1t
   830b0:	d10443ff 	sub	sp, sp, #0x110
   830b4:	a90007e0 	stp	x0, x1, [sp]
   830b8:	a9010fe2 	stp	x2, x3, [sp, #16]
   830bc:	a90217e4 	stp	x4, x5, [sp, #32]
   830c0:	a9031fe6 	stp	x6, x7, [sp, #48]
   830c4:	a90427e8 	stp	x8, x9, [sp, #64]
   830c8:	a9052fea 	stp	x10, x11, [sp, #80]
   830cc:	a90637ec 	stp	x12, x13, [sp, #96]
   830d0:	a9073fee 	stp	x14, x15, [sp, #112]
   830d4:	a90847f0 	stp	x16, x17, [sp, #128]
   830d8:	a9094ff2 	stp	x18, x19, [sp, #144]
   830dc:	a90a57f4 	stp	x20, x21, [sp, #160]
   830e0:	a90b5ff6 	stp	x22, x23, [sp, #176]
   830e4:	a90c67f8 	stp	x24, x25, [sp, #192]
   830e8:	a90d6ffa 	stp	x26, x27, [sp, #208]
   830ec:	a90e77fc 	stp	x28, x29, [sp, #224]
   830f0:	d5384036 	mrs	x22, elr_el1
   830f4:	d5384017 	mrs	x23, spsr_el1
   830f8:	a90f5bfe 	stp	x30, x22, [sp, #240]
   830fc:	f90083f7 	str	x23, [sp, #256]
   83100:	d2800060 	mov	x0, #0x3                   	// #3
   83104:	d5385201 	mrs	x1, esr_el1
   83108:	d5384022 	mrs	x2, elr_el1
   8310c:	97fff5c6 	bl	80824 <show_invalid_entry_message>
   83110:	14000141 	b	83614 <err_hang>

0000000000083114 <sync_invalid_el1h>:

sync_invalid_el1h:
	handle_invalid_entry  SYNC_INVALID_EL1h
   83114:	d10443ff 	sub	sp, sp, #0x110
   83118:	a90007e0 	stp	x0, x1, [sp]
   8311c:	a9010fe2 	stp	x2, x3, [sp, #16]
   83120:	a90217e4 	stp	x4, x5, [sp, #32]
   83124:	a9031fe6 	stp	x6, x7, [sp, #48]
   83128:	a90427e8 	stp	x8, x9, [sp, #64]
   8312c:	a9052fea 	stp	x10, x11, [sp, #80]
   83130:	a90637ec 	stp	x12, x13, [sp, #96]
   83134:	a9073fee 	stp	x14, x15, [sp, #112]
   83138:	a90847f0 	stp	x16, x17, [sp, #128]
   8313c:	a9094ff2 	stp	x18, x19, [sp, #144]
   83140:	a90a57f4 	stp	x20, x21, [sp, #160]
   83144:	a90b5ff6 	stp	x22, x23, [sp, #176]
   83148:	a90c67f8 	stp	x24, x25, [sp, #192]
   8314c:	a90d6ffa 	stp	x26, x27, [sp, #208]
   83150:	a90e77fc 	stp	x28, x29, [sp, #224]
   83154:	d5384036 	mrs	x22, elr_el1
   83158:	d5384017 	mrs	x23, spsr_el1
   8315c:	a90f5bfe 	stp	x30, x22, [sp, #240]
   83160:	f90083f7 	str	x23, [sp, #256]
   83164:	d2800080 	mov	x0, #0x4                   	// #4
   83168:	d5385201 	mrs	x1, esr_el1
   8316c:	d5384022 	mrs	x2, elr_el1
   83170:	97fff5ad 	bl	80824 <show_invalid_entry_message>
   83174:	14000128 	b	83614 <err_hang>

0000000000083178 <fiq_invalid_el1h>:

fiq_invalid_el1h:
	handle_invalid_entry  FIQ_INVALID_EL1h
   83178:	d10443ff 	sub	sp, sp, #0x110
   8317c:	a90007e0 	stp	x0, x1, [sp]
   83180:	a9010fe2 	stp	x2, x3, [sp, #16]
   83184:	a90217e4 	stp	x4, x5, [sp, #32]
   83188:	a9031fe6 	stp	x6, x7, [sp, #48]
   8318c:	a90427e8 	stp	x8, x9, [sp, #64]
   83190:	a9052fea 	stp	x10, x11, [sp, #80]
   83194:	a90637ec 	stp	x12, x13, [sp, #96]
   83198:	a9073fee 	stp	x14, x15, [sp, #112]
   8319c:	a90847f0 	stp	x16, x17, [sp, #128]
   831a0:	a9094ff2 	stp	x18, x19, [sp, #144]
   831a4:	a90a57f4 	stp	x20, x21, [sp, #160]
   831a8:	a90b5ff6 	stp	x22, x23, [sp, #176]
   831ac:	a90c67f8 	stp	x24, x25, [sp, #192]
   831b0:	a90d6ffa 	stp	x26, x27, [sp, #208]
   831b4:	a90e77fc 	stp	x28, x29, [sp, #224]
   831b8:	d5384036 	mrs	x22, elr_el1
   831bc:	d5384017 	mrs	x23, spsr_el1
   831c0:	a90f5bfe 	stp	x30, x22, [sp, #240]
   831c4:	f90083f7 	str	x23, [sp, #256]
   831c8:	d28000c0 	mov	x0, #0x6                   	// #6
   831cc:	d5385201 	mrs	x1, esr_el1
   831d0:	d5384022 	mrs	x2, elr_el1
   831d4:	97fff594 	bl	80824 <show_invalid_entry_message>
   831d8:	1400010f 	b	83614 <err_hang>

00000000000831dc <error_invalid_el1h>:

error_invalid_el1h:
	handle_invalid_entry  ERROR_INVALID_EL1h
   831dc:	d10443ff 	sub	sp, sp, #0x110
   831e0:	a90007e0 	stp	x0, x1, [sp]
   831e4:	a9010fe2 	stp	x2, x3, [sp, #16]
   831e8:	a90217e4 	stp	x4, x5, [sp, #32]
   831ec:	a9031fe6 	stp	x6, x7, [sp, #48]
   831f0:	a90427e8 	stp	x8, x9, [sp, #64]
   831f4:	a9052fea 	stp	x10, x11, [sp, #80]
   831f8:	a90637ec 	stp	x12, x13, [sp, #96]
   831fc:	a9073fee 	stp	x14, x15, [sp, #112]
   83200:	a90847f0 	stp	x16, x17, [sp, #128]
   83204:	a9094ff2 	stp	x18, x19, [sp, #144]
   83208:	a90a57f4 	stp	x20, x21, [sp, #160]
   8320c:	a90b5ff6 	stp	x22, x23, [sp, #176]
   83210:	a90c67f8 	stp	x24, x25, [sp, #192]
   83214:	a90d6ffa 	stp	x26, x27, [sp, #208]
   83218:	a90e77fc 	stp	x28, x29, [sp, #224]
   8321c:	d5384036 	mrs	x22, elr_el1
   83220:	d5384017 	mrs	x23, spsr_el1
   83224:	a90f5bfe 	stp	x30, x22, [sp, #240]
   83228:	f90083f7 	str	x23, [sp, #256]
   8322c:	d28000e0 	mov	x0, #0x7                   	// #7
   83230:	d5385201 	mrs	x1, esr_el1
   83234:	d5384022 	mrs	x2, elr_el1
   83238:	97fff57b 	bl	80824 <show_invalid_entry_message>
   8323c:	140000f6 	b	83614 <err_hang>

0000000000083240 <sync_invalid_el0_64>:

sync_invalid_el0_64:
	handle_invalid_entry  SYNC_INVALID_EL0_64
   83240:	d10443ff 	sub	sp, sp, #0x110
   83244:	a90007e0 	stp	x0, x1, [sp]
   83248:	a9010fe2 	stp	x2, x3, [sp, #16]
   8324c:	a90217e4 	stp	x4, x5, [sp, #32]
   83250:	a9031fe6 	stp	x6, x7, [sp, #48]
   83254:	a90427e8 	stp	x8, x9, [sp, #64]
   83258:	a9052fea 	stp	x10, x11, [sp, #80]
   8325c:	a90637ec 	stp	x12, x13, [sp, #96]
   83260:	a9073fee 	stp	x14, x15, [sp, #112]
   83264:	a90847f0 	stp	x16, x17, [sp, #128]
   83268:	a9094ff2 	stp	x18, x19, [sp, #144]
   8326c:	a90a57f4 	stp	x20, x21, [sp, #160]
   83270:	a90b5ff6 	stp	x22, x23, [sp, #176]
   83274:	a90c67f8 	stp	x24, x25, [sp, #192]
   83278:	a90d6ffa 	stp	x26, x27, [sp, #208]
   8327c:	a90e77fc 	stp	x28, x29, [sp, #224]
   83280:	d5384036 	mrs	x22, elr_el1
   83284:	d5384017 	mrs	x23, spsr_el1
   83288:	a90f5bfe 	stp	x30, x22, [sp, #240]
   8328c:	f90083f7 	str	x23, [sp, #256]
   83290:	d2800100 	mov	x0, #0x8                   	// #8
   83294:	d5385201 	mrs	x1, esr_el1
   83298:	d5384022 	mrs	x2, elr_el1
   8329c:	97fff562 	bl	80824 <show_invalid_entry_message>
   832a0:	140000dd 	b	83614 <err_hang>

00000000000832a4 <irq_invalid_el0_64>:

irq_invalid_el0_64:
	handle_invalid_entry  IRQ_INVALID_EL0_64
   832a4:	d10443ff 	sub	sp, sp, #0x110
   832a8:	a90007e0 	stp	x0, x1, [sp]
   832ac:	a9010fe2 	stp	x2, x3, [sp, #16]
   832b0:	a90217e4 	stp	x4, x5, [sp, #32]
   832b4:	a9031fe6 	stp	x6, x7, [sp, #48]
   832b8:	a90427e8 	stp	x8, x9, [sp, #64]
   832bc:	a9052fea 	stp	x10, x11, [sp, #80]
   832c0:	a90637ec 	stp	x12, x13, [sp, #96]
   832c4:	a9073fee 	stp	x14, x15, [sp, #112]
   832c8:	a90847f0 	stp	x16, x17, [sp, #128]
   832cc:	a9094ff2 	stp	x18, x19, [sp, #144]
   832d0:	a90a57f4 	stp	x20, x21, [sp, #160]
   832d4:	a90b5ff6 	stp	x22, x23, [sp, #176]
   832d8:	a90c67f8 	stp	x24, x25, [sp, #192]
   832dc:	a90d6ffa 	stp	x26, x27, [sp, #208]
   832e0:	a90e77fc 	stp	x28, x29, [sp, #224]
   832e4:	d5384036 	mrs	x22, elr_el1
   832e8:	d5384017 	mrs	x23, spsr_el1
   832ec:	a90f5bfe 	stp	x30, x22, [sp, #240]
   832f0:	f90083f7 	str	x23, [sp, #256]
   832f4:	d2800120 	mov	x0, #0x9                   	// #9
   832f8:	d5385201 	mrs	x1, esr_el1
   832fc:	d5384022 	mrs	x2, elr_el1
   83300:	97fff549 	bl	80824 <show_invalid_entry_message>
   83304:	140000c4 	b	83614 <err_hang>

0000000000083308 <fiq_invalid_el0_64>:

fiq_invalid_el0_64:
	handle_invalid_entry  FIQ_INVALID_EL0_64
   83308:	d10443ff 	sub	sp, sp, #0x110
   8330c:	a90007e0 	stp	x0, x1, [sp]
   83310:	a9010fe2 	stp	x2, x3, [sp, #16]
   83314:	a90217e4 	stp	x4, x5, [sp, #32]
   83318:	a9031fe6 	stp	x6, x7, [sp, #48]
   8331c:	a90427e8 	stp	x8, x9, [sp, #64]
   83320:	a9052fea 	stp	x10, x11, [sp, #80]
   83324:	a90637ec 	stp	x12, x13, [sp, #96]
   83328:	a9073fee 	stp	x14, x15, [sp, #112]
   8332c:	a90847f0 	stp	x16, x17, [sp, #128]
   83330:	a9094ff2 	stp	x18, x19, [sp, #144]
   83334:	a90a57f4 	stp	x20, x21, [sp, #160]
   83338:	a90b5ff6 	stp	x22, x23, [sp, #176]
   8333c:	a90c67f8 	stp	x24, x25, [sp, #192]
   83340:	a90d6ffa 	stp	x26, x27, [sp, #208]
   83344:	a90e77fc 	stp	x28, x29, [sp, #224]
   83348:	d5384036 	mrs	x22, elr_el1
   8334c:	d5384017 	mrs	x23, spsr_el1
   83350:	a90f5bfe 	stp	x30, x22, [sp, #240]
   83354:	f90083f7 	str	x23, [sp, #256]
   83358:	d2800140 	mov	x0, #0xa                   	// #10
   8335c:	d5385201 	mrs	x1, esr_el1
   83360:	d5384022 	mrs	x2, elr_el1
   83364:	97fff530 	bl	80824 <show_invalid_entry_message>
   83368:	140000ab 	b	83614 <err_hang>

000000000008336c <error_invalid_el0_64>:

error_invalid_el0_64:
	handle_invalid_entry  ERROR_INVALID_EL0_64
   8336c:	d10443ff 	sub	sp, sp, #0x110
   83370:	a90007e0 	stp	x0, x1, [sp]
   83374:	a9010fe2 	stp	x2, x3, [sp, #16]
   83378:	a90217e4 	stp	x4, x5, [sp, #32]
   8337c:	a9031fe6 	stp	x6, x7, [sp, #48]
   83380:	a90427e8 	stp	x8, x9, [sp, #64]
   83384:	a9052fea 	stp	x10, x11, [sp, #80]
   83388:	a90637ec 	stp	x12, x13, [sp, #96]
   8338c:	a9073fee 	stp	x14, x15, [sp, #112]
   83390:	a90847f0 	stp	x16, x17, [sp, #128]
   83394:	a9094ff2 	stp	x18, x19, [sp, #144]
   83398:	a90a57f4 	stp	x20, x21, [sp, #160]
   8339c:	a90b5ff6 	stp	x22, x23, [sp, #176]
   833a0:	a90c67f8 	stp	x24, x25, [sp, #192]
   833a4:	a90d6ffa 	stp	x26, x27, [sp, #208]
   833a8:	a90e77fc 	stp	x28, x29, [sp, #224]
   833ac:	d5384036 	mrs	x22, elr_el1
   833b0:	d5384017 	mrs	x23, spsr_el1
   833b4:	a90f5bfe 	stp	x30, x22, [sp, #240]
   833b8:	f90083f7 	str	x23, [sp, #256]
   833bc:	d2800160 	mov	x0, #0xb                   	// #11
   833c0:	d5385201 	mrs	x1, esr_el1
   833c4:	d5384022 	mrs	x2, elr_el1
   833c8:	97fff517 	bl	80824 <show_invalid_entry_message>
   833cc:	14000092 	b	83614 <err_hang>

00000000000833d0 <sync_invalid_el0_32>:

sync_invalid_el0_32:
	handle_invalid_entry  SYNC_INVALID_EL0_32
   833d0:	d10443ff 	sub	sp, sp, #0x110
   833d4:	a90007e0 	stp	x0, x1, [sp]
   833d8:	a9010fe2 	stp	x2, x3, [sp, #16]
   833dc:	a90217e4 	stp	x4, x5, [sp, #32]
   833e0:	a9031fe6 	stp	x6, x7, [sp, #48]
   833e4:	a90427e8 	stp	x8, x9, [sp, #64]
   833e8:	a9052fea 	stp	x10, x11, [sp, #80]
   833ec:	a90637ec 	stp	x12, x13, [sp, #96]
   833f0:	a9073fee 	stp	x14, x15, [sp, #112]
   833f4:	a90847f0 	stp	x16, x17, [sp, #128]
   833f8:	a9094ff2 	stp	x18, x19, [sp, #144]
   833fc:	a90a57f4 	stp	x20, x21, [sp, #160]
   83400:	a90b5ff6 	stp	x22, x23, [sp, #176]
   83404:	a90c67f8 	stp	x24, x25, [sp, #192]
   83408:	a90d6ffa 	stp	x26, x27, [sp, #208]
   8340c:	a90e77fc 	stp	x28, x29, [sp, #224]
   83410:	d5384036 	mrs	x22, elr_el1
   83414:	d5384017 	mrs	x23, spsr_el1
   83418:	a90f5bfe 	stp	x30, x22, [sp, #240]
   8341c:	f90083f7 	str	x23, [sp, #256]
   83420:	d2800180 	mov	x0, #0xc                   	// #12
   83424:	d5385201 	mrs	x1, esr_el1
   83428:	d5384022 	mrs	x2, elr_el1
   8342c:	97fff4fe 	bl	80824 <show_invalid_entry_message>
   83430:	14000079 	b	83614 <err_hang>

0000000000083434 <irq_invalid_el0_32>:

irq_invalid_el0_32:
	handle_invalid_entry  IRQ_INVALID_EL0_32
   83434:	d10443ff 	sub	sp, sp, #0x110
   83438:	a90007e0 	stp	x0, x1, [sp]
   8343c:	a9010fe2 	stp	x2, x3, [sp, #16]
   83440:	a90217e4 	stp	x4, x5, [sp, #32]
   83444:	a9031fe6 	stp	x6, x7, [sp, #48]
   83448:	a90427e8 	stp	x8, x9, [sp, #64]
   8344c:	a9052fea 	stp	x10, x11, [sp, #80]
   83450:	a90637ec 	stp	x12, x13, [sp, #96]
   83454:	a9073fee 	stp	x14, x15, [sp, #112]
   83458:	a90847f0 	stp	x16, x17, [sp, #128]
   8345c:	a9094ff2 	stp	x18, x19, [sp, #144]
   83460:	a90a57f4 	stp	x20, x21, [sp, #160]
   83464:	a90b5ff6 	stp	x22, x23, [sp, #176]
   83468:	a90c67f8 	stp	x24, x25, [sp, #192]
   8346c:	a90d6ffa 	stp	x26, x27, [sp, #208]
   83470:	a90e77fc 	stp	x28, x29, [sp, #224]
   83474:	d5384036 	mrs	x22, elr_el1
   83478:	d5384017 	mrs	x23, spsr_el1
   8347c:	a90f5bfe 	stp	x30, x22, [sp, #240]
   83480:	f90083f7 	str	x23, [sp, #256]
   83484:	d28001a0 	mov	x0, #0xd                   	// #13
   83488:	d5385201 	mrs	x1, esr_el1
   8348c:	d5384022 	mrs	x2, elr_el1
   83490:	97fff4e5 	bl	80824 <show_invalid_entry_message>
   83494:	14000060 	b	83614 <err_hang>

0000000000083498 <fiq_invalid_el0_32>:

fiq_invalid_el0_32:
	handle_invalid_entry  FIQ_INVALID_EL0_32
   83498:	d10443ff 	sub	sp, sp, #0x110
   8349c:	a90007e0 	stp	x0, x1, [sp]
   834a0:	a9010fe2 	stp	x2, x3, [sp, #16]
   834a4:	a90217e4 	stp	x4, x5, [sp, #32]
   834a8:	a9031fe6 	stp	x6, x7, [sp, #48]
   834ac:	a90427e8 	stp	x8, x9, [sp, #64]
   834b0:	a9052fea 	stp	x10, x11, [sp, #80]
   834b4:	a90637ec 	stp	x12, x13, [sp, #96]
   834b8:	a9073fee 	stp	x14, x15, [sp, #112]
   834bc:	a90847f0 	stp	x16, x17, [sp, #128]
   834c0:	a9094ff2 	stp	x18, x19, [sp, #144]
   834c4:	a90a57f4 	stp	x20, x21, [sp, #160]
   834c8:	a90b5ff6 	stp	x22, x23, [sp, #176]
   834cc:	a90c67f8 	stp	x24, x25, [sp, #192]
   834d0:	a90d6ffa 	stp	x26, x27, [sp, #208]
   834d4:	a90e77fc 	stp	x28, x29, [sp, #224]
   834d8:	d5384036 	mrs	x22, elr_el1
   834dc:	d5384017 	mrs	x23, spsr_el1
   834e0:	a90f5bfe 	stp	x30, x22, [sp, #240]
   834e4:	f90083f7 	str	x23, [sp, #256]
   834e8:	d28001c0 	mov	x0, #0xe                   	// #14
   834ec:	d5385201 	mrs	x1, esr_el1
   834f0:	d5384022 	mrs	x2, elr_el1
   834f4:	97fff4cc 	bl	80824 <show_invalid_entry_message>
   834f8:	14000047 	b	83614 <err_hang>

00000000000834fc <error_invalid_el0_32>:

error_invalid_el0_32:
	handle_invalid_entry  ERROR_INVALID_EL0_32
   834fc:	d10443ff 	sub	sp, sp, #0x110
   83500:	a90007e0 	stp	x0, x1, [sp]
   83504:	a9010fe2 	stp	x2, x3, [sp, #16]
   83508:	a90217e4 	stp	x4, x5, [sp, #32]
   8350c:	a9031fe6 	stp	x6, x7, [sp, #48]
   83510:	a90427e8 	stp	x8, x9, [sp, #64]
   83514:	a9052fea 	stp	x10, x11, [sp, #80]
   83518:	a90637ec 	stp	x12, x13, [sp, #96]
   8351c:	a9073fee 	stp	x14, x15, [sp, #112]
   83520:	a90847f0 	stp	x16, x17, [sp, #128]
   83524:	a9094ff2 	stp	x18, x19, [sp, #144]
   83528:	a90a57f4 	stp	x20, x21, [sp, #160]
   8352c:	a90b5ff6 	stp	x22, x23, [sp, #176]
   83530:	a90c67f8 	stp	x24, x25, [sp, #192]
   83534:	a90d6ffa 	stp	x26, x27, [sp, #208]
   83538:	a90e77fc 	stp	x28, x29, [sp, #224]
   8353c:	d5384036 	mrs	x22, elr_el1
   83540:	d5384017 	mrs	x23, spsr_el1
   83544:	a90f5bfe 	stp	x30, x22, [sp, #240]
   83548:	f90083f7 	str	x23, [sp, #256]
   8354c:	d28001e0 	mov	x0, #0xf                   	// #15
   83550:	d5385201 	mrs	x1, esr_el1
   83554:	d5384022 	mrs	x2, elr_el1
   83558:	97fff4b3 	bl	80824 <show_invalid_entry_message>
   8355c:	1400002e 	b	83614 <err_hang>

0000000000083560 <el1_irq>:

el1_irq:
	kernel_entry 
   83560:	d10443ff 	sub	sp, sp, #0x110
   83564:	a90007e0 	stp	x0, x1, [sp]
   83568:	a9010fe2 	stp	x2, x3, [sp, #16]
   8356c:	a90217e4 	stp	x4, x5, [sp, #32]
   83570:	a9031fe6 	stp	x6, x7, [sp, #48]
   83574:	a90427e8 	stp	x8, x9, [sp, #64]
   83578:	a9052fea 	stp	x10, x11, [sp, #80]
   8357c:	a90637ec 	stp	x12, x13, [sp, #96]
   83580:	a9073fee 	stp	x14, x15, [sp, #112]
   83584:	a90847f0 	stp	x16, x17, [sp, #128]
   83588:	a9094ff2 	stp	x18, x19, [sp, #144]
   8358c:	a90a57f4 	stp	x20, x21, [sp, #160]
   83590:	a90b5ff6 	stp	x22, x23, [sp, #176]
   83594:	a90c67f8 	stp	x24, x25, [sp, #192]
   83598:	a90d6ffa 	stp	x26, x27, [sp, #208]
   8359c:	a90e77fc 	stp	x28, x29, [sp, #224]
   835a0:	d5384036 	mrs	x22, elr_el1
   835a4:	d5384017 	mrs	x23, spsr_el1
   835a8:	a90f5bfe 	stp	x30, x22, [sp, #240]
   835ac:	f90083f7 	str	x23, [sp, #256]
	bl	handle_irq
   835b0:	97fff4af 	bl	8086c <handle_irq>
	kernel_exit 
   835b4:	f94083f7 	ldr	x23, [sp, #256]
   835b8:	a94f5bfe 	ldp	x30, x22, [sp, #240]
   835bc:	d5184036 	msr	elr_el1, x22
   835c0:	d5184017 	msr	spsr_el1, x23
   835c4:	a94007e0 	ldp	x0, x1, [sp]
   835c8:	a9410fe2 	ldp	x2, x3, [sp, #16]
   835cc:	a94217e4 	ldp	x4, x5, [sp, #32]
   835d0:	a9431fe6 	ldp	x6, x7, [sp, #48]
   835d4:	a94427e8 	ldp	x8, x9, [sp, #64]
   835d8:	a9452fea 	ldp	x10, x11, [sp, #80]
   835dc:	a94637ec 	ldp	x12, x13, [sp, #96]
   835e0:	a9473fee 	ldp	x14, x15, [sp, #112]
   835e4:	a94847f0 	ldp	x16, x17, [sp, #128]
   835e8:	a9494ff2 	ldp	x18, x19, [sp, #144]
   835ec:	a94a57f4 	ldp	x20, x21, [sp, #160]
   835f0:	a94b5ff6 	ldp	x22, x23, [sp, #176]
   835f4:	a94c67f8 	ldp	x24, x25, [sp, #192]
   835f8:	a94d6ffa 	ldp	x26, x27, [sp, #208]
   835fc:	a94e77fc 	ldp	x28, x29, [sp, #224]
   83600:	910443ff 	add	sp, sp, #0x110
   83604:	d69f03e0 	eret

0000000000083608 <ret_from_fork>:

.globl ret_from_fork
ret_from_fork:
	bl	schedule_tail
   83608:	97fff685 	bl	8101c <schedule_tail>
	mov	x0, x20
   8360c:	aa1403e0 	mov	x0, x20
	blr	x19 		//should never return
   83610:	d63f0260 	blr	x19

0000000000083614 <err_hang>:

.globl err_hang
err_hang: b err_hang
   83614:	14000000 	b	83614 <err_hang>

0000000000083618 <irq_vector_init>:
.globl irq_vector_init
irq_vector_init:
	adr	x0, vectors		// load VBAR_EL1 with virtual
   83618:	10ff8f40 	adr	x0, 82800 <vectors>
	msr	vbar_el1, x0		// vector table address
   8361c:	d518c000 	msr	vbar_el1, x0
	ret
   83620:	d65f03c0 	ret

0000000000083624 <enable_irq>:

.globl enable_irq
enable_irq:
	msr    daifclr, #2 
   83624:	d50342ff 	msr	daifclr, #0x2
	ret
   83628:	d65f03c0 	ret

000000000008362c <disable_irq>:

.globl disable_irq
disable_irq:
	msr	daifset, #2
   8362c:	d50342df 	msr	daifset, #0x2
	ret
   83630:	d65f03c0 	ret

0000000000083634 <memzero>:
.globl memzero
memzero:
	str xzr, [x0], #8
   83634:	f800841f 	str	xzr, [x0], #8
	subs x1, x1, #8
   83638:	f1002021 	subs	x1, x1, #0x8
	b.gt memzero
   8363c:	54ffffcc 	b.gt	83634 <memzero>
	ret
   83640:	d65f03c0 	ret

0000000000083644 <cpu_switch_to>:
#include "sched.h"

.globl cpu_switch_to
cpu_switch_to:
	mov	x10, #THREAD_CPU_CONTEXT
   83644:	d280000a 	mov	x10, #0x0                   	// #0
	add	x8, x0, x10
   83648:	8b0a0008 	add	x8, x0, x10
	mov	x9, sp
   8364c:	910003e9 	mov	x9, sp
	stp	x19, x20, [x8], #16		// store callee-saved registers
   83650:	a8815113 	stp	x19, x20, [x8], #16
	stp	x21, x22, [x8], #16
   83654:	a8815915 	stp	x21, x22, [x8], #16
	stp	x23, x24, [x8], #16
   83658:	a8816117 	stp	x23, x24, [x8], #16
	stp	x25, x26, [x8], #16
   8365c:	a8816919 	stp	x25, x26, [x8], #16
	stp	x27, x28, [x8], #16
   83660:	a881711b 	stp	x27, x28, [x8], #16
	stp	x29, x9, [x8], #16
   83664:	a881251d 	stp	x29, x9, [x8], #16
	str	x30, [x8]
   83668:	f900011e 	str	x30, [x8]
	add	x8, x1, x10
   8366c:	8b0a0028 	add	x8, x1, x10
	ldp	x19, x20, [x8], #16		// restore callee-saved registers
   83670:	a8c15113 	ldp	x19, x20, [x8], #16
	ldp	x21, x22, [x8], #16
   83674:	a8c15915 	ldp	x21, x22, [x8], #16
	ldp	x23, x24, [x8], #16
   83678:	a8c16117 	ldp	x23, x24, [x8], #16
	ldp	x25, x26, [x8], #16
   8367c:	a8c16919 	ldp	x25, x26, [x8], #16
	ldp	x27, x28, [x8], #16
   83680:	a8c1711b 	ldp	x27, x28, [x8], #16
	ldp	x29, x9, [x8], #16
   83684:	a8c1251d 	ldp	x29, x9, [x8], #16
	ldr	x30, [x8]
   83688:	f940011e 	ldr	x30, [x8]
	mov	sp, x9
   8368c:	9100013f 	mov	sp, x9
	ret
   83690:	d65f03c0 	ret

0000000000083694 <get_interrupt_pc>:

.globl get_interrupt_pc
get_interrupt_pc:
	mrs x0, elr_el1
   83694:	d5384020 	mrs	x0, elr_el1
	ret
   83698:	d65f03c0 	ret

000000000008369c <get_sp>:

.globl get_sp
get_sp:
	mov x0, sp
   8369c:	910003e0 	mov	x0, sp
	ret
   836a0:	d65f03c0 	ret

00000000000836a4 <get_el>:
.globl get_el
get_el:
	mrs x0, CurrentEL
   836a4:	d5384240 	mrs	x0, currentel
	lsr x0, x0, #2
   836a8:	d342fc00 	lsr	x0, x0, #2
	ret
   836ac:	d65f03c0 	ret

00000000000836b0 <put32>:

.globl put32
put32:
	str w1,[x0]
   836b0:	b9000001 	str	w1, [x0]
	ret
   836b4:	d65f03c0 	ret

00000000000836b8 <get32>:

.globl get32
get32:
	ldr w0,[x0]
   836b8:	b9400000 	ldr	w0, [x0]
	ret
   836bc:	d65f03c0 	ret

00000000000836c0 <delay>:

.globl delay
delay:
	subs x0, x0, #1
   836c0:	f1000400 	subs	x0, x0, #0x1
	bne delay
   836c4:	54ffffe1 	b.ne	836c0 <delay>  // b.any
	ret
   836c8:	d65f03c0 	ret
