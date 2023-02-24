
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
   8004c:	940007e4 	bl	81fdc <kernel_main>
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
    "ERROR_INVALID_EL0_32"	
};

void enable_interrupt_controller()
{
    // Enables Core 0 Timers interrupt control for the generic timer 
   80800:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   80804:	910003fd 	mov	x29, sp
    put32(TIMER_INT_CTRL_0, TIMER_INT_CTRL_0_VALUE);
}
   80808:	52800041 	mov	w1, #0x2                   	// #2
   8080c:	d2800800 	mov	x0, #0x40                  	// #64
   80810:	f2a80000 	movk	x0, #0x4000, lsl #16
   80814:	94000ba7 	bl	836b0 <put32>

   80818:	d503201f 	nop
   8081c:	a8c17bfd 	ldp	x29, x30, [sp], #16
   80820:	d65f03c0 	ret

0000000000080824 <show_invalid_entry_message>:
void show_invalid_entry_message(int type, unsigned long esr, unsigned long address)
{
    printf("%s, ESR: %x, address: %x\r\n", entry_error_messages[type], esr, address);
   80824:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   80828:	910003fd 	mov	x29, sp
   8082c:	b9002fe0 	str	w0, [sp, #44]
   80830:	f90013e1 	str	x1, [sp, #32]
   80834:	f9000fe2 	str	x2, [sp, #24]
}
   80838:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   8083c:	913d2000 	add	x0, x0, #0xf48
   80840:	b9802fe1 	ldrsw	x1, [sp, #44]
   80844:	f8617800 	ldr	x0, [x0, x1, lsl #3]
   80848:	f9400fe3 	ldr	x3, [sp, #24]
   8084c:	f94013e2 	ldr	x2, [sp, #32]
   80850:	aa0003e1 	mov	x1, x0
   80854:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80858:	91214000 	add	x0, x0, #0x850
   8085c:	9400055a 	bl	81dc4 <tfp_printf>

   80860:	d503201f 	nop
   80864:	a8c37bfd 	ldp	x29, x30, [sp], #48
   80868:	d65f03c0 	ret

000000000008086c <handle_irq>:
void handle_irq(void)
{
    // Each Core has its own pending local intrrupts register
   8086c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   80870:	910003fd 	mov	x29, sp
    unsigned int irq = get32(INT_SOURCE_0);
    switch (irq) {
   80874:	94000b8a 	bl	8369c <get_sp>
   80878:	1104c000 	add	w0, w0, #0x130
   8087c:	b9001fe0 	str	w0, [sp, #28]
        case (GENERIC_TIMER_INTERRUPT):
   80880:	940002dc 	bl	813f0 <get_time_ms>
   80884:	b9001be0 	str	w0, [sp, #24]
            handle_generic_timer_irq();
   80888:	94000b83 	bl	83694 <get_interrupt_pc>
   8088c:	b90017e0 	str	w0, [sp, #20]
            break;
        default:
            printf("Unknown pending irq: %x\r\n", irq);
   80890:	d2800c00 	mov	x0, #0x60                  	// #96
   80894:	f2a80000 	movk	x0, #0x4000, lsl #16
   80898:	94000b88 	bl	836b8 <get32>
   8089c:	b90013e0 	str	w0, [sp, #16]
    }
   808a0:	b94013e0 	ldr	w0, [sp, #16]
   808a4:	7100081f 	cmp	w0, #0x2
   808a8:	540000e1 	b.ne	808c4 <handle_irq+0x58>  // b.any
   808ac:	b9401be0 	ldr	w0, [sp, #24]
   808b0:	b94017e1 	ldr	w1, [sp, #20]
   808b4:	b9401fe2 	ldr	w2, [sp, #28]
   808b8:	94000211 	bl	810fc <init_trace>
   808bc:	940002c3 	bl	813c8 <handle_generic_timer_irq>
   808c0:	14000006 	b	808d8 <handle_irq+0x6c>
   808c4:	b94013e1 	ldr	w1, [sp, #16]
   808c8:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   808cc:	9121c000 	add	x0, x0, #0x870
   808d0:	9400053d 	bl	81dc4 <tfp_printf>
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
	current->preempt_count--;
}


void _schedule(void)
{
   80ba8:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80bac:	913f2000 	add	x0, x0, #0xfc8
   80bb0:	f9400000 	ldr	x0, [x0]
   80bb4:	f9404001 	ldr	x1, [x0, #128]
   80bb8:	91000421 	add	x1, x1, #0x1
   80bbc:	f9004001 	str	x1, [x0, #128]
	/* ensure no context happens in the following code region
   80bc0:	d503201f 	nop
   80bc4:	d65f03c0 	ret

0000000000080bc8 <preempt_enable>:
		we still leave irq on, because irq handler may set a task to be TASK_RUNNING, which 
		will be picked up by the scheduler below */
	preempt_disable(); 
	int next,c;
   80bc8:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80bcc:	913f2000 	add	x0, x0, #0xfc8
   80bd0:	f9400000 	ldr	x0, [x0]
   80bd4:	f9404001 	ldr	x1, [x0, #128]
   80bd8:	d1000421 	sub	x1, x1, #0x1
   80bdc:	f9004001 	str	x1, [x0, #128]
	struct task_struct * p;
   80be0:	d503201f 	nop
   80be4:	d65f03c0 	ret

0000000000080be8 <_schedule>:
	while (1) {
		c = -1; // the maximum counter of all tasks 
		next = 0;
   80be8:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   80bec:	910003fd 	mov	x29, sp

		/* Iterates over all tasks and tries to find a task in 
		TASK_RUNNING state with the maximum counter. If such 
		a task is found, we immediately break from the while loop 
   80bf0:	97ffffee 	bl	80ba8 <preempt_disable>
		and switch to this task. */

		for (int i = 0; i < NR_TASKS; i++){
			p = task[i];
			if (p && p->state == TASK_RUNNING && p->counter > c) {
   80bf4:	12800000 	mov	w0, #0xffffffff            	// #-1
   80bf8:	b9002be0 	str	w0, [sp, #40]
				c = p->counter;
   80bfc:	b9002fff 	str	wzr, [sp, #44]
			}
		}
		if (c) {
			break;
		}

   80c00:	b90027ff 	str	wzr, [sp, #36]
   80c04:	1400001a 	b	80c6c <_schedule+0x84>
		/* If no such task is found, this is either because i) no 
		task is in TASK_RUNNING state or ii) all such tasks have 0 counters.
   80c08:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80c0c:	913f4000 	add	x0, x0, #0xfd0
   80c10:	b98027e1 	ldrsw	x1, [sp, #36]
   80c14:	f8617800 	ldr	x0, [x0, x1, lsl #3]
   80c18:	f9000fe0 	str	x0, [sp, #24]
		in our current implemenation which misses TASK_WAIT, only condition ii) is possible. 
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
		Hence, we recharge counters. Bump counters for all tasks once. */
		
   80c4c:	f9400fe0 	ldr	x0, [sp, #24]
   80c50:	f9403800 	ldr	x0, [x0, #112]
   80c54:	b9002be0 	str	w0, [sp, #40]
		for (int i = 0; i < NR_TASKS; i++) {
   80c58:	b94027e0 	ldr	w0, [sp, #36]
   80c5c:	b9002fe0 	str	w0, [sp, #44]

   80c60:	b94027e0 	ldr	w0, [sp, #36]
   80c64:	11000400 	add	w0, w0, #0x1
   80c68:	b90027e0 	str	w0, [sp, #36]
   80c6c:	b94027e0 	ldr	w0, [sp, #36]
   80c70:	7100fc1f 	cmp	w0, #0x3f
   80c74:	54fffcad 	b.le	80c08 <_schedule+0x20>
			p = task[i];
			if (p) {
				p->counter = (p->counter >> 1) + p->priority;
   80c78:	b9402be0 	ldr	w0, [sp, #40]
   80c7c:	7100001f 	cmp	w0, #0x0
   80c80:	54000341 	b.ne	80ce8 <_schedule+0x100>  // b.any
	preempt_enable();
}

void schedule(void)
{
	current->counter = 0;
   80c84:	b90023ff 	str	wzr, [sp, #32]
   80c88:	14000014 	b	80cd8 <_schedule+0xf0>
	_schedule();
}
   80c8c:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80c90:	913f4000 	add	x0, x0, #0xfd0
   80c94:	b98023e1 	ldrsw	x1, [sp, #32]
   80c98:	f8617800 	ldr	x0, [x0, x1, lsl #3]
   80c9c:	f9000fe0 	str	x0, [sp, #24]

   80ca0:	f9400fe0 	ldr	x0, [sp, #24]
   80ca4:	f100001f 	cmp	x0, #0x0
   80ca8:	54000120 	b.eq	80ccc <_schedule+0xe4>  // b.none
void switch_to(struct task_struct * next) 
{
   80cac:	f9400fe0 	ldr	x0, [sp, #24]
   80cb0:	f9403800 	ldr	x0, [x0, #112]
   80cb4:	9341fc01 	asr	x1, x0, #1
   80cb8:	f9400fe0 	ldr	x0, [sp, #24]
   80cbc:	f9403c00 	ldr	x0, [x0, #120]
   80cc0:	8b000021 	add	x1, x1, x0
   80cc4:	f9400fe0 	ldr	x0, [sp, #24]
   80cc8:	f9003801 	str	x1, [x0, #112]
	current->counter = 0;
   80ccc:	b94023e0 	ldr	w0, [sp, #32]
   80cd0:	11000400 	add	w0, w0, #0x1
   80cd4:	b90023e0 	str	w0, [sp, #32]
   80cd8:	b94023e0 	ldr	w0, [sp, #32]
   80cdc:	7100fc1f 	cmp	w0, #0x3f
   80ce0:	54fffd6d 	b.le	80c8c <_schedule+0xa4>
			if (p && p->state == TASK_RUNNING && p->counter > c) {
   80ce4:	17ffffc4 	b	80bf4 <_schedule+0xc>
		}
   80ce8:	d503201f 	nop
	if (current == next) 
		return;
	struct task_struct * prev = current;
	current = next;
   80cec:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80cf0:	913f4000 	add	x0, x0, #0xfd0
   80cf4:	b9802fe1 	ldrsw	x1, [sp, #44]
   80cf8:	f8617800 	ldr	x0, [x0, x1, lsl #3]
   80cfc:	940000a9 	bl	80fa0 <switch_to>
	cpu_switch_to(prev, next);
   80d00:	97ffffb2 	bl	80bc8 <preempt_enable>
}
   80d04:	d503201f 	nop
   80d08:	a8c37bfd 	ldp	x29, x30, [sp], #48
   80d0c:	d65f03c0 	ret

0000000000080d10 <schedule>:

void schedule_tail(void) {
	preempt_enable();
   80d10:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   80d14:	910003fd 	mov	x29, sp
}
   80d18:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80d1c:	913f2000 	add	x0, x0, #0xfc8
   80d20:	f9400000 	ldr	x0, [x0]
   80d24:	f900381f 	str	xzr, [x0, #112]

   80d28:	97ffffb0 	bl	80be8 <_schedule>

   80d2c:	d503201f 	nop
   80d30:	a8c17bfd 	ldp	x29, x30, [sp], #16
   80d34:	d65f03c0 	ret

0000000000080d38 <initialize_trace_arrays>:
			return i;
		}
	}
	return -1;
}
   80d38:	d10103ff 	sub	sp, sp, #0x40
   80d3c:	a9007fff 	stp	xzr, xzr, [sp]
   80d40:	a9017fff 	stp	xzr, xzr, [sp, #16]
   80d44:	a9027fff 	stp	xzr, xzr, [sp, #32]
   80d48:	f9001bff 	str	xzr, [sp, #48]
   80d4c:	12800000 	mov	w0, #0xffffffff            	// #-1
   80d50:	b9000be0 	str	w0, [sp, #8]
   80d54:	12800000 	mov	w0, #0xffffffff            	// #-1
   80d58:	b90023e0 	str	w0, [sp, #32]
   80d5c:	b9003fff 	str	wzr, [sp, #60]
   80d60:	14000016 	b	80db8 <initialize_trace_arrays+0x80>
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
   80dac:	b9403fe0 	ldr	w0, [sp, #60]
   80db0:	11000400 	add	w0, w0, #0x1
   80db4:	b9003fe0 	str	w0, [sp, #60]
   80db8:	b9403fe0 	ldr	w0, [sp, #60]
   80dbc:	7100c41f 	cmp	w0, #0x31
   80dc0:	54fffd2d 	b.le	80d64 <initialize_trace_arrays+0x2c>
   80dc4:	b9003bff 	str	wzr, [sp, #56]
   80dc8:	14000016 	b	80e20 <initialize_trace_arrays+0xe8>
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
   80e14:	b9403be0 	ldr	w0, [sp, #56]
   80e18:	11000400 	add	w0, w0, #0x1
   80e1c:	b9003be0 	str	w0, [sp, #56]
   80e20:	b9403be0 	ldr	w0, [sp, #56]
   80e24:	7100fc1f 	cmp	w0, #0x3f
   80e28:	54fffd2d 	b.le	80dcc <initialize_trace_arrays+0x94>
   80e2c:	d503201f 	nop
   80e30:	d503201f 	nop
   80e34:	910103ff 	add	sp, sp, #0x40
   80e38:	d65f03c0 	ret

0000000000080e3c <update_new_trace>:
   80e3c:	a9b77bfd 	stp	x29, x30, [sp, #-144]!
   80e40:	910003fd 	mov	x29, sp
   80e44:	9400012b 	bl	812f0 <get_pid>
   80e48:	b9008fe0 	str	w0, [sp, #140]
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
   80ee4:	b9408fe0 	ldr	w0, [sp, #140]
   80ee8:	b90073e0 	str	w0, [sp, #112]
   80eec:	b94023e0 	ldr	w0, [sp, #32]
   80ef0:	3100041f 	cmn	w0, #0x1
   80ef4:	540000c0 	b.eq	80f0c <update_new_trace+0xd0>  // b.none
   80ef8:	f94017e0 	ldr	x0, [sp, #40]
   80efc:	f9003fe0 	str	x0, [sp, #120]
   80f00:	f9401be0 	ldr	x0, [sp, #48]
   80f04:	f90043e0 	str	x0, [sp, #128]
   80f08:	1400000d 	b	80f3c <update_new_trace+0x100>
   80f0c:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80f10:	913f4000 	add	x0, x0, #0xfd0
   80f14:	b9808fe1 	ldrsw	x1, [sp, #140]
   80f18:	f8617800 	ldr	x0, [x0, x1, lsl #3]
   80f1c:	f9403000 	ldr	x0, [x0, #96]
   80f20:	f9003fe0 	str	x0, [sp, #120]
   80f24:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80f28:	913f4000 	add	x0, x0, #0xfd0
   80f2c:	b9808fe1 	ldrsw	x1, [sp, #140]
   80f30:	f8617800 	ldr	x0, [x0, x1, lsl #3]
   80f34:	f9402c00 	ldr	x0, [x0, #88]
   80f38:	f90043e0 	str	x0, [sp, #128]
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
   80f94:	d503201f 	nop
   80f98:	a8c97bfd 	ldp	x29, x30, [sp], #144
   80f9c:	d65f03c0 	ret

0000000000080fa0 <switch_to>:
   80fa0:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   80fa4:	910003fd 	mov	x29, sp
   80fa8:	f9000fe0 	str	x0, [sp, #24]
   80fac:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80fb0:	913f2000 	add	x0, x0, #0xfc8
   80fb4:	f9400000 	ldr	x0, [x0]
   80fb8:	f9400fe1 	ldr	x1, [sp, #24]
   80fbc:	eb00003f 	cmp	x1, x0
   80fc0:	540000a1 	b.ne	80fd4 <switch_to+0x34>  // b.any
   80fc4:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80fc8:	91224000 	add	x0, x0, #0x890
   80fcc:	9400037e 	bl	81dc4 <tfp_printf>
   80fd0:	14000013 	b	8101c <switch_to+0x7c>
   80fd4:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80fd8:	913f2000 	add	x0, x0, #0xfc8
   80fdc:	f9400000 	ldr	x0, [x0]
   80fe0:	f90017e0 	str	x0, [sp, #40]
   80fe4:	f0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   80fe8:	913f2000 	add	x0, x0, #0xfc8
   80fec:	f9400fe1 	ldr	x1, [sp, #24]
   80ff0:	f9000001 	str	x1, [x0]
   80ff4:	f0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   80ff8:	910c2000 	add	x0, x0, #0x308
   80ffc:	b9400000 	ldr	w0, [x0]
   81000:	7100001f 	cmp	w0, #0x0
   81004:	5400006d 	b.le	81010 <switch_to+0x70>
   81008:	f9400fe0 	ldr	x0, [sp, #24]
   8100c:	97ffff8c 	bl	80e3c <update_new_trace>
   81010:	f9400fe1 	ldr	x1, [sp, #24]
   81014:	f94017e0 	ldr	x0, [sp, #40]
   81018:	9400098b 	bl	83644 <cpu_switch_to>
   8101c:	a8c37bfd 	ldp	x29, x30, [sp], #48
   81020:	d65f03c0 	ret

0000000000081024 <schedule_tail>:
   81024:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   81028:	910003fd 	mov	x29, sp
   8102c:	97fffee7 	bl	80bc8 <preempt_enable>
   81030:	d503201f 	nop
   81034:	a8c17bfd 	ldp	x29, x30, [sp], #16
   81038:	d65f03c0 	ret

000000000008103c <print_all_traces>:
   8103c:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
   81040:	910003fd 	mov	x29, sp
   81044:	b9004fff 	str	wzr, [sp, #76]
   81048:	14000026 	b	810e0 <print_all_traces+0xa4>
   8104c:	90000400 	adrp	x0, 101000 <mem_map+0x7cde8>
   81050:	91286002 	add	x2, x0, #0xa18
   81054:	b9804fe1 	ldrsw	x1, [sp, #76]
   81058:	aa0103e0 	mov	x0, x1
   8105c:	d37df000 	lsl	x0, x0, #3
   81060:	cb010000 	sub	x0, x0, x1
   81064:	d37df000 	lsl	x0, x0, #3
   81068:	8b000041 	add	x1, x2, x0
   8106c:	910043e0 	add	x0, sp, #0x10
   81070:	a9400c22 	ldp	x2, x3, [x1]
   81074:	a9000c02 	stp	x2, x3, [x0]
   81078:	a9410c22 	ldp	x2, x3, [x1, #16]
   8107c:	a9010c02 	stp	x2, x3, [x0, #16]
   81080:	a9420c22 	ldp	x2, x3, [x1, #32]
   81084:	a9020c02 	stp	x2, x3, [x0, #32]
   81088:	f9401821 	ldr	x1, [x1, #48]
   8108c:	f9001801 	str	x1, [x0, #48]
   81090:	f9400be0 	ldr	x0, [sp, #16]
   81094:	b9401be1 	ldr	w1, [sp, #24]
   81098:	f94013e2 	ldr	x2, [sp, #32]
   8109c:	f94017e3 	ldr	x3, [sp, #40]
   810a0:	b94033e4 	ldr	w4, [sp, #48]
   810a4:	f9401fe5 	ldr	x5, [sp, #56]
   810a8:	f94023e6 	ldr	x6, [sp, #64]
   810ac:	aa0603e7 	mov	x7, x6
   810b0:	aa0503e6 	mov	x6, x5
   810b4:	2a0403e5 	mov	w5, w4
   810b8:	aa0303e4 	mov	x4, x3
   810bc:	aa0203e3 	mov	x3, x2
   810c0:	2a0103e2 	mov	w2, w1
   810c4:	aa0003e1 	mov	x1, x0
   810c8:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   810cc:	9122a000 	add	x0, x0, #0x8a8
   810d0:	9400033d 	bl	81dc4 <tfp_printf>
   810d4:	b9404fe0 	ldr	w0, [sp, #76]
   810d8:	11000400 	add	w0, w0, #0x1
   810dc:	b9004fe0 	str	w0, [sp, #76]
   810e0:	b9404fe0 	ldr	w0, [sp, #76]
   810e4:	7100c41f 	cmp	w0, #0x31
   810e8:	54fffb2d 	b.le	8104c <print_all_traces+0x10>
   810ec:	d503201f 	nop
   810f0:	d503201f 	nop
   810f4:	a8c57bfd 	ldp	x29, x30, [sp], #80
   810f8:	d65f03c0 	ret

00000000000810fc <init_trace>:
   810fc:	a9b97bfd 	stp	x29, x30, [sp, #-112]!
   81100:	910003fd 	mov	x29, sp
   81104:	f90017e0 	str	x0, [sp, #40]
   81108:	f90013e1 	str	x1, [sp, #32]
   8110c:	f9000fe2 	str	x2, [sp, #24]
   81110:	94000078 	bl	812f0 <get_pid>
   81114:	b9006fe0 	str	w0, [sp, #108]
   81118:	b9406fe0 	ldr	w0, [sp, #108]
   8111c:	3100041f 	cmn	w0, #0x1
   81120:	54000a40 	b.eq	81268 <init_trace+0x16c>  // b.none
   81124:	f94017e0 	ldr	x0, [sp, #40]
   81128:	f9001be0 	str	x0, [sp, #48]
   8112c:	b9406fe0 	ldr	w0, [sp, #108]
   81130:	b9003be0 	str	w0, [sp, #56]
   81134:	f94013e0 	ldr	x0, [sp, #32]
   81138:	f90023e0 	str	x0, [sp, #64]
   8113c:	f9400fe0 	ldr	x0, [sp, #24]
   81140:	f90027e0 	str	x0, [sp, #72]
   81144:	12800000 	mov	w0, #0xffffffff            	// #-1
   81148:	b90053e0 	str	w0, [sp, #80]
   8114c:	f9002fff 	str	xzr, [sp, #88]
   81150:	f90033ff 	str	xzr, [sp, #96]
   81154:	b0000400 	adrp	x0, 102000 <traces+0x5e8>
   81158:	91142002 	add	x2, x0, #0x508
   8115c:	b9806fe1 	ldrsw	x1, [sp, #108]
   81160:	aa0103e0 	mov	x0, x1
   81164:	d37df000 	lsl	x0, x0, #3
   81168:	cb010000 	sub	x0, x0, x1
   8116c:	d37df000 	lsl	x0, x0, #3
   81170:	8b000040 	add	x0, x2, x0
   81174:	aa0003e1 	mov	x1, x0
   81178:	9100c3e0 	add	x0, sp, #0x30
   8117c:	a9400c02 	ldp	x2, x3, [x0]
   81180:	a9000c22 	stp	x2, x3, [x1]
   81184:	a9410c02 	ldp	x2, x3, [x0, #16]
   81188:	a9010c22 	stp	x2, x3, [x1, #16]
   8118c:	a9420c02 	ldp	x2, x3, [x0, #32]
   81190:	a9020c22 	stp	x2, x3, [x1, #32]
   81194:	f9401800 	ldr	x0, [x0, #48]
   81198:	f9001820 	str	x0, [x1, #48]
   8119c:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   811a0:	910c2000 	add	x0, x0, #0x308
   811a4:	b9400000 	ldr	w0, [x0]
   811a8:	7100c41f 	cmp	w0, #0x31
   811ac:	540003cc 	b.gt	81224 <init_trace+0x128>
   811b0:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   811b4:	910c2000 	add	x0, x0, #0x308
   811b8:	b9400001 	ldr	w1, [x0]
   811bc:	90000400 	adrp	x0, 101000 <mem_map+0x7cde8>
   811c0:	91286002 	add	x2, x0, #0xa18
   811c4:	93407c21 	sxtw	x1, w1
   811c8:	aa0103e0 	mov	x0, x1
   811cc:	d37df000 	lsl	x0, x0, #3
   811d0:	cb010000 	sub	x0, x0, x1
   811d4:	d37df000 	lsl	x0, x0, #3
   811d8:	8b000040 	add	x0, x2, x0
   811dc:	aa0003e1 	mov	x1, x0
   811e0:	9100c3e0 	add	x0, sp, #0x30
   811e4:	a9400c02 	ldp	x2, x3, [x0]
   811e8:	a9000c22 	stp	x2, x3, [x1]
   811ec:	a9410c02 	ldp	x2, x3, [x0, #16]
   811f0:	a9010c22 	stp	x2, x3, [x1, #16]
   811f4:	a9420c02 	ldp	x2, x3, [x0, #32]
   811f8:	a9020c22 	stp	x2, x3, [x1, #32]
   811fc:	f9401800 	ldr	x0, [x0, #48]
   81200:	f9001820 	str	x0, [x1, #48]
   81204:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81208:	910c2000 	add	x0, x0, #0x308
   8120c:	b9400000 	ldr	w0, [x0]
   81210:	11000401 	add	w1, w0, #0x1
   81214:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81218:	910c2000 	add	x0, x0, #0x308
   8121c:	b9000001 	str	w1, [x0]
   81220:	14000013 	b	8126c <init_trace+0x170>
   81224:	90000400 	adrp	x0, 101000 <mem_map+0x7cde8>
   81228:	91286000 	add	x0, x0, #0xa18
   8122c:	aa0003e1 	mov	x1, x0
   81230:	9100c3e0 	add	x0, sp, #0x30
   81234:	a9400c02 	ldp	x2, x3, [x0]
   81238:	a9000c22 	stp	x2, x3, [x1]
   8123c:	a9410c02 	ldp	x2, x3, [x0, #16]
   81240:	a9010c22 	stp	x2, x3, [x1, #16]
   81244:	a9420c02 	ldp	x2, x3, [x0, #32]
   81248:	a9020c22 	stp	x2, x3, [x1, #32]
   8124c:	f9401800 	ldr	x0, [x0, #48]
   81250:	f9001820 	str	x0, [x1, #48]
   81254:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81258:	910c2000 	add	x0, x0, #0x308
   8125c:	52800021 	mov	w1, #0x1                   	// #1
   81260:	b9000001 	str	w1, [x0]
   81264:	14000002 	b	8126c <init_trace+0x170>
   81268:	d503201f 	nop
   8126c:	a8c77bfd 	ldp	x29, x30, [sp], #112
   81270:	d65f03c0 	ret

0000000000081274 <timer_tick>:
   81274:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   81278:	910003fd 	mov	x29, sp
   8127c:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81280:	913f2000 	add	x0, x0, #0xfc8
   81284:	f9400000 	ldr	x0, [x0]
   81288:	f9403801 	ldr	x1, [x0, #112]
   8128c:	d1000421 	sub	x1, x1, #0x1
   81290:	f9003801 	str	x1, [x0, #112]
   81294:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81298:	913f2000 	add	x0, x0, #0xfc8
   8129c:	f9400000 	ldr	x0, [x0]
   812a0:	f9403800 	ldr	x0, [x0, #112]
   812a4:	f100001f 	cmp	x0, #0x0
   812a8:	540001ec 	b.gt	812e4 <timer_tick+0x70>
   812ac:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   812b0:	913f2000 	add	x0, x0, #0xfc8
   812b4:	f9400000 	ldr	x0, [x0]
   812b8:	f9404000 	ldr	x0, [x0, #128]
   812bc:	f100001f 	cmp	x0, #0x0
   812c0:	5400012c 	b.gt	812e4 <timer_tick+0x70>
   812c4:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   812c8:	913f2000 	add	x0, x0, #0xfc8
   812cc:	f9400000 	ldr	x0, [x0]
   812d0:	f900381f 	str	xzr, [x0, #112]
   812d4:	940008d4 	bl	83624 <enable_irq>
   812d8:	97fffe44 	bl	80be8 <_schedule>
   812dc:	940008d4 	bl	8362c <disable_irq>
   812e0:	14000002 	b	812e8 <timer_tick+0x74>
   812e4:	d503201f 	nop
   812e8:	a8c17bfd 	ldp	x29, x30, [sp], #16
   812ec:	d65f03c0 	ret

00000000000812f0 <get_pid>:
   812f0:	d10043ff 	sub	sp, sp, #0x10
   812f4:	b9000fff 	str	wzr, [sp, #12]
   812f8:	14000015 	b	8134c <get_pid+0x5c>
   812fc:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81300:	913f4000 	add	x0, x0, #0xfd0
   81304:	b9800fe1 	ldrsw	x1, [sp, #12]
   81308:	f8617800 	ldr	x0, [x0, x1, lsl #3]
   8130c:	f100001f 	cmp	x0, #0x0
   81310:	54000180 	b.eq	81340 <get_pid+0x50>  // b.none
   81314:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81318:	913f4000 	add	x0, x0, #0xfd0
   8131c:	b9800fe1 	ldrsw	x1, [sp, #12]
   81320:	f8617801 	ldr	x1, [x0, x1, lsl #3]
   81324:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81328:	913f2000 	add	x0, x0, #0xfc8
   8132c:	f9400000 	ldr	x0, [x0]
   81330:	eb00003f 	cmp	x1, x0
   81334:	54000061 	b.ne	81340 <get_pid+0x50>  // b.any
   81338:	b9400fe0 	ldr	w0, [sp, #12]
   8133c:	1400000b 	b	81368 <get_pid+0x78>
   81340:	b9400fe0 	ldr	w0, [sp, #12]
   81344:	11000400 	add	w0, w0, #0x1
   81348:	b9000fe0 	str	w0, [sp, #12]
   8134c:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81350:	913d0000 	add	x0, x0, #0xf40
   81354:	b9400000 	ldr	w0, [x0]
   81358:	b9400fe1 	ldr	w1, [sp, #12]
   8135c:	6b00003f 	cmp	w1, w0
   81360:	54fffceb 	b.lt	812fc <get_pid+0xc>  // b.tstop
   81364:	12800000 	mov	w0, #0xffffffff            	// #-1
   81368:	910043ff 	add	sp, sp, #0x10
   8136c:	d65f03c0 	ret

0000000000081370 <generic_timer_init>:
/* 	These are for Arm generic timer. 
	They are fully functional on both QEMU and Rpi3 
	Recommended.
*/
void generic_timer_init ( void )
{
   81370:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   81374:	910003fd 	mov	x29, sp
	printf("Frequency is set to: %d\n", get_timer_freq());
   81378:	9400036d 	bl	8212c <get_timer_freq>
   8137c:	2a0003e1 	mov	w1, w0
   81380:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81384:	9123a000 	add	x0, x0, #0x8e8
   81388:	9400028f 	bl	81dc4 <tfp_printf>
	printf("interval is set to: %u\r\n", interval);
   8138c:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81390:	913d1000 	add	x0, x0, #0xf44
   81394:	b9400000 	ldr	w0, [x0]
   81398:	2a0003e1 	mov	w1, w0
   8139c:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   813a0:	91242000 	add	x0, x0, #0x908
   813a4:	94000288 	bl	81dc4 <tfp_printf>
	gen_timer_init();
   813a8:	9400035c 	bl	82118 <gen_timer_init>
	gen_timer_reset(interval);
   813ac:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   813b0:	913d1000 	add	x0, x0, #0xf44
   813b4:	b9400000 	ldr	w0, [x0]
   813b8:	9400035b 	bl	82124 <gen_timer_reset>
}
   813bc:	d503201f 	nop
   813c0:	a8c17bfd 	ldp	x29, x30, [sp], #16
   813c4:	d65f03c0 	ret

00000000000813c8 <handle_generic_timer_irq>:

void handle_generic_timer_irq( void ) 
{
   813c8:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   813cc:	910003fd 	mov	x29, sp
	gen_timer_reset(interval);
   813d0:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   813d4:	913d1000 	add	x0, x0, #0xf44
   813d8:	b9400000 	ldr	w0, [x0]
   813dc:	94000352 	bl	82124 <gen_timer_reset>
    timer_tick();
   813e0:	97ffffa5 	bl	81274 <timer_tick>
}
   813e4:	d503201f 	nop
   813e8:	a8c17bfd 	ldp	x29, x30, [sp], #16
   813ec:	d65f03c0 	ret

00000000000813f0 <get_time_ms>:

/* 
	These are for "System Timer". They are NOT in use by this project. 
   813f0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   813f4:	910003fd 	mov	x29, sp
	I leave the code here FYI. 
   813f8:	9400034f 	bl	82134 <get_sys_count>
   813fc:	f9000fe0 	str	x0, [sp, #24]
	Rpi3: System Timer works fine. Can generate intrerrupts and be used as a counter for timekeeping.
   81400:	f9400fe1 	ldr	x1, [sp, #24]
   81404:	d2869b60 	mov	x0, #0x34db                	// #13531
   81408:	f2baf6c0 	movk	x0, #0xd7b6, lsl #16
   8140c:	f2dbd040 	movk	x0, #0xde82, lsl #32
   81410:	f2e86360 	movk	x0, #0x431b, lsl #48
   81414:	9bc07c20 	umulh	x0, x1, x0
   81418:	d34efc00 	lsr	x0, x0, #14
	QEMU: System Timer can be used for timekeeping. Cannot generate interrupts. 
   8141c:	a8c27bfd 	ldp	x29, x30, [sp], #32
   81420:	d65f03c0 	ret

0000000000081424 <timer_init>:
	curVal = get32(TIMER_CLO);
	curVal += interval;
	put32(TIMER_C1, curVal);
}

void handle_timer_irq( void ) 
   81424:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   81428:	910003fd 	mov	x29, sp
{
   8142c:	d2860080 	mov	x0, #0x3004                	// #12292
   81430:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   81434:	940008a1 	bl	836b8 <get32>
   81438:	2a0003e1 	mov	w1, w0
   8143c:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81440:	910c3000 	add	x0, x0, #0x30c
   81444:	b9000001 	str	w1, [x0]
	curVal += interval;
   81448:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   8144c:	910c3000 	add	x0, x0, #0x30c
   81450:	b9400001 	ldr	w1, [x0]
   81454:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81458:	913d1000 	add	x0, x0, #0xf44
   8145c:	b9400000 	ldr	w0, [x0]
   81460:	0b000021 	add	w1, w1, w0
   81464:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81468:	910c3000 	add	x0, x0, #0x30c
   8146c:	b9000001 	str	w1, [x0]
	put32(TIMER_C1, curVal);
   81470:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81474:	910c3000 	add	x0, x0, #0x30c
   81478:	b9400000 	ldr	w0, [x0]
   8147c:	2a0003e1 	mov	w1, w0
   81480:	d2860200 	mov	x0, #0x3010                	// #12304
   81484:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   81488:	9400088a 	bl	836b0 <put32>
	put32(TIMER_CS, TIMER_CS_M1);
   8148c:	d503201f 	nop
   81490:	a8c17bfd 	ldp	x29, x30, [sp], #16
   81494:	d65f03c0 	ret

0000000000081498 <handle_timer_irq>:
	timer_tick();
}

   81498:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
   8149c:	910003fd 	mov	x29, sp
unsigned long get_time_ms(void){
   814a0:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   814a4:	910c3000 	add	x0, x0, #0x30c
   814a8:	b9400001 	ldr	w1, [x0]
   814ac:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   814b0:	913d1000 	add	x0, x0, #0xf44
   814b4:	b9400000 	ldr	w0, [x0]
   814b8:	0b000021 	add	w1, w1, w0
   814bc:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   814c0:	910c3000 	add	x0, x0, #0x30c
   814c4:	b9000001 	str	w1, [x0]
	unsigned long sys_count = get_sys_count();
   814c8:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   814cc:	910c3000 	add	x0, x0, #0x30c
   814d0:	b9400000 	ldr	w0, [x0]
   814d4:	2a0003e1 	mov	w1, w0
   814d8:	d2860200 	mov	x0, #0x3010                	// #12304
   814dc:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   814e0:	94000874 	bl	836b0 <put32>
	return (unsigned long) sys_count / 62500;
   814e4:	52800041 	mov	w1, #0x2                   	// #2
   814e8:	d2860000 	mov	x0, #0x3000                	// #12288
   814ec:	f2a7e000 	movk	x0, #0x3f00, lsl #16
   814f0:	94000870 	bl	836b0 <put32>
   814f4:	97ffff60 	bl	81274 <timer_tick>
   814f8:	d503201f 	nop
   814fc:	a8c17bfd 	ldp	x29, x30, [sp], #16
   81500:	d65f03c0 	ret

0000000000081504 <copy_process>:
#include "mm.h"
#include "sched.h"
#include "entry.h"

int copy_process(unsigned long fn, unsigned long arg)
{
   81504:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   81508:	910003fd 	mov	x29, sp
   8150c:	f9000fe0 	str	x0, [sp, #24]
   81510:	f9000be1 	str	x1, [sp, #16]
	preempt_disable();
   81514:	97fffda5 	bl	80ba8 <preempt_disable>
	struct task_struct *p;

	p = (struct task_struct *) get_free_page();
   81518:	97fffcf3 	bl	808e4 <get_free_page>
   8151c:	f90017e0 	str	x0, [sp, #40]
	if (!p)
   81520:	f94017e0 	ldr	x0, [sp, #40]
   81524:	f100001f 	cmp	x0, #0x0
   81528:	54000061 	b.ne	81534 <copy_process+0x30>  // b.any
		return 1;
   8152c:	52800020 	mov	w0, #0x1                   	// #1
   81530:	1400002d 	b	815e4 <copy_process+0xe0>
	p->priority = current->priority;
   81534:	f0000000 	adrp	x0, 84000 <task+0x30>
   81538:	f940ec00 	ldr	x0, [x0, #472]
   8153c:	f9400000 	ldr	x0, [x0]
   81540:	f9403c01 	ldr	x1, [x0, #120]
   81544:	f94017e0 	ldr	x0, [sp, #40]
   81548:	f9003c01 	str	x1, [x0, #120]
	p->state = TASK_RUNNING;
   8154c:	f94017e0 	ldr	x0, [sp, #40]
   81550:	f900341f 	str	xzr, [x0, #104]
	p->counter = p->priority;
   81554:	f94017e0 	ldr	x0, [sp, #40]
   81558:	f9403c01 	ldr	x1, [x0, #120]
   8155c:	f94017e0 	ldr	x0, [sp, #40]
   81560:	f9003801 	str	x1, [x0, #112]
	p->preempt_count = 1; //disable preemtion until schedule_tail
   81564:	f94017e0 	ldr	x0, [sp, #40]
   81568:	d2800021 	mov	x1, #0x1                   	// #1
   8156c:	f9004001 	str	x1, [x0, #128]

	p->cpu_context.x19 = fn;
   81570:	f94017e0 	ldr	x0, [sp, #40]
   81574:	f9400fe1 	ldr	x1, [sp, #24]
   81578:	f9000001 	str	x1, [x0]
	p->cpu_context.x20 = arg;
   8157c:	f94017e0 	ldr	x0, [sp, #40]
   81580:	f9400be1 	ldr	x1, [sp, #16]
   81584:	f9000401 	str	x1, [x0, #8]
	p->cpu_context.pc = (unsigned long)ret_from_fork;
   81588:	f0000000 	adrp	x0, 84000 <task+0x30>
   8158c:	f940fc01 	ldr	x1, [x0, #504]
   81590:	f94017e0 	ldr	x0, [sp, #40]
   81594:	f9003001 	str	x1, [x0, #96]
	p->cpu_context.sp = (unsigned long)p + THREAD_SIZE;
   81598:	f94017e0 	ldr	x0, [sp, #40]
   8159c:	91400401 	add	x1, x0, #0x1, lsl #12
   815a0:	f94017e0 	ldr	x0, [sp, #40]
   815a4:	f9002c01 	str	x1, [x0, #88]
	int pid = nr_tasks++;
   815a8:	f0000000 	adrp	x0, 84000 <task+0x30>
   815ac:	f940f000 	ldr	x0, [x0, #480]
   815b0:	b9400000 	ldr	w0, [x0]
   815b4:	11000402 	add	w2, w0, #0x1
   815b8:	f0000001 	adrp	x1, 84000 <task+0x30>
   815bc:	f940f021 	ldr	x1, [x1, #480]
   815c0:	b9000022 	str	w2, [x1]
   815c4:	b90027e0 	str	w0, [sp, #36]
	task[pid] = p;	
   815c8:	f0000000 	adrp	x0, 84000 <task+0x30>
   815cc:	f940f400 	ldr	x0, [x0, #488]
   815d0:	b98027e1 	ldrsw	x1, [sp, #36]
   815d4:	f94017e2 	ldr	x2, [sp, #40]
   815d8:	f8217802 	str	x2, [x0, x1, lsl #3]
	preempt_enable();
   815dc:	97fffd7b 	bl	80bc8 <preempt_enable>
	return 0;
   815e0:	52800000 	mov	w0, #0x0                   	// #0
}
   815e4:	a8c37bfd 	ldp	x29, x30, [sp], #48
   815e8:	d65f03c0 	ret

00000000000815ec <ui2a>:
    }

#endif

static void ui2a(unsigned int num, unsigned int base, int uc,char * bf)
    {
   815ec:	d100c3ff 	sub	sp, sp, #0x30
   815f0:	b9001fe0 	str	w0, [sp, #28]
   815f4:	b9001be1 	str	w1, [sp, #24]
   815f8:	b90017e2 	str	w2, [sp, #20]
   815fc:	f90007e3 	str	x3, [sp, #8]
    int n=0;
   81600:	b9002fff 	str	wzr, [sp, #44]
    unsigned int d=1;
   81604:	52800020 	mov	w0, #0x1                   	// #1
   81608:	b9002be0 	str	w0, [sp, #40]
    while (num/d >= base)
   8160c:	14000005 	b	81620 <ui2a+0x34>
        d*=base;
   81610:	b9402be1 	ldr	w1, [sp, #40]
   81614:	b9401be0 	ldr	w0, [sp, #24]
   81618:	1b007c20 	mul	w0, w1, w0
   8161c:	b9002be0 	str	w0, [sp, #40]
    while (num/d >= base)
   81620:	b9401fe1 	ldr	w1, [sp, #28]
   81624:	b9402be0 	ldr	w0, [sp, #40]
   81628:	1ac00820 	udiv	w0, w1, w0
   8162c:	b9401be1 	ldr	w1, [sp, #24]
   81630:	6b00003f 	cmp	w1, w0
   81634:	54fffee9 	b.ls	81610 <ui2a+0x24>  // b.plast
    while (d!=0) {
   81638:	1400002f 	b	816f4 <ui2a+0x108>
        int dgt = num / d;
   8163c:	b9401fe1 	ldr	w1, [sp, #28]
   81640:	b9402be0 	ldr	w0, [sp, #40]
   81644:	1ac00820 	udiv	w0, w1, w0
   81648:	b90027e0 	str	w0, [sp, #36]
        num%= d;
   8164c:	b9401fe0 	ldr	w0, [sp, #28]
   81650:	b9402be1 	ldr	w1, [sp, #40]
   81654:	1ac10802 	udiv	w2, w0, w1
   81658:	b9402be1 	ldr	w1, [sp, #40]
   8165c:	1b017c41 	mul	w1, w2, w1
   81660:	4b010000 	sub	w0, w0, w1
   81664:	b9001fe0 	str	w0, [sp, #28]
        d/=base;
   81668:	b9402be1 	ldr	w1, [sp, #40]
   8166c:	b9401be0 	ldr	w0, [sp, #24]
   81670:	1ac00820 	udiv	w0, w1, w0
   81674:	b9002be0 	str	w0, [sp, #40]
        if (n || dgt>0 || d==0) {
   81678:	b9402fe0 	ldr	w0, [sp, #44]
   8167c:	7100001f 	cmp	w0, #0x0
   81680:	540000e1 	b.ne	8169c <ui2a+0xb0>  // b.any
   81684:	b94027e0 	ldr	w0, [sp, #36]
   81688:	7100001f 	cmp	w0, #0x0
   8168c:	5400008c 	b.gt	8169c <ui2a+0xb0>
   81690:	b9402be0 	ldr	w0, [sp, #40]
   81694:	7100001f 	cmp	w0, #0x0
   81698:	540002e1 	b.ne	816f4 <ui2a+0x108>  // b.any
            *bf++ = dgt+(dgt<10 ? '0' : (uc ? 'A' : 'a')-10);
   8169c:	b94027e0 	ldr	w0, [sp, #36]
   816a0:	7100241f 	cmp	w0, #0x9
   816a4:	5400010d 	b.le	816c4 <ui2a+0xd8>
   816a8:	b94017e0 	ldr	w0, [sp, #20]
   816ac:	7100001f 	cmp	w0, #0x0
   816b0:	54000060 	b.eq	816bc <ui2a+0xd0>  // b.none
   816b4:	528006e0 	mov	w0, #0x37                  	// #55
   816b8:	14000004 	b	816c8 <ui2a+0xdc>
   816bc:	52800ae0 	mov	w0, #0x57                  	// #87
   816c0:	14000002 	b	816c8 <ui2a+0xdc>
   816c4:	52800600 	mov	w0, #0x30                  	// #48
   816c8:	b94027e1 	ldr	w1, [sp, #36]
   816cc:	12001c22 	and	w2, w1, #0xff
   816d0:	f94007e1 	ldr	x1, [sp, #8]
   816d4:	91000423 	add	x3, x1, #0x1
   816d8:	f90007e3 	str	x3, [sp, #8]
   816dc:	0b020000 	add	w0, w0, w2
   816e0:	12001c00 	and	w0, w0, #0xff
   816e4:	39000020 	strb	w0, [x1]
            ++n;
   816e8:	b9402fe0 	ldr	w0, [sp, #44]
   816ec:	11000400 	add	w0, w0, #0x1
   816f0:	b9002fe0 	str	w0, [sp, #44]
    while (d!=0) {
   816f4:	b9402be0 	ldr	w0, [sp, #40]
   816f8:	7100001f 	cmp	w0, #0x0
   816fc:	54fffa01 	b.ne	8163c <ui2a+0x50>  // b.any
            }
        }
    *bf=0;
   81700:	f94007e0 	ldr	x0, [sp, #8]
   81704:	3900001f 	strb	wzr, [x0]
    }
   81708:	d503201f 	nop
   8170c:	9100c3ff 	add	sp, sp, #0x30
   81710:	d65f03c0 	ret

0000000000081714 <i2a>:

static void i2a (int num, char * bf)
    {
   81714:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   81718:	910003fd 	mov	x29, sp
   8171c:	b9001fe0 	str	w0, [sp, #28]
   81720:	f9000be1 	str	x1, [sp, #16]
    if (num<0) {
   81724:	b9401fe0 	ldr	w0, [sp, #28]
   81728:	7100001f 	cmp	w0, #0x0
   8172c:	5400012a 	b.ge	81750 <i2a+0x3c>  // b.tcont
        num=-num;
   81730:	b9401fe0 	ldr	w0, [sp, #28]
   81734:	4b0003e0 	neg	w0, w0
   81738:	b9001fe0 	str	w0, [sp, #28]
        *bf++ = '-';
   8173c:	f9400be0 	ldr	x0, [sp, #16]
   81740:	91000401 	add	x1, x0, #0x1
   81744:	f9000be1 	str	x1, [sp, #16]
   81748:	528005a1 	mov	w1, #0x2d                  	// #45
   8174c:	39000001 	strb	w1, [x0]
        }
    ui2a(num,10,0,bf);
   81750:	b9401fe0 	ldr	w0, [sp, #28]
   81754:	f9400be3 	ldr	x3, [sp, #16]
   81758:	52800002 	mov	w2, #0x0                   	// #0
   8175c:	52800141 	mov	w1, #0xa                   	// #10
   81760:	97ffffa3 	bl	815ec <ui2a>
    }
   81764:	d503201f 	nop
   81768:	a8c27bfd 	ldp	x29, x30, [sp], #32
   8176c:	d65f03c0 	ret

0000000000081770 <a2d>:

static int a2d(char ch)
    {
   81770:	d10043ff 	sub	sp, sp, #0x10
   81774:	39003fe0 	strb	w0, [sp, #15]
    if (ch>='0' && ch<='9')
   81778:	39403fe0 	ldrb	w0, [sp, #15]
   8177c:	7100bc1f 	cmp	w0, #0x2f
   81780:	540000e9 	b.ls	8179c <a2d+0x2c>  // b.plast
   81784:	39403fe0 	ldrb	w0, [sp, #15]
   81788:	7100e41f 	cmp	w0, #0x39
   8178c:	54000088 	b.hi	8179c <a2d+0x2c>  // b.pmore
        return ch-'0';
   81790:	39403fe0 	ldrb	w0, [sp, #15]
   81794:	5100c000 	sub	w0, w0, #0x30
   81798:	14000014 	b	817e8 <a2d+0x78>
    else if (ch>='a' && ch<='f')
   8179c:	39403fe0 	ldrb	w0, [sp, #15]
   817a0:	7101801f 	cmp	w0, #0x60
   817a4:	540000e9 	b.ls	817c0 <a2d+0x50>  // b.plast
   817a8:	39403fe0 	ldrb	w0, [sp, #15]
   817ac:	7101981f 	cmp	w0, #0x66
   817b0:	54000088 	b.hi	817c0 <a2d+0x50>  // b.pmore
        return ch-'a'+10;
   817b4:	39403fe0 	ldrb	w0, [sp, #15]
   817b8:	51015c00 	sub	w0, w0, #0x57
   817bc:	1400000b 	b	817e8 <a2d+0x78>
    else if (ch>='A' && ch<='F')
   817c0:	39403fe0 	ldrb	w0, [sp, #15]
   817c4:	7101001f 	cmp	w0, #0x40
   817c8:	540000e9 	b.ls	817e4 <a2d+0x74>  // b.plast
   817cc:	39403fe0 	ldrb	w0, [sp, #15]
   817d0:	7101181f 	cmp	w0, #0x46
   817d4:	54000088 	b.hi	817e4 <a2d+0x74>  // b.pmore
        return ch-'A'+10;
   817d8:	39403fe0 	ldrb	w0, [sp, #15]
   817dc:	5100dc00 	sub	w0, w0, #0x37
   817e0:	14000002 	b	817e8 <a2d+0x78>
    else return -1;
   817e4:	12800000 	mov	w0, #0xffffffff            	// #-1
    }
   817e8:	910043ff 	add	sp, sp, #0x10
   817ec:	d65f03c0 	ret

00000000000817f0 <a2i>:

static char a2i(char ch, char** src,int base,int* nump)
    {
   817f0:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   817f4:	910003fd 	mov	x29, sp
   817f8:	3900bfe0 	strb	w0, [sp, #47]
   817fc:	f90013e1 	str	x1, [sp, #32]
   81800:	b9002be2 	str	w2, [sp, #40]
   81804:	f9000fe3 	str	x3, [sp, #24]
    char* p= *src;
   81808:	f94013e0 	ldr	x0, [sp, #32]
   8180c:	f9400000 	ldr	x0, [x0]
   81810:	f9001fe0 	str	x0, [sp, #56]
    int num=0;
   81814:	b90037ff 	str	wzr, [sp, #52]
    int digit;
    while ((digit=a2d(ch))>=0) {
   81818:	14000010 	b	81858 <a2i+0x68>
        if (digit>base) break;
   8181c:	b94033e1 	ldr	w1, [sp, #48]
   81820:	b9402be0 	ldr	w0, [sp, #40]
   81824:	6b00003f 	cmp	w1, w0
   81828:	5400026c 	b.gt	81874 <a2i+0x84>
        num=num*base+digit;
   8182c:	b94037e1 	ldr	w1, [sp, #52]
   81830:	b9402be0 	ldr	w0, [sp, #40]
   81834:	1b007c20 	mul	w0, w1, w0
   81838:	b94033e1 	ldr	w1, [sp, #48]
   8183c:	0b000020 	add	w0, w1, w0
   81840:	b90037e0 	str	w0, [sp, #52]
        ch=*p++;
   81844:	f9401fe0 	ldr	x0, [sp, #56]
   81848:	91000401 	add	x1, x0, #0x1
   8184c:	f9001fe1 	str	x1, [sp, #56]
   81850:	39400000 	ldrb	w0, [x0]
   81854:	3900bfe0 	strb	w0, [sp, #47]
    while ((digit=a2d(ch))>=0) {
   81858:	3940bfe0 	ldrb	w0, [sp, #47]
   8185c:	97ffffc5 	bl	81770 <a2d>
   81860:	b90033e0 	str	w0, [sp, #48]
   81864:	b94033e0 	ldr	w0, [sp, #48]
   81868:	7100001f 	cmp	w0, #0x0
   8186c:	54fffd8a 	b.ge	8181c <a2i+0x2c>  // b.tcont
   81870:	14000002 	b	81878 <a2i+0x88>
        if (digit>base) break;
   81874:	d503201f 	nop
        }
    *src=p;
   81878:	f94013e0 	ldr	x0, [sp, #32]
   8187c:	f9401fe1 	ldr	x1, [sp, #56]
   81880:	f9000001 	str	x1, [x0]
    *nump=num;
   81884:	f9400fe0 	ldr	x0, [sp, #24]
   81888:	b94037e1 	ldr	w1, [sp, #52]
   8188c:	b9000001 	str	w1, [x0]
    return ch;
   81890:	3940bfe0 	ldrb	w0, [sp, #47]
    }
   81894:	a8c47bfd 	ldp	x29, x30, [sp], #64
   81898:	d65f03c0 	ret

000000000008189c <putchw>:

static void putchw(void* putp,putcf putf,int n, char z, char* bf)
    {
   8189c:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   818a0:	910003fd 	mov	x29, sp
   818a4:	f90017e0 	str	x0, [sp, #40]
   818a8:	f90013e1 	str	x1, [sp, #32]
   818ac:	b9001fe2 	str	w2, [sp, #28]
   818b0:	39006fe3 	strb	w3, [sp, #27]
   818b4:	f9000be4 	str	x4, [sp, #16]
    char fc=z? '0' : ' ';
   818b8:	39406fe0 	ldrb	w0, [sp, #27]
   818bc:	7100001f 	cmp	w0, #0x0
   818c0:	54000060 	b.eq	818cc <putchw+0x30>  // b.none
   818c4:	52800600 	mov	w0, #0x30                  	// #48
   818c8:	14000002 	b	818d0 <putchw+0x34>
   818cc:	52800400 	mov	w0, #0x20                  	// #32
   818d0:	3900dfe0 	strb	w0, [sp, #55]
    char ch;
    char* p=bf;
   818d4:	f9400be0 	ldr	x0, [sp, #16]
   818d8:	f9001fe0 	str	x0, [sp, #56]
    while (*p++ && n > 0)
   818dc:	14000004 	b	818ec <putchw+0x50>
        n--;
   818e0:	b9401fe0 	ldr	w0, [sp, #28]
   818e4:	51000400 	sub	w0, w0, #0x1
   818e8:	b9001fe0 	str	w0, [sp, #28]
    while (*p++ && n > 0)
   818ec:	f9401fe0 	ldr	x0, [sp, #56]
   818f0:	91000401 	add	x1, x0, #0x1
   818f4:	f9001fe1 	str	x1, [sp, #56]
   818f8:	39400000 	ldrb	w0, [x0]
   818fc:	7100001f 	cmp	w0, #0x0
   81900:	54000120 	b.eq	81924 <putchw+0x88>  // b.none
   81904:	b9401fe0 	ldr	w0, [sp, #28]
   81908:	7100001f 	cmp	w0, #0x0
   8190c:	54fffeac 	b.gt	818e0 <putchw+0x44>
    while (n-- > 0)
   81910:	14000005 	b	81924 <putchw+0x88>
        putf(putp,fc);
   81914:	f94013e2 	ldr	x2, [sp, #32]
   81918:	3940dfe1 	ldrb	w1, [sp, #55]
   8191c:	f94017e0 	ldr	x0, [sp, #40]
   81920:	d63f0040 	blr	x2
    while (n-- > 0)
   81924:	b9401fe0 	ldr	w0, [sp, #28]
   81928:	51000401 	sub	w1, w0, #0x1
   8192c:	b9001fe1 	str	w1, [sp, #28]
   81930:	7100001f 	cmp	w0, #0x0
   81934:	54ffff0c 	b.gt	81914 <putchw+0x78>
    while ((ch= *bf++))
   81938:	14000005 	b	8194c <putchw+0xb0>
        putf(putp,ch);
   8193c:	f94013e2 	ldr	x2, [sp, #32]
   81940:	3940dbe1 	ldrb	w1, [sp, #54]
   81944:	f94017e0 	ldr	x0, [sp, #40]
   81948:	d63f0040 	blr	x2
    while ((ch= *bf++))
   8194c:	f9400be0 	ldr	x0, [sp, #16]
   81950:	91000401 	add	x1, x0, #0x1
   81954:	f9000be1 	str	x1, [sp, #16]
   81958:	39400000 	ldrb	w0, [x0]
   8195c:	3900dbe0 	strb	w0, [sp, #54]
   81960:	3940dbe0 	ldrb	w0, [sp, #54]
   81964:	7100001f 	cmp	w0, #0x0
   81968:	54fffea1 	b.ne	8193c <putchw+0xa0>  // b.any
    }
   8196c:	d503201f 	nop
   81970:	d503201f 	nop
   81974:	a8c47bfd 	ldp	x29, x30, [sp], #64
   81978:	d65f03c0 	ret

000000000008197c <tfp_format>:

void tfp_format(void* putp,putcf putf,char *fmt, va_list va)
    {
   8197c:	a9ba7bfd 	stp	x29, x30, [sp, #-96]!
   81980:	910003fd 	mov	x29, sp
   81984:	f9000bf3 	str	x19, [sp, #16]
   81988:	f9001fe0 	str	x0, [sp, #56]
   8198c:	f9001be1 	str	x1, [sp, #48]
   81990:	f90017e2 	str	x2, [sp, #40]
   81994:	aa0303f3 	mov	x19, x3
    char bf[12];

    char ch;


    while ((ch=*(fmt++))) {
   81998:	140000ef 	b	81d54 <tfp_format+0x3d8>
        if (ch!='%')
   8199c:	39417fe0 	ldrb	w0, [sp, #95]
   819a0:	7100941f 	cmp	w0, #0x25
   819a4:	540000c0 	b.eq	819bc <tfp_format+0x40>  // b.none
            putf(putp,ch);
   819a8:	f9401be2 	ldr	x2, [sp, #48]
   819ac:	39417fe1 	ldrb	w1, [sp, #95]
   819b0:	f9401fe0 	ldr	x0, [sp, #56]
   819b4:	d63f0040 	blr	x2
   819b8:	140000e7 	b	81d54 <tfp_format+0x3d8>
        else {
            char lz=0;
   819bc:	39017bff 	strb	wzr, [sp, #94]
#ifdef  PRINTF_LONG_SUPPORT
            char lng=0;
#endif
            int w=0;
   819c0:	b9004fff 	str	wzr, [sp, #76]
            ch=*(fmt++);
   819c4:	f94017e0 	ldr	x0, [sp, #40]
   819c8:	91000401 	add	x1, x0, #0x1
   819cc:	f90017e1 	str	x1, [sp, #40]
   819d0:	39400000 	ldrb	w0, [x0]
   819d4:	39017fe0 	strb	w0, [sp, #95]
            if (ch=='0') {
   819d8:	39417fe0 	ldrb	w0, [sp, #95]
   819dc:	7100c01f 	cmp	w0, #0x30
   819e0:	54000101 	b.ne	81a00 <tfp_format+0x84>  // b.any
                ch=*(fmt++);
   819e4:	f94017e0 	ldr	x0, [sp, #40]
   819e8:	91000401 	add	x1, x0, #0x1
   819ec:	f90017e1 	str	x1, [sp, #40]
   819f0:	39400000 	ldrb	w0, [x0]
   819f4:	39017fe0 	strb	w0, [sp, #95]
                lz=1;
   819f8:	52800020 	mov	w0, #0x1                   	// #1
   819fc:	39017be0 	strb	w0, [sp, #94]
                }
            if (ch>='0' && ch<='9') {
   81a00:	39417fe0 	ldrb	w0, [sp, #95]
   81a04:	7100bc1f 	cmp	w0, #0x2f
   81a08:	54000189 	b.ls	81a38 <tfp_format+0xbc>  // b.plast
   81a0c:	39417fe0 	ldrb	w0, [sp, #95]
   81a10:	7100e41f 	cmp	w0, #0x39
   81a14:	54000128 	b.hi	81a38 <tfp_format+0xbc>  // b.pmore
                ch=a2i(ch,&fmt,10,&w);
   81a18:	910133e1 	add	x1, sp, #0x4c
   81a1c:	9100a3e0 	add	x0, sp, #0x28
   81a20:	aa0103e3 	mov	x3, x1
   81a24:	52800142 	mov	w2, #0xa                   	// #10
   81a28:	aa0003e1 	mov	x1, x0
   81a2c:	39417fe0 	ldrb	w0, [sp, #95]
   81a30:	97ffff70 	bl	817f0 <a2i>
   81a34:	39017fe0 	strb	w0, [sp, #95]
            if (ch=='l') {
                ch=*(fmt++);
                lng=1;
            }
#endif
            switch (ch) {
   81a38:	39417fe0 	ldrb	w0, [sp, #95]
   81a3c:	7101e01f 	cmp	w0, #0x78
   81a40:	54000be0 	b.eq	81bbc <tfp_format+0x240>  // b.none
   81a44:	7101e01f 	cmp	w0, #0x78
   81a48:	5400184c 	b.gt	81d50 <tfp_format+0x3d4>
   81a4c:	7101d41f 	cmp	w0, #0x75
   81a50:	54000300 	b.eq	81ab0 <tfp_format+0x134>  // b.none
   81a54:	7101d41f 	cmp	w0, #0x75
   81a58:	540017cc 	b.gt	81d50 <tfp_format+0x3d4>
   81a5c:	7101cc1f 	cmp	w0, #0x73
   81a60:	54001360 	b.eq	81ccc <tfp_format+0x350>  // b.none
   81a64:	7101cc1f 	cmp	w0, #0x73
   81a68:	5400174c 	b.gt	81d50 <tfp_format+0x3d4>
   81a6c:	7101901f 	cmp	w0, #0x64
   81a70:	54000660 	b.eq	81b3c <tfp_format+0x1c0>  // b.none
   81a74:	7101901f 	cmp	w0, #0x64
   81a78:	540016cc 	b.gt	81d50 <tfp_format+0x3d4>
   81a7c:	71018c1f 	cmp	w0, #0x63
   81a80:	54000f00 	b.eq	81c60 <tfp_format+0x2e4>  // b.none
   81a84:	71018c1f 	cmp	w0, #0x63
   81a88:	5400164c 	b.gt	81d50 <tfp_format+0x3d4>
   81a8c:	7101601f 	cmp	w0, #0x58
   81a90:	54000960 	b.eq	81bbc <tfp_format+0x240>  // b.none
   81a94:	7101601f 	cmp	w0, #0x58
   81a98:	540015cc 	b.gt	81d50 <tfp_format+0x3d4>
   81a9c:	7100001f 	cmp	w0, #0x0
   81aa0:	540016c0 	b.eq	81d78 <tfp_format+0x3fc>  // b.none
   81aa4:	7100941f 	cmp	w0, #0x25
   81aa8:	540014c0 	b.eq	81d40 <tfp_format+0x3c4>  // b.none
                    putchw(putp,putf,w,0,va_arg(va, char*));
                    break;
                case '%' :
                    putf(putp,ch);
                default:
                    break;
   81aac:	140000a9 	b	81d50 <tfp_format+0x3d4>
                    ui2a(va_arg(va, unsigned int),10,0,bf);
   81ab0:	b9401a61 	ldr	w1, [x19, #24]
   81ab4:	f9400260 	ldr	x0, [x19]
   81ab8:	7100003f 	cmp	w1, #0x0
   81abc:	540000ab 	b.lt	81ad0 <tfp_format+0x154>  // b.tstop
   81ac0:	91002c01 	add	x1, x0, #0xb
   81ac4:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81ac8:	f9000261 	str	x1, [x19]
   81acc:	1400000d 	b	81b00 <tfp_format+0x184>
   81ad0:	11002022 	add	w2, w1, #0x8
   81ad4:	b9001a62 	str	w2, [x19, #24]
   81ad8:	b9401a62 	ldr	w2, [x19, #24]
   81adc:	7100005f 	cmp	w2, #0x0
   81ae0:	540000ad 	b.le	81af4 <tfp_format+0x178>
   81ae4:	91002c01 	add	x1, x0, #0xb
   81ae8:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81aec:	f9000261 	str	x1, [x19]
   81af0:	14000004 	b	81b00 <tfp_format+0x184>
   81af4:	f9400662 	ldr	x2, [x19, #8]
   81af8:	93407c20 	sxtw	x0, w1
   81afc:	8b000040 	add	x0, x2, x0
   81b00:	b9400000 	ldr	w0, [x0]
   81b04:	910143e1 	add	x1, sp, #0x50
   81b08:	aa0103e3 	mov	x3, x1
   81b0c:	52800002 	mov	w2, #0x0                   	// #0
   81b10:	52800141 	mov	w1, #0xa                   	// #10
   81b14:	97fffeb6 	bl	815ec <ui2a>
                    putchw(putp,putf,w,lz,bf);
   81b18:	b9404fe0 	ldr	w0, [sp, #76]
   81b1c:	910143e1 	add	x1, sp, #0x50
   81b20:	aa0103e4 	mov	x4, x1
   81b24:	39417be3 	ldrb	w3, [sp, #94]
   81b28:	2a0003e2 	mov	w2, w0
   81b2c:	f9401be1 	ldr	x1, [sp, #48]
   81b30:	f9401fe0 	ldr	x0, [sp, #56]
   81b34:	97ffff5a 	bl	8189c <putchw>
                    break;
   81b38:	14000087 	b	81d54 <tfp_format+0x3d8>
                    i2a(va_arg(va, int),bf);
   81b3c:	b9401a61 	ldr	w1, [x19, #24]
   81b40:	f9400260 	ldr	x0, [x19]
   81b44:	7100003f 	cmp	w1, #0x0
   81b48:	540000ab 	b.lt	81b5c <tfp_format+0x1e0>  // b.tstop
   81b4c:	91002c01 	add	x1, x0, #0xb
   81b50:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81b54:	f9000261 	str	x1, [x19]
   81b58:	1400000d 	b	81b8c <tfp_format+0x210>
   81b5c:	11002022 	add	w2, w1, #0x8
   81b60:	b9001a62 	str	w2, [x19, #24]
   81b64:	b9401a62 	ldr	w2, [x19, #24]
   81b68:	7100005f 	cmp	w2, #0x0
   81b6c:	540000ad 	b.le	81b80 <tfp_format+0x204>
   81b70:	91002c01 	add	x1, x0, #0xb
   81b74:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81b78:	f9000261 	str	x1, [x19]
   81b7c:	14000004 	b	81b8c <tfp_format+0x210>
   81b80:	f9400662 	ldr	x2, [x19, #8]
   81b84:	93407c20 	sxtw	x0, w1
   81b88:	8b000040 	add	x0, x2, x0
   81b8c:	b9400000 	ldr	w0, [x0]
   81b90:	910143e1 	add	x1, sp, #0x50
   81b94:	97fffee0 	bl	81714 <i2a>
                    putchw(putp,putf,w,lz,bf);
   81b98:	b9404fe0 	ldr	w0, [sp, #76]
   81b9c:	910143e1 	add	x1, sp, #0x50
   81ba0:	aa0103e4 	mov	x4, x1
   81ba4:	39417be3 	ldrb	w3, [sp, #94]
   81ba8:	2a0003e2 	mov	w2, w0
   81bac:	f9401be1 	ldr	x1, [sp, #48]
   81bb0:	f9401fe0 	ldr	x0, [sp, #56]
   81bb4:	97ffff3a 	bl	8189c <putchw>
                    break;
   81bb8:	14000067 	b	81d54 <tfp_format+0x3d8>
                    ui2a(va_arg(va, unsigned int),16,(ch=='X'),bf);
   81bbc:	b9401a61 	ldr	w1, [x19, #24]
   81bc0:	f9400260 	ldr	x0, [x19]
   81bc4:	7100003f 	cmp	w1, #0x0
   81bc8:	540000ab 	b.lt	81bdc <tfp_format+0x260>  // b.tstop
   81bcc:	91002c01 	add	x1, x0, #0xb
   81bd0:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81bd4:	f9000261 	str	x1, [x19]
   81bd8:	1400000d 	b	81c0c <tfp_format+0x290>
   81bdc:	11002022 	add	w2, w1, #0x8
   81be0:	b9001a62 	str	w2, [x19, #24]
   81be4:	b9401a62 	ldr	w2, [x19, #24]
   81be8:	7100005f 	cmp	w2, #0x0
   81bec:	540000ad 	b.le	81c00 <tfp_format+0x284>
   81bf0:	91002c01 	add	x1, x0, #0xb
   81bf4:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81bf8:	f9000261 	str	x1, [x19]
   81bfc:	14000004 	b	81c0c <tfp_format+0x290>
   81c00:	f9400662 	ldr	x2, [x19, #8]
   81c04:	93407c20 	sxtw	x0, w1
   81c08:	8b000040 	add	x0, x2, x0
   81c0c:	b9400004 	ldr	w4, [x0]
   81c10:	39417fe0 	ldrb	w0, [sp, #95]
   81c14:	7101601f 	cmp	w0, #0x58
   81c18:	1a9f17e0 	cset	w0, eq  // eq = none
   81c1c:	12001c00 	and	w0, w0, #0xff
   81c20:	2a0003e1 	mov	w1, w0
   81c24:	910143e0 	add	x0, sp, #0x50
   81c28:	aa0003e3 	mov	x3, x0
   81c2c:	2a0103e2 	mov	w2, w1
   81c30:	52800201 	mov	w1, #0x10                  	// #16
   81c34:	2a0403e0 	mov	w0, w4
   81c38:	97fffe6d 	bl	815ec <ui2a>
                    putchw(putp,putf,w,lz,bf);
   81c3c:	b9404fe0 	ldr	w0, [sp, #76]
   81c40:	910143e1 	add	x1, sp, #0x50
   81c44:	aa0103e4 	mov	x4, x1
   81c48:	39417be3 	ldrb	w3, [sp, #94]
   81c4c:	2a0003e2 	mov	w2, w0
   81c50:	f9401be1 	ldr	x1, [sp, #48]
   81c54:	f9401fe0 	ldr	x0, [sp, #56]
   81c58:	97ffff11 	bl	8189c <putchw>
                    break;
   81c5c:	1400003e 	b	81d54 <tfp_format+0x3d8>
                    putf(putp,(char)(va_arg(va, int)));
   81c60:	b9401a61 	ldr	w1, [x19, #24]
   81c64:	f9400260 	ldr	x0, [x19]
   81c68:	7100003f 	cmp	w1, #0x0
   81c6c:	540000ab 	b.lt	81c80 <tfp_format+0x304>  // b.tstop
   81c70:	91002c01 	add	x1, x0, #0xb
   81c74:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81c78:	f9000261 	str	x1, [x19]
   81c7c:	1400000d 	b	81cb0 <tfp_format+0x334>
   81c80:	11002022 	add	w2, w1, #0x8
   81c84:	b9001a62 	str	w2, [x19, #24]
   81c88:	b9401a62 	ldr	w2, [x19, #24]
   81c8c:	7100005f 	cmp	w2, #0x0
   81c90:	540000ad 	b.le	81ca4 <tfp_format+0x328>
   81c94:	91002c01 	add	x1, x0, #0xb
   81c98:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81c9c:	f9000261 	str	x1, [x19]
   81ca0:	14000004 	b	81cb0 <tfp_format+0x334>
   81ca4:	f9400662 	ldr	x2, [x19, #8]
   81ca8:	93407c20 	sxtw	x0, w1
   81cac:	8b000040 	add	x0, x2, x0
   81cb0:	b9400000 	ldr	w0, [x0]
   81cb4:	12001c00 	and	w0, w0, #0xff
   81cb8:	f9401be2 	ldr	x2, [sp, #48]
   81cbc:	2a0003e1 	mov	w1, w0
   81cc0:	f9401fe0 	ldr	x0, [sp, #56]
   81cc4:	d63f0040 	blr	x2
                    break;
   81cc8:	14000023 	b	81d54 <tfp_format+0x3d8>
                    putchw(putp,putf,w,0,va_arg(va, char*));
   81ccc:	b9404fe5 	ldr	w5, [sp, #76]
   81cd0:	b9401a61 	ldr	w1, [x19, #24]
   81cd4:	f9400260 	ldr	x0, [x19]
   81cd8:	7100003f 	cmp	w1, #0x0
   81cdc:	540000ab 	b.lt	81cf0 <tfp_format+0x374>  // b.tstop
   81ce0:	91003c01 	add	x1, x0, #0xf
   81ce4:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81ce8:	f9000261 	str	x1, [x19]
   81cec:	1400000d 	b	81d20 <tfp_format+0x3a4>
   81cf0:	11002022 	add	w2, w1, #0x8
   81cf4:	b9001a62 	str	w2, [x19, #24]
   81cf8:	b9401a62 	ldr	w2, [x19, #24]
   81cfc:	7100005f 	cmp	w2, #0x0
   81d00:	540000ad 	b.le	81d14 <tfp_format+0x398>
   81d04:	91003c01 	add	x1, x0, #0xf
   81d08:	927df021 	and	x1, x1, #0xfffffffffffffff8
   81d0c:	f9000261 	str	x1, [x19]
   81d10:	14000004 	b	81d20 <tfp_format+0x3a4>
   81d14:	f9400662 	ldr	x2, [x19, #8]
   81d18:	93407c20 	sxtw	x0, w1
   81d1c:	8b000040 	add	x0, x2, x0
   81d20:	f9400000 	ldr	x0, [x0]
   81d24:	aa0003e4 	mov	x4, x0
   81d28:	52800003 	mov	w3, #0x0                   	// #0
   81d2c:	2a0503e2 	mov	w2, w5
   81d30:	f9401be1 	ldr	x1, [sp, #48]
   81d34:	f9401fe0 	ldr	x0, [sp, #56]
   81d38:	97fffed9 	bl	8189c <putchw>
                    break;
   81d3c:	14000006 	b	81d54 <tfp_format+0x3d8>
                    putf(putp,ch);
   81d40:	f9401be2 	ldr	x2, [sp, #48]
   81d44:	39417fe1 	ldrb	w1, [sp, #95]
   81d48:	f9401fe0 	ldr	x0, [sp, #56]
   81d4c:	d63f0040 	blr	x2
                    break;
   81d50:	d503201f 	nop
    while ((ch=*(fmt++))) {
   81d54:	f94017e0 	ldr	x0, [sp, #40]
   81d58:	91000401 	add	x1, x0, #0x1
   81d5c:	f90017e1 	str	x1, [sp, #40]
   81d60:	39400000 	ldrb	w0, [x0]
   81d64:	39017fe0 	strb	w0, [sp, #95]
   81d68:	39417fe0 	ldrb	w0, [sp, #95]
   81d6c:	7100001f 	cmp	w0, #0x0
   81d70:	54ffe161 	b.ne	8199c <tfp_format+0x20>  // b.any
                }
            }
        }
    abort:;
   81d74:	14000002 	b	81d7c <tfp_format+0x400>
                    goto abort;
   81d78:	d503201f 	nop
    }
   81d7c:	d503201f 	nop
   81d80:	f9400bf3 	ldr	x19, [sp, #16]
   81d84:	a8c67bfd 	ldp	x29, x30, [sp], #96
   81d88:	d65f03c0 	ret

0000000000081d8c <init_printf>:


void init_printf(void* putp,void (*putf) (void*,char))
    {
   81d8c:	d10043ff 	sub	sp, sp, #0x10
   81d90:	f90007e0 	str	x0, [sp, #8]
   81d94:	f90003e1 	str	x1, [sp]
    stdout_putf=putf;
   81d98:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81d9c:	910c4000 	add	x0, x0, #0x310
   81da0:	f94003e1 	ldr	x1, [sp]
   81da4:	f9000001 	str	x1, [x0]
    stdout_putp=putp;
   81da8:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81dac:	910c6000 	add	x0, x0, #0x318
   81db0:	f94007e1 	ldr	x1, [sp, #8]
   81db4:	f9000001 	str	x1, [x0]
    }
   81db8:	d503201f 	nop
   81dbc:	910043ff 	add	sp, sp, #0x10
   81dc0:	d65f03c0 	ret

0000000000081dc4 <tfp_printf>:

void tfp_printf(char *fmt, ...)
    {
   81dc4:	a9b67bfd 	stp	x29, x30, [sp, #-160]!
   81dc8:	910003fd 	mov	x29, sp
   81dcc:	f9001fe0 	str	x0, [sp, #56]
   81dd0:	f90037e1 	str	x1, [sp, #104]
   81dd4:	f9003be2 	str	x2, [sp, #112]
   81dd8:	f9003fe3 	str	x3, [sp, #120]
   81ddc:	f90043e4 	str	x4, [sp, #128]
   81de0:	f90047e5 	str	x5, [sp, #136]
   81de4:	f9004be6 	str	x6, [sp, #144]
   81de8:	f9004fe7 	str	x7, [sp, #152]
    va_list va;
    va_start(va,fmt);
   81dec:	910283e0 	add	x0, sp, #0xa0
   81df0:	f90023e0 	str	x0, [sp, #64]
   81df4:	910283e0 	add	x0, sp, #0xa0
   81df8:	f90027e0 	str	x0, [sp, #72]
   81dfc:	910183e0 	add	x0, sp, #0x60
   81e00:	f9002be0 	str	x0, [sp, #80]
   81e04:	128006e0 	mov	w0, #0xffffffc8            	// #-56
   81e08:	b9005be0 	str	w0, [sp, #88]
   81e0c:	b9005fff 	str	wzr, [sp, #92]
    tfp_format(stdout_putp,stdout_putf,fmt,va);
   81e10:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81e14:	910c6000 	add	x0, x0, #0x318
   81e18:	f9400004 	ldr	x4, [x0]
   81e1c:	d0000400 	adrp	x0, 103000 <most_recent+0xaf8>
   81e20:	910c4000 	add	x0, x0, #0x310
   81e24:	f9400005 	ldr	x5, [x0]
   81e28:	910043e2 	add	x2, sp, #0x10
   81e2c:	910103e3 	add	x3, sp, #0x40
   81e30:	a9400460 	ldp	x0, x1, [x3]
   81e34:	a9000440 	stp	x0, x1, [x2]
   81e38:	a9410460 	ldp	x0, x1, [x3, #16]
   81e3c:	a9010440 	stp	x0, x1, [x2, #16]
   81e40:	910043e0 	add	x0, sp, #0x10
   81e44:	aa0003e3 	mov	x3, x0
   81e48:	f9401fe2 	ldr	x2, [sp, #56]
   81e4c:	aa0503e1 	mov	x1, x5
   81e50:	aa0403e0 	mov	x0, x4
   81e54:	97fffeca 	bl	8197c <tfp_format>
    va_end(va);
    }
   81e58:	d503201f 	nop
   81e5c:	a8ca7bfd 	ldp	x29, x30, [sp], #160
   81e60:	d65f03c0 	ret

0000000000081e64 <putcp>:

static void putcp(void* p,char c)
    {
   81e64:	d10043ff 	sub	sp, sp, #0x10
   81e68:	f90007e0 	str	x0, [sp, #8]
   81e6c:	39001fe1 	strb	w1, [sp, #7]
    *(*((char**)p))++ = c;
   81e70:	f94007e0 	ldr	x0, [sp, #8]
   81e74:	f9400000 	ldr	x0, [x0]
   81e78:	91000402 	add	x2, x0, #0x1
   81e7c:	f94007e1 	ldr	x1, [sp, #8]
   81e80:	f9000022 	str	x2, [x1]
   81e84:	39401fe1 	ldrb	w1, [sp, #7]
   81e88:	39000001 	strb	w1, [x0]
    }
   81e8c:	d503201f 	nop
   81e90:	910043ff 	add	sp, sp, #0x10
   81e94:	d65f03c0 	ret

0000000000081e98 <tfp_sprintf>:



void tfp_sprintf(char* s,char *fmt, ...)
    {
   81e98:	a9b77bfd 	stp	x29, x30, [sp, #-144]!
   81e9c:	910003fd 	mov	x29, sp
   81ea0:	f9001fe0 	str	x0, [sp, #56]
   81ea4:	f9001be1 	str	x1, [sp, #48]
   81ea8:	f90033e2 	str	x2, [sp, #96]
   81eac:	f90037e3 	str	x3, [sp, #104]
   81eb0:	f9003be4 	str	x4, [sp, #112]
   81eb4:	f9003fe5 	str	x5, [sp, #120]
   81eb8:	f90043e6 	str	x6, [sp, #128]
   81ebc:	f90047e7 	str	x7, [sp, #136]
    va_list va;
    va_start(va,fmt);
   81ec0:	910243e0 	add	x0, sp, #0x90
   81ec4:	f90023e0 	str	x0, [sp, #64]
   81ec8:	910243e0 	add	x0, sp, #0x90
   81ecc:	f90027e0 	str	x0, [sp, #72]
   81ed0:	910183e0 	add	x0, sp, #0x60
   81ed4:	f9002be0 	str	x0, [sp, #80]
   81ed8:	128005e0 	mov	w0, #0xffffffd0            	// #-48
   81edc:	b9005be0 	str	w0, [sp, #88]
   81ee0:	b9005fff 	str	wzr, [sp, #92]
    tfp_format(&s,putcp,fmt,va);
   81ee4:	910043e2 	add	x2, sp, #0x10
   81ee8:	910103e3 	add	x3, sp, #0x40
   81eec:	a9400460 	ldp	x0, x1, [x3]
   81ef0:	a9000440 	stp	x0, x1, [x2]
   81ef4:	a9410460 	ldp	x0, x1, [x3, #16]
   81ef8:	a9010440 	stp	x0, x1, [x2, #16]
   81efc:	910043e0 	add	x0, sp, #0x10
   81f00:	9100e3e4 	add	x4, sp, #0x38
   81f04:	aa0003e3 	mov	x3, x0
   81f08:	f9401be2 	ldr	x2, [sp, #48]
   81f0c:	90000000 	adrp	x0, 81000 <switch_to+0x60>
   81f10:	91399001 	add	x1, x0, #0xe64
   81f14:	aa0403e0 	mov	x0, x4
   81f18:	97fffe99 	bl	8197c <tfp_format>
    putcp(&s,0);
   81f1c:	9100e3e0 	add	x0, sp, #0x38
   81f20:	52800001 	mov	w1, #0x0                   	// #0
   81f24:	97ffffd0 	bl	81e64 <putcp>
    va_end(va);
    }
   81f28:	d503201f 	nop
   81f2c:	a8c97bfd 	ldp	x29, x30, [sp], #144
   81f30:	d65f03c0 	ret

0000000000081f34 <process>:
#include "fork.h"
#include "sched.h"
#include "mini_uart.h"

void process(char *array)
{
   81f34:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   81f38:	910003fd 	mov	x29, sp
   81f3c:	f9000fe0 	str	x0, [sp, #24]
	while (1) {
		for (int i = 0; i < 5; i++){
   81f40:	b9002fff 	str	wzr, [sp, #44]
   81f44:	1400000c 	b	81f74 <process+0x40>
			uart_send(array[i]);
   81f48:	b9802fe0 	ldrsw	x0, [sp, #44]
   81f4c:	f9400fe1 	ldr	x1, [sp, #24]
   81f50:	8b000020 	add	x0, x1, x0
   81f54:	39400000 	ldrb	w0, [x0]
   81f58:	97fffa8c 	bl	80988 <uart_send>
			delay(5000000);
   81f5c:	d2896800 	mov	x0, #0x4b40                	// #19264
   81f60:	f2a00980 	movk	x0, #0x4c, lsl #16
   81f64:	940005d7 	bl	836c0 <delay>
		for (int i = 0; i < 5; i++){
   81f68:	b9402fe0 	ldr	w0, [sp, #44]
   81f6c:	11000400 	add	w0, w0, #0x1
   81f70:	b9002fe0 	str	w0, [sp, #44]
   81f74:	b9402fe0 	ldr	w0, [sp, #44]
   81f78:	7100101f 	cmp	w0, #0x4
   81f7c:	54fffe6d 	b.le	81f48 <process+0x14>
		}
	}
   81f80:	d503201f 	nop
}

   81f84:	a8c37bfd 	ldp	x29, x30, [sp], #48
   81f88:	d65f03c0 	ret

0000000000081f8c <process2>:
void process2(char *array)
{
	while (1) {
   81f8c:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   81f90:	910003fd 	mov	x29, sp
   81f94:	f9000fe0 	str	x0, [sp, #24]
		for (int i = 0; i < 5; i++){
			uart_send(array[i]);
   81f98:	b9002fff 	str	wzr, [sp, #44]
   81f9c:	1400000c 	b	81fcc <process2+0x40>
			delay(5000000);
   81fa0:	b9802fe0 	ldrsw	x0, [sp, #44]
   81fa4:	f9400fe1 	ldr	x1, [sp, #24]
   81fa8:	8b000020 	add	x0, x1, x0
   81fac:	39400000 	ldrb	w0, [x0]
   81fb0:	97fffa76 	bl	80988 <uart_send>
		}
   81fb4:	d2896800 	mov	x0, #0x4b40                	// #19264
   81fb8:	f2a00980 	movk	x0, #0x4c, lsl #16
   81fbc:	940005c1 	bl	836c0 <delay>
			uart_send(array[i]);
   81fc0:	b9402fe0 	ldr	w0, [sp, #44]
   81fc4:	11000400 	add	w0, w0, #0x1
   81fc8:	b9002fe0 	str	w0, [sp, #44]
   81fcc:	b9402fe0 	ldr	w0, [sp, #44]
   81fd0:	7100101f 	cmp	w0, #0x4
   81fd4:	54fffe6d 	b.le	81fa0 <process2+0x14>
   81fd8:	17fffff0 	b	81f98 <process2+0xc>

0000000000081fdc <kernel_main>:
}


void kernel_main(void)
{
	uart_init();
   81fdc:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   81fe0:	910003fd 	mov	x29, sp
	init_printf(0, putc);
   81fe4:	97fffaa3 	bl	80a70 <uart_init>

   81fe8:	f0000000 	adrp	x0, 84000 <task+0x30>
   81fec:	f940f801 	ldr	x1, [x0, #496]
   81ff0:	d2800000 	mov	x0, #0x0                   	// #0
   81ff4:	97ffff66 	bl	81d8c <init_printf>
	printf("kernel boots\n");

   81ff8:	d0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   81ffc:	9124a000 	add	x0, x0, #0x928
   82000:	97ffff71 	bl	81dc4 <tfp_printf>
	irq_vector_init();
	generic_timer_init();
   82004:	94000585 	bl	83618 <irq_vector_init>
	enable_interrupt_controller();
   82008:	97fffcda 	bl	81370 <generic_timer_init>
	enable_irq();
   8200c:	97fff9fd 	bl	80800 <enable_interrupt_controller>

   82010:	94000585 	bl	83624 <enable_irq>
	int res = copy_process((unsigned long)&process, (unsigned long)"12345");
	if (res != 0) {
   82014:	97fffb49 	bl	80d38 <initialize_trace_arrays>
		printf("error while starting process 1");
		return;
   82018:	f0ffffe0 	adrp	x0, 81000 <switch_to+0x60>
   8201c:	913cd002 	add	x2, x0, #0xf34
   82020:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   82024:	9124e000 	add	x0, x0, #0x938
   82028:	aa0003e1 	mov	x1, x0
   8202c:	aa0203e0 	mov	x0, x2
   82030:	97fffd35 	bl	81504 <copy_process>
   82034:	b9001fe0 	str	w0, [sp, #28]
	}
   82038:	b9401fe0 	ldr	w0, [sp, #28]
   8203c:	7100001f 	cmp	w0, #0x0
   82040:	540000a0 	b.eq	82054 <kernel_main+0x78>  // b.none
	res = copy_process((unsigned long)&process2, (unsigned long)"abcde");
   82044:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   82048:	91250000 	add	x0, x0, #0x940
   8204c:	97ffff5e 	bl	81dc4 <tfp_printf>
	if (res != 0) {
   82050:	14000030 	b	82110 <kernel_main+0x134>
		printf("error while starting process 2");
		return;
   82054:	f0ffffe0 	adrp	x0, 81000 <switch_to+0x60>
   82058:	913e3002 	add	x2, x0, #0xf8c
   8205c:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   82060:	91258000 	add	x0, x0, #0x960
   82064:	aa0003e1 	mov	x1, x0
   82068:	aa0203e0 	mov	x0, x2
   8206c:	97fffd26 	bl	81504 <copy_process>
   82070:	b9001fe0 	str	w0, [sp, #28]
	}
   82074:	b9401fe0 	ldr	w0, [sp, #28]
   82078:	7100001f 	cmp	w0, #0x0
   8207c:	540000a0 	b.eq	82090 <kernel_main+0xb4>  // b.none
	res = copy_process((unsigned long) &process, (unsigned long) "Hello");
   82080:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   82084:	9125a000 	add	x0, x0, #0x968
   82088:	97ffff4f 	bl	81dc4 <tfp_printf>
	if (res != 0){
   8208c:	14000021 	b	82110 <kernel_main+0x134>
		printf("Error while starting process 3");
		return;
   82090:	f0ffffe0 	adrp	x0, 81000 <switch_to+0x60>
   82094:	913cd002 	add	x2, x0, #0xf34
   82098:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   8209c:	91262000 	add	x0, x0, #0x988
   820a0:	aa0003e1 	mov	x1, x0
   820a4:	aa0203e0 	mov	x0, x2
   820a8:	97fffd17 	bl	81504 <copy_process>
   820ac:	b9001fe0 	str	w0, [sp, #28]
	}
   820b0:	b9401fe0 	ldr	w0, [sp, #28]
   820b4:	7100001f 	cmp	w0, #0x0
   820b8:	540000a0 	b.eq	820cc <kernel_main+0xf0>  // b.none
	res = copy_process((unsigned long) &process, (unsigned long) "there");
   820bc:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   820c0:	91264000 	add	x0, x0, #0x990
   820c4:	97ffff40 	bl	81dc4 <tfp_printf>
	if(res != 0){
   820c8:	14000012 	b	82110 <kernel_main+0x134>
		printf("Error while starting process 4");
		return;
   820cc:	f0ffffe0 	adrp	x0, 81000 <switch_to+0x60>
   820d0:	913cd002 	add	x2, x0, #0xf34
   820d4:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   820d8:	9126c000 	add	x0, x0, #0x9b0
   820dc:	aa0003e1 	mov	x1, x0
   820e0:	aa0203e0 	mov	x0, x2
   820e4:	97fffd08 	bl	81504 <copy_process>
   820e8:	b9001fe0 	str	w0, [sp, #28]
	}
   820ec:	b9401fe0 	ldr	w0, [sp, #28]
   820f0:	7100001f 	cmp	w0, #0x0
   820f4:	540000a0 	b.eq	82108 <kernel_main+0x12c>  // b.none

   820f8:	b0000000 	adrp	x0, 83000 <irq_invalid_el1t+0x18>
   820fc:	9126e000 	add	x0, x0, #0x9b8
   82100:	97ffff31 	bl	81dc4 <tfp_printf>
	while (1){
   82104:	14000003 	b	82110 <kernel_main+0x134>
		schedule();
	}	
}
   82108:	97fffb02 	bl	80d10 <schedule>
   8210c:	17ffffff 	b	82108 <kernel_main+0x12c>
   82110:	a8c27bfd 	ldp	x29, x30, [sp], #32
   82114:	d65f03c0 	ret

0000000000082118 <gen_timer_init>:
 *  https://developer.arm.com/docs/ddi0487/ca/arm-architecture-reference-manual-armv8-for-armv8-a-architecture-profile
 */

.globl gen_timer_init
gen_timer_init:
	mov x0, #1
   82118:	d2800020 	mov	x0, #0x1                   	// #1
	msr CNTP_CTL_EL0, x0
   8211c:	d51be220 	msr	cntp_ctl_el0, x0
	ret
   82120:	d65f03c0 	ret

0000000000082124 <gen_timer_reset>:

.globl gen_timer_reset
gen_timer_reset:
#    mov x0, #1
#	lsl x0, x0, #24 
	msr CNTP_TVAL_EL0, x0
   82124:	d51be200 	msr	cntp_tval_el0, x0
    ret
   82128:	d65f03c0 	ret

000000000008212c <get_timer_freq>:

.globl get_timer_freq
get_timer_freq:
	mrs x0, CNTFRQ_EL0
   8212c:	d53be000 	mrs	x0, cntfrq_el0
	ret
   82130:	d65f03c0 	ret

0000000000082134 <get_sys_count>:

.globl get_sys_count
get_sys_count:
	mrs x0, CNTPCT_EL0
   82134:	d53be020 	mrs	x0, cntpct_el0
   82138:	d65f03c0 	ret
	...

0000000000082800 <vectors>:
 */
.align	11
.globl vectors 
vectors:
	ventry	sync_invalid_el1t			// Synchronous EL1t
	ventry	irq_invalid_el1t			// IRQ EL1t
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
	ventry	fiq_invalid_el1t			// FIQ EL1t
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
	ventry	error_invalid_el1t			// Error EL1t
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
	ventry	el1_irq					// IRQ EL1h
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
	ventry	fiq_invalid_el1h			// FIQ EL1h
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
	ventry	error_invalid_el1h			// Error EL1h
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
	ventry	irq_invalid_el0_64			// IRQ 64-bit EL0
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
	ventry	fiq_invalid_el0_64			// FIQ 64-bit EL0
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
	ventry	error_invalid_el0_64			// Error 64-bit EL0
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
	ventry	irq_invalid_el0_32			// IRQ 32-bit EL0
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
	ventry	fiq_invalid_el0_32			// FIQ 32-bit EL0
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
	ventry	error_invalid_el0_32			// Error 32-bit EL0
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
	bl	handle_irq
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
	kernel_exit 
   835b0:	97fff4af 	bl	8086c <handle_irq>

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
	mov	x0, x20
   83608:	97fff687 	bl	81024 <schedule_tail>
	blr	x19 		//should never return
   8360c:	aa1403e0 	mov	x0, x20

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

   83694:	d5384020 	mrs	x0, elr_el1
   83698:	d65f03c0 	ret

000000000008369c <get_sp>:
   8369c:	910003e0 	mov	x0, sp
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
