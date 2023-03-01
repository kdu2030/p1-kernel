
build/kernel8.elf:     file format elf64-littleaarch64


Disassembly of section .text.boot:

ffff000000080000 <_start>:

.section ".text.boot"

.globl _start
_start:
	mrs	x0, mpidr_el1		
ffff000000080000:	d53800a0 	mrs	x0, mpidr_el1
	and	x0, x0,#0xFF		// Check processor id
ffff000000080004:	92401c00 	and	x0, x0, #0xff
	cbz	x0, master		// Hang for all non-primary CPU
ffff000000080008:	b4000060 	cbz	x0, ffff000000080014 <master>
	b	proc_hang
ffff00000008000c:	14000001 	b	ffff000000080010 <proc_hang>

ffff000000080010 <proc_hang>:

proc_hang: 
	b proc_hang
ffff000000080010:	14000000 	b	ffff000000080010 <proc_hang>

ffff000000080014 <master>:

master:
	ldr	x0, =SCTLR_VALUE_MMU_DISABLED
ffff000000080014:	58001460 	ldr	x0, ffff0000000802a0 <__create_page_tables+0x134>
	msr	sctlr_el1, x0		
ffff000000080018:	d5181000 	msr	sctlr_el1, x0
	
	mrs x0, CurrentEL
ffff00000008001c:	d5384240 	mrs	x0, currentel
  lsr x0, x0, #2
ffff000000080020:	d342fc00 	lsr	x0, x0, #2
	cmp x0, #3
ffff000000080024:	f1000c1f 	cmp	x0, #0x3
	beq el3
ffff000000080028:	54000120 	b.eq	ffff00000008004c <el3>  // b.none

//	ldr	x0, =HCR_VALUE
//	msr	hcr_el2, x0
	mrs	x0, hcr_el2
ffff00000008002c:	d53c1100 	mrs	x0, hcr_el2
	orr	x0, x0, #(1<<31)
ffff000000080030:	b2610000 	orr	x0, x0, #0x80000000
	msr	hcr_el2, x0
ffff000000080034:	d51c1100 	msr	hcr_el2, x0

	mov 	x0, #SPSR_VALUE
ffff000000080038:	d28038a0 	mov	x0, #0x1c5                 	// #453
	msr	spsr_el2, x0
ffff00000008003c:	d51c4000 	msr	spsr_el2, x0

	adr	x0, el1_entry
ffff000000080040:	10000180 	adr	x0, ffff000000080070 <el1_entry>
	msr	elr_el2, x0
ffff000000080044:	d51c4020 	msr	elr_el2, x0
	eret
ffff000000080048:	d69f03e0 	eret

ffff00000008004c <el3>:

el3:
  ldr x0, =HCR_VALUE
ffff00000008004c:	580012e0 	ldr	x0, ffff0000000802a8 <__create_page_tables+0x13c>
  msr hcr_el2, x0
ffff000000080050:	d51c1100 	msr	hcr_el2, x0

	ldr	x0, =SCR_VALUE
ffff000000080054:	580012e0 	ldr	x0, ffff0000000802b0 <__create_page_tables+0x144>
	msr	scr_el3, x0
ffff000000080058:	d51e1100 	msr	scr_el3, x0

	ldr	x0, =SPSR_VALUE
ffff00000008005c:	580012e0 	ldr	x0, ffff0000000802b8 <__create_page_tables+0x14c>
	msr	spsr_el3, x0
ffff000000080060:	d51e4000 	msr	spsr_el3, x0

	adr	x0, el1_entry		
ffff000000080064:	10000060 	adr	x0, ffff000000080070 <el1_entry>
	msr	elr_el3, x0
ffff000000080068:	d51e4020 	msr	elr_el3, x0

	eret				
ffff00000008006c:	d69f03e0 	eret

ffff000000080070 <el1_entry>:

el1_entry:
	adr	x0, bss_begin
ffff000000080070:	1002b6c0 	adr	x0, ffff000000085748 <mem_map>
	adr	x1, bss_end
ffff000000080074:	10417761 	adr	x1, ffff000000102f60 <bss_end>
	sub	x1, x1, x0
ffff000000080078:	cb000021 	sub	x1, x1, x0
	bl 	memzero
ffff00000008007c:	9400123a 	bl	ffff000000084964 <memzero>
// pgtable tree at TTBR0 that maps all physical DRAM (0 -- PHYS_MEMORY_SIZE) to virtual 
// addresses with the same values. That keeps translation going on at the switch of MMU. 
//
// Cf: https://github.com/s-matyukevich/raspberry-pi-os/issues/8
// https://www.raspberrypi.org/forums/viewtopic.php?t=222408
	bl	__create_idmap
ffff000000080080:	94000010 	bl	ffff0000000800c0 <__create_idmap>
	adrp	x0, idmap_dir
ffff000000080084:	f0000400 	adrp	x0, ffff000000103000 <idmap_dir>
	msr	ttbr0_el1, x0
ffff000000080088:	d5182000 	msr	ttbr0_el1, x0
#endif

	bl 	__create_page_tables
ffff00000008008c:	94000038 	bl	ffff00000008016c <__create_page_tables>

	mov	x0, #VA_START			
ffff000000080090:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
	add	sp, x0, #LOW_MEMORY
ffff000000080094:	9150001f 	add	sp, x0, #0x400, lsl #12

	adrp	x0, pg_dir				
ffff000000080098:	d0000420 	adrp	x0, ffff000000106000 <pg_dir>
	msr	ttbr1_el1, x0
ffff00000008009c:	d5182020 	msr	ttbr1_el1, x0

	// tcr_el1: Translation Control Register, responsible for configuring MMU, e.g. page size
	ldr	x0, =(TCR_VALUE)		
ffff0000000800a0:	58001100 	ldr	x0, ffff0000000802c0 <__create_page_tables+0x154>
	msr	tcr_el1, x0 
ffff0000000800a4:	d5182040 	msr	tcr_el1, x0

	ldr	x0, =(MAIR_VALUE)
ffff0000000800a8:	58001100 	ldr	x0, ffff0000000802c8 <__create_page_tables+0x15c>
	msr	mair_el1, x0
ffff0000000800ac:	d518a200 	msr	mair_el1, x0

	ldr	x2, =kernel_main
ffff0000000800b0:	58001102 	ldr	x2, ffff0000000802d0 <__create_page_tables+0x164>

	mov	x0, #SCTLR_MMU_ENABLED				
ffff0000000800b4:	d2800020 	mov	x0, #0x1                   	// #1
	msr	sctlr_el1, x0	// BOOM! we are on virtual after this.
ffff0000000800b8:	d5181000 	msr	sctlr_el1, x0

	br 	x2
ffff0000000800bc:	d61f0040 	br	x2

ffff0000000800c0 <__create_idmap>:
	b.ls	9999b
	.endm

#ifdef USE_QEMU
__create_idmap:
	mov	x29, x30
ffff0000000800c0:	aa1e03fd 	mov	x29, x30
	
	adrp	x0, idmap_dir
ffff0000000800c4:	f0000400 	adrp	x0, ffff000000103000 <idmap_dir>
	mov	x1, #PG_DIR_SIZE
ffff0000000800c8:	d2880001 	mov	x1, #0x4000                	// #16384
	bl	memzero
ffff0000000800cc:	94001226 	bl	ffff000000084964 <memzero>

	adrp	x0, idmap_dir
ffff0000000800d0:	f0000400 	adrp	x0, ffff000000103000 <idmap_dir>
	mov	x1, xzr
ffff0000000800d4:	aa1f03e1 	mov	x1, xzr
	create_pgd_entry	x0, x1, x2, x3
ffff0000000800d8:	d367fc22 	lsr	x2, x1, #39
ffff0000000800dc:	92402042 	and	x2, x2, #0x1ff
ffff0000000800e0:	91400403 	add	x3, x0, #0x1, lsl #12
ffff0000000800e4:	b2400463 	orr	x3, x3, #0x3
ffff0000000800e8:	f8227803 	str	x3, [x0, x2, lsl #3]
ffff0000000800ec:	91400400 	add	x0, x0, #0x1, lsl #12
ffff0000000800f0:	d35efc22 	lsr	x2, x1, #30
ffff0000000800f4:	92402042 	and	x2, x2, #0x1ff
ffff0000000800f8:	91400403 	add	x3, x0, #0x1, lsl #12
ffff0000000800fc:	b2400463 	orr	x3, x3, #0x3
ffff000000080100:	f8227803 	str	x3, [x0, x2, lsl #3]
ffff000000080104:	58000ea2 	ldr	x2, ffff0000000802d8 <__create_page_tables+0x16c>
ffff000000080108:	d35efc42 	lsr	x2, x2, #30
ffff00000008010c:	92402042 	and	x2, x2, #0x1ff
ffff000000080110:	58000e83 	ldr	x3, ffff0000000802e0 <__create_page_tables+0x174>
ffff000000080114:	d37ff863 	lsl	x3, x3, #1
ffff000000080118:	8b000063 	add	x3, x3, x0
ffff00000008011c:	b2400463 	orr	x3, x3, #0x3
ffff000000080120:	f8227803 	str	x3, [x0, x2, lsl #3]
ffff000000080124:	91400400 	add	x0, x0, #0x1, lsl #12

	mov	x1, xzr
ffff000000080128:	aa1f03e1 	mov	x1, xzr
	mov	x2, xzr
ffff00000008012c:	aa1f03e2 	mov	x2, xzr
	ldr	x3, =(PHYS_MEMORY_SIZE)
ffff000000080130:	58000dc3 	ldr	x3, ffff0000000802e8 <__create_page_tables+0x17c>
	create_block_map x0, x1, x2, x3, MMU_FLAGS, x4
ffff000000080134:	d355fc42 	lsr	x2, x2, #21
ffff000000080138:	92402042 	and	x2, x2, #0x1ff
ffff00000008013c:	d355fc63 	lsr	x3, x3, #21
ffff000000080140:	92402063 	and	x3, x3, #0x1ff
ffff000000080144:	d355fc21 	lsr	x1, x1, #21
ffff000000080148:	d28080a4 	mov	x4, #0x405                 	// #1029
ffff00000008014c:	aa015481 	orr	x1, x4, x1, lsl #21
ffff000000080150:	f8227801 	str	x1, [x0, x2, lsl #3]
ffff000000080154:	91000442 	add	x2, x2, #0x1
ffff000000080158:	91480021 	add	x1, x1, #0x200, lsl #12
ffff00000008015c:	eb03005f 	cmp	x2, x3
ffff000000080160:	54ffff89 	b.ls	ffff000000080150 <__create_idmap+0x90>  // b.plast

	mov	x30, x29
ffff000000080164:	aa1d03fe 	mov	x30, x29
	ret
ffff000000080168:	d65f03c0 	ret

ffff00000008016c <__create_page_tables>:
#endif

__create_page_tables:
	mov		x29, x30						// save return address
ffff00000008016c:	aa1e03fd 	mov	x29, x30
	add sp, sp, #LOW_MEMORY
ffff000000080170:	915003ff 	add	sp, sp, #0x400, lsl #12
	str x30, [sp]
ffff000000080174:	f90003fe 	str	x30, [sp]

	// clear the mem region backing pgtables
	adrp 	x0, pg_dir
ffff000000080178:	d0000420 	adrp	x0, ffff000000106000 <pg_dir>
	mov		x1, #PG_DIR_SIZE
ffff00000008017c:	d2880001 	mov	x1, #0x4000                	// #16384
	bl 		memzero
ffff000000080180:	940011f9 	bl	ffff000000084964 <memzero>

	// allocate one PUD & one PMD; link PGD (pg_dir)->PUD, and PUD->PMD
	adrp	x0, pg_dir
ffff000000080184:	d0000420 	adrp	x0, ffff000000106000 <pg_dir>
	mov		x1, #VA_START 
ffff000000080188:	d2ffffe1 	mov	x1, #0xffff000000000000    	// #-281474976710656
	create_pgd_entry x0, x1, x2, x3		// after this, x0 points to the new PMD table
ffff00000008018c:	d367fc22 	lsr	x2, x1, #39
ffff000000080190:	92402042 	and	x2, x2, #0x1ff
ffff000000080194:	91400403 	add	x3, x0, #0x1, lsl #12
ffff000000080198:	b2400463 	orr	x3, x3, #0x3
ffff00000008019c:	f8227803 	str	x3, [x0, x2, lsl #3]
ffff0000000801a0:	91400400 	add	x0, x0, #0x1, lsl #12
ffff0000000801a4:	d35efc22 	lsr	x2, x1, #30
ffff0000000801a8:	92402042 	and	x2, x2, #0x1ff
ffff0000000801ac:	91400403 	add	x3, x0, #0x1, lsl #12
ffff0000000801b0:	b2400463 	orr	x3, x3, #0x3
ffff0000000801b4:	f8227803 	str	x3, [x0, x2, lsl #3]
ffff0000000801b8:	58000902 	ldr	x2, ffff0000000802d8 <__create_page_tables+0x16c>
ffff0000000801bc:	d35efc42 	lsr	x2, x2, #30
ffff0000000801c0:	92402042 	and	x2, x2, #0x1ff
ffff0000000801c4:	580008e3 	ldr	x3, ffff0000000802e0 <__create_page_tables+0x174>
ffff0000000801c8:	d37ff863 	lsl	x3, x3, #1
ffff0000000801cc:	8b000063 	add	x3, x3, x0
ffff0000000801d0:	b2400463 	orr	x3, x3, #0x3
ffff0000000801d4:	f8227803 	str	x3, [x0, x2, lsl #3]
ffff0000000801d8:	91400400 	add	x0, x0, #0x1, lsl #12

	/* Mapping kernel and init stack. Phys addr range: 0--DEVICE_BASE */
	mov 	x1, xzr				// x1 = starting phys addr. set x1 to 0. 
ffff0000000801dc:	aa1f03e1 	mov	x1, xzr
	mov 	x2, #VA_START		// x2 = the virtual base of the first section
ffff0000000801e0:	d2ffffe2 	mov	x2, #0xffff000000000000    	// #-281474976710656
	ldr		x3, =(VA_START + DEVICE_BASE - SECTION_SIZE)  // x3 = the virtual base of the last section
ffff0000000801e4:	58000863 	ldr	x3, ffff0000000802f0 <__create_page_tables+0x184>
	create_block_map x0, x1, x2, x3, MMU_FLAGS, x4
ffff0000000801e8:	d355fc42 	lsr	x2, x2, #21
ffff0000000801ec:	92402042 	and	x2, x2, #0x1ff
ffff0000000801f0:	d355fc63 	lsr	x3, x3, #21
ffff0000000801f4:	92402063 	and	x3, x3, #0x1ff
ffff0000000801f8:	d355fc21 	lsr	x1, x1, #21
ffff0000000801fc:	d28080a4 	mov	x4, #0x405                 	// #1029
ffff000000080200:	aa015481 	orr	x1, x4, x1, lsl #21
ffff000000080204:	f8227801 	str	x1, [x0, x2, lsl #3]
ffff000000080208:	91000442 	add	x2, x2, #0x1
ffff00000008020c:	91480021 	add	x1, x1, #0x200, lsl #12
ffff000000080210:	eb03005f 	cmp	x2, x3
ffff000000080214:	54ffff89 	b.ls	ffff000000080204 <__create_page_tables+0x98>  // b.plast

	/* Mapping device memory. Phys addr range: DEVICE_BASE--PHYS_MEMORY_SIZE(0x40000000) */
	mov 	x1, #DEVICE_BASE					// x1 = start mapping from device base address 
ffff000000080218:	d2a7e001 	mov	x1, #0x3f000000            	// #1056964608
	ldr 	x2, =(VA_START + DEVICE_BASE)				// x2 = first virtual address
ffff00000008021c:	580006e2 	ldr	x2, ffff0000000802f8 <__create_page_tables+0x18c>
	ldr		x3, =(VA_START + PHYS_MEMORY_SIZE - SECTION_SIZE)	// x3 = the virtual base of the last section
ffff000000080220:	58000703 	ldr	x3, ffff000000080300 <__create_page_tables+0x194>
	create_block_map x0, x1, x2, x3, MMU_DEVICE_FLAGS, x4
ffff000000080224:	d355fc42 	lsr	x2, x2, #21
ffff000000080228:	92402042 	and	x2, x2, #0x1ff
ffff00000008022c:	d355fc63 	lsr	x3, x3, #21
ffff000000080230:	92402063 	and	x3, x3, #0x1ff
ffff000000080234:	d355fc21 	lsr	x1, x1, #21
ffff000000080238:	d2808024 	mov	x4, #0x401                 	// #1025
ffff00000008023c:	aa015481 	orr	x1, x4, x1, lsl #21
ffff000000080240:	f8227801 	str	x1, [x0, x2, lsl #3]
ffff000000080244:	91000442 	add	x2, x2, #0x1
ffff000000080248:	91480021 	add	x1, x1, #0x200, lsl #12
ffff00000008024c:	eb03005f 	cmp	x2, x3
ffff000000080250:	54ffff89 	b.ls	ffff000000080240 <__create_page_tables+0xd4>  // b.plast

	/* Mapping timer registers */
	add x0, x0, #PAGE_SIZE	// Point to PMD 2
ffff000000080254:	91400400 	add	x0, x0, #0x1, lsl #12
	ldr x1, =0x40000000 // x1 = Start mapping from physical address 0x40000000
ffff000000080258:	58000481 	ldr	x1, ffff0000000802e8 <__create_page_tables+0x17c>
	ldr x2, =(VA_IRQ_START) // x2 = Start from VA_IRQ_START for the virtual address - This should have a PMD Index of 1
ffff00000008025c:	580003e2 	ldr	x2, ffff0000000802d8 <__create_page_tables+0x16c>
	ldr x3, =(VA_IRQ_START + SECTION_SIZE)
ffff000000080260:	58000543 	ldr	x3, ffff000000080308 <__create_page_tables+0x19c>
	create_block_map x0, x1, x2, x3, MMU_FLAGS, x4
ffff000000080264:	d355fc42 	lsr	x2, x2, #21
ffff000000080268:	92402042 	and	x2, x2, #0x1ff
ffff00000008026c:	d355fc63 	lsr	x3, x3, #21
ffff000000080270:	92402063 	and	x3, x3, #0x1ff
ffff000000080274:	d355fc21 	lsr	x1, x1, #21
ffff000000080278:	d28080a4 	mov	x4, #0x405                 	// #1029
ffff00000008027c:	aa015481 	orr	x1, x4, x1, lsl #21
ffff000000080280:	f8227801 	str	x1, [x0, x2, lsl #3]
ffff000000080284:	91000442 	add	x2, x2, #0x1
ffff000000080288:	91480021 	add	x1, x1, #0x200, lsl #12
ffff00000008028c:	eb03005f 	cmp	x2, x3
ffff000000080290:	54ffff89 	b.ls	ffff000000080280 <__create_page_tables+0x114>  // b.plast

	mov	x30, x29						// restore return address
ffff000000080294:	aa1d03fe 	mov	x30, x29
	ret
ffff000000080298:	d65f03c0 	ret
ffff00000008029c:	00000000 	.inst	0x00000000 ; undefined
ffff0000000802a0:	30d00800 	.word	0x30d00800
ffff0000000802a4:	00000000 	.word	0x00000000
ffff0000000802a8:	80000000 	.word	0x80000000
ffff0000000802ac:	00000000 	.word	0x00000000
ffff0000000802b0:	00000431 	.word	0x00000431
ffff0000000802b4:	00000000 	.word	0x00000000
ffff0000000802b8:	000001c5 	.word	0x000001c5
ffff0000000802bc:	00000000 	.word	0x00000000
ffff0000000802c0:	80100010 	.word	0x80100010
ffff0000000802c4:	00000000 	.word	0x00000000
ffff0000000802c8:	00004400 	.word	0x00004400
ffff0000000802cc:	00000000 	.word	0x00000000
ffff0000000802d0:	00083168 	.word	0x00083168
ffff0000000802d4:	ffff0000 	.word	0xffff0000
ffff0000000802d8:	00100000 	.word	0x00100000
ffff0000000802dc:	ffff0000 	.word	0xffff0000
ffff0000000802e0:	00001000 	.word	0x00001000
ffff0000000802e4:	00000000 	.word	0x00000000
ffff0000000802e8:	40000000 	.word	0x40000000
ffff0000000802ec:	00000000 	.word	0x00000000
ffff0000000802f0:	3ee00000 	.word	0x3ee00000
ffff0000000802f4:	ffff0000 	.word	0xffff0000
ffff0000000802f8:	3f000000 	.word	0x3f000000
ffff0000000802fc:	ffff0000 	.word	0xffff0000
ffff000000080300:	3fe00000 	.word	0x3fe00000
ffff000000080304:	ffff0000 	.word	0xffff0000
ffff000000080308:	00300000 	.word	0x00300000
ffff00000008030c:	ffff0000 	.word	0xffff0000

Disassembly of section .text.user:

ffff000000081000 <loop>:
#include "user_sys.h"
#include "user.h"
#include "printf.h"

void loop(char* str)
{
ffff000000081000:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff000000081004:	910003fd 	mov	x29, sp
ffff000000081008:	f9000fe0 	str	x0, [sp, #24]
	char buf[2] = {""};
ffff00000008100c:	790053ff 	strh	wzr, [sp, #40]
	while (1){
		for (int i = 0; i < 5; i++){
ffff000000081010:	b9002fff 	str	wzr, [sp, #44]
ffff000000081014:	1400000e 	b	ffff00000008104c <loop+0x4c>
			buf[0] = str[i];
ffff000000081018:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008101c:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000081020:	8b000020 	add	x0, x1, x0
ffff000000081024:	39400000 	ldrb	w0, [x0]
ffff000000081028:	3900a3e0 	strb	w0, [sp, #40]
			call_sys_write(buf);
ffff00000008102c:	9100a3e0 	add	x0, sp, #0x28
ffff000000081030:	94000029 	bl	ffff0000000810d4 <call_sys_write>
			user_delay(1000000);
ffff000000081034:	d2884800 	mov	x0, #0x4240                	// #16960
ffff000000081038:	f2a001e0 	movk	x0, #0xf, lsl #16
ffff00000008103c:	94000023 	bl	ffff0000000810c8 <user_delay>
		for (int i = 0; i < 5; i++){
ffff000000081040:	b9402fe0 	ldr	w0, [sp, #44]
ffff000000081044:	11000400 	add	w0, w0, #0x1
ffff000000081048:	b9002fe0 	str	w0, [sp, #44]
ffff00000008104c:	b9402fe0 	ldr	w0, [sp, #44]
ffff000000081050:	7100101f 	cmp	w0, #0x4
ffff000000081054:	54fffe2d 	b.le	ffff000000081018 <loop+0x18>
ffff000000081058:	17ffffee 	b	ffff000000081010 <loop+0x10>

ffff00000008105c <user_process>:
		}
	}
}

void user_process() 
{
ffff00000008105c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff000000081060:	910003fd 	mov	x29, sp
	call_sys_write("User process\n\r");
ffff000000081064:	90000000 	adrp	x0, ffff000000081000 <loop>
ffff000000081068:	9103e000 	add	x0, x0, #0xf8
ffff00000008106c:	9400001a 	bl	ffff0000000810d4 <call_sys_write>
	int pid = call_sys_fork();
ffff000000081070:	9400001f 	bl	ffff0000000810ec <call_sys_fork>
ffff000000081074:	b9001fe0 	str	w0, [sp, #28]
	if (pid < 0) {
ffff000000081078:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008107c:	7100001f 	cmp	w0, #0x0
ffff000000081080:	540000ca 	b.ge	ffff000000081098 <user_process+0x3c>  // b.tcont
		call_sys_write("Error during fork\n\r");
ffff000000081084:	90000000 	adrp	x0, ffff000000081000 <loop>
ffff000000081088:	91042000 	add	x0, x0, #0x108
ffff00000008108c:	94000012 	bl	ffff0000000810d4 <call_sys_write>
		call_sys_exit();
ffff000000081090:	94000014 	bl	ffff0000000810e0 <call_sys_exit>
		return;
ffff000000081094:	1400000b 	b	ffff0000000810c0 <user_process+0x64>
	}
	if (pid == 0){
ffff000000081098:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008109c:	7100001f 	cmp	w0, #0x0
ffff0000000810a0:	540000a1 	b.ne	ffff0000000810b4 <user_process+0x58>  // b.any
		loop("abcde");
ffff0000000810a4:	90000000 	adrp	x0, ffff000000081000 <loop>
ffff0000000810a8:	91048000 	add	x0, x0, #0x120
ffff0000000810ac:	97ffffd5 	bl	ffff000000081000 <loop>
ffff0000000810b0:	14000004 	b	ffff0000000810c0 <user_process+0x64>
	} else {
		loop("12345");
ffff0000000810b4:	90000000 	adrp	x0, ffff000000081000 <loop>
ffff0000000810b8:	9104a000 	add	x0, x0, #0x128
ffff0000000810bc:	97ffffd1 	bl	ffff000000081000 <loop>
	}
}
ffff0000000810c0:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff0000000810c4:	d65f03c0 	ret

ffff0000000810c8 <user_delay>:
.set SYS_FORK_NUMBER, 1 	
.set SYS_EXIT_NUMBER, 2 	

.globl user_delay
user_delay:
	subs x0, x0, #1
ffff0000000810c8:	f1000400 	subs	x0, x0, #0x1
	bne user_delay
ffff0000000810cc:	54ffffe1 	b.ne	ffff0000000810c8 <user_delay>  // b.any
	ret
ffff0000000810d0:	d65f03c0 	ret

ffff0000000810d4 <call_sys_write>:

.globl call_sys_write
call_sys_write:
	mov w8, #SYS_WRITE_NUMBER	
ffff0000000810d4:	52800008 	mov	w8, #0x0                   	// #0
	svc #0
ffff0000000810d8:	d4000001 	svc	#0x0
	ret
ffff0000000810dc:	d65f03c0 	ret

ffff0000000810e0 <call_sys_exit>:

.globl call_sys_exit
call_sys_exit:
	mov w8, #SYS_EXIT_NUMBER	
ffff0000000810e0:	52800048 	mov	w8, #0x2                   	// #2
	svc #0
ffff0000000810e4:	d4000001 	svc	#0x0
	ret
ffff0000000810e8:	d65f03c0 	ret

ffff0000000810ec <call_sys_fork>:

.globl call_sys_fork
call_sys_fork:
	mov w8, #SYS_FORK_NUMBER	
ffff0000000810ec:	52800028 	mov	w8, #0x1                   	// #1
	svc #0
ffff0000000810f0:	d4000001 	svc	#0x0
	ret
ffff0000000810f4:	d65f03c0 	ret

Disassembly of section .text:

ffff000000081800 <enable_interrupt_controller>:
	"FIQ_INVALID_EL0_32",		
	"ERROR_INVALID_EL0_32"	
};

void enable_interrupt_controller()
{
ffff000000081800:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000081804:	910003fd 	mov	x29, sp
	put32(ENABLE_IRQS_1, SYSTEM_TIMER_IRQ_1);
ffff000000081808:	52800041 	mov	w1, #0x2                   	// #2
ffff00000008180c:	d2964200 	mov	x0, #0xb210                	// #45584
ffff000000081810:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff000000081814:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081818:	94000c6e 	bl	ffff0000000849d0 <put32>

  // Enables Core 0 Timers interrupt control for the generic timer
//  put32(TIMER_INT_CTRL_0, TIMER_INT_CTRL_0_VALUE);
}
ffff00000008181c:	d503201f 	nop
ffff000000081820:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000081824:	d65f03c0 	ret

ffff000000081828 <show_invalid_entry_message>:

void show_invalid_entry_message(int type, unsigned long esr, unsigned long address)
{
ffff000000081828:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008182c:	910003fd 	mov	x29, sp
ffff000000081830:	b9002fe0 	str	w0, [sp, #44]
ffff000000081834:	f90013e1 	str	x1, [sp, #32]
ffff000000081838:	f9000fe2 	str	x2, [sp, #24]
	printf("%s, ESR: %x, address: %x\r\n", entry_error_messages[type], esr, address);
ffff00000008183c:	90000020 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000081840:	9112a000 	add	x0, x0, #0x4a8
ffff000000081844:	b9802fe1 	ldrsw	x1, [sp, #44]
ffff000000081848:	f8617800 	ldr	x0, [x0, x1, lsl #3]
ffff00000008184c:	f9400fe3 	ldr	x3, [sp, #24]
ffff000000081850:	f94013e2 	ldr	x2, [sp, #32]
ffff000000081854:	aa0003e1 	mov	x1, x0
ffff000000081858:	f0000000 	adrp	x0, ffff000000084000 <irq_invalid_el1t+0x14>
ffff00000008185c:	912e6000 	add	x0, x0, #0xb98
ffff000000081860:	940005c2 	bl	ffff000000082f68 <tfp_printf>
}
ffff000000081864:	d503201f 	nop
ffff000000081868:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008186c:	d65f03c0 	ret

ffff000000081870 <handle_irq>:
	}
}
#endif

void handle_irq(void)
{
ffff000000081870:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff000000081874:	910003fd 	mov	x29, sp
	unsigned int irq = get32(IRQ_PENDING_1);
ffff000000081878:	d2964080 	mov	x0, #0xb204                	// #45572
ffff00000008187c:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff000000081880:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081884:	94000c55 	bl	ffff0000000849d8 <get32>
ffff000000081888:	b9001fe0 	str	w0, [sp, #28]
	switch (irq) {
ffff00000008188c:	b9401fe0 	ldr	w0, [sp, #28]
ffff000000081890:	7100081f 	cmp	w0, #0x2
ffff000000081894:	54000061 	b.ne	ffff0000000818a0 <handle_irq+0x30>  // b.any
		case (SYSTEM_TIMER_IRQ_1):
			handle_timer_irq();
ffff000000081898:	94000319 	bl	ffff0000000824fc <handle_timer_irq>
			break;
ffff00000008189c:	14000006 	b	ffff0000000818b4 <handle_irq+0x44>
		default:
			printf("Inknown pending irq: %x\r\n", irq);
ffff0000000818a0:	b9401fe1 	ldr	w1, [sp, #28]
ffff0000000818a4:	f0000000 	adrp	x0, ffff000000084000 <irq_invalid_el1t+0x14>
ffff0000000818a8:	912ee000 	add	x0, x0, #0xbb8
ffff0000000818ac:	940005af 	bl	ffff000000082f68 <tfp_printf>
	}
}
ffff0000000818b0:	d503201f 	nop
ffff0000000818b4:	d503201f 	nop
ffff0000000818b8:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff0000000818bc:	d65f03c0 	ret

ffff0000000818c0 <allocate_kernel_page>:
/* 
	minimalist page allocation 
*/
static unsigned short mem_map [ PAGING_PAGES ] = {0,};

unsigned long allocate_kernel_page() {
ffff0000000818c0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff0000000818c4:	910003fd 	mov	x29, sp
	unsigned long page = get_free_page();
ffff0000000818c8:	94000020 	bl	ffff000000081948 <get_free_page>
ffff0000000818cc:	f9000fe0 	str	x0, [sp, #24]
	if (page == 0) {
ffff0000000818d0:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000818d4:	f100001f 	cmp	x0, #0x0
ffff0000000818d8:	54000061 	b.ne	ffff0000000818e4 <allocate_kernel_page+0x24>  // b.any
		return 0;
ffff0000000818dc:	d2800000 	mov	x0, #0x0                   	// #0
ffff0000000818e0:	14000004 	b	ffff0000000818f0 <allocate_kernel_page+0x30>
	}
	return page + VA_START;
ffff0000000818e4:	f9400fe1 	ldr	x1, [sp, #24]
ffff0000000818e8:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff0000000818ec:	8b000020 	add	x0, x1, x0
}
ffff0000000818f0:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff0000000818f4:	d65f03c0 	ret

ffff0000000818f8 <allocate_user_page>:

unsigned long allocate_user_page(struct task_struct *task, unsigned long va) {
ffff0000000818f8:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff0000000818fc:	910003fd 	mov	x29, sp
ffff000000081900:	f9000fe0 	str	x0, [sp, #24]
ffff000000081904:	f9000be1 	str	x1, [sp, #16]
	unsigned long page = get_free_page();
ffff000000081908:	94000010 	bl	ffff000000081948 <get_free_page>
ffff00000008190c:	f90017e0 	str	x0, [sp, #40]
	if (page == 0) {
ffff000000081910:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081914:	f100001f 	cmp	x0, #0x0
ffff000000081918:	54000061 	b.ne	ffff000000081924 <allocate_user_page+0x2c>  // b.any
		return 0;
ffff00000008191c:	d2800000 	mov	x0, #0x0                   	// #0
ffff000000081920:	14000008 	b	ffff000000081940 <allocate_user_page+0x48>
	}
	map_page(task, va, page);
ffff000000081924:	f94017e2 	ldr	x2, [sp, #40]
ffff000000081928:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008192c:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081930:	9400007d 	bl	ffff000000081b24 <map_page>
	return page + VA_START;
ffff000000081934:	f94017e1 	ldr	x1, [sp, #40]
ffff000000081938:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff00000008193c:	8b000020 	add	x0, x1, x0
}
ffff000000081940:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff000000081944:	d65f03c0 	ret

ffff000000081948 <get_free_page>:

unsigned long get_free_page()
{
ffff000000081948:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008194c:	910003fd 	mov	x29, sp
	for (int i = 0; i < PAGING_PAGES; i++){
ffff000000081950:	b9001fff 	str	wzr, [sp, #28]
ffff000000081954:	1400001b 	b	ffff0000000819c0 <get_free_page+0x78>
		if (mem_map[i] == 0){
ffff000000081958:	90000020 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff00000008195c:	911d2000 	add	x0, x0, #0x748
ffff000000081960:	b9801fe1 	ldrsw	x1, [sp, #28]
ffff000000081964:	78617800 	ldrh	w0, [x0, x1, lsl #1]
ffff000000081968:	7100001f 	cmp	w0, #0x0
ffff00000008196c:	54000241 	b.ne	ffff0000000819b4 <get_free_page+0x6c>  // b.any
			mem_map[i] = 1;
ffff000000081970:	90000020 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000081974:	911d2000 	add	x0, x0, #0x748
ffff000000081978:	b9801fe1 	ldrsw	x1, [sp, #28]
ffff00000008197c:	52800022 	mov	w2, #0x1                   	// #1
ffff000000081980:	78217802 	strh	w2, [x0, x1, lsl #1]
			unsigned long page = LOW_MEMORY + i*PAGE_SIZE;
ffff000000081984:	b9401fe0 	ldr	w0, [sp, #28]
ffff000000081988:	11100000 	add	w0, w0, #0x400
ffff00000008198c:	53144c00 	lsl	w0, w0, #12
ffff000000081990:	93407c00 	sxtw	x0, w0
ffff000000081994:	f9000be0 	str	x0, [sp, #16]
			memzero(page + VA_START, PAGE_SIZE);
ffff000000081998:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008199c:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff0000000819a0:	8b000020 	add	x0, x1, x0
ffff0000000819a4:	d2820001 	mov	x1, #0x1000                	// #4096
ffff0000000819a8:	94000bef 	bl	ffff000000084964 <memzero>
			return page;
ffff0000000819ac:	f9400be0 	ldr	x0, [sp, #16]
ffff0000000819b0:	1400000a 	b	ffff0000000819d8 <get_free_page+0x90>
	for (int i = 0; i < PAGING_PAGES; i++){
ffff0000000819b4:	b9401fe0 	ldr	w0, [sp, #28]
ffff0000000819b8:	11000400 	add	w0, w0, #0x1
ffff0000000819bc:	b9001fe0 	str	w0, [sp, #28]
ffff0000000819c0:	b9401fe1 	ldr	w1, [sp, #28]
ffff0000000819c4:	529d7fe0 	mov	w0, #0xebff                	// #60415
ffff0000000819c8:	72a00060 	movk	w0, #0x3, lsl #16
ffff0000000819cc:	6b00003f 	cmp	w1, w0
ffff0000000819d0:	54fffc4d 	b.le	ffff000000081958 <get_free_page+0x10>
		}
	}
	return 0;
ffff0000000819d4:	d2800000 	mov	x0, #0x0                   	// #0
}
ffff0000000819d8:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff0000000819dc:	d65f03c0 	ret

ffff0000000819e0 <free_page>:

void free_page(unsigned long p){
ffff0000000819e0:	d10043ff 	sub	sp, sp, #0x10
ffff0000000819e4:	f90007e0 	str	x0, [sp, #8]
	mem_map[(p - LOW_MEMORY) / PAGE_SIZE] = 0;
ffff0000000819e8:	f94007e0 	ldr	x0, [sp, #8]
ffff0000000819ec:	d1500000 	sub	x0, x0, #0x400, lsl #12
ffff0000000819f0:	d34cfc01 	lsr	x1, x0, #12
ffff0000000819f4:	90000020 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff0000000819f8:	911d2000 	add	x0, x0, #0x748
ffff0000000819fc:	7821781f 	strh	wzr, [x0, x1, lsl #1]
}
ffff000000081a00:	d503201f 	nop
ffff000000081a04:	910043ff 	add	sp, sp, #0x10
ffff000000081a08:	d65f03c0 	ret

ffff000000081a0c <map_table_entry>:
	Virtual memory implementation
*/

/* set a pte (at the bottom of a pgtable tree), 
   so that @va is mapped to @pa. @pte: the 0-th pte of that pgtable */
void map_table_entry(unsigned long *pte, unsigned long va, unsigned long pa) {
ffff000000081a0c:	d100c3ff 	sub	sp, sp, #0x30
ffff000000081a10:	f9000fe0 	str	x0, [sp, #24]
ffff000000081a14:	f9000be1 	str	x1, [sp, #16]
ffff000000081a18:	f90007e2 	str	x2, [sp, #8]
	unsigned long index = va >> PAGE_SHIFT;
ffff000000081a1c:	f9400be0 	ldr	x0, [sp, #16]
ffff000000081a20:	d34cfc00 	lsr	x0, x0, #12
ffff000000081a24:	f90017e0 	str	x0, [sp, #40]
	index = index & (PTRS_PER_TABLE - 1);
ffff000000081a28:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081a2c:	92402000 	and	x0, x0, #0x1ff
ffff000000081a30:	f90017e0 	str	x0, [sp, #40]
	unsigned long entry = pa | MMU_PTE_FLAGS; 
ffff000000081a34:	f94007e1 	ldr	x1, [sp, #8]
ffff000000081a38:	d28088e0 	mov	x0, #0x447                 	// #1095
ffff000000081a3c:	aa000020 	orr	x0, x1, x0
ffff000000081a40:	f90013e0 	str	x0, [sp, #32]
	pte[index] = entry;
ffff000000081a44:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081a48:	d37df000 	lsl	x0, x0, #3
ffff000000081a4c:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000081a50:	8b000020 	add	x0, x1, x0
ffff000000081a54:	f94013e1 	ldr	x1, [sp, #32]
ffff000000081a58:	f9000001 	str	x1, [x0]
}
ffff000000081a5c:	d503201f 	nop
ffff000000081a60:	9100c3ff 	add	sp, sp, #0x30
ffff000000081a64:	d65f03c0 	ret

ffff000000081a68 <map_table>:
   @va: the virt address of the page to be mapped
   @new_table [out]: 1 means a new pgtable is allocated; 0 otherwise

   Return: the phys addr of the next pgtable. 
*/
unsigned long map_table(unsigned long *table, unsigned long shift, unsigned long va, int* new_table) {
ffff000000081a68:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
ffff000000081a6c:	910003fd 	mov	x29, sp
ffff000000081a70:	f90017e0 	str	x0, [sp, #40]
ffff000000081a74:	f90013e1 	str	x1, [sp, #32]
ffff000000081a78:	f9000fe2 	str	x2, [sp, #24]
ffff000000081a7c:	f9000be3 	str	x3, [sp, #16]
	unsigned long index = va >> shift;
ffff000000081a80:	f94013e0 	ldr	x0, [sp, #32]
ffff000000081a84:	2a0003e1 	mov	w1, w0
ffff000000081a88:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081a8c:	9ac12400 	lsr	x0, x0, x1
ffff000000081a90:	f90027e0 	str	x0, [sp, #72]
	index = index & (PTRS_PER_TABLE - 1);
ffff000000081a94:	f94027e0 	ldr	x0, [sp, #72]
ffff000000081a98:	92402000 	and	x0, x0, #0x1ff
ffff000000081a9c:	f90027e0 	str	x0, [sp, #72]
	if (!table[index]){ /* next level pgtable absent. alloate a new page & install. */
ffff000000081aa0:	f94027e0 	ldr	x0, [sp, #72]
ffff000000081aa4:	d37df000 	lsl	x0, x0, #3
ffff000000081aa8:	f94017e1 	ldr	x1, [sp, #40]
ffff000000081aac:	8b000020 	add	x0, x1, x0
ffff000000081ab0:	f9400000 	ldr	x0, [x0]
ffff000000081ab4:	f100001f 	cmp	x0, #0x0
ffff000000081ab8:	54000221 	b.ne	ffff000000081afc <map_table+0x94>  // b.any
		*new_table = 1;
ffff000000081abc:	f9400be0 	ldr	x0, [sp, #16]
ffff000000081ac0:	52800021 	mov	w1, #0x1                   	// #1
ffff000000081ac4:	b9000001 	str	w1, [x0]
		unsigned long next_level_table = get_free_page();
ffff000000081ac8:	97ffffa0 	bl	ffff000000081948 <get_free_page>
ffff000000081acc:	f90023e0 	str	x0, [sp, #64]
		unsigned long entry = next_level_table | MM_TYPE_PAGE_TABLE;
ffff000000081ad0:	f94023e0 	ldr	x0, [sp, #64]
ffff000000081ad4:	b2400400 	orr	x0, x0, #0x3
ffff000000081ad8:	f9001fe0 	str	x0, [sp, #56]
		table[index] = entry;
ffff000000081adc:	f94027e0 	ldr	x0, [sp, #72]
ffff000000081ae0:	d37df000 	lsl	x0, x0, #3
ffff000000081ae4:	f94017e1 	ldr	x1, [sp, #40]
ffff000000081ae8:	8b000020 	add	x0, x1, x0
ffff000000081aec:	f9401fe1 	ldr	x1, [sp, #56]
ffff000000081af0:	f9000001 	str	x1, [x0]
		return next_level_table;
ffff000000081af4:	f94023e0 	ldr	x0, [sp, #64]
ffff000000081af8:	14000009 	b	ffff000000081b1c <map_table+0xb4>
	} else {
		*new_table = 0;
ffff000000081afc:	f9400be0 	ldr	x0, [sp, #16]
ffff000000081b00:	b900001f 	str	wzr, [x0]
	}
	return table[index] & PAGE_MASK;
ffff000000081b04:	f94027e0 	ldr	x0, [sp, #72]
ffff000000081b08:	d37df000 	lsl	x0, x0, #3
ffff000000081b0c:	f94017e1 	ldr	x1, [sp, #40]
ffff000000081b10:	8b000020 	add	x0, x1, x0
ffff000000081b14:	f9400000 	ldr	x0, [x0]
ffff000000081b18:	9274cc00 	and	x0, x0, #0xfffffffffffff000
}
ffff000000081b1c:	a8c57bfd 	ldp	x29, x30, [sp], #80
ffff000000081b20:	d65f03c0 	ret

ffff000000081b24 <map_page>:

/* map a page to the given @task at its virtual address @va. 
   @page: the phys addr of the page start. 
   Descend in the task's pgtable tree and alloate any absent pgtables on the way.
   */
void map_page(struct task_struct *task, unsigned long va, unsigned long page){
ffff000000081b24:	a9b97bfd 	stp	x29, x30, [sp, #-112]!
ffff000000081b28:	910003fd 	mov	x29, sp
ffff000000081b2c:	f90017e0 	str	x0, [sp, #40]
ffff000000081b30:	f90013e1 	str	x1, [sp, #32]
ffff000000081b34:	f9000fe2 	str	x2, [sp, #24]
	unsigned long pgd;
	if (!task->mm.pgd) { /* start from the task's top-level pgtable. allocate if absent */
ffff000000081b38:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081b3c:	f9404800 	ldr	x0, [x0, #144]
ffff000000081b40:	f100001f 	cmp	x0, #0x0
ffff000000081b44:	54000281 	b.ne	ffff000000081b94 <map_page+0x70>  // b.any
		task->mm.pgd = get_free_page();
ffff000000081b48:	97ffff80 	bl	ffff000000081948 <get_free_page>
ffff000000081b4c:	aa0003e1 	mov	x1, x0
ffff000000081b50:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081b54:	f9004801 	str	x1, [x0, #144]
		task->mm.kernel_pages[++task->mm.kernel_pages_count] = task->mm.pgd;
ffff000000081b58:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081b5c:	b941a000 	ldr	w0, [x0, #416]
ffff000000081b60:	11000401 	add	w1, w0, #0x1
ffff000000081b64:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081b68:	b901a001 	str	w1, [x0, #416]
ffff000000081b6c:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081b70:	b941a003 	ldr	w3, [x0, #416]
ffff000000081b74:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081b78:	f9404801 	ldr	x1, [x0, #144]
ffff000000081b7c:	f94017e2 	ldr	x2, [sp, #40]
ffff000000081b80:	93407c60 	sxtw	x0, w3
ffff000000081b84:	9100d000 	add	x0, x0, #0x34
ffff000000081b88:	d37df000 	lsl	x0, x0, #3
ffff000000081b8c:	8b000040 	add	x0, x2, x0
ffff000000081b90:	f9000401 	str	x1, [x0, #8]
	}
	pgd = task->mm.pgd;
ffff000000081b94:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081b98:	f9404800 	ldr	x0, [x0, #144]
ffff000000081b9c:	f90037e0 	str	x0, [sp, #104]
	int new_table; 
	/* move to the next level pgtable. allocate one if absent */
	unsigned long pud = map_table((unsigned long *)(pgd + VA_START), PGD_SHIFT, va, &new_table);
ffff000000081ba0:	f94037e1 	ldr	x1, [sp, #104]
ffff000000081ba4:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff000000081ba8:	8b000020 	add	x0, x1, x0
ffff000000081bac:	aa0003e4 	mov	x4, x0
ffff000000081bb0:	910133e0 	add	x0, sp, #0x4c
ffff000000081bb4:	aa0003e3 	mov	x3, x0
ffff000000081bb8:	f94013e2 	ldr	x2, [sp, #32]
ffff000000081bbc:	d28004e1 	mov	x1, #0x27                  	// #39
ffff000000081bc0:	aa0403e0 	mov	x0, x4
ffff000000081bc4:	97ffffa9 	bl	ffff000000081a68 <map_table>
ffff000000081bc8:	f90033e0 	str	x0, [sp, #96]
	if (new_table) { /* we've allocated a new kernel page. take it into account for future reclaim */
ffff000000081bcc:	b9404fe0 	ldr	w0, [sp, #76]
ffff000000081bd0:	7100001f 	cmp	w0, #0x0
ffff000000081bd4:	540001e0 	b.eq	ffff000000081c10 <map_page+0xec>  // b.none
		task->mm.kernel_pages[++task->mm.kernel_pages_count] = pud;
ffff000000081bd8:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081bdc:	b941a000 	ldr	w0, [x0, #416]
ffff000000081be0:	11000401 	add	w1, w0, #0x1
ffff000000081be4:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081be8:	b901a001 	str	w1, [x0, #416]
ffff000000081bec:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081bf0:	b941a000 	ldr	w0, [x0, #416]
ffff000000081bf4:	f94017e1 	ldr	x1, [sp, #40]
ffff000000081bf8:	93407c00 	sxtw	x0, w0
ffff000000081bfc:	9100d000 	add	x0, x0, #0x34
ffff000000081c00:	d37df000 	lsl	x0, x0, #3
ffff000000081c04:	8b000020 	add	x0, x1, x0
ffff000000081c08:	f94033e1 	ldr	x1, [sp, #96]
ffff000000081c0c:	f9000401 	str	x1, [x0, #8]
	}
	/* next level ... */
	unsigned long pmd = map_table((unsigned long *)(pud + VA_START) , PUD_SHIFT, va, &new_table);
ffff000000081c10:	f94033e1 	ldr	x1, [sp, #96]
ffff000000081c14:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff000000081c18:	8b000020 	add	x0, x1, x0
ffff000000081c1c:	aa0003e4 	mov	x4, x0
ffff000000081c20:	910133e0 	add	x0, sp, #0x4c
ffff000000081c24:	aa0003e3 	mov	x3, x0
ffff000000081c28:	f94013e2 	ldr	x2, [sp, #32]
ffff000000081c2c:	d28003c1 	mov	x1, #0x1e                  	// #30
ffff000000081c30:	aa0403e0 	mov	x0, x4
ffff000000081c34:	97ffff8d 	bl	ffff000000081a68 <map_table>
ffff000000081c38:	f9002fe0 	str	x0, [sp, #88]
	if (new_table) {
ffff000000081c3c:	b9404fe0 	ldr	w0, [sp, #76]
ffff000000081c40:	7100001f 	cmp	w0, #0x0
ffff000000081c44:	540001e0 	b.eq	ffff000000081c80 <map_page+0x15c>  // b.none
		task->mm.kernel_pages[++task->mm.kernel_pages_count] = pmd;
ffff000000081c48:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081c4c:	b941a000 	ldr	w0, [x0, #416]
ffff000000081c50:	11000401 	add	w1, w0, #0x1
ffff000000081c54:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081c58:	b901a001 	str	w1, [x0, #416]
ffff000000081c5c:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081c60:	b941a000 	ldr	w0, [x0, #416]
ffff000000081c64:	f94017e1 	ldr	x1, [sp, #40]
ffff000000081c68:	93407c00 	sxtw	x0, w0
ffff000000081c6c:	9100d000 	add	x0, x0, #0x34
ffff000000081c70:	d37df000 	lsl	x0, x0, #3
ffff000000081c74:	8b000020 	add	x0, x1, x0
ffff000000081c78:	f9402fe1 	ldr	x1, [sp, #88]
ffff000000081c7c:	f9000401 	str	x1, [x0, #8]
	}
	/* next level ... */
	unsigned long pte = map_table((unsigned long *)(pmd + VA_START), PMD_SHIFT, va, &new_table);
ffff000000081c80:	f9402fe1 	ldr	x1, [sp, #88]
ffff000000081c84:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff000000081c88:	8b000020 	add	x0, x1, x0
ffff000000081c8c:	aa0003e4 	mov	x4, x0
ffff000000081c90:	910133e0 	add	x0, sp, #0x4c
ffff000000081c94:	aa0003e3 	mov	x3, x0
ffff000000081c98:	f94013e2 	ldr	x2, [sp, #32]
ffff000000081c9c:	d28002a1 	mov	x1, #0x15                  	// #21
ffff000000081ca0:	aa0403e0 	mov	x0, x4
ffff000000081ca4:	97ffff71 	bl	ffff000000081a68 <map_table>
ffff000000081ca8:	f9002be0 	str	x0, [sp, #80]
	if (new_table) {
ffff000000081cac:	b9404fe0 	ldr	w0, [sp, #76]
ffff000000081cb0:	7100001f 	cmp	w0, #0x0
ffff000000081cb4:	540001e0 	b.eq	ffff000000081cf0 <map_page+0x1cc>  // b.none
		task->mm.kernel_pages[++task->mm.kernel_pages_count] = pte;
ffff000000081cb8:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081cbc:	b941a000 	ldr	w0, [x0, #416]
ffff000000081cc0:	11000401 	add	w1, w0, #0x1
ffff000000081cc4:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081cc8:	b901a001 	str	w1, [x0, #416]
ffff000000081ccc:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081cd0:	b941a000 	ldr	w0, [x0, #416]
ffff000000081cd4:	f94017e1 	ldr	x1, [sp, #40]
ffff000000081cd8:	93407c00 	sxtw	x0, w0
ffff000000081cdc:	9100d000 	add	x0, x0, #0x34
ffff000000081ce0:	d37df000 	lsl	x0, x0, #3
ffff000000081ce4:	8b000020 	add	x0, x1, x0
ffff000000081ce8:	f9402be1 	ldr	x1, [sp, #80]
ffff000000081cec:	f9000401 	str	x1, [x0, #8]
	}
	/* reached the bottom level of pgtable tree */
	map_table_entry((unsigned long *)(pte + VA_START), va, page);
ffff000000081cf0:	f9402be1 	ldr	x1, [sp, #80]
ffff000000081cf4:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff000000081cf8:	8b000020 	add	x0, x1, x0
ffff000000081cfc:	f9400fe2 	ldr	x2, [sp, #24]
ffff000000081d00:	f94013e1 	ldr	x1, [sp, #32]
ffff000000081d04:	97ffff42 	bl	ffff000000081a0c <map_table_entry>
	struct user_page p = {page, va};
ffff000000081d08:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081d0c:	f9001fe0 	str	x0, [sp, #56]
ffff000000081d10:	f94013e0 	ldr	x0, [sp, #32]
ffff000000081d14:	f90023e0 	str	x0, [sp, #64]
	task->mm.user_pages[task->mm.user_pages_count++] = p;
ffff000000081d18:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081d1c:	b9409800 	ldr	w0, [x0, #152]
ffff000000081d20:	11000402 	add	w2, w0, #0x1
ffff000000081d24:	f94017e1 	ldr	x1, [sp, #40]
ffff000000081d28:	b9009822 	str	w2, [x1, #152]
ffff000000081d2c:	f94017e1 	ldr	x1, [sp, #40]
ffff000000081d30:	93407c00 	sxtw	x0, w0
ffff000000081d34:	91002800 	add	x0, x0, #0xa
ffff000000081d38:	d37cec00 	lsl	x0, x0, #4
ffff000000081d3c:	8b000022 	add	x2, x1, x0
ffff000000081d40:	a94387e0 	ldp	x0, x1, [sp, #56]
ffff000000081d44:	a9000440 	stp	x0, x1, [x2]
}
ffff000000081d48:	d503201f 	nop
ffff000000081d4c:	a8c77bfd 	ldp	x29, x30, [sp], #112
ffff000000081d50:	d65f03c0 	ret

ffff000000081d54 <copy_virt_memory>:

/* duplicate the contents of the @current task's user pages to the @dst task */
int copy_virt_memory(struct task_struct *dst) {
ffff000000081d54:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff000000081d58:	910003fd 	mov	x29, sp
ffff000000081d5c:	f9000fe0 	str	x0, [sp, #24]
	struct task_struct* src = current;
ffff000000081d60:	90000020 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000081d64:	f9422800 	ldr	x0, [x0, #1104]
ffff000000081d68:	f9400000 	ldr	x0, [x0]
ffff000000081d6c:	f9001be0 	str	x0, [sp, #48]
	for (int i = 0; i < src->mm.user_pages_count; i++) {
ffff000000081d70:	b9003fff 	str	wzr, [sp, #60]
ffff000000081d74:	1400001c 	b	ffff000000081de4 <copy_virt_memory+0x90>
		unsigned long kernel_va = allocate_user_page(dst, src->mm.user_pages[i].virt_addr);
ffff000000081d78:	f9401be1 	ldr	x1, [sp, #48]
ffff000000081d7c:	b9803fe0 	ldrsw	x0, [sp, #60]
ffff000000081d80:	91002800 	add	x0, x0, #0xa
ffff000000081d84:	d37cec00 	lsl	x0, x0, #4
ffff000000081d88:	8b000020 	add	x0, x1, x0
ffff000000081d8c:	f9400400 	ldr	x0, [x0, #8]
ffff000000081d90:	aa0003e1 	mov	x1, x0
ffff000000081d94:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081d98:	97fffed8 	bl	ffff0000000818f8 <allocate_user_page>
ffff000000081d9c:	f90017e0 	str	x0, [sp, #40]
		if( kernel_va == 0) {
ffff000000081da0:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081da4:	f100001f 	cmp	x0, #0x0
ffff000000081da8:	54000061 	b.ne	ffff000000081db4 <copy_virt_memory+0x60>  // b.any
			return -1;
ffff000000081dac:	12800000 	mov	w0, #0xffffffff            	// #-1
ffff000000081db0:	14000013 	b	ffff000000081dfc <copy_virt_memory+0xa8>
		}
		memcpy(src->mm.user_pages[i].virt_addr, kernel_va, PAGE_SIZE);
ffff000000081db4:	f9401be1 	ldr	x1, [sp, #48]
ffff000000081db8:	b9803fe0 	ldrsw	x0, [sp, #60]
ffff000000081dbc:	91002800 	add	x0, x0, #0xa
ffff000000081dc0:	d37cec00 	lsl	x0, x0, #4
ffff000000081dc4:	8b000020 	add	x0, x1, x0
ffff000000081dc8:	f9400400 	ldr	x0, [x0, #8]
ffff000000081dcc:	d2820002 	mov	x2, #0x1000                	// #4096
ffff000000081dd0:	f94017e1 	ldr	x1, [sp, #40]
ffff000000081dd4:	94000adf 	bl	ffff000000084950 <memcpy>
	for (int i = 0; i < src->mm.user_pages_count; i++) {
ffff000000081dd8:	b9403fe0 	ldr	w0, [sp, #60]
ffff000000081ddc:	11000400 	add	w0, w0, #0x1
ffff000000081de0:	b9003fe0 	str	w0, [sp, #60]
ffff000000081de4:	f9401be0 	ldr	x0, [sp, #48]
ffff000000081de8:	b9409800 	ldr	w0, [x0, #152]
ffff000000081dec:	b9403fe1 	ldr	w1, [sp, #60]
ffff000000081df0:	6b00003f 	cmp	w1, w0
ffff000000081df4:	54fffc2b 	b.lt	ffff000000081d78 <copy_virt_memory+0x24>  // b.tstop
	}
	return 0;
ffff000000081df8:	52800000 	mov	w0, #0x0                   	// #0
}
ffff000000081dfc:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff000000081e00:	d65f03c0 	ret

ffff000000081e04 <do_mem_abort>:

static int ind = 1;

int do_mem_abort(unsigned long addr, unsigned long esr) {
ffff000000081e04:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff000000081e08:	910003fd 	mov	x29, sp
ffff000000081e0c:	f9000fe0 	str	x0, [sp, #24]
ffff000000081e10:	f9000be1 	str	x1, [sp, #16]
	unsigned long dfs = (esr & 0b111111);
ffff000000081e14:	f9400be0 	ldr	x0, [sp, #16]
ffff000000081e18:	92401400 	and	x0, x0, #0x3f
ffff000000081e1c:	f90017e0 	str	x0, [sp, #40]
	if ((dfs & 0b111100) == 0b100) {
ffff000000081e20:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081e24:	927e0c00 	and	x0, x0, #0x3c
ffff000000081e28:	f100101f 	cmp	x0, #0x4
ffff000000081e2c:	54000421 	b.ne	ffff000000081eb0 <do_mem_abort+0xac>  // b.any
		unsigned long page = get_free_page();
ffff000000081e30:	97fffec6 	bl	ffff000000081948 <get_free_page>
ffff000000081e34:	f90013e0 	str	x0, [sp, #32]
		if (page == 0) {
ffff000000081e38:	f94013e0 	ldr	x0, [sp, #32]
ffff000000081e3c:	f100001f 	cmp	x0, #0x0
ffff000000081e40:	54000061 	b.ne	ffff000000081e4c <do_mem_abort+0x48>  // b.any
			return -1;
ffff000000081e44:	12800000 	mov	w0, #0xffffffff            	// #-1
ffff000000081e48:	1400001b 	b	ffff000000081eb4 <do_mem_abort+0xb0>
		}
		map_page(current, addr & PAGE_MASK, page);
ffff000000081e4c:	90000020 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000081e50:	f9422800 	ldr	x0, [x0, #1104]
ffff000000081e54:	f9400003 	ldr	x3, [x0]
ffff000000081e58:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081e5c:	9274cc00 	and	x0, x0, #0xfffffffffffff000
ffff000000081e60:	f94013e2 	ldr	x2, [sp, #32]
ffff000000081e64:	aa0003e1 	mov	x1, x0
ffff000000081e68:	aa0303e0 	mov	x0, x3
ffff000000081e6c:	97ffff2e 	bl	ffff000000081b24 <map_page>
		ind++;
ffff000000081e70:	90000020 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000081e74:	91084000 	add	x0, x0, #0x210
ffff000000081e78:	b9400000 	ldr	w0, [x0]
ffff000000081e7c:	11000401 	add	w1, w0, #0x1
ffff000000081e80:	90000020 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000081e84:	91084000 	add	x0, x0, #0x210
ffff000000081e88:	b9000001 	str	w1, [x0]
		if (ind > 2){
ffff000000081e8c:	90000020 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000081e90:	91084000 	add	x0, x0, #0x210
ffff000000081e94:	b9400000 	ldr	w0, [x0]
ffff000000081e98:	7100081f 	cmp	w0, #0x2
ffff000000081e9c:	5400006d 	b.le	ffff000000081ea8 <do_mem_abort+0xa4>
			return -1;
ffff000000081ea0:	12800000 	mov	w0, #0xffffffff            	// #-1
ffff000000081ea4:	14000004 	b	ffff000000081eb4 <do_mem_abort+0xb0>
		}
		return 0;
ffff000000081ea8:	52800000 	mov	w0, #0x0                   	// #0
ffff000000081eac:	14000002 	b	ffff000000081eb4 <do_mem_abort+0xb0>
	}
	return -1;
ffff000000081eb0:	12800000 	mov	w0, #0xffffffff            	// #-1
}
ffff000000081eb4:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff000000081eb8:	d65f03c0 	ret

ffff000000081ebc <uart_send>:
#include "utils.h"
#include "peripherals/mini_uart.h"
#include "peripherals/gpio.h"

void uart_send ( char c )
{
ffff000000081ebc:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff000000081ec0:	910003fd 	mov	x29, sp
ffff000000081ec4:	39007fe0 	strb	w0, [sp, #31]
	while(1) {
		if(get32(AUX_MU_LSR_REG)&0x20) 
ffff000000081ec8:	d28a0a80 	mov	x0, #0x5054                	// #20564
ffff000000081ecc:	f2a7e420 	movk	x0, #0x3f21, lsl #16
ffff000000081ed0:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081ed4:	94000ac1 	bl	ffff0000000849d8 <get32>
ffff000000081ed8:	121b0000 	and	w0, w0, #0x20
ffff000000081edc:	7100001f 	cmp	w0, #0x0
ffff000000081ee0:	54000041 	b.ne	ffff000000081ee8 <uart_send+0x2c>  // b.any
ffff000000081ee4:	17fffff9 	b	ffff000000081ec8 <uart_send+0xc>
			break;
ffff000000081ee8:	d503201f 	nop
	}
	put32(AUX_MU_IO_REG,c);
ffff000000081eec:	39407fe0 	ldrb	w0, [sp, #31]
ffff000000081ef0:	2a0003e1 	mov	w1, w0
ffff000000081ef4:	d28a0800 	mov	x0, #0x5040                	// #20544
ffff000000081ef8:	f2a7e420 	movk	x0, #0x3f21, lsl #16
ffff000000081efc:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081f00:	94000ab4 	bl	ffff0000000849d0 <put32>
}
ffff000000081f04:	d503201f 	nop
ffff000000081f08:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff000000081f0c:	d65f03c0 	ret

ffff000000081f10 <uart_recv>:

char uart_recv ( void )
{
ffff000000081f10:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000081f14:	910003fd 	mov	x29, sp
	while(1) {
		if(get32(AUX_MU_LSR_REG)&0x01) 
ffff000000081f18:	d28a0a80 	mov	x0, #0x5054                	// #20564
ffff000000081f1c:	f2a7e420 	movk	x0, #0x3f21, lsl #16
ffff000000081f20:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081f24:	94000aad 	bl	ffff0000000849d8 <get32>
ffff000000081f28:	12000000 	and	w0, w0, #0x1
ffff000000081f2c:	7100001f 	cmp	w0, #0x0
ffff000000081f30:	54000041 	b.ne	ffff000000081f38 <uart_recv+0x28>  // b.any
ffff000000081f34:	17fffff9 	b	ffff000000081f18 <uart_recv+0x8>
			break;
ffff000000081f38:	d503201f 	nop
	}
	return(get32(AUX_MU_IO_REG)&0xFF);
ffff000000081f3c:	d28a0800 	mov	x0, #0x5040                	// #20544
ffff000000081f40:	f2a7e420 	movk	x0, #0x3f21, lsl #16
ffff000000081f44:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081f48:	94000aa4 	bl	ffff0000000849d8 <get32>
ffff000000081f4c:	12001c00 	and	w0, w0, #0xff
}
ffff000000081f50:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000081f54:	d65f03c0 	ret

ffff000000081f58 <uart_send_string>:

void uart_send_string(char* str)
{
ffff000000081f58:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff000000081f5c:	910003fd 	mov	x29, sp
ffff000000081f60:	f9000fe0 	str	x0, [sp, #24]
	for (int i = 0; str[i] != '\0'; i ++) {
ffff000000081f64:	b9002fff 	str	wzr, [sp, #44]
ffff000000081f68:	14000009 	b	ffff000000081f8c <uart_send_string+0x34>
		uart_send((char)str[i]);
ffff000000081f6c:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff000000081f70:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000081f74:	8b000020 	add	x0, x1, x0
ffff000000081f78:	39400000 	ldrb	w0, [x0]
ffff000000081f7c:	97ffffd0 	bl	ffff000000081ebc <uart_send>
	for (int i = 0; str[i] != '\0'; i ++) {
ffff000000081f80:	b9402fe0 	ldr	w0, [sp, #44]
ffff000000081f84:	11000400 	add	w0, w0, #0x1
ffff000000081f88:	b9002fe0 	str	w0, [sp, #44]
ffff000000081f8c:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff000000081f90:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000081f94:	8b000020 	add	x0, x1, x0
ffff000000081f98:	39400000 	ldrb	w0, [x0]
ffff000000081f9c:	7100001f 	cmp	w0, #0x0
ffff000000081fa0:	54fffe61 	b.ne	ffff000000081f6c <uart_send_string+0x14>  // b.any
	}
}
ffff000000081fa4:	d503201f 	nop
ffff000000081fa8:	d503201f 	nop
ffff000000081fac:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff000000081fb0:	d65f03c0 	ret

ffff000000081fb4 <uart_init>:

void uart_init ( void )
{
ffff000000081fb4:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff000000081fb8:	910003fd 	mov	x29, sp
	unsigned int selector;

	selector = get32(GPFSEL1);
ffff000000081fbc:	d2800080 	mov	x0, #0x4                   	// #4
ffff000000081fc0:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000081fc4:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081fc8:	94000a84 	bl	ffff0000000849d8 <get32>
ffff000000081fcc:	b9001fe0 	str	w0, [sp, #28]
	selector &= ~(7<<12);                   // clean gpio14
ffff000000081fd0:	b9401fe0 	ldr	w0, [sp, #28]
ffff000000081fd4:	12117000 	and	w0, w0, #0xffff8fff
ffff000000081fd8:	b9001fe0 	str	w0, [sp, #28]
	selector |= 2<<12;                      // set alt5 for gpio14
ffff000000081fdc:	b9401fe0 	ldr	w0, [sp, #28]
ffff000000081fe0:	32130000 	orr	w0, w0, #0x2000
ffff000000081fe4:	b9001fe0 	str	w0, [sp, #28]
	selector &= ~(7<<15);                   // clean gpio15
ffff000000081fe8:	b9401fe0 	ldr	w0, [sp, #28]
ffff000000081fec:	120e7000 	and	w0, w0, #0xfffc7fff
ffff000000081ff0:	b9001fe0 	str	w0, [sp, #28]
	selector |= 2<<15;                      // set alt5 for gpio15
ffff000000081ff4:	b9401fe0 	ldr	w0, [sp, #28]
ffff000000081ff8:	32100000 	orr	w0, w0, #0x10000
ffff000000081ffc:	b9001fe0 	str	w0, [sp, #28]
	put32(GPFSEL1,selector);
ffff000000082000:	b9401fe1 	ldr	w1, [sp, #28]
ffff000000082004:	d2800080 	mov	x0, #0x4                   	// #4
ffff000000082008:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff00000008200c:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000082010:	94000a70 	bl	ffff0000000849d0 <put32>

	put32(GPPUD,0);
ffff000000082014:	52800001 	mov	w1, #0x0                   	// #0
ffff000000082018:	d2801280 	mov	x0, #0x94                  	// #148
ffff00000008201c:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000082020:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000082024:	94000a6b 	bl	ffff0000000849d0 <put32>
	delay(150);
ffff000000082028:	d28012c0 	mov	x0, #0x96                  	// #150
ffff00000008202c:	94000a6d 	bl	ffff0000000849e0 <delay>
	put32(GPPUDCLK0,(1<<14)|(1<<15));
ffff000000082030:	52980001 	mov	w1, #0xc000                	// #49152
ffff000000082034:	d2801300 	mov	x0, #0x98                  	// #152
ffff000000082038:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff00000008203c:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000082040:	94000a64 	bl	ffff0000000849d0 <put32>
	delay(150);
ffff000000082044:	d28012c0 	mov	x0, #0x96                  	// #150
ffff000000082048:	94000a66 	bl	ffff0000000849e0 <delay>
	put32(GPPUDCLK0,0);
ffff00000008204c:	52800001 	mov	w1, #0x0                   	// #0
ffff000000082050:	d2801300 	mov	x0, #0x98                  	// #152
ffff000000082054:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000082058:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008205c:	94000a5d 	bl	ffff0000000849d0 <put32>

	put32(AUX_ENABLES,1);                   //Enable mini uart (this also enables access to it registers)
ffff000000082060:	52800021 	mov	w1, #0x1                   	// #1
ffff000000082064:	d28a0080 	mov	x0, #0x5004                	// #20484
ffff000000082068:	f2a7e420 	movk	x0, #0x3f21, lsl #16
ffff00000008206c:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000082070:	94000a58 	bl	ffff0000000849d0 <put32>
	put32(AUX_MU_CNTL_REG,0);               //Disable auto flow control and disable receiver and transmitter (for now)
ffff000000082074:	52800001 	mov	w1, #0x0                   	// #0
ffff000000082078:	d28a0c00 	mov	x0, #0x5060                	// #20576
ffff00000008207c:	f2a7e420 	movk	x0, #0x3f21, lsl #16
ffff000000082080:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000082084:	94000a53 	bl	ffff0000000849d0 <put32>
	put32(AUX_MU_IER_REG,0);                //Disable receive and transmit interrupts
ffff000000082088:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008208c:	d28a0880 	mov	x0, #0x5044                	// #20548
ffff000000082090:	f2a7e420 	movk	x0, #0x3f21, lsl #16
ffff000000082094:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000082098:	94000a4e 	bl	ffff0000000849d0 <put32>
	put32(AUX_MU_LCR_REG,3);                //Enable 8 bit mode
ffff00000008209c:	52800061 	mov	w1, #0x3                   	// #3
ffff0000000820a0:	d28a0980 	mov	x0, #0x504c                	// #20556
ffff0000000820a4:	f2a7e420 	movk	x0, #0x3f21, lsl #16
ffff0000000820a8:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff0000000820ac:	94000a49 	bl	ffff0000000849d0 <put32>
	put32(AUX_MU_MCR_REG,0);                //Set RTS line to be always high
ffff0000000820b0:	52800001 	mov	w1, #0x0                   	// #0
ffff0000000820b4:	d28a0a00 	mov	x0, #0x5050                	// #20560
ffff0000000820b8:	f2a7e420 	movk	x0, #0x3f21, lsl #16
ffff0000000820bc:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff0000000820c0:	94000a44 	bl	ffff0000000849d0 <put32>
	put32(AUX_MU_BAUD_REG,270);             //Set baud rate to 115200
ffff0000000820c4:	528021c1 	mov	w1, #0x10e                 	// #270
ffff0000000820c8:	d28a0d00 	mov	x0, #0x5068                	// #20584
ffff0000000820cc:	f2a7e420 	movk	x0, #0x3f21, lsl #16
ffff0000000820d0:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff0000000820d4:	94000a3f 	bl	ffff0000000849d0 <put32>

	put32(AUX_MU_CNTL_REG,3);               //Finally, enable transmitter and receiver
ffff0000000820d8:	52800061 	mov	w1, #0x3                   	// #3
ffff0000000820dc:	d28a0c00 	mov	x0, #0x5060                	// #20576
ffff0000000820e0:	f2a7e420 	movk	x0, #0x3f21, lsl #16
ffff0000000820e4:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff0000000820e8:	94000a3a 	bl	ffff0000000849d0 <put32>
}
ffff0000000820ec:	d503201f 	nop
ffff0000000820f0:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff0000000820f4:	d65f03c0 	ret

ffff0000000820f8 <putc>:


// This function is required by printf function
void putc ( void* p, char c)
{
ffff0000000820f8:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff0000000820fc:	910003fd 	mov	x29, sp
ffff000000082100:	f9000fe0 	str	x0, [sp, #24]
ffff000000082104:	39005fe1 	strb	w1, [sp, #23]
	uart_send(c);
ffff000000082108:	39405fe0 	ldrb	w0, [sp, #23]
ffff00000008210c:	97ffff6c 	bl	ffff000000081ebc <uart_send>
}
ffff000000082110:	d503201f 	nop
ffff000000082114:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff000000082118:	d65f03c0 	ret

ffff00000008211c <preempt_disable>:
struct task_struct * task[NR_TASKS] = {&(init_task), };
int nr_tasks = 1;

void preempt_disable(void)
{
	current->preempt_count++;
ffff00000008211c:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000082120:	9114a000 	add	x0, x0, #0x528
ffff000000082124:	f9400000 	ldr	x0, [x0]
ffff000000082128:	f9404001 	ldr	x1, [x0, #128]
ffff00000008212c:	91000421 	add	x1, x1, #0x1
ffff000000082130:	f9004001 	str	x1, [x0, #128]
}
ffff000000082134:	d503201f 	nop
ffff000000082138:	d65f03c0 	ret

ffff00000008213c <preempt_enable>:

void preempt_enable(void)
{
	current->preempt_count--;
ffff00000008213c:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000082140:	9114a000 	add	x0, x0, #0x528
ffff000000082144:	f9400000 	ldr	x0, [x0]
ffff000000082148:	f9404001 	ldr	x1, [x0, #128]
ffff00000008214c:	d1000421 	sub	x1, x1, #0x1
ffff000000082150:	f9004001 	str	x1, [x0, #128]
}
ffff000000082154:	d503201f 	nop
ffff000000082158:	d65f03c0 	ret

ffff00000008215c <_schedule>:


void _schedule(void)
{
ffff00000008215c:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff000000082160:	910003fd 	mov	x29, sp
	preempt_disable();
ffff000000082164:	97ffffee 	bl	ffff00000008211c <preempt_disable>
	int next,c;
	struct task_struct * p;
	while (1) {
		c = -1;
ffff000000082168:	12800000 	mov	w0, #0xffffffff            	// #-1
ffff00000008216c:	b9002be0 	str	w0, [sp, #40]
		next = 0;
ffff000000082170:	b9002fff 	str	wzr, [sp, #44]
		for (int i = 0; i < NR_TASKS; i++){
ffff000000082174:	b90027ff 	str	wzr, [sp, #36]
ffff000000082178:	1400001a 	b	ffff0000000821e0 <_schedule+0x84>
			p = task[i];
ffff00000008217c:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000082180:	9114c000 	add	x0, x0, #0x530
ffff000000082184:	b98027e1 	ldrsw	x1, [sp, #36]
ffff000000082188:	f8617800 	ldr	x0, [x0, x1, lsl #3]
ffff00000008218c:	f9000fe0 	str	x0, [sp, #24]
			if (p && p->state == TASK_RUNNING && p->counter > c) {
ffff000000082190:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000082194:	f100001f 	cmp	x0, #0x0
ffff000000082198:	540001e0 	b.eq	ffff0000000821d4 <_schedule+0x78>  // b.none
ffff00000008219c:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000821a0:	f9403400 	ldr	x0, [x0, #104]
ffff0000000821a4:	f100001f 	cmp	x0, #0x0
ffff0000000821a8:	54000161 	b.ne	ffff0000000821d4 <_schedule+0x78>  // b.any
ffff0000000821ac:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000821b0:	f9403801 	ldr	x1, [x0, #112]
ffff0000000821b4:	b9802be0 	ldrsw	x0, [sp, #40]
ffff0000000821b8:	eb00003f 	cmp	x1, x0
ffff0000000821bc:	540000cd 	b.le	ffff0000000821d4 <_schedule+0x78>
				c = p->counter;
ffff0000000821c0:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000821c4:	f9403800 	ldr	x0, [x0, #112]
ffff0000000821c8:	b9002be0 	str	w0, [sp, #40]
				next = i;
ffff0000000821cc:	b94027e0 	ldr	w0, [sp, #36]
ffff0000000821d0:	b9002fe0 	str	w0, [sp, #44]
		for (int i = 0; i < NR_TASKS; i++){
ffff0000000821d4:	b94027e0 	ldr	w0, [sp, #36]
ffff0000000821d8:	11000400 	add	w0, w0, #0x1
ffff0000000821dc:	b90027e0 	str	w0, [sp, #36]
ffff0000000821e0:	b94027e0 	ldr	w0, [sp, #36]
ffff0000000821e4:	7100fc1f 	cmp	w0, #0x3f
ffff0000000821e8:	54fffcad 	b.le	ffff00000008217c <_schedule+0x20>
			}
		}
		if (c) {
ffff0000000821ec:	b9402be0 	ldr	w0, [sp, #40]
ffff0000000821f0:	7100001f 	cmp	w0, #0x0
ffff0000000821f4:	54000341 	b.ne	ffff00000008225c <_schedule+0x100>  // b.any
			break;
		}
		for (int i = 0; i < NR_TASKS; i++) {
ffff0000000821f8:	b90023ff 	str	wzr, [sp, #32]
ffff0000000821fc:	14000014 	b	ffff00000008224c <_schedule+0xf0>
			p = task[i];
ffff000000082200:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000082204:	9114c000 	add	x0, x0, #0x530
ffff000000082208:	b98023e1 	ldrsw	x1, [sp, #32]
ffff00000008220c:	f8617800 	ldr	x0, [x0, x1, lsl #3]
ffff000000082210:	f9000fe0 	str	x0, [sp, #24]
			if (p) {
ffff000000082214:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000082218:	f100001f 	cmp	x0, #0x0
ffff00000008221c:	54000120 	b.eq	ffff000000082240 <_schedule+0xe4>  // b.none
				p->counter = (p->counter >> 1) + p->priority;
ffff000000082220:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000082224:	f9403800 	ldr	x0, [x0, #112]
ffff000000082228:	9341fc01 	asr	x1, x0, #1
ffff00000008222c:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000082230:	f9403c00 	ldr	x0, [x0, #120]
ffff000000082234:	8b000021 	add	x1, x1, x0
ffff000000082238:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008223c:	f9003801 	str	x1, [x0, #112]
		for (int i = 0; i < NR_TASKS; i++) {
ffff000000082240:	b94023e0 	ldr	w0, [sp, #32]
ffff000000082244:	11000400 	add	w0, w0, #0x1
ffff000000082248:	b90023e0 	str	w0, [sp, #32]
ffff00000008224c:	b94023e0 	ldr	w0, [sp, #32]
ffff000000082250:	7100fc1f 	cmp	w0, #0x3f
ffff000000082254:	54fffd6d 	b.le	ffff000000082200 <_schedule+0xa4>
		c = -1;
ffff000000082258:	17ffffc4 	b	ffff000000082168 <_schedule+0xc>
			break;
ffff00000008225c:	d503201f 	nop
			}
		}
	}
	switch_to(task[next]);
ffff000000082260:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000082264:	9114c000 	add	x0, x0, #0x530
ffff000000082268:	b9802fe1 	ldrsw	x1, [sp, #44]
ffff00000008226c:	f8617800 	ldr	x0, [x0, x1, lsl #3]
ffff000000082270:	9400000f 	bl	ffff0000000822ac <switch_to>
	preempt_enable();
ffff000000082274:	97ffffb2 	bl	ffff00000008213c <preempt_enable>
}
ffff000000082278:	d503201f 	nop
ffff00000008227c:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff000000082280:	d65f03c0 	ret

ffff000000082284 <schedule>:

void schedule(void)
{
ffff000000082284:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000082288:	910003fd 	mov	x29, sp
	current->counter = 0;
ffff00000008228c:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000082290:	9114a000 	add	x0, x0, #0x528
ffff000000082294:	f9400000 	ldr	x0, [x0]
ffff000000082298:	f900381f 	str	xzr, [x0, #112]
	_schedule();
ffff00000008229c:	97ffffb0 	bl	ffff00000008215c <_schedule>
}
ffff0000000822a0:	d503201f 	nop
ffff0000000822a4:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff0000000822a8:	d65f03c0 	ret

ffff0000000822ac <switch_to>:


void switch_to(struct task_struct * next) 
{
ffff0000000822ac:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff0000000822b0:	910003fd 	mov	x29, sp
ffff0000000822b4:	f9000fe0 	str	x0, [sp, #24]
	if (current == next) 
ffff0000000822b8:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff0000000822bc:	9114a000 	add	x0, x0, #0x528
ffff0000000822c0:	f9400000 	ldr	x0, [x0]
ffff0000000822c4:	f9400fe1 	ldr	x1, [sp, #24]
ffff0000000822c8:	eb00003f 	cmp	x1, x0
ffff0000000822cc:	54000200 	b.eq	ffff00000008230c <switch_to+0x60>  // b.none
		return;
	struct task_struct * prev = current;
ffff0000000822d0:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff0000000822d4:	9114a000 	add	x0, x0, #0x528
ffff0000000822d8:	f9400000 	ldr	x0, [x0]
ffff0000000822dc:	f90017e0 	str	x0, [sp, #40]
	current = next;
ffff0000000822e0:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff0000000822e4:	9114a000 	add	x0, x0, #0x528
ffff0000000822e8:	f9400fe1 	ldr	x1, [sp, #24]
ffff0000000822ec:	f9000001 	str	x1, [x0]
	set_pgd(next->mm.pgd);
ffff0000000822f0:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000822f4:	f9404800 	ldr	x0, [x0, #144]
ffff0000000822f8:	940009bd 	bl	ffff0000000849ec <set_pgd>
	cpu_switch_to(prev, next);
ffff0000000822fc:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000082300:	f94017e0 	ldr	x0, [sp, #40]
ffff000000082304:	9400099c 	bl	ffff000000084974 <cpu_switch_to>
ffff000000082308:	14000002 	b	ffff000000082310 <switch_to+0x64>
		return;
ffff00000008230c:	d503201f 	nop
}
ffff000000082310:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff000000082314:	d65f03c0 	ret

ffff000000082318 <schedule_tail>:

void schedule_tail(void) {
ffff000000082318:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff00000008231c:	910003fd 	mov	x29, sp
	preempt_enable();
ffff000000082320:	97ffff87 	bl	ffff00000008213c <preempt_enable>
}
ffff000000082324:	d503201f 	nop
ffff000000082328:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff00000008232c:	d65f03c0 	ret

ffff000000082330 <timer_tick>:


void timer_tick()
{
ffff000000082330:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000082334:	910003fd 	mov	x29, sp
	--current->counter;
ffff000000082338:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff00000008233c:	9114a000 	add	x0, x0, #0x528
ffff000000082340:	f9400000 	ldr	x0, [x0]
ffff000000082344:	f9403801 	ldr	x1, [x0, #112]
ffff000000082348:	d1000421 	sub	x1, x1, #0x1
ffff00000008234c:	f9003801 	str	x1, [x0, #112]
	if (current->counter>0 || current->preempt_count >0) {
ffff000000082350:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000082354:	9114a000 	add	x0, x0, #0x528
ffff000000082358:	f9400000 	ldr	x0, [x0]
ffff00000008235c:	f9403800 	ldr	x0, [x0, #112]
ffff000000082360:	f100001f 	cmp	x0, #0x0
ffff000000082364:	540001ec 	b.gt	ffff0000000823a0 <timer_tick+0x70>
ffff000000082368:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff00000008236c:	9114a000 	add	x0, x0, #0x528
ffff000000082370:	f9400000 	ldr	x0, [x0]
ffff000000082374:	f9404000 	ldr	x0, [x0, #128]
ffff000000082378:	f100001f 	cmp	x0, #0x0
ffff00000008237c:	5400012c 	b.gt	ffff0000000823a0 <timer_tick+0x70>
		return;
	}
	current->counter=0;
ffff000000082380:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000082384:	9114a000 	add	x0, x0, #0x528
ffff000000082388:	f9400000 	ldr	x0, [x0]
ffff00000008238c:	f900381f 	str	xzr, [x0, #112]
	enable_irq();
ffff000000082390:	9400096c 	bl	ffff000000084940 <enable_irq>
	_schedule();
ffff000000082394:	97ffff72 	bl	ffff00000008215c <_schedule>
	disable_irq();
ffff000000082398:	9400096c 	bl	ffff000000084948 <disable_irq>
ffff00000008239c:	14000002 	b	ffff0000000823a4 <timer_tick+0x74>
		return;
ffff0000000823a0:	d503201f 	nop
}
ffff0000000823a4:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff0000000823a8:	d65f03c0 	ret

ffff0000000823ac <exit_process>:

void exit_process(){
ffff0000000823ac:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff0000000823b0:	910003fd 	mov	x29, sp
	preempt_disable();
ffff0000000823b4:	97ffff5a 	bl	ffff00000008211c <preempt_disable>
	for (int i = 0; i < NR_TASKS; i++){
ffff0000000823b8:	b9001fff 	str	wzr, [sp, #28]
ffff0000000823bc:	14000014 	b	ffff00000008240c <exit_process+0x60>
		if (task[i] == current) {
ffff0000000823c0:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff0000000823c4:	9114c000 	add	x0, x0, #0x530
ffff0000000823c8:	b9801fe1 	ldrsw	x1, [sp, #28]
ffff0000000823cc:	f8617801 	ldr	x1, [x0, x1, lsl #3]
ffff0000000823d0:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff0000000823d4:	9114a000 	add	x0, x0, #0x528
ffff0000000823d8:	f9400000 	ldr	x0, [x0]
ffff0000000823dc:	eb00003f 	cmp	x1, x0
ffff0000000823e0:	54000101 	b.ne	ffff000000082400 <exit_process+0x54>  // b.any
			task[i]->state = TASK_ZOMBIE;
ffff0000000823e4:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff0000000823e8:	9114c000 	add	x0, x0, #0x530
ffff0000000823ec:	b9801fe1 	ldrsw	x1, [sp, #28]
ffff0000000823f0:	f8617800 	ldr	x0, [x0, x1, lsl #3]
ffff0000000823f4:	d2800021 	mov	x1, #0x1                   	// #1
ffff0000000823f8:	f9003401 	str	x1, [x0, #104]
			break;
ffff0000000823fc:	14000007 	b	ffff000000082418 <exit_process+0x6c>
	for (int i = 0; i < NR_TASKS; i++){
ffff000000082400:	b9401fe0 	ldr	w0, [sp, #28]
ffff000000082404:	11000400 	add	w0, w0, #0x1
ffff000000082408:	b9001fe0 	str	w0, [sp, #28]
ffff00000008240c:	b9401fe0 	ldr	w0, [sp, #28]
ffff000000082410:	7100fc1f 	cmp	w0, #0x3f
ffff000000082414:	54fffd6d 	b.le	ffff0000000823c0 <exit_process+0x14>
		}
	}
	preempt_enable();
ffff000000082418:	97ffff49 	bl	ffff00000008213c <preempt_enable>
	schedule();
ffff00000008241c:	97ffff9a 	bl	ffff000000082284 <schedule>
}
ffff000000082420:	d503201f 	nop
ffff000000082424:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff000000082428:	d65f03c0 	ret

ffff00000008242c <sys_write>:
#include "utils.h"
#include "sched.h"
#include "mm.h"


void sys_write(char * buf){
ffff00000008242c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff000000082430:	910003fd 	mov	x29, sp
ffff000000082434:	f9000fe0 	str	x0, [sp, #24]
	printf(buf);
ffff000000082438:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008243c:	940002cb 	bl	ffff000000082f68 <tfp_printf>
}
ffff000000082440:	d503201f 	nop
ffff000000082444:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff000000082448:	d65f03c0 	ret

ffff00000008244c <sys_fork>:

int sys_fork(){
ffff00000008244c:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000082450:	910003fd 	mov	x29, sp
	return copy_process(0, 0, 0);
ffff000000082454:	d2800002 	mov	x2, #0x0                   	// #0
ffff000000082458:	d2800001 	mov	x1, #0x0                   	// #0
ffff00000008245c:	d2800000 	mov	x0, #0x0                   	// #0
ffff000000082460:	94000043 	bl	ffff00000008256c <copy_process>
}
ffff000000082464:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000082468:	d65f03c0 	ret

ffff00000008246c <sys_exit>:

void sys_exit(){
ffff00000008246c:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000082470:	910003fd 	mov	x29, sp
	exit_process();
ffff000000082474:	97ffffce 	bl	ffff0000000823ac <exit_process>
}
ffff000000082478:	d503201f 	nop
ffff00000008247c:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000082480:	d65f03c0 	ret

ffff000000082484 <timer_init>:
	cf: 
	https://fxlin.github.io/p1-kernel/exp3/rpi-os/#fyi-other-timers-on-rpi3
*/

void timer_init ( void )
{
ffff000000082484:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000082488:	910003fd 	mov	x29, sp
	curVal = get32(TIMER_CLO);
ffff00000008248c:	d2860080 	mov	x0, #0x3004                	// #12292
ffff000000082490:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff000000082494:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000082498:	94000950 	bl	ffff0000000849d8 <get32>
ffff00000008249c:	2a0003e1 	mov	w1, w0
ffff0000000824a0:	90000400 	adrp	x0, ffff000000102000 <mem_map+0x7c8b8>
ffff0000000824a4:	913d2000 	add	x0, x0, #0xf48
ffff0000000824a8:	b9000001 	str	w1, [x0]
	curVal += interval;
ffff0000000824ac:	90000400 	adrp	x0, ffff000000102000 <mem_map+0x7c8b8>
ffff0000000824b0:	913d2000 	add	x0, x0, #0xf48
ffff0000000824b4:	b9400001 	ldr	w1, [x0]
ffff0000000824b8:	5281a800 	mov	w0, #0xd40                 	// #3392
ffff0000000824bc:	72a00060 	movk	w0, #0x3, lsl #16
ffff0000000824c0:	0b000021 	add	w1, w1, w0
ffff0000000824c4:	90000400 	adrp	x0, ffff000000102000 <mem_map+0x7c8b8>
ffff0000000824c8:	913d2000 	add	x0, x0, #0xf48
ffff0000000824cc:	b9000001 	str	w1, [x0]
	put32(TIMER_C1, curVal);
ffff0000000824d0:	90000400 	adrp	x0, ffff000000102000 <mem_map+0x7c8b8>
ffff0000000824d4:	913d2000 	add	x0, x0, #0xf48
ffff0000000824d8:	b9400000 	ldr	w0, [x0]
ffff0000000824dc:	2a0003e1 	mov	w1, w0
ffff0000000824e0:	d2860200 	mov	x0, #0x3010                	// #12304
ffff0000000824e4:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff0000000824e8:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff0000000824ec:	94000939 	bl	ffff0000000849d0 <put32>
}
ffff0000000824f0:	d503201f 	nop
ffff0000000824f4:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff0000000824f8:	d65f03c0 	ret

ffff0000000824fc <handle_timer_irq>:

void handle_timer_irq( void ) 
{
ffff0000000824fc:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000082500:	910003fd 	mov	x29, sp
	curVal += interval;
ffff000000082504:	90000400 	adrp	x0, ffff000000102000 <mem_map+0x7c8b8>
ffff000000082508:	913d2000 	add	x0, x0, #0xf48
ffff00000008250c:	b9400001 	ldr	w1, [x0]
ffff000000082510:	5281a800 	mov	w0, #0xd40                 	// #3392
ffff000000082514:	72a00060 	movk	w0, #0x3, lsl #16
ffff000000082518:	0b000021 	add	w1, w1, w0
ffff00000008251c:	90000400 	adrp	x0, ffff000000102000 <mem_map+0x7c8b8>
ffff000000082520:	913d2000 	add	x0, x0, #0xf48
ffff000000082524:	b9000001 	str	w1, [x0]
	put32(TIMER_C1, curVal);
ffff000000082528:	90000400 	adrp	x0, ffff000000102000 <mem_map+0x7c8b8>
ffff00000008252c:	913d2000 	add	x0, x0, #0xf48
ffff000000082530:	b9400000 	ldr	w0, [x0]
ffff000000082534:	2a0003e1 	mov	w1, w0
ffff000000082538:	d2860200 	mov	x0, #0x3010                	// #12304
ffff00000008253c:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff000000082540:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000082544:	94000923 	bl	ffff0000000849d0 <put32>
	put32(TIMER_CS, TIMER_CS_M1);
ffff000000082548:	52800041 	mov	w1, #0x2                   	// #2
ffff00000008254c:	d2860000 	mov	x0, #0x3000                	// #12288
ffff000000082550:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff000000082554:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000082558:	9400091e 	bl	ffff0000000849d0 <put32>
	timer_tick();
ffff00000008255c:	97ffff75 	bl	ffff000000082330 <timer_tick>
}
ffff000000082560:	d503201f 	nop
ffff000000082564:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000082568:	d65f03c0 	ret

ffff00000008256c <copy_process>:
#include "fork.h"
#include "utils.h"
#include "entry.h"

int copy_process(unsigned long clone_flags, unsigned long fn, unsigned long arg)
{
ffff00000008256c:	a9ba7bfd 	stp	x29, x30, [sp, #-96]!
ffff000000082570:	910003fd 	mov	x29, sp
ffff000000082574:	f90017e0 	str	x0, [sp, #40]
ffff000000082578:	f90013e1 	str	x1, [sp, #32]
ffff00000008257c:	f9000fe2 	str	x2, [sp, #24]
	preempt_disable();
ffff000000082580:	97fffee7 	bl	ffff00000008211c <preempt_disable>
	struct task_struct *p;

	unsigned long page = allocate_kernel_page();
ffff000000082584:	97fffccf 	bl	ffff0000000818c0 <allocate_kernel_page>
ffff000000082588:	f9002fe0 	str	x0, [sp, #88]
	p = (struct task_struct *) page;
ffff00000008258c:	f9402fe0 	ldr	x0, [sp, #88]
ffff000000082590:	f9002be0 	str	x0, [sp, #80]
	struct pt_regs *childregs = task_pt_regs(p);
ffff000000082594:	f9402be0 	ldr	x0, [sp, #80]
ffff000000082598:	94000076 	bl	ffff000000082770 <task_pt_regs>
ffff00000008259c:	f90027e0 	str	x0, [sp, #72]

	if (!p)
ffff0000000825a0:	f9402be0 	ldr	x0, [sp, #80]
ffff0000000825a4:	f100001f 	cmp	x0, #0x0
ffff0000000825a8:	54000061 	b.ne	ffff0000000825b4 <copy_process+0x48>  // b.any
		return -1;
ffff0000000825ac:	12800000 	mov	w0, #0xffffffff            	// #-1
ffff0000000825b0:	14000045 	b	ffff0000000826c4 <copy_process+0x158>

	if (clone_flags & PF_KTHREAD) {
ffff0000000825b4:	f94017e0 	ldr	x0, [sp, #40]
ffff0000000825b8:	927f0000 	and	x0, x0, #0x2
ffff0000000825bc:	f100001f 	cmp	x0, #0x0
ffff0000000825c0:	54000100 	b.eq	ffff0000000825e0 <copy_process+0x74>  // b.none
		p->cpu_context.x19 = fn;
ffff0000000825c4:	f9402be0 	ldr	x0, [sp, #80]
ffff0000000825c8:	f94013e1 	ldr	x1, [sp, #32]
ffff0000000825cc:	f9000001 	str	x1, [x0]
		p->cpu_context.x20 = arg;
ffff0000000825d0:	f9402be0 	ldr	x0, [sp, #80]
ffff0000000825d4:	f9400fe1 	ldr	x1, [sp, #24]
ffff0000000825d8:	f9000401 	str	x1, [x0, #8]
ffff0000000825dc:	14000012 	b	ffff000000082624 <copy_process+0xb8>
	} else {
		struct pt_regs * cur_regs = task_pt_regs(current);
ffff0000000825e0:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff0000000825e4:	f9422800 	ldr	x0, [x0, #1104]
ffff0000000825e8:	f9400000 	ldr	x0, [x0]
ffff0000000825ec:	94000061 	bl	ffff000000082770 <task_pt_regs>
ffff0000000825f0:	f90023e0 	str	x0, [sp, #64]
		*cur_regs = *childregs;
ffff0000000825f4:	f94023e1 	ldr	x1, [sp, #64]
ffff0000000825f8:	f94027e0 	ldr	x0, [sp, #72]
ffff0000000825fc:	aa0103e3 	mov	x3, x1
ffff000000082600:	aa0003e1 	mov	x1, x0
ffff000000082604:	d2802200 	mov	x0, #0x110                 	// #272
ffff000000082608:	aa0003e2 	mov	x2, x0
ffff00000008260c:	aa0303e0 	mov	x0, x3
ffff000000082610:	940008d0 	bl	ffff000000084950 <memcpy>
		childregs->regs[0] = 0;
ffff000000082614:	f94027e0 	ldr	x0, [sp, #72]
ffff000000082618:	f900001f 	str	xzr, [x0]
		copy_virt_memory(p);
ffff00000008261c:	f9402be0 	ldr	x0, [sp, #80]
ffff000000082620:	97fffdcd 	bl	ffff000000081d54 <copy_virt_memory>
	}
	p->flags = clone_flags;
ffff000000082624:	f9402be0 	ldr	x0, [sp, #80]
ffff000000082628:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008262c:	f9004401 	str	x1, [x0, #136]
	p->priority = current->priority;
ffff000000082630:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000082634:	f9422800 	ldr	x0, [x0, #1104]
ffff000000082638:	f9400000 	ldr	x0, [x0]
ffff00000008263c:	f9403c01 	ldr	x1, [x0, #120]
ffff000000082640:	f9402be0 	ldr	x0, [sp, #80]
ffff000000082644:	f9003c01 	str	x1, [x0, #120]
	p->state = TASK_RUNNING;
ffff000000082648:	f9402be0 	ldr	x0, [sp, #80]
ffff00000008264c:	f900341f 	str	xzr, [x0, #104]
	p->counter = p->priority;
ffff000000082650:	f9402be0 	ldr	x0, [sp, #80]
ffff000000082654:	f9403c01 	ldr	x1, [x0, #120]
ffff000000082658:	f9402be0 	ldr	x0, [sp, #80]
ffff00000008265c:	f9003801 	str	x1, [x0, #112]
	p->preempt_count = 1; //disable preemtion until schedule_tail
ffff000000082660:	f9402be0 	ldr	x0, [sp, #80]
ffff000000082664:	d2800021 	mov	x1, #0x1                   	// #1
ffff000000082668:	f9004001 	str	x1, [x0, #128]

	p->cpu_context.pc = (unsigned long)ret_from_fork;
ffff00000008266c:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000082670:	f9423c01 	ldr	x1, [x0, #1144]
ffff000000082674:	f9402be0 	ldr	x0, [sp, #80]
ffff000000082678:	f9003001 	str	x1, [x0, #96]
	p->cpu_context.sp = (unsigned long)childregs;
ffff00000008267c:	f94027e1 	ldr	x1, [sp, #72]
ffff000000082680:	f9402be0 	ldr	x0, [sp, #80]
ffff000000082684:	f9002c01 	str	x1, [x0, #88]
	int pid = nr_tasks++;
ffff000000082688:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff00000008268c:	f9422c00 	ldr	x0, [x0, #1112]
ffff000000082690:	b9400000 	ldr	w0, [x0]
ffff000000082694:	11000402 	add	w2, w0, #0x1
ffff000000082698:	f0000001 	adrp	x1, ffff000000085000 <interval+0x42c>
ffff00000008269c:	f9422c21 	ldr	x1, [x1, #1112]
ffff0000000826a0:	b9000022 	str	w2, [x1]
ffff0000000826a4:	b9003fe0 	str	w0, [sp, #60]
	task[pid] = p;	
ffff0000000826a8:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff0000000826ac:	f9423000 	ldr	x0, [x0, #1120]
ffff0000000826b0:	b9803fe1 	ldrsw	x1, [sp, #60]
ffff0000000826b4:	f9402be2 	ldr	x2, [sp, #80]
ffff0000000826b8:	f8217802 	str	x2, [x0, x1, lsl #3]

	preempt_enable();
ffff0000000826bc:	97fffea0 	bl	ffff00000008213c <preempt_enable>
	return pid;
ffff0000000826c0:	b9403fe0 	ldr	w0, [sp, #60]
}
ffff0000000826c4:	a8c67bfd 	ldp	x29, x30, [sp], #96
ffff0000000826c8:	d65f03c0 	ret

ffff0000000826cc <move_to_user_mode>:
   @size: size of the area 
   @pc: offset of the startup function inside the area
*/   

int move_to_user_mode(unsigned long start, unsigned long size, unsigned long pc)
{
ffff0000000826cc:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff0000000826d0:	910003fd 	mov	x29, sp
ffff0000000826d4:	f90017e0 	str	x0, [sp, #40]
ffff0000000826d8:	f90013e1 	str	x1, [sp, #32]
ffff0000000826dc:	f9000fe2 	str	x2, [sp, #24]
	struct pt_regs *regs = task_pt_regs(current);
ffff0000000826e0:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff0000000826e4:	f9422800 	ldr	x0, [x0, #1104]
ffff0000000826e8:	f9400000 	ldr	x0, [x0]
ffff0000000826ec:	94000021 	bl	ffff000000082770 <task_pt_regs>
ffff0000000826f0:	f9001fe0 	str	x0, [sp, #56]
	regs->pstate = PSR_MODE_EL0t;
ffff0000000826f4:	f9401fe0 	ldr	x0, [sp, #56]
ffff0000000826f8:	f900841f 	str	xzr, [x0, #264]
	regs->pc = pc;
ffff0000000826fc:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000082700:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000082704:	f9008001 	str	x1, [x0, #256]
	regs->sp = 2 *  PAGE_SIZE;  
ffff000000082708:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008270c:	d2840001 	mov	x1, #0x2000                	// #8192
ffff000000082710:	f9007c01 	str	x1, [x0, #248]
	unsigned long code_page = allocate_user_page(current, 0);
ffff000000082714:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000082718:	f9422800 	ldr	x0, [x0, #1104]
ffff00000008271c:	f9400000 	ldr	x0, [x0]
ffff000000082720:	d2800001 	mov	x1, #0x0                   	// #0
ffff000000082724:	97fffc75 	bl	ffff0000000818f8 <allocate_user_page>
ffff000000082728:	f9001be0 	str	x0, [sp, #48]
	if (code_page == 0)	{
ffff00000008272c:	f9401be0 	ldr	x0, [sp, #48]
ffff000000082730:	f100001f 	cmp	x0, #0x0
ffff000000082734:	54000061 	b.ne	ffff000000082740 <move_to_user_mode+0x74>  // b.any
		return -1;
ffff000000082738:	12800000 	mov	w0, #0xffffffff            	// #-1
ffff00000008273c:	1400000b 	b	ffff000000082768 <move_to_user_mode+0x9c>
	}
	memcpy(start, code_page, size); /* NB: arg1-src; arg2-dest */
ffff000000082740:	f94013e2 	ldr	x2, [sp, #32]
ffff000000082744:	f9401be1 	ldr	x1, [sp, #48]
ffff000000082748:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008274c:	94000881 	bl	ffff000000084950 <memcpy>
	set_pgd(current->mm.pgd);
ffff000000082750:	f0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000082754:	f9422800 	ldr	x0, [x0, #1104]
ffff000000082758:	f9400000 	ldr	x0, [x0]
ffff00000008275c:	f9404800 	ldr	x0, [x0, #144]
ffff000000082760:	940008a3 	bl	ffff0000000849ec <set_pgd>
	return 0;
ffff000000082764:	52800000 	mov	w0, #0x0                   	// #0
}
ffff000000082768:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008276c:	d65f03c0 	ret

ffff000000082770 <task_pt_regs>:

struct pt_regs * task_pt_regs(struct task_struct *tsk)
{
ffff000000082770:	d10083ff 	sub	sp, sp, #0x20
ffff000000082774:	f90007e0 	str	x0, [sp, #8]
	unsigned long p = (unsigned long)tsk + THREAD_SIZE - sizeof(struct pt_regs);
ffff000000082778:	f94007e0 	ldr	x0, [sp, #8]
ffff00000008277c:	913bc000 	add	x0, x0, #0xef0
ffff000000082780:	f9000fe0 	str	x0, [sp, #24]
	return (struct pt_regs *)p;
ffff000000082784:	f9400fe0 	ldr	x0, [sp, #24]
}
ffff000000082788:	910083ff 	add	sp, sp, #0x20
ffff00000008278c:	d65f03c0 	ret

ffff000000082790 <ui2a>:
    }

#endif

static void ui2a(unsigned int num, unsigned int base, int uc,char * bf)
    {
ffff000000082790:	d100c3ff 	sub	sp, sp, #0x30
ffff000000082794:	b9001fe0 	str	w0, [sp, #28]
ffff000000082798:	b9001be1 	str	w1, [sp, #24]
ffff00000008279c:	b90017e2 	str	w2, [sp, #20]
ffff0000000827a0:	f90007e3 	str	x3, [sp, #8]
    int n=0;
ffff0000000827a4:	b9002fff 	str	wzr, [sp, #44]
    unsigned int d=1;
ffff0000000827a8:	52800020 	mov	w0, #0x1                   	// #1
ffff0000000827ac:	b9002be0 	str	w0, [sp, #40]
    while (num/d >= base)
ffff0000000827b0:	14000005 	b	ffff0000000827c4 <ui2a+0x34>
        d*=base;
ffff0000000827b4:	b9402be1 	ldr	w1, [sp, #40]
ffff0000000827b8:	b9401be0 	ldr	w0, [sp, #24]
ffff0000000827bc:	1b007c20 	mul	w0, w1, w0
ffff0000000827c0:	b9002be0 	str	w0, [sp, #40]
    while (num/d >= base)
ffff0000000827c4:	b9401fe1 	ldr	w1, [sp, #28]
ffff0000000827c8:	b9402be0 	ldr	w0, [sp, #40]
ffff0000000827cc:	1ac00820 	udiv	w0, w1, w0
ffff0000000827d0:	b9401be1 	ldr	w1, [sp, #24]
ffff0000000827d4:	6b00003f 	cmp	w1, w0
ffff0000000827d8:	54fffee9 	b.ls	ffff0000000827b4 <ui2a+0x24>  // b.plast
    while (d!=0) {
ffff0000000827dc:	1400002f 	b	ffff000000082898 <ui2a+0x108>
        int dgt = num / d;
ffff0000000827e0:	b9401fe1 	ldr	w1, [sp, #28]
ffff0000000827e4:	b9402be0 	ldr	w0, [sp, #40]
ffff0000000827e8:	1ac00820 	udiv	w0, w1, w0
ffff0000000827ec:	b90027e0 	str	w0, [sp, #36]
        num%= d;
ffff0000000827f0:	b9401fe0 	ldr	w0, [sp, #28]
ffff0000000827f4:	b9402be1 	ldr	w1, [sp, #40]
ffff0000000827f8:	1ac10802 	udiv	w2, w0, w1
ffff0000000827fc:	b9402be1 	ldr	w1, [sp, #40]
ffff000000082800:	1b017c41 	mul	w1, w2, w1
ffff000000082804:	4b010000 	sub	w0, w0, w1
ffff000000082808:	b9001fe0 	str	w0, [sp, #28]
        d/=base;
ffff00000008280c:	b9402be1 	ldr	w1, [sp, #40]
ffff000000082810:	b9401be0 	ldr	w0, [sp, #24]
ffff000000082814:	1ac00820 	udiv	w0, w1, w0
ffff000000082818:	b9002be0 	str	w0, [sp, #40]
        if (n || dgt>0 || d==0) {
ffff00000008281c:	b9402fe0 	ldr	w0, [sp, #44]
ffff000000082820:	7100001f 	cmp	w0, #0x0
ffff000000082824:	540000e1 	b.ne	ffff000000082840 <ui2a+0xb0>  // b.any
ffff000000082828:	b94027e0 	ldr	w0, [sp, #36]
ffff00000008282c:	7100001f 	cmp	w0, #0x0
ffff000000082830:	5400008c 	b.gt	ffff000000082840 <ui2a+0xb0>
ffff000000082834:	b9402be0 	ldr	w0, [sp, #40]
ffff000000082838:	7100001f 	cmp	w0, #0x0
ffff00000008283c:	540002e1 	b.ne	ffff000000082898 <ui2a+0x108>  // b.any
            *bf++ = dgt+(dgt<10 ? '0' : (uc ? 'A' : 'a')-10);
ffff000000082840:	b94027e0 	ldr	w0, [sp, #36]
ffff000000082844:	7100241f 	cmp	w0, #0x9
ffff000000082848:	5400010d 	b.le	ffff000000082868 <ui2a+0xd8>
ffff00000008284c:	b94017e0 	ldr	w0, [sp, #20]
ffff000000082850:	7100001f 	cmp	w0, #0x0
ffff000000082854:	54000060 	b.eq	ffff000000082860 <ui2a+0xd0>  // b.none
ffff000000082858:	528006e0 	mov	w0, #0x37                  	// #55
ffff00000008285c:	14000004 	b	ffff00000008286c <ui2a+0xdc>
ffff000000082860:	52800ae0 	mov	w0, #0x57                  	// #87
ffff000000082864:	14000002 	b	ffff00000008286c <ui2a+0xdc>
ffff000000082868:	52800600 	mov	w0, #0x30                  	// #48
ffff00000008286c:	b94027e1 	ldr	w1, [sp, #36]
ffff000000082870:	12001c22 	and	w2, w1, #0xff
ffff000000082874:	f94007e1 	ldr	x1, [sp, #8]
ffff000000082878:	91000423 	add	x3, x1, #0x1
ffff00000008287c:	f90007e3 	str	x3, [sp, #8]
ffff000000082880:	0b020000 	add	w0, w0, w2
ffff000000082884:	12001c00 	and	w0, w0, #0xff
ffff000000082888:	39000020 	strb	w0, [x1]
            ++n;
ffff00000008288c:	b9402fe0 	ldr	w0, [sp, #44]
ffff000000082890:	11000400 	add	w0, w0, #0x1
ffff000000082894:	b9002fe0 	str	w0, [sp, #44]
    while (d!=0) {
ffff000000082898:	b9402be0 	ldr	w0, [sp, #40]
ffff00000008289c:	7100001f 	cmp	w0, #0x0
ffff0000000828a0:	54fffa01 	b.ne	ffff0000000827e0 <ui2a+0x50>  // b.any
            }
        }
    *bf=0;
ffff0000000828a4:	f94007e0 	ldr	x0, [sp, #8]
ffff0000000828a8:	3900001f 	strb	wzr, [x0]
    }
ffff0000000828ac:	d503201f 	nop
ffff0000000828b0:	9100c3ff 	add	sp, sp, #0x30
ffff0000000828b4:	d65f03c0 	ret

ffff0000000828b8 <i2a>:

static void i2a (int num, char * bf)
    {
ffff0000000828b8:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff0000000828bc:	910003fd 	mov	x29, sp
ffff0000000828c0:	b9001fe0 	str	w0, [sp, #28]
ffff0000000828c4:	f9000be1 	str	x1, [sp, #16]
    if (num<0) {
ffff0000000828c8:	b9401fe0 	ldr	w0, [sp, #28]
ffff0000000828cc:	7100001f 	cmp	w0, #0x0
ffff0000000828d0:	5400012a 	b.ge	ffff0000000828f4 <i2a+0x3c>  // b.tcont
        num=-num;
ffff0000000828d4:	b9401fe0 	ldr	w0, [sp, #28]
ffff0000000828d8:	4b0003e0 	neg	w0, w0
ffff0000000828dc:	b9001fe0 	str	w0, [sp, #28]
        *bf++ = '-';
ffff0000000828e0:	f9400be0 	ldr	x0, [sp, #16]
ffff0000000828e4:	91000401 	add	x1, x0, #0x1
ffff0000000828e8:	f9000be1 	str	x1, [sp, #16]
ffff0000000828ec:	528005a1 	mov	w1, #0x2d                  	// #45
ffff0000000828f0:	39000001 	strb	w1, [x0]
        }
    ui2a(num,10,0,bf);
ffff0000000828f4:	b9401fe0 	ldr	w0, [sp, #28]
ffff0000000828f8:	f9400be3 	ldr	x3, [sp, #16]
ffff0000000828fc:	52800002 	mov	w2, #0x0                   	// #0
ffff000000082900:	52800141 	mov	w1, #0xa                   	// #10
ffff000000082904:	97ffffa3 	bl	ffff000000082790 <ui2a>
    }
ffff000000082908:	d503201f 	nop
ffff00000008290c:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff000000082910:	d65f03c0 	ret

ffff000000082914 <a2d>:

static int a2d(char ch)
    {
ffff000000082914:	d10043ff 	sub	sp, sp, #0x10
ffff000000082918:	39003fe0 	strb	w0, [sp, #15]
    if (ch>='0' && ch<='9')
ffff00000008291c:	39403fe0 	ldrb	w0, [sp, #15]
ffff000000082920:	7100bc1f 	cmp	w0, #0x2f
ffff000000082924:	540000e9 	b.ls	ffff000000082940 <a2d+0x2c>  // b.plast
ffff000000082928:	39403fe0 	ldrb	w0, [sp, #15]
ffff00000008292c:	7100e41f 	cmp	w0, #0x39
ffff000000082930:	54000088 	b.hi	ffff000000082940 <a2d+0x2c>  // b.pmore
        return ch-'0';
ffff000000082934:	39403fe0 	ldrb	w0, [sp, #15]
ffff000000082938:	5100c000 	sub	w0, w0, #0x30
ffff00000008293c:	14000014 	b	ffff00000008298c <a2d+0x78>
    else if (ch>='a' && ch<='f')
ffff000000082940:	39403fe0 	ldrb	w0, [sp, #15]
ffff000000082944:	7101801f 	cmp	w0, #0x60
ffff000000082948:	540000e9 	b.ls	ffff000000082964 <a2d+0x50>  // b.plast
ffff00000008294c:	39403fe0 	ldrb	w0, [sp, #15]
ffff000000082950:	7101981f 	cmp	w0, #0x66
ffff000000082954:	54000088 	b.hi	ffff000000082964 <a2d+0x50>  // b.pmore
        return ch-'a'+10;
ffff000000082958:	39403fe0 	ldrb	w0, [sp, #15]
ffff00000008295c:	51015c00 	sub	w0, w0, #0x57
ffff000000082960:	1400000b 	b	ffff00000008298c <a2d+0x78>
    else if (ch>='A' && ch<='F')
ffff000000082964:	39403fe0 	ldrb	w0, [sp, #15]
ffff000000082968:	7101001f 	cmp	w0, #0x40
ffff00000008296c:	540000e9 	b.ls	ffff000000082988 <a2d+0x74>  // b.plast
ffff000000082970:	39403fe0 	ldrb	w0, [sp, #15]
ffff000000082974:	7101181f 	cmp	w0, #0x46
ffff000000082978:	54000088 	b.hi	ffff000000082988 <a2d+0x74>  // b.pmore
        return ch-'A'+10;
ffff00000008297c:	39403fe0 	ldrb	w0, [sp, #15]
ffff000000082980:	5100dc00 	sub	w0, w0, #0x37
ffff000000082984:	14000002 	b	ffff00000008298c <a2d+0x78>
    else return -1;
ffff000000082988:	12800000 	mov	w0, #0xffffffff            	// #-1
    }
ffff00000008298c:	910043ff 	add	sp, sp, #0x10
ffff000000082990:	d65f03c0 	ret

ffff000000082994 <a2i>:

static char a2i(char ch, char** src,int base,int* nump)
    {
ffff000000082994:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff000000082998:	910003fd 	mov	x29, sp
ffff00000008299c:	3900bfe0 	strb	w0, [sp, #47]
ffff0000000829a0:	f90013e1 	str	x1, [sp, #32]
ffff0000000829a4:	b9002be2 	str	w2, [sp, #40]
ffff0000000829a8:	f9000fe3 	str	x3, [sp, #24]
    char* p= *src;
ffff0000000829ac:	f94013e0 	ldr	x0, [sp, #32]
ffff0000000829b0:	f9400000 	ldr	x0, [x0]
ffff0000000829b4:	f9001fe0 	str	x0, [sp, #56]
    int num=0;
ffff0000000829b8:	b90037ff 	str	wzr, [sp, #52]
    int digit;
    while ((digit=a2d(ch))>=0) {
ffff0000000829bc:	14000010 	b	ffff0000000829fc <a2i+0x68>
        if (digit>base) break;
ffff0000000829c0:	b94033e1 	ldr	w1, [sp, #48]
ffff0000000829c4:	b9402be0 	ldr	w0, [sp, #40]
ffff0000000829c8:	6b00003f 	cmp	w1, w0
ffff0000000829cc:	5400026c 	b.gt	ffff000000082a18 <a2i+0x84>
        num=num*base+digit;
ffff0000000829d0:	b94037e1 	ldr	w1, [sp, #52]
ffff0000000829d4:	b9402be0 	ldr	w0, [sp, #40]
ffff0000000829d8:	1b007c20 	mul	w0, w1, w0
ffff0000000829dc:	b94033e1 	ldr	w1, [sp, #48]
ffff0000000829e0:	0b000020 	add	w0, w1, w0
ffff0000000829e4:	b90037e0 	str	w0, [sp, #52]
        ch=*p++;
ffff0000000829e8:	f9401fe0 	ldr	x0, [sp, #56]
ffff0000000829ec:	91000401 	add	x1, x0, #0x1
ffff0000000829f0:	f9001fe1 	str	x1, [sp, #56]
ffff0000000829f4:	39400000 	ldrb	w0, [x0]
ffff0000000829f8:	3900bfe0 	strb	w0, [sp, #47]
    while ((digit=a2d(ch))>=0) {
ffff0000000829fc:	3940bfe0 	ldrb	w0, [sp, #47]
ffff000000082a00:	97ffffc5 	bl	ffff000000082914 <a2d>
ffff000000082a04:	b90033e0 	str	w0, [sp, #48]
ffff000000082a08:	b94033e0 	ldr	w0, [sp, #48]
ffff000000082a0c:	7100001f 	cmp	w0, #0x0
ffff000000082a10:	54fffd8a 	b.ge	ffff0000000829c0 <a2i+0x2c>  // b.tcont
ffff000000082a14:	14000002 	b	ffff000000082a1c <a2i+0x88>
        if (digit>base) break;
ffff000000082a18:	d503201f 	nop
        }
    *src=p;
ffff000000082a1c:	f94013e0 	ldr	x0, [sp, #32]
ffff000000082a20:	f9401fe1 	ldr	x1, [sp, #56]
ffff000000082a24:	f9000001 	str	x1, [x0]
    *nump=num;
ffff000000082a28:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000082a2c:	b94037e1 	ldr	w1, [sp, #52]
ffff000000082a30:	b9000001 	str	w1, [x0]
    return ch;
ffff000000082a34:	3940bfe0 	ldrb	w0, [sp, #47]
    }
ffff000000082a38:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff000000082a3c:	d65f03c0 	ret

ffff000000082a40 <putchw>:

static void putchw(void* putp,putcf putf,int n, char z, char* bf)
    {
ffff000000082a40:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff000000082a44:	910003fd 	mov	x29, sp
ffff000000082a48:	f90017e0 	str	x0, [sp, #40]
ffff000000082a4c:	f90013e1 	str	x1, [sp, #32]
ffff000000082a50:	b9001fe2 	str	w2, [sp, #28]
ffff000000082a54:	39006fe3 	strb	w3, [sp, #27]
ffff000000082a58:	f9000be4 	str	x4, [sp, #16]
    char fc=z? '0' : ' ';
ffff000000082a5c:	39406fe0 	ldrb	w0, [sp, #27]
ffff000000082a60:	7100001f 	cmp	w0, #0x0
ffff000000082a64:	54000060 	b.eq	ffff000000082a70 <putchw+0x30>  // b.none
ffff000000082a68:	52800600 	mov	w0, #0x30                  	// #48
ffff000000082a6c:	14000002 	b	ffff000000082a74 <putchw+0x34>
ffff000000082a70:	52800400 	mov	w0, #0x20                  	// #32
ffff000000082a74:	3900dfe0 	strb	w0, [sp, #55]
    char ch;
    char* p=bf;
ffff000000082a78:	f9400be0 	ldr	x0, [sp, #16]
ffff000000082a7c:	f9001fe0 	str	x0, [sp, #56]
    while (*p++ && n > 0)
ffff000000082a80:	14000004 	b	ffff000000082a90 <putchw+0x50>
        n--;
ffff000000082a84:	b9401fe0 	ldr	w0, [sp, #28]
ffff000000082a88:	51000400 	sub	w0, w0, #0x1
ffff000000082a8c:	b9001fe0 	str	w0, [sp, #28]
    while (*p++ && n > 0)
ffff000000082a90:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000082a94:	91000401 	add	x1, x0, #0x1
ffff000000082a98:	f9001fe1 	str	x1, [sp, #56]
ffff000000082a9c:	39400000 	ldrb	w0, [x0]
ffff000000082aa0:	7100001f 	cmp	w0, #0x0
ffff000000082aa4:	54000120 	b.eq	ffff000000082ac8 <putchw+0x88>  // b.none
ffff000000082aa8:	b9401fe0 	ldr	w0, [sp, #28]
ffff000000082aac:	7100001f 	cmp	w0, #0x0
ffff000000082ab0:	54fffeac 	b.gt	ffff000000082a84 <putchw+0x44>
    while (n-- > 0)
ffff000000082ab4:	14000005 	b	ffff000000082ac8 <putchw+0x88>
        putf(putp,fc);
ffff000000082ab8:	f94013e2 	ldr	x2, [sp, #32]
ffff000000082abc:	3940dfe1 	ldrb	w1, [sp, #55]
ffff000000082ac0:	f94017e0 	ldr	x0, [sp, #40]
ffff000000082ac4:	d63f0040 	blr	x2
    while (n-- > 0)
ffff000000082ac8:	b9401fe0 	ldr	w0, [sp, #28]
ffff000000082acc:	51000401 	sub	w1, w0, #0x1
ffff000000082ad0:	b9001fe1 	str	w1, [sp, #28]
ffff000000082ad4:	7100001f 	cmp	w0, #0x0
ffff000000082ad8:	54ffff0c 	b.gt	ffff000000082ab8 <putchw+0x78>
    while ((ch= *bf++))
ffff000000082adc:	14000005 	b	ffff000000082af0 <putchw+0xb0>
        putf(putp,ch);
ffff000000082ae0:	f94013e2 	ldr	x2, [sp, #32]
ffff000000082ae4:	3940dbe1 	ldrb	w1, [sp, #54]
ffff000000082ae8:	f94017e0 	ldr	x0, [sp, #40]
ffff000000082aec:	d63f0040 	blr	x2
    while ((ch= *bf++))
ffff000000082af0:	f9400be0 	ldr	x0, [sp, #16]
ffff000000082af4:	91000401 	add	x1, x0, #0x1
ffff000000082af8:	f9000be1 	str	x1, [sp, #16]
ffff000000082afc:	39400000 	ldrb	w0, [x0]
ffff000000082b00:	3900dbe0 	strb	w0, [sp, #54]
ffff000000082b04:	3940dbe0 	ldrb	w0, [sp, #54]
ffff000000082b08:	7100001f 	cmp	w0, #0x0
ffff000000082b0c:	54fffea1 	b.ne	ffff000000082ae0 <putchw+0xa0>  // b.any
    }
ffff000000082b10:	d503201f 	nop
ffff000000082b14:	d503201f 	nop
ffff000000082b18:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff000000082b1c:	d65f03c0 	ret

ffff000000082b20 <tfp_format>:

void tfp_format(void* putp,putcf putf,char *fmt, va_list va)
    {
ffff000000082b20:	a9ba7bfd 	stp	x29, x30, [sp, #-96]!
ffff000000082b24:	910003fd 	mov	x29, sp
ffff000000082b28:	f9000bf3 	str	x19, [sp, #16]
ffff000000082b2c:	f9001fe0 	str	x0, [sp, #56]
ffff000000082b30:	f9001be1 	str	x1, [sp, #48]
ffff000000082b34:	f90017e2 	str	x2, [sp, #40]
ffff000000082b38:	aa0303f3 	mov	x19, x3
    char bf[12];

    char ch;


    while ((ch=*(fmt++))) {
ffff000000082b3c:	140000ef 	b	ffff000000082ef8 <tfp_format+0x3d8>
        if (ch!='%')
ffff000000082b40:	39417fe0 	ldrb	w0, [sp, #95]
ffff000000082b44:	7100941f 	cmp	w0, #0x25
ffff000000082b48:	540000c0 	b.eq	ffff000000082b60 <tfp_format+0x40>  // b.none
            putf(putp,ch);
ffff000000082b4c:	f9401be2 	ldr	x2, [sp, #48]
ffff000000082b50:	39417fe1 	ldrb	w1, [sp, #95]
ffff000000082b54:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000082b58:	d63f0040 	blr	x2
ffff000000082b5c:	140000e7 	b	ffff000000082ef8 <tfp_format+0x3d8>
        else {
            char lz=0;
ffff000000082b60:	39017bff 	strb	wzr, [sp, #94]
#ifdef  PRINTF_LONG_SUPPORT
            char lng=0;
#endif
            int w=0;
ffff000000082b64:	b9004fff 	str	wzr, [sp, #76]
            ch=*(fmt++);
ffff000000082b68:	f94017e0 	ldr	x0, [sp, #40]
ffff000000082b6c:	91000401 	add	x1, x0, #0x1
ffff000000082b70:	f90017e1 	str	x1, [sp, #40]
ffff000000082b74:	39400000 	ldrb	w0, [x0]
ffff000000082b78:	39017fe0 	strb	w0, [sp, #95]
            if (ch=='0') {
ffff000000082b7c:	39417fe0 	ldrb	w0, [sp, #95]
ffff000000082b80:	7100c01f 	cmp	w0, #0x30
ffff000000082b84:	54000101 	b.ne	ffff000000082ba4 <tfp_format+0x84>  // b.any
                ch=*(fmt++);
ffff000000082b88:	f94017e0 	ldr	x0, [sp, #40]
ffff000000082b8c:	91000401 	add	x1, x0, #0x1
ffff000000082b90:	f90017e1 	str	x1, [sp, #40]
ffff000000082b94:	39400000 	ldrb	w0, [x0]
ffff000000082b98:	39017fe0 	strb	w0, [sp, #95]
                lz=1;
ffff000000082b9c:	52800020 	mov	w0, #0x1                   	// #1
ffff000000082ba0:	39017be0 	strb	w0, [sp, #94]
                }
            if (ch>='0' && ch<='9') {
ffff000000082ba4:	39417fe0 	ldrb	w0, [sp, #95]
ffff000000082ba8:	7100bc1f 	cmp	w0, #0x2f
ffff000000082bac:	54000189 	b.ls	ffff000000082bdc <tfp_format+0xbc>  // b.plast
ffff000000082bb0:	39417fe0 	ldrb	w0, [sp, #95]
ffff000000082bb4:	7100e41f 	cmp	w0, #0x39
ffff000000082bb8:	54000128 	b.hi	ffff000000082bdc <tfp_format+0xbc>  // b.pmore
                ch=a2i(ch,&fmt,10,&w);
ffff000000082bbc:	910133e1 	add	x1, sp, #0x4c
ffff000000082bc0:	9100a3e0 	add	x0, sp, #0x28
ffff000000082bc4:	aa0103e3 	mov	x3, x1
ffff000000082bc8:	52800142 	mov	w2, #0xa                   	// #10
ffff000000082bcc:	aa0003e1 	mov	x1, x0
ffff000000082bd0:	39417fe0 	ldrb	w0, [sp, #95]
ffff000000082bd4:	97ffff70 	bl	ffff000000082994 <a2i>
ffff000000082bd8:	39017fe0 	strb	w0, [sp, #95]
            if (ch=='l') {
                ch=*(fmt++);
                lng=1;
            }
#endif
            switch (ch) {
ffff000000082bdc:	39417fe0 	ldrb	w0, [sp, #95]
ffff000000082be0:	7101e01f 	cmp	w0, #0x78
ffff000000082be4:	54000be0 	b.eq	ffff000000082d60 <tfp_format+0x240>  // b.none
ffff000000082be8:	7101e01f 	cmp	w0, #0x78
ffff000000082bec:	5400184c 	b.gt	ffff000000082ef4 <tfp_format+0x3d4>
ffff000000082bf0:	7101d41f 	cmp	w0, #0x75
ffff000000082bf4:	54000300 	b.eq	ffff000000082c54 <tfp_format+0x134>  // b.none
ffff000000082bf8:	7101d41f 	cmp	w0, #0x75
ffff000000082bfc:	540017cc 	b.gt	ffff000000082ef4 <tfp_format+0x3d4>
ffff000000082c00:	7101cc1f 	cmp	w0, #0x73
ffff000000082c04:	54001360 	b.eq	ffff000000082e70 <tfp_format+0x350>  // b.none
ffff000000082c08:	7101cc1f 	cmp	w0, #0x73
ffff000000082c0c:	5400174c 	b.gt	ffff000000082ef4 <tfp_format+0x3d4>
ffff000000082c10:	7101901f 	cmp	w0, #0x64
ffff000000082c14:	54000660 	b.eq	ffff000000082ce0 <tfp_format+0x1c0>  // b.none
ffff000000082c18:	7101901f 	cmp	w0, #0x64
ffff000000082c1c:	540016cc 	b.gt	ffff000000082ef4 <tfp_format+0x3d4>
ffff000000082c20:	71018c1f 	cmp	w0, #0x63
ffff000000082c24:	54000f00 	b.eq	ffff000000082e04 <tfp_format+0x2e4>  // b.none
ffff000000082c28:	71018c1f 	cmp	w0, #0x63
ffff000000082c2c:	5400164c 	b.gt	ffff000000082ef4 <tfp_format+0x3d4>
ffff000000082c30:	7101601f 	cmp	w0, #0x58
ffff000000082c34:	54000960 	b.eq	ffff000000082d60 <tfp_format+0x240>  // b.none
ffff000000082c38:	7101601f 	cmp	w0, #0x58
ffff000000082c3c:	540015cc 	b.gt	ffff000000082ef4 <tfp_format+0x3d4>
ffff000000082c40:	7100001f 	cmp	w0, #0x0
ffff000000082c44:	540016c0 	b.eq	ffff000000082f1c <tfp_format+0x3fc>  // b.none
ffff000000082c48:	7100941f 	cmp	w0, #0x25
ffff000000082c4c:	540014c0 	b.eq	ffff000000082ee4 <tfp_format+0x3c4>  // b.none
                    putchw(putp,putf,w,0,va_arg(va, char*));
                    break;
                case '%' :
                    putf(putp,ch);
                default:
                    break;
ffff000000082c50:	140000a9 	b	ffff000000082ef4 <tfp_format+0x3d4>
                    ui2a(va_arg(va, unsigned int),10,0,bf);
ffff000000082c54:	b9401a61 	ldr	w1, [x19, #24]
ffff000000082c58:	f9400260 	ldr	x0, [x19]
ffff000000082c5c:	7100003f 	cmp	w1, #0x0
ffff000000082c60:	540000ab 	b.lt	ffff000000082c74 <tfp_format+0x154>  // b.tstop
ffff000000082c64:	91002c01 	add	x1, x0, #0xb
ffff000000082c68:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000082c6c:	f9000261 	str	x1, [x19]
ffff000000082c70:	1400000d 	b	ffff000000082ca4 <tfp_format+0x184>
ffff000000082c74:	11002022 	add	w2, w1, #0x8
ffff000000082c78:	b9001a62 	str	w2, [x19, #24]
ffff000000082c7c:	b9401a62 	ldr	w2, [x19, #24]
ffff000000082c80:	7100005f 	cmp	w2, #0x0
ffff000000082c84:	540000ad 	b.le	ffff000000082c98 <tfp_format+0x178>
ffff000000082c88:	91002c01 	add	x1, x0, #0xb
ffff000000082c8c:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000082c90:	f9000261 	str	x1, [x19]
ffff000000082c94:	14000004 	b	ffff000000082ca4 <tfp_format+0x184>
ffff000000082c98:	f9400662 	ldr	x2, [x19, #8]
ffff000000082c9c:	93407c20 	sxtw	x0, w1
ffff000000082ca0:	8b000040 	add	x0, x2, x0
ffff000000082ca4:	b9400000 	ldr	w0, [x0]
ffff000000082ca8:	910143e1 	add	x1, sp, #0x50
ffff000000082cac:	aa0103e3 	mov	x3, x1
ffff000000082cb0:	52800002 	mov	w2, #0x0                   	// #0
ffff000000082cb4:	52800141 	mov	w1, #0xa                   	// #10
ffff000000082cb8:	97fffeb6 	bl	ffff000000082790 <ui2a>
                    putchw(putp,putf,w,lz,bf);
ffff000000082cbc:	b9404fe0 	ldr	w0, [sp, #76]
ffff000000082cc0:	910143e1 	add	x1, sp, #0x50
ffff000000082cc4:	aa0103e4 	mov	x4, x1
ffff000000082cc8:	39417be3 	ldrb	w3, [sp, #94]
ffff000000082ccc:	2a0003e2 	mov	w2, w0
ffff000000082cd0:	f9401be1 	ldr	x1, [sp, #48]
ffff000000082cd4:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000082cd8:	97ffff5a 	bl	ffff000000082a40 <putchw>
                    break;
ffff000000082cdc:	14000087 	b	ffff000000082ef8 <tfp_format+0x3d8>
                    i2a(va_arg(va, int),bf);
ffff000000082ce0:	b9401a61 	ldr	w1, [x19, #24]
ffff000000082ce4:	f9400260 	ldr	x0, [x19]
ffff000000082ce8:	7100003f 	cmp	w1, #0x0
ffff000000082cec:	540000ab 	b.lt	ffff000000082d00 <tfp_format+0x1e0>  // b.tstop
ffff000000082cf0:	91002c01 	add	x1, x0, #0xb
ffff000000082cf4:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000082cf8:	f9000261 	str	x1, [x19]
ffff000000082cfc:	1400000d 	b	ffff000000082d30 <tfp_format+0x210>
ffff000000082d00:	11002022 	add	w2, w1, #0x8
ffff000000082d04:	b9001a62 	str	w2, [x19, #24]
ffff000000082d08:	b9401a62 	ldr	w2, [x19, #24]
ffff000000082d0c:	7100005f 	cmp	w2, #0x0
ffff000000082d10:	540000ad 	b.le	ffff000000082d24 <tfp_format+0x204>
ffff000000082d14:	91002c01 	add	x1, x0, #0xb
ffff000000082d18:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000082d1c:	f9000261 	str	x1, [x19]
ffff000000082d20:	14000004 	b	ffff000000082d30 <tfp_format+0x210>
ffff000000082d24:	f9400662 	ldr	x2, [x19, #8]
ffff000000082d28:	93407c20 	sxtw	x0, w1
ffff000000082d2c:	8b000040 	add	x0, x2, x0
ffff000000082d30:	b9400000 	ldr	w0, [x0]
ffff000000082d34:	910143e1 	add	x1, sp, #0x50
ffff000000082d38:	97fffee0 	bl	ffff0000000828b8 <i2a>
                    putchw(putp,putf,w,lz,bf);
ffff000000082d3c:	b9404fe0 	ldr	w0, [sp, #76]
ffff000000082d40:	910143e1 	add	x1, sp, #0x50
ffff000000082d44:	aa0103e4 	mov	x4, x1
ffff000000082d48:	39417be3 	ldrb	w3, [sp, #94]
ffff000000082d4c:	2a0003e2 	mov	w2, w0
ffff000000082d50:	f9401be1 	ldr	x1, [sp, #48]
ffff000000082d54:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000082d58:	97ffff3a 	bl	ffff000000082a40 <putchw>
                    break;
ffff000000082d5c:	14000067 	b	ffff000000082ef8 <tfp_format+0x3d8>
                    ui2a(va_arg(va, unsigned int),16,(ch=='X'),bf);
ffff000000082d60:	b9401a61 	ldr	w1, [x19, #24]
ffff000000082d64:	f9400260 	ldr	x0, [x19]
ffff000000082d68:	7100003f 	cmp	w1, #0x0
ffff000000082d6c:	540000ab 	b.lt	ffff000000082d80 <tfp_format+0x260>  // b.tstop
ffff000000082d70:	91002c01 	add	x1, x0, #0xb
ffff000000082d74:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000082d78:	f9000261 	str	x1, [x19]
ffff000000082d7c:	1400000d 	b	ffff000000082db0 <tfp_format+0x290>
ffff000000082d80:	11002022 	add	w2, w1, #0x8
ffff000000082d84:	b9001a62 	str	w2, [x19, #24]
ffff000000082d88:	b9401a62 	ldr	w2, [x19, #24]
ffff000000082d8c:	7100005f 	cmp	w2, #0x0
ffff000000082d90:	540000ad 	b.le	ffff000000082da4 <tfp_format+0x284>
ffff000000082d94:	91002c01 	add	x1, x0, #0xb
ffff000000082d98:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000082d9c:	f9000261 	str	x1, [x19]
ffff000000082da0:	14000004 	b	ffff000000082db0 <tfp_format+0x290>
ffff000000082da4:	f9400662 	ldr	x2, [x19, #8]
ffff000000082da8:	93407c20 	sxtw	x0, w1
ffff000000082dac:	8b000040 	add	x0, x2, x0
ffff000000082db0:	b9400004 	ldr	w4, [x0]
ffff000000082db4:	39417fe0 	ldrb	w0, [sp, #95]
ffff000000082db8:	7101601f 	cmp	w0, #0x58
ffff000000082dbc:	1a9f17e0 	cset	w0, eq  // eq = none
ffff000000082dc0:	12001c00 	and	w0, w0, #0xff
ffff000000082dc4:	2a0003e1 	mov	w1, w0
ffff000000082dc8:	910143e0 	add	x0, sp, #0x50
ffff000000082dcc:	aa0003e3 	mov	x3, x0
ffff000000082dd0:	2a0103e2 	mov	w2, w1
ffff000000082dd4:	52800201 	mov	w1, #0x10                  	// #16
ffff000000082dd8:	2a0403e0 	mov	w0, w4
ffff000000082ddc:	97fffe6d 	bl	ffff000000082790 <ui2a>
                    putchw(putp,putf,w,lz,bf);
ffff000000082de0:	b9404fe0 	ldr	w0, [sp, #76]
ffff000000082de4:	910143e1 	add	x1, sp, #0x50
ffff000000082de8:	aa0103e4 	mov	x4, x1
ffff000000082dec:	39417be3 	ldrb	w3, [sp, #94]
ffff000000082df0:	2a0003e2 	mov	w2, w0
ffff000000082df4:	f9401be1 	ldr	x1, [sp, #48]
ffff000000082df8:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000082dfc:	97ffff11 	bl	ffff000000082a40 <putchw>
                    break;
ffff000000082e00:	1400003e 	b	ffff000000082ef8 <tfp_format+0x3d8>
                    putf(putp,(char)(va_arg(va, int)));
ffff000000082e04:	b9401a61 	ldr	w1, [x19, #24]
ffff000000082e08:	f9400260 	ldr	x0, [x19]
ffff000000082e0c:	7100003f 	cmp	w1, #0x0
ffff000000082e10:	540000ab 	b.lt	ffff000000082e24 <tfp_format+0x304>  // b.tstop
ffff000000082e14:	91002c01 	add	x1, x0, #0xb
ffff000000082e18:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000082e1c:	f9000261 	str	x1, [x19]
ffff000000082e20:	1400000d 	b	ffff000000082e54 <tfp_format+0x334>
ffff000000082e24:	11002022 	add	w2, w1, #0x8
ffff000000082e28:	b9001a62 	str	w2, [x19, #24]
ffff000000082e2c:	b9401a62 	ldr	w2, [x19, #24]
ffff000000082e30:	7100005f 	cmp	w2, #0x0
ffff000000082e34:	540000ad 	b.le	ffff000000082e48 <tfp_format+0x328>
ffff000000082e38:	91002c01 	add	x1, x0, #0xb
ffff000000082e3c:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000082e40:	f9000261 	str	x1, [x19]
ffff000000082e44:	14000004 	b	ffff000000082e54 <tfp_format+0x334>
ffff000000082e48:	f9400662 	ldr	x2, [x19, #8]
ffff000000082e4c:	93407c20 	sxtw	x0, w1
ffff000000082e50:	8b000040 	add	x0, x2, x0
ffff000000082e54:	b9400000 	ldr	w0, [x0]
ffff000000082e58:	12001c00 	and	w0, w0, #0xff
ffff000000082e5c:	f9401be2 	ldr	x2, [sp, #48]
ffff000000082e60:	2a0003e1 	mov	w1, w0
ffff000000082e64:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000082e68:	d63f0040 	blr	x2
                    break;
ffff000000082e6c:	14000023 	b	ffff000000082ef8 <tfp_format+0x3d8>
                    putchw(putp,putf,w,0,va_arg(va, char*));
ffff000000082e70:	b9404fe5 	ldr	w5, [sp, #76]
ffff000000082e74:	b9401a61 	ldr	w1, [x19, #24]
ffff000000082e78:	f9400260 	ldr	x0, [x19]
ffff000000082e7c:	7100003f 	cmp	w1, #0x0
ffff000000082e80:	540000ab 	b.lt	ffff000000082e94 <tfp_format+0x374>  // b.tstop
ffff000000082e84:	91003c01 	add	x1, x0, #0xf
ffff000000082e88:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000082e8c:	f9000261 	str	x1, [x19]
ffff000000082e90:	1400000d 	b	ffff000000082ec4 <tfp_format+0x3a4>
ffff000000082e94:	11002022 	add	w2, w1, #0x8
ffff000000082e98:	b9001a62 	str	w2, [x19, #24]
ffff000000082e9c:	b9401a62 	ldr	w2, [x19, #24]
ffff000000082ea0:	7100005f 	cmp	w2, #0x0
ffff000000082ea4:	540000ad 	b.le	ffff000000082eb8 <tfp_format+0x398>
ffff000000082ea8:	91003c01 	add	x1, x0, #0xf
ffff000000082eac:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000082eb0:	f9000261 	str	x1, [x19]
ffff000000082eb4:	14000004 	b	ffff000000082ec4 <tfp_format+0x3a4>
ffff000000082eb8:	f9400662 	ldr	x2, [x19, #8]
ffff000000082ebc:	93407c20 	sxtw	x0, w1
ffff000000082ec0:	8b000040 	add	x0, x2, x0
ffff000000082ec4:	f9400000 	ldr	x0, [x0]
ffff000000082ec8:	aa0003e4 	mov	x4, x0
ffff000000082ecc:	52800003 	mov	w3, #0x0                   	// #0
ffff000000082ed0:	2a0503e2 	mov	w2, w5
ffff000000082ed4:	f9401be1 	ldr	x1, [sp, #48]
ffff000000082ed8:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000082edc:	97fffed9 	bl	ffff000000082a40 <putchw>
                    break;
ffff000000082ee0:	14000006 	b	ffff000000082ef8 <tfp_format+0x3d8>
                    putf(putp,ch);
ffff000000082ee4:	f9401be2 	ldr	x2, [sp, #48]
ffff000000082ee8:	39417fe1 	ldrb	w1, [sp, #95]
ffff000000082eec:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000082ef0:	d63f0040 	blr	x2
                    break;
ffff000000082ef4:	d503201f 	nop
    while ((ch=*(fmt++))) {
ffff000000082ef8:	f94017e0 	ldr	x0, [sp, #40]
ffff000000082efc:	91000401 	add	x1, x0, #0x1
ffff000000082f00:	f90017e1 	str	x1, [sp, #40]
ffff000000082f04:	39400000 	ldrb	w0, [x0]
ffff000000082f08:	39017fe0 	strb	w0, [sp, #95]
ffff000000082f0c:	39417fe0 	ldrb	w0, [sp, #95]
ffff000000082f10:	7100001f 	cmp	w0, #0x0
ffff000000082f14:	54ffe161 	b.ne	ffff000000082b40 <tfp_format+0x20>  // b.any
                }
            }
        }
    abort:;
ffff000000082f18:	14000002 	b	ffff000000082f20 <tfp_format+0x400>
                    goto abort;
ffff000000082f1c:	d503201f 	nop
    }
ffff000000082f20:	d503201f 	nop
ffff000000082f24:	f9400bf3 	ldr	x19, [sp, #16]
ffff000000082f28:	a8c67bfd 	ldp	x29, x30, [sp], #96
ffff000000082f2c:	d65f03c0 	ret

ffff000000082f30 <init_printf>:


void init_printf(void* putp,void (*putf) (void*,char))
    {
ffff000000082f30:	d10043ff 	sub	sp, sp, #0x10
ffff000000082f34:	f90007e0 	str	x0, [sp, #8]
ffff000000082f38:	f90003e1 	str	x1, [sp]
    stdout_putf=putf;
ffff000000082f3c:	90000400 	adrp	x0, ffff000000102000 <mem_map+0x7c8b8>
ffff000000082f40:	913d4000 	add	x0, x0, #0xf50
ffff000000082f44:	f94003e1 	ldr	x1, [sp]
ffff000000082f48:	f9000001 	str	x1, [x0]
    stdout_putp=putp;
ffff000000082f4c:	90000400 	adrp	x0, ffff000000102000 <mem_map+0x7c8b8>
ffff000000082f50:	913d6000 	add	x0, x0, #0xf58
ffff000000082f54:	f94007e1 	ldr	x1, [sp, #8]
ffff000000082f58:	f9000001 	str	x1, [x0]
    }
ffff000000082f5c:	d503201f 	nop
ffff000000082f60:	910043ff 	add	sp, sp, #0x10
ffff000000082f64:	d65f03c0 	ret

ffff000000082f68 <tfp_printf>:

void tfp_printf(char *fmt, ...)
    {
ffff000000082f68:	a9b67bfd 	stp	x29, x30, [sp, #-160]!
ffff000000082f6c:	910003fd 	mov	x29, sp
ffff000000082f70:	f9001fe0 	str	x0, [sp, #56]
ffff000000082f74:	f90037e1 	str	x1, [sp, #104]
ffff000000082f78:	f9003be2 	str	x2, [sp, #112]
ffff000000082f7c:	f9003fe3 	str	x3, [sp, #120]
ffff000000082f80:	f90043e4 	str	x4, [sp, #128]
ffff000000082f84:	f90047e5 	str	x5, [sp, #136]
ffff000000082f88:	f9004be6 	str	x6, [sp, #144]
ffff000000082f8c:	f9004fe7 	str	x7, [sp, #152]
    va_list va;
    va_start(va,fmt);
ffff000000082f90:	910283e0 	add	x0, sp, #0xa0
ffff000000082f94:	f90023e0 	str	x0, [sp, #64]
ffff000000082f98:	910283e0 	add	x0, sp, #0xa0
ffff000000082f9c:	f90027e0 	str	x0, [sp, #72]
ffff000000082fa0:	910183e0 	add	x0, sp, #0x60
ffff000000082fa4:	f9002be0 	str	x0, [sp, #80]
ffff000000082fa8:	128006e0 	mov	w0, #0xffffffc8            	// #-56
ffff000000082fac:	b9005be0 	str	w0, [sp, #88]
ffff000000082fb0:	b9005fff 	str	wzr, [sp, #92]
    tfp_format(stdout_putp,stdout_putf,fmt,va);
ffff000000082fb4:	90000400 	adrp	x0, ffff000000102000 <mem_map+0x7c8b8>
ffff000000082fb8:	913d6000 	add	x0, x0, #0xf58
ffff000000082fbc:	f9400004 	ldr	x4, [x0]
ffff000000082fc0:	90000400 	adrp	x0, ffff000000102000 <mem_map+0x7c8b8>
ffff000000082fc4:	913d4000 	add	x0, x0, #0xf50
ffff000000082fc8:	f9400005 	ldr	x5, [x0]
ffff000000082fcc:	910043e2 	add	x2, sp, #0x10
ffff000000082fd0:	910103e3 	add	x3, sp, #0x40
ffff000000082fd4:	a9400460 	ldp	x0, x1, [x3]
ffff000000082fd8:	a9000440 	stp	x0, x1, [x2]
ffff000000082fdc:	a9410460 	ldp	x0, x1, [x3, #16]
ffff000000082fe0:	a9010440 	stp	x0, x1, [x2, #16]
ffff000000082fe4:	910043e0 	add	x0, sp, #0x10
ffff000000082fe8:	aa0003e3 	mov	x3, x0
ffff000000082fec:	f9401fe2 	ldr	x2, [sp, #56]
ffff000000082ff0:	aa0503e1 	mov	x1, x5
ffff000000082ff4:	aa0403e0 	mov	x0, x4
ffff000000082ff8:	97fffeca 	bl	ffff000000082b20 <tfp_format>
    va_end(va);
    }
ffff000000082ffc:	d503201f 	nop
ffff000000083000:	a8ca7bfd 	ldp	x29, x30, [sp], #160
ffff000000083004:	d65f03c0 	ret

ffff000000083008 <putcp>:

static void putcp(void* p,char c)
    {
ffff000000083008:	d10043ff 	sub	sp, sp, #0x10
ffff00000008300c:	f90007e0 	str	x0, [sp, #8]
ffff000000083010:	39001fe1 	strb	w1, [sp, #7]
    *(*((char**)p))++ = c;
ffff000000083014:	f94007e0 	ldr	x0, [sp, #8]
ffff000000083018:	f9400000 	ldr	x0, [x0]
ffff00000008301c:	91000402 	add	x2, x0, #0x1
ffff000000083020:	f94007e1 	ldr	x1, [sp, #8]
ffff000000083024:	f9000022 	str	x2, [x1]
ffff000000083028:	39401fe1 	ldrb	w1, [sp, #7]
ffff00000008302c:	39000001 	strb	w1, [x0]
    }
ffff000000083030:	d503201f 	nop
ffff000000083034:	910043ff 	add	sp, sp, #0x10
ffff000000083038:	d65f03c0 	ret

ffff00000008303c <tfp_sprintf>:



void tfp_sprintf(char* s,char *fmt, ...)
    {
ffff00000008303c:	a9b77bfd 	stp	x29, x30, [sp, #-144]!
ffff000000083040:	910003fd 	mov	x29, sp
ffff000000083044:	f9001fe0 	str	x0, [sp, #56]
ffff000000083048:	f9001be1 	str	x1, [sp, #48]
ffff00000008304c:	f90033e2 	str	x2, [sp, #96]
ffff000000083050:	f90037e3 	str	x3, [sp, #104]
ffff000000083054:	f9003be4 	str	x4, [sp, #112]
ffff000000083058:	f9003fe5 	str	x5, [sp, #120]
ffff00000008305c:	f90043e6 	str	x6, [sp, #128]
ffff000000083060:	f90047e7 	str	x7, [sp, #136]
    va_list va;
    va_start(va,fmt);
ffff000000083064:	910243e0 	add	x0, sp, #0x90
ffff000000083068:	f90023e0 	str	x0, [sp, #64]
ffff00000008306c:	910243e0 	add	x0, sp, #0x90
ffff000000083070:	f90027e0 	str	x0, [sp, #72]
ffff000000083074:	910183e0 	add	x0, sp, #0x60
ffff000000083078:	f9002be0 	str	x0, [sp, #80]
ffff00000008307c:	128005e0 	mov	w0, #0xffffffd0            	// #-48
ffff000000083080:	b9005be0 	str	w0, [sp, #88]
ffff000000083084:	b9005fff 	str	wzr, [sp, #92]
    tfp_format(&s,putcp,fmt,va);
ffff000000083088:	910043e2 	add	x2, sp, #0x10
ffff00000008308c:	910103e3 	add	x3, sp, #0x40
ffff000000083090:	a9400460 	ldp	x0, x1, [x3]
ffff000000083094:	a9000440 	stp	x0, x1, [x2]
ffff000000083098:	a9410460 	ldp	x0, x1, [x3, #16]
ffff00000008309c:	a9010440 	stp	x0, x1, [x2, #16]
ffff0000000830a0:	910043e0 	add	x0, sp, #0x10
ffff0000000830a4:	9100e3e4 	add	x4, sp, #0x38
ffff0000000830a8:	aa0003e3 	mov	x3, x0
ffff0000000830ac:	f9401be2 	ldr	x2, [sp, #48]
ffff0000000830b0:	90000000 	adrp	x0, ffff000000083000 <tfp_printf+0x98>
ffff0000000830b4:	91002001 	add	x1, x0, #0x8
ffff0000000830b8:	aa0403e0 	mov	x0, x4
ffff0000000830bc:	97fffe99 	bl	ffff000000082b20 <tfp_format>
    putcp(&s,0);
ffff0000000830c0:	9100e3e0 	add	x0, sp, #0x38
ffff0000000830c4:	52800001 	mov	w1, #0x0                   	// #0
ffff0000000830c8:	97ffffd0 	bl	ffff000000083008 <putcp>
    va_end(va);
    }
ffff0000000830cc:	d503201f 	nop
ffff0000000830d0:	a8c97bfd 	ldp	x29, x30, [sp], #144
ffff0000000830d4:	d65f03c0 	ret

ffff0000000830d8 <kernel_process>:
#include "mini_uart.h"
#include "sys.h"
#include "user.h"


void kernel_process(){
ffff0000000830d8:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff0000000830dc:	910003fd 	mov	x29, sp
	printf("Kernel process started. EL %d\r\n", get_el());
ffff0000000830e0:	94000639 	bl	ffff0000000849c4 <get_el>
ffff0000000830e4:	aa0003e1 	mov	x1, x0
ffff0000000830e8:	b0000000 	adrp	x0, ffff000000084000 <irq_invalid_el1t+0x14>
ffff0000000830ec:	912f6000 	add	x0, x0, #0xbd8
ffff0000000830f0:	97ffff9e 	bl	ffff000000082f68 <tfp_printf>
	unsigned long begin = (unsigned long)&user_begin;
ffff0000000830f4:	d0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff0000000830f8:	f9423800 	ldr	x0, [x0, #1136]
ffff0000000830fc:	f90017e0 	str	x0, [sp, #40]
	unsigned long end = (unsigned long)&user_end;
ffff000000083100:	d0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000083104:	f9424000 	ldr	x0, [x0, #1152]
ffff000000083108:	f90013e0 	str	x0, [sp, #32]
	unsigned long process = (unsigned long)&user_process;
ffff00000008310c:	d0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000083110:	f9424400 	ldr	x0, [x0, #1160]
ffff000000083114:	f9000fe0 	str	x0, [sp, #24]
	int err = move_to_user_mode(begin, end - begin, process - begin);
ffff000000083118:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008311c:	f94017e0 	ldr	x0, [sp, #40]
ffff000000083120:	cb000023 	sub	x3, x1, x0
ffff000000083124:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000083128:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008312c:	cb000020 	sub	x0, x1, x0
ffff000000083130:	aa0003e2 	mov	x2, x0
ffff000000083134:	aa0303e1 	mov	x1, x3
ffff000000083138:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008313c:	97fffd64 	bl	ffff0000000826cc <move_to_user_mode>
ffff000000083140:	b90017e0 	str	w0, [sp, #20]
	if (err < 0){
ffff000000083144:	b94017e0 	ldr	w0, [sp, #20]
ffff000000083148:	7100001f 	cmp	w0, #0x0
ffff00000008314c:	5400008a 	b.ge	ffff00000008315c <kernel_process+0x84>  // b.tcont
		printf("Error while moving process to user mode\n\r");
ffff000000083150:	b0000000 	adrp	x0, ffff000000084000 <irq_invalid_el1t+0x14>
ffff000000083154:	912fe000 	add	x0, x0, #0xbf8
ffff000000083158:	97ffff84 	bl	ffff000000082f68 <tfp_printf>
	} 
}
ffff00000008315c:	d503201f 	nop
ffff000000083160:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff000000083164:	d65f03c0 	ret

ffff000000083168 <kernel_main>:


void kernel_main()
{
ffff000000083168:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008316c:	910003fd 	mov	x29, sp
	uart_init();
ffff000000083170:	97fffb91 	bl	ffff000000081fb4 <uart_init>
	init_printf(NULL, putc);
ffff000000083174:	d0000000 	adrp	x0, ffff000000085000 <interval+0x42c>
ffff000000083178:	f9423401 	ldr	x1, [x0, #1128]
ffff00000008317c:	d2800000 	mov	x0, #0x0                   	// #0
ffff000000083180:	97ffff6c 	bl	ffff000000082f30 <init_printf>

	printf("kernel boots ...\n\r");
ffff000000083184:	b0000000 	adrp	x0, ffff000000084000 <irq_invalid_el1t+0x14>
ffff000000083188:	9130a000 	add	x0, x0, #0xc28
ffff00000008318c:	97ffff77 	bl	ffff000000082f68 <tfp_printf>

	irq_vector_init();
ffff000000083190:	940005e9 	bl	ffff000000084934 <irq_vector_init>
	timer_init();
ffff000000083194:	97fffcbc 	bl	ffff000000082484 <timer_init>
//	generic_timer_init();
	enable_interrupt_controller();
ffff000000083198:	97fff99a 	bl	ffff000000081800 <enable_interrupt_controller>
	enable_irq();
ffff00000008319c:	940005e9 	bl	ffff000000084940 <enable_irq>

	int res = copy_process(PF_KTHREAD, (unsigned long)&kernel_process, 0);
ffff0000000831a0:	90000000 	adrp	x0, ffff000000083000 <tfp_printf+0x98>
ffff0000000831a4:	91036000 	add	x0, x0, #0xd8
ffff0000000831a8:	d2800002 	mov	x2, #0x0                   	// #0
ffff0000000831ac:	aa0003e1 	mov	x1, x0
ffff0000000831b0:	d2800040 	mov	x0, #0x2                   	// #2
ffff0000000831b4:	97fffcee 	bl	ffff00000008256c <copy_process>
ffff0000000831b8:	b9001fe0 	str	w0, [sp, #28]
	if (res < 0) {
ffff0000000831bc:	b9401fe0 	ldr	w0, [sp, #28]
ffff0000000831c0:	7100001f 	cmp	w0, #0x0
ffff0000000831c4:	540000aa 	b.ge	ffff0000000831d8 <kernel_main+0x70>  // b.tcont
		printf("error while starting kernel process");
ffff0000000831c8:	b0000000 	adrp	x0, ffff000000084000 <irq_invalid_el1t+0x14>
ffff0000000831cc:	91310000 	add	x0, x0, #0xc40
ffff0000000831d0:	97ffff66 	bl	ffff000000082f68 <tfp_printf>
		return;
ffff0000000831d4:	14000003 	b	ffff0000000831e0 <kernel_main+0x78>
	}

	while (1){
		schedule();
ffff0000000831d8:	97fffc2b 	bl	ffff000000082284 <schedule>
ffff0000000831dc:	17ffffff 	b	ffff0000000831d8 <kernel_main+0x70>
	}	
}
ffff0000000831e0:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff0000000831e4:	d65f03c0 	ret

ffff0000000831e8 <gen_timer_init>:
 *  https://developer.arm.com/docs/ddi0487/ca/arm-architecture-reference-manual-armv8-for-armv8-a-architecture-profile
 */

.globl gen_timer_init
gen_timer_init:
  mov x0, #1
ffff0000000831e8:	d2800020 	mov	x0, #0x1                   	// #1
  msr CNTP_CTL_EL0, x0
ffff0000000831ec:	d51be220 	msr	cntp_ctl_el0, x0
  ret
ffff0000000831f0:	d65f03c0 	ret

ffff0000000831f4 <gen_timer_reset>:

.globl gen_timer_reset
gen_timer_reset:
    mov x0, #1
ffff0000000831f4:	d2800020 	mov	x0, #0x1                   	// #1
  lsl x0, x0, #24
ffff0000000831f8:	d3689c00 	lsl	x0, x0, #24
  msr CNTP_TVAL_EL0, x0
ffff0000000831fc:	d51be200 	msr	cntp_tval_el0, x0
    ret
ffff000000083200:	d65f03c0 	ret
	...

ffff000000083800 <vectors>:
 * Exception vectors.
 */
.align	11
.globl vectors 
vectors:
	ventry	sync_invalid_el1t			// Synchronous EL1t
ffff000000083800:	140001e1 	b	ffff000000083f84 <sync_invalid_el1t>
ffff000000083804:	d503201f 	nop
ffff000000083808:	d503201f 	nop
ffff00000008380c:	d503201f 	nop
ffff000000083810:	d503201f 	nop
ffff000000083814:	d503201f 	nop
ffff000000083818:	d503201f 	nop
ffff00000008381c:	d503201f 	nop
ffff000000083820:	d503201f 	nop
ffff000000083824:	d503201f 	nop
ffff000000083828:	d503201f 	nop
ffff00000008382c:	d503201f 	nop
ffff000000083830:	d503201f 	nop
ffff000000083834:	d503201f 	nop
ffff000000083838:	d503201f 	nop
ffff00000008383c:	d503201f 	nop
ffff000000083840:	d503201f 	nop
ffff000000083844:	d503201f 	nop
ffff000000083848:	d503201f 	nop
ffff00000008384c:	d503201f 	nop
ffff000000083850:	d503201f 	nop
ffff000000083854:	d503201f 	nop
ffff000000083858:	d503201f 	nop
ffff00000008385c:	d503201f 	nop
ffff000000083860:	d503201f 	nop
ffff000000083864:	d503201f 	nop
ffff000000083868:	d503201f 	nop
ffff00000008386c:	d503201f 	nop
ffff000000083870:	d503201f 	nop
ffff000000083874:	d503201f 	nop
ffff000000083878:	d503201f 	nop
ffff00000008387c:	d503201f 	nop
	ventry	irq_invalid_el1t			// IRQ EL1t
ffff000000083880:	140001db 	b	ffff000000083fec <irq_invalid_el1t>
ffff000000083884:	d503201f 	nop
ffff000000083888:	d503201f 	nop
ffff00000008388c:	d503201f 	nop
ffff000000083890:	d503201f 	nop
ffff000000083894:	d503201f 	nop
ffff000000083898:	d503201f 	nop
ffff00000008389c:	d503201f 	nop
ffff0000000838a0:	d503201f 	nop
ffff0000000838a4:	d503201f 	nop
ffff0000000838a8:	d503201f 	nop
ffff0000000838ac:	d503201f 	nop
ffff0000000838b0:	d503201f 	nop
ffff0000000838b4:	d503201f 	nop
ffff0000000838b8:	d503201f 	nop
ffff0000000838bc:	d503201f 	nop
ffff0000000838c0:	d503201f 	nop
ffff0000000838c4:	d503201f 	nop
ffff0000000838c8:	d503201f 	nop
ffff0000000838cc:	d503201f 	nop
ffff0000000838d0:	d503201f 	nop
ffff0000000838d4:	d503201f 	nop
ffff0000000838d8:	d503201f 	nop
ffff0000000838dc:	d503201f 	nop
ffff0000000838e0:	d503201f 	nop
ffff0000000838e4:	d503201f 	nop
ffff0000000838e8:	d503201f 	nop
ffff0000000838ec:	d503201f 	nop
ffff0000000838f0:	d503201f 	nop
ffff0000000838f4:	d503201f 	nop
ffff0000000838f8:	d503201f 	nop
ffff0000000838fc:	d503201f 	nop
	ventry	fiq_invalid_el1t			// FIQ EL1t
ffff000000083900:	140001d5 	b	ffff000000084054 <fiq_invalid_el1t>
ffff000000083904:	d503201f 	nop
ffff000000083908:	d503201f 	nop
ffff00000008390c:	d503201f 	nop
ffff000000083910:	d503201f 	nop
ffff000000083914:	d503201f 	nop
ffff000000083918:	d503201f 	nop
ffff00000008391c:	d503201f 	nop
ffff000000083920:	d503201f 	nop
ffff000000083924:	d503201f 	nop
ffff000000083928:	d503201f 	nop
ffff00000008392c:	d503201f 	nop
ffff000000083930:	d503201f 	nop
ffff000000083934:	d503201f 	nop
ffff000000083938:	d503201f 	nop
ffff00000008393c:	d503201f 	nop
ffff000000083940:	d503201f 	nop
ffff000000083944:	d503201f 	nop
ffff000000083948:	d503201f 	nop
ffff00000008394c:	d503201f 	nop
ffff000000083950:	d503201f 	nop
ffff000000083954:	d503201f 	nop
ffff000000083958:	d503201f 	nop
ffff00000008395c:	d503201f 	nop
ffff000000083960:	d503201f 	nop
ffff000000083964:	d503201f 	nop
ffff000000083968:	d503201f 	nop
ffff00000008396c:	d503201f 	nop
ffff000000083970:	d503201f 	nop
ffff000000083974:	d503201f 	nop
ffff000000083978:	d503201f 	nop
ffff00000008397c:	d503201f 	nop
	ventry	error_invalid_el1t			// Error EL1t
ffff000000083980:	140001cf 	b	ffff0000000840bc <error_invalid_el1t>
ffff000000083984:	d503201f 	nop
ffff000000083988:	d503201f 	nop
ffff00000008398c:	d503201f 	nop
ffff000000083990:	d503201f 	nop
ffff000000083994:	d503201f 	nop
ffff000000083998:	d503201f 	nop
ffff00000008399c:	d503201f 	nop
ffff0000000839a0:	d503201f 	nop
ffff0000000839a4:	d503201f 	nop
ffff0000000839a8:	d503201f 	nop
ffff0000000839ac:	d503201f 	nop
ffff0000000839b0:	d503201f 	nop
ffff0000000839b4:	d503201f 	nop
ffff0000000839b8:	d503201f 	nop
ffff0000000839bc:	d503201f 	nop
ffff0000000839c0:	d503201f 	nop
ffff0000000839c4:	d503201f 	nop
ffff0000000839c8:	d503201f 	nop
ffff0000000839cc:	d503201f 	nop
ffff0000000839d0:	d503201f 	nop
ffff0000000839d4:	d503201f 	nop
ffff0000000839d8:	d503201f 	nop
ffff0000000839dc:	d503201f 	nop
ffff0000000839e0:	d503201f 	nop
ffff0000000839e4:	d503201f 	nop
ffff0000000839e8:	d503201f 	nop
ffff0000000839ec:	d503201f 	nop
ffff0000000839f0:	d503201f 	nop
ffff0000000839f4:	d503201f 	nop
ffff0000000839f8:	d503201f 	nop
ffff0000000839fc:	d503201f 	nop

	ventry	sync_invalid_el1h			// Synchronous EL1h
ffff000000083a00:	140001c9 	b	ffff000000084124 <sync_invalid_el1h>
ffff000000083a04:	d503201f 	nop
ffff000000083a08:	d503201f 	nop
ffff000000083a0c:	d503201f 	nop
ffff000000083a10:	d503201f 	nop
ffff000000083a14:	d503201f 	nop
ffff000000083a18:	d503201f 	nop
ffff000000083a1c:	d503201f 	nop
ffff000000083a20:	d503201f 	nop
ffff000000083a24:	d503201f 	nop
ffff000000083a28:	d503201f 	nop
ffff000000083a2c:	d503201f 	nop
ffff000000083a30:	d503201f 	nop
ffff000000083a34:	d503201f 	nop
ffff000000083a38:	d503201f 	nop
ffff000000083a3c:	d503201f 	nop
ffff000000083a40:	d503201f 	nop
ffff000000083a44:	d503201f 	nop
ffff000000083a48:	d503201f 	nop
ffff000000083a4c:	d503201f 	nop
ffff000000083a50:	d503201f 	nop
ffff000000083a54:	d503201f 	nop
ffff000000083a58:	d503201f 	nop
ffff000000083a5c:	d503201f 	nop
ffff000000083a60:	d503201f 	nop
ffff000000083a64:	d503201f 	nop
ffff000000083a68:	d503201f 	nop
ffff000000083a6c:	d503201f 	nop
ffff000000083a70:	d503201f 	nop
ffff000000083a74:	d503201f 	nop
ffff000000083a78:	d503201f 	nop
ffff000000083a7c:	d503201f 	nop
	ventry	el1_irq					// IRQ EL1h
ffff000000083a80:	14000293 	b	ffff0000000844cc <el1_irq>
ffff000000083a84:	d503201f 	nop
ffff000000083a88:	d503201f 	nop
ffff000000083a8c:	d503201f 	nop
ffff000000083a90:	d503201f 	nop
ffff000000083a94:	d503201f 	nop
ffff000000083a98:	d503201f 	nop
ffff000000083a9c:	d503201f 	nop
ffff000000083aa0:	d503201f 	nop
ffff000000083aa4:	d503201f 	nop
ffff000000083aa8:	d503201f 	nop
ffff000000083aac:	d503201f 	nop
ffff000000083ab0:	d503201f 	nop
ffff000000083ab4:	d503201f 	nop
ffff000000083ab8:	d503201f 	nop
ffff000000083abc:	d503201f 	nop
ffff000000083ac0:	d503201f 	nop
ffff000000083ac4:	d503201f 	nop
ffff000000083ac8:	d503201f 	nop
ffff000000083acc:	d503201f 	nop
ffff000000083ad0:	d503201f 	nop
ffff000000083ad4:	d503201f 	nop
ffff000000083ad8:	d503201f 	nop
ffff000000083adc:	d503201f 	nop
ffff000000083ae0:	d503201f 	nop
ffff000000083ae4:	d503201f 	nop
ffff000000083ae8:	d503201f 	nop
ffff000000083aec:	d503201f 	nop
ffff000000083af0:	d503201f 	nop
ffff000000083af4:	d503201f 	nop
ffff000000083af8:	d503201f 	nop
ffff000000083afc:	d503201f 	nop
	ventry	fiq_invalid_el1h			// FIQ EL1h
ffff000000083b00:	140001a3 	b	ffff00000008418c <fiq_invalid_el1h>
ffff000000083b04:	d503201f 	nop
ffff000000083b08:	d503201f 	nop
ffff000000083b0c:	d503201f 	nop
ffff000000083b10:	d503201f 	nop
ffff000000083b14:	d503201f 	nop
ffff000000083b18:	d503201f 	nop
ffff000000083b1c:	d503201f 	nop
ffff000000083b20:	d503201f 	nop
ffff000000083b24:	d503201f 	nop
ffff000000083b28:	d503201f 	nop
ffff000000083b2c:	d503201f 	nop
ffff000000083b30:	d503201f 	nop
ffff000000083b34:	d503201f 	nop
ffff000000083b38:	d503201f 	nop
ffff000000083b3c:	d503201f 	nop
ffff000000083b40:	d503201f 	nop
ffff000000083b44:	d503201f 	nop
ffff000000083b48:	d503201f 	nop
ffff000000083b4c:	d503201f 	nop
ffff000000083b50:	d503201f 	nop
ffff000000083b54:	d503201f 	nop
ffff000000083b58:	d503201f 	nop
ffff000000083b5c:	d503201f 	nop
ffff000000083b60:	d503201f 	nop
ffff000000083b64:	d503201f 	nop
ffff000000083b68:	d503201f 	nop
ffff000000083b6c:	d503201f 	nop
ffff000000083b70:	d503201f 	nop
ffff000000083b74:	d503201f 	nop
ffff000000083b78:	d503201f 	nop
ffff000000083b7c:	d503201f 	nop
	ventry	error_invalid_el1h			// Error EL1h
ffff000000083b80:	1400019d 	b	ffff0000000841f4 <error_invalid_el1h>
ffff000000083b84:	d503201f 	nop
ffff000000083b88:	d503201f 	nop
ffff000000083b8c:	d503201f 	nop
ffff000000083b90:	d503201f 	nop
ffff000000083b94:	d503201f 	nop
ffff000000083b98:	d503201f 	nop
ffff000000083b9c:	d503201f 	nop
ffff000000083ba0:	d503201f 	nop
ffff000000083ba4:	d503201f 	nop
ffff000000083ba8:	d503201f 	nop
ffff000000083bac:	d503201f 	nop
ffff000000083bb0:	d503201f 	nop
ffff000000083bb4:	d503201f 	nop
ffff000000083bb8:	d503201f 	nop
ffff000000083bbc:	d503201f 	nop
ffff000000083bc0:	d503201f 	nop
ffff000000083bc4:	d503201f 	nop
ffff000000083bc8:	d503201f 	nop
ffff000000083bcc:	d503201f 	nop
ffff000000083bd0:	d503201f 	nop
ffff000000083bd4:	d503201f 	nop
ffff000000083bd8:	d503201f 	nop
ffff000000083bdc:	d503201f 	nop
ffff000000083be0:	d503201f 	nop
ffff000000083be4:	d503201f 	nop
ffff000000083be8:	d503201f 	nop
ffff000000083bec:	d503201f 	nop
ffff000000083bf0:	d503201f 	nop
ffff000000083bf4:	d503201f 	nop
ffff000000083bf8:	d503201f 	nop
ffff000000083bfc:	d503201f 	nop

	ventry	el0_sync				// Synchronous 64-bit EL0
ffff000000083c00:	1400028a 	b	ffff000000084628 <el0_sync>
ffff000000083c04:	d503201f 	nop
ffff000000083c08:	d503201f 	nop
ffff000000083c0c:	d503201f 	nop
ffff000000083c10:	d503201f 	nop
ffff000000083c14:	d503201f 	nop
ffff000000083c18:	d503201f 	nop
ffff000000083c1c:	d503201f 	nop
ffff000000083c20:	d503201f 	nop
ffff000000083c24:	d503201f 	nop
ffff000000083c28:	d503201f 	nop
ffff000000083c2c:	d503201f 	nop
ffff000000083c30:	d503201f 	nop
ffff000000083c34:	d503201f 	nop
ffff000000083c38:	d503201f 	nop
ffff000000083c3c:	d503201f 	nop
ffff000000083c40:	d503201f 	nop
ffff000000083c44:	d503201f 	nop
ffff000000083c48:	d503201f 	nop
ffff000000083c4c:	d503201f 	nop
ffff000000083c50:	d503201f 	nop
ffff000000083c54:	d503201f 	nop
ffff000000083c58:	d503201f 	nop
ffff000000083c5c:	d503201f 	nop
ffff000000083c60:	d503201f 	nop
ffff000000083c64:	d503201f 	nop
ffff000000083c68:	d503201f 	nop
ffff000000083c6c:	d503201f 	nop
ffff000000083c70:	d503201f 	nop
ffff000000083c74:	d503201f 	nop
ffff000000083c78:	d503201f 	nop
ffff000000083c7c:	d503201f 	nop
	ventry	el0_irq					// IRQ 64-bit EL0
ffff000000083c80:	1400023e 	b	ffff000000084578 <el0_irq>
ffff000000083c84:	d503201f 	nop
ffff000000083c88:	d503201f 	nop
ffff000000083c8c:	d503201f 	nop
ffff000000083c90:	d503201f 	nop
ffff000000083c94:	d503201f 	nop
ffff000000083c98:	d503201f 	nop
ffff000000083c9c:	d503201f 	nop
ffff000000083ca0:	d503201f 	nop
ffff000000083ca4:	d503201f 	nop
ffff000000083ca8:	d503201f 	nop
ffff000000083cac:	d503201f 	nop
ffff000000083cb0:	d503201f 	nop
ffff000000083cb4:	d503201f 	nop
ffff000000083cb8:	d503201f 	nop
ffff000000083cbc:	d503201f 	nop
ffff000000083cc0:	d503201f 	nop
ffff000000083cc4:	d503201f 	nop
ffff000000083cc8:	d503201f 	nop
ffff000000083ccc:	d503201f 	nop
ffff000000083cd0:	d503201f 	nop
ffff000000083cd4:	d503201f 	nop
ffff000000083cd8:	d503201f 	nop
ffff000000083cdc:	d503201f 	nop
ffff000000083ce0:	d503201f 	nop
ffff000000083ce4:	d503201f 	nop
ffff000000083ce8:	d503201f 	nop
ffff000000083cec:	d503201f 	nop
ffff000000083cf0:	d503201f 	nop
ffff000000083cf4:	d503201f 	nop
ffff000000083cf8:	d503201f 	nop
ffff000000083cfc:	d503201f 	nop
	ventry	fiq_invalid_el0_64			// FIQ 64-bit EL0
ffff000000083d00:	14000157 	b	ffff00000008425c <fiq_invalid_el0_64>
ffff000000083d04:	d503201f 	nop
ffff000000083d08:	d503201f 	nop
ffff000000083d0c:	d503201f 	nop
ffff000000083d10:	d503201f 	nop
ffff000000083d14:	d503201f 	nop
ffff000000083d18:	d503201f 	nop
ffff000000083d1c:	d503201f 	nop
ffff000000083d20:	d503201f 	nop
ffff000000083d24:	d503201f 	nop
ffff000000083d28:	d503201f 	nop
ffff000000083d2c:	d503201f 	nop
ffff000000083d30:	d503201f 	nop
ffff000000083d34:	d503201f 	nop
ffff000000083d38:	d503201f 	nop
ffff000000083d3c:	d503201f 	nop
ffff000000083d40:	d503201f 	nop
ffff000000083d44:	d503201f 	nop
ffff000000083d48:	d503201f 	nop
ffff000000083d4c:	d503201f 	nop
ffff000000083d50:	d503201f 	nop
ffff000000083d54:	d503201f 	nop
ffff000000083d58:	d503201f 	nop
ffff000000083d5c:	d503201f 	nop
ffff000000083d60:	d503201f 	nop
ffff000000083d64:	d503201f 	nop
ffff000000083d68:	d503201f 	nop
ffff000000083d6c:	d503201f 	nop
ffff000000083d70:	d503201f 	nop
ffff000000083d74:	d503201f 	nop
ffff000000083d78:	d503201f 	nop
ffff000000083d7c:	d503201f 	nop
	ventry	error_invalid_el0_64			// Error 64-bit EL0
ffff000000083d80:	14000151 	b	ffff0000000842c4 <error_invalid_el0_64>
ffff000000083d84:	d503201f 	nop
ffff000000083d88:	d503201f 	nop
ffff000000083d8c:	d503201f 	nop
ffff000000083d90:	d503201f 	nop
ffff000000083d94:	d503201f 	nop
ffff000000083d98:	d503201f 	nop
ffff000000083d9c:	d503201f 	nop
ffff000000083da0:	d503201f 	nop
ffff000000083da4:	d503201f 	nop
ffff000000083da8:	d503201f 	nop
ffff000000083dac:	d503201f 	nop
ffff000000083db0:	d503201f 	nop
ffff000000083db4:	d503201f 	nop
ffff000000083db8:	d503201f 	nop
ffff000000083dbc:	d503201f 	nop
ffff000000083dc0:	d503201f 	nop
ffff000000083dc4:	d503201f 	nop
ffff000000083dc8:	d503201f 	nop
ffff000000083dcc:	d503201f 	nop
ffff000000083dd0:	d503201f 	nop
ffff000000083dd4:	d503201f 	nop
ffff000000083dd8:	d503201f 	nop
ffff000000083ddc:	d503201f 	nop
ffff000000083de0:	d503201f 	nop
ffff000000083de4:	d503201f 	nop
ffff000000083de8:	d503201f 	nop
ffff000000083dec:	d503201f 	nop
ffff000000083df0:	d503201f 	nop
ffff000000083df4:	d503201f 	nop
ffff000000083df8:	d503201f 	nop
ffff000000083dfc:	d503201f 	nop

	ventry	sync_invalid_el0_32			// Synchronous 32-bit EL0
ffff000000083e00:	1400014b 	b	ffff00000008432c <sync_invalid_el0_32>
ffff000000083e04:	d503201f 	nop
ffff000000083e08:	d503201f 	nop
ffff000000083e0c:	d503201f 	nop
ffff000000083e10:	d503201f 	nop
ffff000000083e14:	d503201f 	nop
ffff000000083e18:	d503201f 	nop
ffff000000083e1c:	d503201f 	nop
ffff000000083e20:	d503201f 	nop
ffff000000083e24:	d503201f 	nop
ffff000000083e28:	d503201f 	nop
ffff000000083e2c:	d503201f 	nop
ffff000000083e30:	d503201f 	nop
ffff000000083e34:	d503201f 	nop
ffff000000083e38:	d503201f 	nop
ffff000000083e3c:	d503201f 	nop
ffff000000083e40:	d503201f 	nop
ffff000000083e44:	d503201f 	nop
ffff000000083e48:	d503201f 	nop
ffff000000083e4c:	d503201f 	nop
ffff000000083e50:	d503201f 	nop
ffff000000083e54:	d503201f 	nop
ffff000000083e58:	d503201f 	nop
ffff000000083e5c:	d503201f 	nop
ffff000000083e60:	d503201f 	nop
ffff000000083e64:	d503201f 	nop
ffff000000083e68:	d503201f 	nop
ffff000000083e6c:	d503201f 	nop
ffff000000083e70:	d503201f 	nop
ffff000000083e74:	d503201f 	nop
ffff000000083e78:	d503201f 	nop
ffff000000083e7c:	d503201f 	nop
	ventry	irq_invalid_el0_32			// IRQ 32-bit EL0
ffff000000083e80:	14000145 	b	ffff000000084394 <irq_invalid_el0_32>
ffff000000083e84:	d503201f 	nop
ffff000000083e88:	d503201f 	nop
ffff000000083e8c:	d503201f 	nop
ffff000000083e90:	d503201f 	nop
ffff000000083e94:	d503201f 	nop
ffff000000083e98:	d503201f 	nop
ffff000000083e9c:	d503201f 	nop
ffff000000083ea0:	d503201f 	nop
ffff000000083ea4:	d503201f 	nop
ffff000000083ea8:	d503201f 	nop
ffff000000083eac:	d503201f 	nop
ffff000000083eb0:	d503201f 	nop
ffff000000083eb4:	d503201f 	nop
ffff000000083eb8:	d503201f 	nop
ffff000000083ebc:	d503201f 	nop
ffff000000083ec0:	d503201f 	nop
ffff000000083ec4:	d503201f 	nop
ffff000000083ec8:	d503201f 	nop
ffff000000083ecc:	d503201f 	nop
ffff000000083ed0:	d503201f 	nop
ffff000000083ed4:	d503201f 	nop
ffff000000083ed8:	d503201f 	nop
ffff000000083edc:	d503201f 	nop
ffff000000083ee0:	d503201f 	nop
ffff000000083ee4:	d503201f 	nop
ffff000000083ee8:	d503201f 	nop
ffff000000083eec:	d503201f 	nop
ffff000000083ef0:	d503201f 	nop
ffff000000083ef4:	d503201f 	nop
ffff000000083ef8:	d503201f 	nop
ffff000000083efc:	d503201f 	nop
	ventry	fiq_invalid_el0_32			// FIQ 32-bit EL0
ffff000000083f00:	1400013f 	b	ffff0000000843fc <fiq_invalid_el0_32>
ffff000000083f04:	d503201f 	nop
ffff000000083f08:	d503201f 	nop
ffff000000083f0c:	d503201f 	nop
ffff000000083f10:	d503201f 	nop
ffff000000083f14:	d503201f 	nop
ffff000000083f18:	d503201f 	nop
ffff000000083f1c:	d503201f 	nop
ffff000000083f20:	d503201f 	nop
ffff000000083f24:	d503201f 	nop
ffff000000083f28:	d503201f 	nop
ffff000000083f2c:	d503201f 	nop
ffff000000083f30:	d503201f 	nop
ffff000000083f34:	d503201f 	nop
ffff000000083f38:	d503201f 	nop
ffff000000083f3c:	d503201f 	nop
ffff000000083f40:	d503201f 	nop
ffff000000083f44:	d503201f 	nop
ffff000000083f48:	d503201f 	nop
ffff000000083f4c:	d503201f 	nop
ffff000000083f50:	d503201f 	nop
ffff000000083f54:	d503201f 	nop
ffff000000083f58:	d503201f 	nop
ffff000000083f5c:	d503201f 	nop
ffff000000083f60:	d503201f 	nop
ffff000000083f64:	d503201f 	nop
ffff000000083f68:	d503201f 	nop
ffff000000083f6c:	d503201f 	nop
ffff000000083f70:	d503201f 	nop
ffff000000083f74:	d503201f 	nop
ffff000000083f78:	d503201f 	nop
ffff000000083f7c:	d503201f 	nop
	ventry	error_invalid_el0_32			// Error 32-bit EL0
ffff000000083f80:	14000139 	b	ffff000000084464 <error_invalid_el0_32>

ffff000000083f84 <sync_invalid_el1t>:

sync_invalid_el1t:
	handle_invalid_entry 1, SYNC_INVALID_EL1t
ffff000000083f84:	d10443ff 	sub	sp, sp, #0x110
ffff000000083f88:	a90007e0 	stp	x0, x1, [sp]
ffff000000083f8c:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff000000083f90:	a90217e4 	stp	x4, x5, [sp, #32]
ffff000000083f94:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff000000083f98:	a90427e8 	stp	x8, x9, [sp, #64]
ffff000000083f9c:	a9052fea 	stp	x10, x11, [sp, #80]
ffff000000083fa0:	a90637ec 	stp	x12, x13, [sp, #96]
ffff000000083fa4:	a9073fee 	stp	x14, x15, [sp, #112]
ffff000000083fa8:	a90847f0 	stp	x16, x17, [sp, #128]
ffff000000083fac:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff000000083fb0:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff000000083fb4:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff000000083fb8:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff000000083fbc:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff000000083fc0:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff000000083fc4:	910443f5 	add	x21, sp, #0x110
ffff000000083fc8:	d5384036 	mrs	x22, elr_el1
ffff000000083fcc:	d5384017 	mrs	x23, spsr_el1
ffff000000083fd0:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff000000083fd4:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff000000083fd8:	d2800000 	mov	x0, #0x0                   	// #0
ffff000000083fdc:	d5385201 	mrs	x1, esr_el1
ffff000000083fe0:	d5384022 	mrs	x2, elr_el1
ffff000000083fe4:	97fff611 	bl	ffff000000081828 <show_invalid_entry_message>
ffff000000083fe8:	14000252 	b	ffff000000084930 <err_hang>

ffff000000083fec <irq_invalid_el1t>:

irq_invalid_el1t:
	handle_invalid_entry 1, IRQ_INVALID_EL1t
ffff000000083fec:	d10443ff 	sub	sp, sp, #0x110
ffff000000083ff0:	a90007e0 	stp	x0, x1, [sp]
ffff000000083ff4:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff000000083ff8:	a90217e4 	stp	x4, x5, [sp, #32]
ffff000000083ffc:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff000000084000:	a90427e8 	stp	x8, x9, [sp, #64]
ffff000000084004:	a9052fea 	stp	x10, x11, [sp, #80]
ffff000000084008:	a90637ec 	stp	x12, x13, [sp, #96]
ffff00000008400c:	a9073fee 	stp	x14, x15, [sp, #112]
ffff000000084010:	a90847f0 	stp	x16, x17, [sp, #128]
ffff000000084014:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff000000084018:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff00000008401c:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff000000084020:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff000000084024:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff000000084028:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff00000008402c:	910443f5 	add	x21, sp, #0x110
ffff000000084030:	d5384036 	mrs	x22, elr_el1
ffff000000084034:	d5384017 	mrs	x23, spsr_el1
ffff000000084038:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff00000008403c:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff000000084040:	d2800020 	mov	x0, #0x1                   	// #1
ffff000000084044:	d5385201 	mrs	x1, esr_el1
ffff000000084048:	d5384022 	mrs	x2, elr_el1
ffff00000008404c:	97fff5f7 	bl	ffff000000081828 <show_invalid_entry_message>
ffff000000084050:	14000238 	b	ffff000000084930 <err_hang>

ffff000000084054 <fiq_invalid_el1t>:

fiq_invalid_el1t:
	handle_invalid_entry 1, FIQ_INVALID_EL1t
ffff000000084054:	d10443ff 	sub	sp, sp, #0x110
ffff000000084058:	a90007e0 	stp	x0, x1, [sp]
ffff00000008405c:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff000000084060:	a90217e4 	stp	x4, x5, [sp, #32]
ffff000000084064:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff000000084068:	a90427e8 	stp	x8, x9, [sp, #64]
ffff00000008406c:	a9052fea 	stp	x10, x11, [sp, #80]
ffff000000084070:	a90637ec 	stp	x12, x13, [sp, #96]
ffff000000084074:	a9073fee 	stp	x14, x15, [sp, #112]
ffff000000084078:	a90847f0 	stp	x16, x17, [sp, #128]
ffff00000008407c:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff000000084080:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff000000084084:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff000000084088:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff00000008408c:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff000000084090:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff000000084094:	910443f5 	add	x21, sp, #0x110
ffff000000084098:	d5384036 	mrs	x22, elr_el1
ffff00000008409c:	d5384017 	mrs	x23, spsr_el1
ffff0000000840a0:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff0000000840a4:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff0000000840a8:	d2800040 	mov	x0, #0x2                   	// #2
ffff0000000840ac:	d5385201 	mrs	x1, esr_el1
ffff0000000840b0:	d5384022 	mrs	x2, elr_el1
ffff0000000840b4:	97fff5dd 	bl	ffff000000081828 <show_invalid_entry_message>
ffff0000000840b8:	1400021e 	b	ffff000000084930 <err_hang>

ffff0000000840bc <error_invalid_el1t>:

error_invalid_el1t:
	handle_invalid_entry 1, ERROR_INVALID_EL1t
ffff0000000840bc:	d10443ff 	sub	sp, sp, #0x110
ffff0000000840c0:	a90007e0 	stp	x0, x1, [sp]
ffff0000000840c4:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff0000000840c8:	a90217e4 	stp	x4, x5, [sp, #32]
ffff0000000840cc:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff0000000840d0:	a90427e8 	stp	x8, x9, [sp, #64]
ffff0000000840d4:	a9052fea 	stp	x10, x11, [sp, #80]
ffff0000000840d8:	a90637ec 	stp	x12, x13, [sp, #96]
ffff0000000840dc:	a9073fee 	stp	x14, x15, [sp, #112]
ffff0000000840e0:	a90847f0 	stp	x16, x17, [sp, #128]
ffff0000000840e4:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff0000000840e8:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff0000000840ec:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff0000000840f0:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff0000000840f4:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff0000000840f8:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff0000000840fc:	910443f5 	add	x21, sp, #0x110
ffff000000084100:	d5384036 	mrs	x22, elr_el1
ffff000000084104:	d5384017 	mrs	x23, spsr_el1
ffff000000084108:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff00000008410c:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff000000084110:	d2800060 	mov	x0, #0x3                   	// #3
ffff000000084114:	d5385201 	mrs	x1, esr_el1
ffff000000084118:	d5384022 	mrs	x2, elr_el1
ffff00000008411c:	97fff5c3 	bl	ffff000000081828 <show_invalid_entry_message>
ffff000000084120:	14000204 	b	ffff000000084930 <err_hang>

ffff000000084124 <sync_invalid_el1h>:

sync_invalid_el1h:
	handle_invalid_entry 1, SYNC_INVALID_EL1h
ffff000000084124:	d10443ff 	sub	sp, sp, #0x110
ffff000000084128:	a90007e0 	stp	x0, x1, [sp]
ffff00000008412c:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff000000084130:	a90217e4 	stp	x4, x5, [sp, #32]
ffff000000084134:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff000000084138:	a90427e8 	stp	x8, x9, [sp, #64]
ffff00000008413c:	a9052fea 	stp	x10, x11, [sp, #80]
ffff000000084140:	a90637ec 	stp	x12, x13, [sp, #96]
ffff000000084144:	a9073fee 	stp	x14, x15, [sp, #112]
ffff000000084148:	a90847f0 	stp	x16, x17, [sp, #128]
ffff00000008414c:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff000000084150:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff000000084154:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff000000084158:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff00000008415c:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff000000084160:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff000000084164:	910443f5 	add	x21, sp, #0x110
ffff000000084168:	d5384036 	mrs	x22, elr_el1
ffff00000008416c:	d5384017 	mrs	x23, spsr_el1
ffff000000084170:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff000000084174:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff000000084178:	d2800080 	mov	x0, #0x4                   	// #4
ffff00000008417c:	d5385201 	mrs	x1, esr_el1
ffff000000084180:	d5384022 	mrs	x2, elr_el1
ffff000000084184:	97fff5a9 	bl	ffff000000081828 <show_invalid_entry_message>
ffff000000084188:	140001ea 	b	ffff000000084930 <err_hang>

ffff00000008418c <fiq_invalid_el1h>:

fiq_invalid_el1h:
	handle_invalid_entry 1, FIQ_INVALID_EL1h
ffff00000008418c:	d10443ff 	sub	sp, sp, #0x110
ffff000000084190:	a90007e0 	stp	x0, x1, [sp]
ffff000000084194:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff000000084198:	a90217e4 	stp	x4, x5, [sp, #32]
ffff00000008419c:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff0000000841a0:	a90427e8 	stp	x8, x9, [sp, #64]
ffff0000000841a4:	a9052fea 	stp	x10, x11, [sp, #80]
ffff0000000841a8:	a90637ec 	stp	x12, x13, [sp, #96]
ffff0000000841ac:	a9073fee 	stp	x14, x15, [sp, #112]
ffff0000000841b0:	a90847f0 	stp	x16, x17, [sp, #128]
ffff0000000841b4:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff0000000841b8:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff0000000841bc:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff0000000841c0:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff0000000841c4:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff0000000841c8:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff0000000841cc:	910443f5 	add	x21, sp, #0x110
ffff0000000841d0:	d5384036 	mrs	x22, elr_el1
ffff0000000841d4:	d5384017 	mrs	x23, spsr_el1
ffff0000000841d8:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff0000000841dc:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff0000000841e0:	d28000a0 	mov	x0, #0x5                   	// #5
ffff0000000841e4:	d5385201 	mrs	x1, esr_el1
ffff0000000841e8:	d5384022 	mrs	x2, elr_el1
ffff0000000841ec:	97fff58f 	bl	ffff000000081828 <show_invalid_entry_message>
ffff0000000841f0:	140001d0 	b	ffff000000084930 <err_hang>

ffff0000000841f4 <error_invalid_el1h>:

error_invalid_el1h:
	handle_invalid_entry 1, ERROR_INVALID_EL1h
ffff0000000841f4:	d10443ff 	sub	sp, sp, #0x110
ffff0000000841f8:	a90007e0 	stp	x0, x1, [sp]
ffff0000000841fc:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff000000084200:	a90217e4 	stp	x4, x5, [sp, #32]
ffff000000084204:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff000000084208:	a90427e8 	stp	x8, x9, [sp, #64]
ffff00000008420c:	a9052fea 	stp	x10, x11, [sp, #80]
ffff000000084210:	a90637ec 	stp	x12, x13, [sp, #96]
ffff000000084214:	a9073fee 	stp	x14, x15, [sp, #112]
ffff000000084218:	a90847f0 	stp	x16, x17, [sp, #128]
ffff00000008421c:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff000000084220:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff000000084224:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff000000084228:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff00000008422c:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff000000084230:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff000000084234:	910443f5 	add	x21, sp, #0x110
ffff000000084238:	d5384036 	mrs	x22, elr_el1
ffff00000008423c:	d5384017 	mrs	x23, spsr_el1
ffff000000084240:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff000000084244:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff000000084248:	d28000c0 	mov	x0, #0x6                   	// #6
ffff00000008424c:	d5385201 	mrs	x1, esr_el1
ffff000000084250:	d5384022 	mrs	x2, elr_el1
ffff000000084254:	97fff575 	bl	ffff000000081828 <show_invalid_entry_message>
ffff000000084258:	140001b6 	b	ffff000000084930 <err_hang>

ffff00000008425c <fiq_invalid_el0_64>:

fiq_invalid_el0_64:
	handle_invalid_entry 0, FIQ_INVALID_EL0_64
ffff00000008425c:	d10443ff 	sub	sp, sp, #0x110
ffff000000084260:	a90007e0 	stp	x0, x1, [sp]
ffff000000084264:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff000000084268:	a90217e4 	stp	x4, x5, [sp, #32]
ffff00000008426c:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff000000084270:	a90427e8 	stp	x8, x9, [sp, #64]
ffff000000084274:	a9052fea 	stp	x10, x11, [sp, #80]
ffff000000084278:	a90637ec 	stp	x12, x13, [sp, #96]
ffff00000008427c:	a9073fee 	stp	x14, x15, [sp, #112]
ffff000000084280:	a90847f0 	stp	x16, x17, [sp, #128]
ffff000000084284:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff000000084288:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff00000008428c:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff000000084290:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff000000084294:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff000000084298:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff00000008429c:	d5384115 	mrs	x21, sp_el0
ffff0000000842a0:	d5384036 	mrs	x22, elr_el1
ffff0000000842a4:	d5384017 	mrs	x23, spsr_el1
ffff0000000842a8:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff0000000842ac:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff0000000842b0:	d28000e0 	mov	x0, #0x7                   	// #7
ffff0000000842b4:	d5385201 	mrs	x1, esr_el1
ffff0000000842b8:	d5384022 	mrs	x2, elr_el1
ffff0000000842bc:	97fff55b 	bl	ffff000000081828 <show_invalid_entry_message>
ffff0000000842c0:	1400019c 	b	ffff000000084930 <err_hang>

ffff0000000842c4 <error_invalid_el0_64>:

error_invalid_el0_64:
	handle_invalid_entry 0, ERROR_INVALID_EL0_64
ffff0000000842c4:	d10443ff 	sub	sp, sp, #0x110
ffff0000000842c8:	a90007e0 	stp	x0, x1, [sp]
ffff0000000842cc:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff0000000842d0:	a90217e4 	stp	x4, x5, [sp, #32]
ffff0000000842d4:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff0000000842d8:	a90427e8 	stp	x8, x9, [sp, #64]
ffff0000000842dc:	a9052fea 	stp	x10, x11, [sp, #80]
ffff0000000842e0:	a90637ec 	stp	x12, x13, [sp, #96]
ffff0000000842e4:	a9073fee 	stp	x14, x15, [sp, #112]
ffff0000000842e8:	a90847f0 	stp	x16, x17, [sp, #128]
ffff0000000842ec:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff0000000842f0:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff0000000842f4:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff0000000842f8:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff0000000842fc:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff000000084300:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff000000084304:	d5384115 	mrs	x21, sp_el0
ffff000000084308:	d5384036 	mrs	x22, elr_el1
ffff00000008430c:	d5384017 	mrs	x23, spsr_el1
ffff000000084310:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff000000084314:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff000000084318:	d2800100 	mov	x0, #0x8                   	// #8
ffff00000008431c:	d5385201 	mrs	x1, esr_el1
ffff000000084320:	d5384022 	mrs	x2, elr_el1
ffff000000084324:	97fff541 	bl	ffff000000081828 <show_invalid_entry_message>
ffff000000084328:	14000182 	b	ffff000000084930 <err_hang>

ffff00000008432c <sync_invalid_el0_32>:

sync_invalid_el0_32:
	handle_invalid_entry  0, SYNC_INVALID_EL0_32
ffff00000008432c:	d10443ff 	sub	sp, sp, #0x110
ffff000000084330:	a90007e0 	stp	x0, x1, [sp]
ffff000000084334:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff000000084338:	a90217e4 	stp	x4, x5, [sp, #32]
ffff00000008433c:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff000000084340:	a90427e8 	stp	x8, x9, [sp, #64]
ffff000000084344:	a9052fea 	stp	x10, x11, [sp, #80]
ffff000000084348:	a90637ec 	stp	x12, x13, [sp, #96]
ffff00000008434c:	a9073fee 	stp	x14, x15, [sp, #112]
ffff000000084350:	a90847f0 	stp	x16, x17, [sp, #128]
ffff000000084354:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff000000084358:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff00000008435c:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff000000084360:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff000000084364:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff000000084368:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff00000008436c:	d5384115 	mrs	x21, sp_el0
ffff000000084370:	d5384036 	mrs	x22, elr_el1
ffff000000084374:	d5384017 	mrs	x23, spsr_el1
ffff000000084378:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff00000008437c:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff000000084380:	d2800120 	mov	x0, #0x9                   	// #9
ffff000000084384:	d5385201 	mrs	x1, esr_el1
ffff000000084388:	d5384022 	mrs	x2, elr_el1
ffff00000008438c:	97fff527 	bl	ffff000000081828 <show_invalid_entry_message>
ffff000000084390:	14000168 	b	ffff000000084930 <err_hang>

ffff000000084394 <irq_invalid_el0_32>:

irq_invalid_el0_32:
	handle_invalid_entry  0, IRQ_INVALID_EL0_32
ffff000000084394:	d10443ff 	sub	sp, sp, #0x110
ffff000000084398:	a90007e0 	stp	x0, x1, [sp]
ffff00000008439c:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff0000000843a0:	a90217e4 	stp	x4, x5, [sp, #32]
ffff0000000843a4:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff0000000843a8:	a90427e8 	stp	x8, x9, [sp, #64]
ffff0000000843ac:	a9052fea 	stp	x10, x11, [sp, #80]
ffff0000000843b0:	a90637ec 	stp	x12, x13, [sp, #96]
ffff0000000843b4:	a9073fee 	stp	x14, x15, [sp, #112]
ffff0000000843b8:	a90847f0 	stp	x16, x17, [sp, #128]
ffff0000000843bc:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff0000000843c0:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff0000000843c4:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff0000000843c8:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff0000000843cc:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff0000000843d0:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff0000000843d4:	d5384115 	mrs	x21, sp_el0
ffff0000000843d8:	d5384036 	mrs	x22, elr_el1
ffff0000000843dc:	d5384017 	mrs	x23, spsr_el1
ffff0000000843e0:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff0000000843e4:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff0000000843e8:	d2800140 	mov	x0, #0xa                   	// #10
ffff0000000843ec:	d5385201 	mrs	x1, esr_el1
ffff0000000843f0:	d5384022 	mrs	x2, elr_el1
ffff0000000843f4:	97fff50d 	bl	ffff000000081828 <show_invalid_entry_message>
ffff0000000843f8:	1400014e 	b	ffff000000084930 <err_hang>

ffff0000000843fc <fiq_invalid_el0_32>:

fiq_invalid_el0_32:
	handle_invalid_entry  0, FIQ_INVALID_EL0_32
ffff0000000843fc:	d10443ff 	sub	sp, sp, #0x110
ffff000000084400:	a90007e0 	stp	x0, x1, [sp]
ffff000000084404:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff000000084408:	a90217e4 	stp	x4, x5, [sp, #32]
ffff00000008440c:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff000000084410:	a90427e8 	stp	x8, x9, [sp, #64]
ffff000000084414:	a9052fea 	stp	x10, x11, [sp, #80]
ffff000000084418:	a90637ec 	stp	x12, x13, [sp, #96]
ffff00000008441c:	a9073fee 	stp	x14, x15, [sp, #112]
ffff000000084420:	a90847f0 	stp	x16, x17, [sp, #128]
ffff000000084424:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff000000084428:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff00000008442c:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff000000084430:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff000000084434:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff000000084438:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff00000008443c:	d5384115 	mrs	x21, sp_el0
ffff000000084440:	d5384036 	mrs	x22, elr_el1
ffff000000084444:	d5384017 	mrs	x23, spsr_el1
ffff000000084448:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff00000008444c:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff000000084450:	d2800160 	mov	x0, #0xb                   	// #11
ffff000000084454:	d5385201 	mrs	x1, esr_el1
ffff000000084458:	d5384022 	mrs	x2, elr_el1
ffff00000008445c:	97fff4f3 	bl	ffff000000081828 <show_invalid_entry_message>
ffff000000084460:	14000134 	b	ffff000000084930 <err_hang>

ffff000000084464 <error_invalid_el0_32>:

error_invalid_el0_32:
	handle_invalid_entry  0, ERROR_INVALID_EL0_32
ffff000000084464:	d10443ff 	sub	sp, sp, #0x110
ffff000000084468:	a90007e0 	stp	x0, x1, [sp]
ffff00000008446c:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff000000084470:	a90217e4 	stp	x4, x5, [sp, #32]
ffff000000084474:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff000000084478:	a90427e8 	stp	x8, x9, [sp, #64]
ffff00000008447c:	a9052fea 	stp	x10, x11, [sp, #80]
ffff000000084480:	a90637ec 	stp	x12, x13, [sp, #96]
ffff000000084484:	a9073fee 	stp	x14, x15, [sp, #112]
ffff000000084488:	a90847f0 	stp	x16, x17, [sp, #128]
ffff00000008448c:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff000000084490:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff000000084494:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff000000084498:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff00000008449c:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff0000000844a0:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff0000000844a4:	d5384115 	mrs	x21, sp_el0
ffff0000000844a8:	d5384036 	mrs	x22, elr_el1
ffff0000000844ac:	d5384017 	mrs	x23, spsr_el1
ffff0000000844b0:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff0000000844b4:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff0000000844b8:	d2800180 	mov	x0, #0xc                   	// #12
ffff0000000844bc:	d5385201 	mrs	x1, esr_el1
ffff0000000844c0:	d5384022 	mrs	x2, elr_el1
ffff0000000844c4:	97fff4d9 	bl	ffff000000081828 <show_invalid_entry_message>
ffff0000000844c8:	1400011a 	b	ffff000000084930 <err_hang>

ffff0000000844cc <el1_irq>:


el1_irq:
	kernel_entry 1 
ffff0000000844cc:	d10443ff 	sub	sp, sp, #0x110
ffff0000000844d0:	a90007e0 	stp	x0, x1, [sp]
ffff0000000844d4:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff0000000844d8:	a90217e4 	stp	x4, x5, [sp, #32]
ffff0000000844dc:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff0000000844e0:	a90427e8 	stp	x8, x9, [sp, #64]
ffff0000000844e4:	a9052fea 	stp	x10, x11, [sp, #80]
ffff0000000844e8:	a90637ec 	stp	x12, x13, [sp, #96]
ffff0000000844ec:	a9073fee 	stp	x14, x15, [sp, #112]
ffff0000000844f0:	a90847f0 	stp	x16, x17, [sp, #128]
ffff0000000844f4:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff0000000844f8:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff0000000844fc:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff000000084500:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff000000084504:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff000000084508:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff00000008450c:	910443f5 	add	x21, sp, #0x110
ffff000000084510:	d5384036 	mrs	x22, elr_el1
ffff000000084514:	d5384017 	mrs	x23, spsr_el1
ffff000000084518:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff00000008451c:	a9105ff6 	stp	x22, x23, [sp, #256]
	bl	handle_irq
ffff000000084520:	97fff4d4 	bl	ffff000000081870 <handle_irq>
	kernel_exit 1 
ffff000000084524:	a9505ff6 	ldp	x22, x23, [sp, #256]
ffff000000084528:	a94f57fe 	ldp	x30, x21, [sp, #240]
ffff00000008452c:	d5184036 	msr	elr_el1, x22
ffff000000084530:	d5184017 	msr	spsr_el1, x23
ffff000000084534:	a94007e0 	ldp	x0, x1, [sp]
ffff000000084538:	a9410fe2 	ldp	x2, x3, [sp, #16]
ffff00000008453c:	a94217e4 	ldp	x4, x5, [sp, #32]
ffff000000084540:	a9431fe6 	ldp	x6, x7, [sp, #48]
ffff000000084544:	a94427e8 	ldp	x8, x9, [sp, #64]
ffff000000084548:	a9452fea 	ldp	x10, x11, [sp, #80]
ffff00000008454c:	a94637ec 	ldp	x12, x13, [sp, #96]
ffff000000084550:	a9473fee 	ldp	x14, x15, [sp, #112]
ffff000000084554:	a94847f0 	ldp	x16, x17, [sp, #128]
ffff000000084558:	a9494ff2 	ldp	x18, x19, [sp, #144]
ffff00000008455c:	a94a57f4 	ldp	x20, x21, [sp, #160]
ffff000000084560:	a94b5ff6 	ldp	x22, x23, [sp, #176]
ffff000000084564:	a94c67f8 	ldp	x24, x25, [sp, #192]
ffff000000084568:	a94d6ffa 	ldp	x26, x27, [sp, #208]
ffff00000008456c:	a94e77fc 	ldp	x28, x29, [sp, #224]
ffff000000084570:	910443ff 	add	sp, sp, #0x110
ffff000000084574:	d69f03e0 	eret

ffff000000084578 <el0_irq>:

el0_irq:
	kernel_entry 0 
ffff000000084578:	d10443ff 	sub	sp, sp, #0x110
ffff00000008457c:	a90007e0 	stp	x0, x1, [sp]
ffff000000084580:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff000000084584:	a90217e4 	stp	x4, x5, [sp, #32]
ffff000000084588:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff00000008458c:	a90427e8 	stp	x8, x9, [sp, #64]
ffff000000084590:	a9052fea 	stp	x10, x11, [sp, #80]
ffff000000084594:	a90637ec 	stp	x12, x13, [sp, #96]
ffff000000084598:	a9073fee 	stp	x14, x15, [sp, #112]
ffff00000008459c:	a90847f0 	stp	x16, x17, [sp, #128]
ffff0000000845a0:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff0000000845a4:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff0000000845a8:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff0000000845ac:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff0000000845b0:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff0000000845b4:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff0000000845b8:	d5384115 	mrs	x21, sp_el0
ffff0000000845bc:	d5384036 	mrs	x22, elr_el1
ffff0000000845c0:	d5384017 	mrs	x23, spsr_el1
ffff0000000845c4:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff0000000845c8:	a9105ff6 	stp	x22, x23, [sp, #256]
	bl	handle_irq
ffff0000000845cc:	97fff4a9 	bl	ffff000000081870 <handle_irq>
	kernel_exit 0 
ffff0000000845d0:	a9505ff6 	ldp	x22, x23, [sp, #256]
ffff0000000845d4:	a94f57fe 	ldp	x30, x21, [sp, #240]
ffff0000000845d8:	d5184115 	msr	sp_el0, x21
ffff0000000845dc:	d5184036 	msr	elr_el1, x22
ffff0000000845e0:	d5184017 	msr	spsr_el1, x23
ffff0000000845e4:	a94007e0 	ldp	x0, x1, [sp]
ffff0000000845e8:	a9410fe2 	ldp	x2, x3, [sp, #16]
ffff0000000845ec:	a94217e4 	ldp	x4, x5, [sp, #32]
ffff0000000845f0:	a9431fe6 	ldp	x6, x7, [sp, #48]
ffff0000000845f4:	a94427e8 	ldp	x8, x9, [sp, #64]
ffff0000000845f8:	a9452fea 	ldp	x10, x11, [sp, #80]
ffff0000000845fc:	a94637ec 	ldp	x12, x13, [sp, #96]
ffff000000084600:	a9473fee 	ldp	x14, x15, [sp, #112]
ffff000000084604:	a94847f0 	ldp	x16, x17, [sp, #128]
ffff000000084608:	a9494ff2 	ldp	x18, x19, [sp, #144]
ffff00000008460c:	a94a57f4 	ldp	x20, x21, [sp, #160]
ffff000000084610:	a94b5ff6 	ldp	x22, x23, [sp, #176]
ffff000000084614:	a94c67f8 	ldp	x24, x25, [sp, #192]
ffff000000084618:	a94d6ffa 	ldp	x26, x27, [sp, #208]
ffff00000008461c:	a94e77fc 	ldp	x28, x29, [sp, #224]
ffff000000084620:	910443ff 	add	sp, sp, #0x110
ffff000000084624:	d69f03e0 	eret

ffff000000084628 <el0_sync>:

el0_sync:
	kernel_entry 0
ffff000000084628:	d10443ff 	sub	sp, sp, #0x110
ffff00000008462c:	a90007e0 	stp	x0, x1, [sp]
ffff000000084630:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff000000084634:	a90217e4 	stp	x4, x5, [sp, #32]
ffff000000084638:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff00000008463c:	a90427e8 	stp	x8, x9, [sp, #64]
ffff000000084640:	a9052fea 	stp	x10, x11, [sp, #80]
ffff000000084644:	a90637ec 	stp	x12, x13, [sp, #96]
ffff000000084648:	a9073fee 	stp	x14, x15, [sp, #112]
ffff00000008464c:	a90847f0 	stp	x16, x17, [sp, #128]
ffff000000084650:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff000000084654:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff000000084658:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff00000008465c:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff000000084660:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff000000084664:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff000000084668:	d5384115 	mrs	x21, sp_el0
ffff00000008466c:	d5384036 	mrs	x22, elr_el1
ffff000000084670:	d5384017 	mrs	x23, spsr_el1
ffff000000084674:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff000000084678:	a9105ff6 	stp	x22, x23, [sp, #256]
	mrs	x25, esr_el1				// read the syndrome register
ffff00000008467c:	d5385219 	mrs	x25, esr_el1
	lsr	x24, x25, #ESR_ELx_EC_SHIFT		// exception class
ffff000000084680:	d35aff38 	lsr	x24, x25, #26
	cmp	x24, #ESR_ELx_EC_SVC64			// SVC in 64-bit state
ffff000000084684:	f100571f 	cmp	x24, #0x15
	b.eq	el0_svc
ffff000000084688:	540003a0 	b.eq	ffff0000000846fc <el0_svc>  // b.none
	cmp	x24, #ESR_ELx_EC_DABT_LOW		// data abort in EL0
ffff00000008468c:	f100931f 	cmp	x24, #0x24
	b.eq	el0_da
ffff000000084690:	54000ac0 	b.eq	ffff0000000847e8 <el0_da>  // b.none
	handle_invalid_entry 0, SYNC_ERROR
ffff000000084694:	d10443ff 	sub	sp, sp, #0x110
ffff000000084698:	a90007e0 	stp	x0, x1, [sp]
ffff00000008469c:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff0000000846a0:	a90217e4 	stp	x4, x5, [sp, #32]
ffff0000000846a4:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff0000000846a8:	a90427e8 	stp	x8, x9, [sp, #64]
ffff0000000846ac:	a9052fea 	stp	x10, x11, [sp, #80]
ffff0000000846b0:	a90637ec 	stp	x12, x13, [sp, #96]
ffff0000000846b4:	a9073fee 	stp	x14, x15, [sp, #112]
ffff0000000846b8:	a90847f0 	stp	x16, x17, [sp, #128]
ffff0000000846bc:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff0000000846c0:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff0000000846c4:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff0000000846c8:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff0000000846cc:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff0000000846d0:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff0000000846d4:	d5384115 	mrs	x21, sp_el0
ffff0000000846d8:	d5384036 	mrs	x22, elr_el1
ffff0000000846dc:	d5384017 	mrs	x23, spsr_el1
ffff0000000846e0:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff0000000846e4:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff0000000846e8:	d28001a0 	mov	x0, #0xd                   	// #13
ffff0000000846ec:	d5385201 	mrs	x1, esr_el1
ffff0000000846f0:	d5384022 	mrs	x2, elr_el1
ffff0000000846f4:	97fff44d 	bl	ffff000000081828 <show_invalid_entry_message>
ffff0000000846f8:	1400008e 	b	ffff000000084930 <err_hang>

ffff0000000846fc <el0_svc>:
sc_nr	.req	x25					// number of system calls
scno	.req	x26					// syscall number
stbl	.req	x27					// syscall table pointer

el0_svc:
	adr	stbl, sys_call_table			// load syscall table pointer
ffff0000000846fc:	100081bb 	adr	x27, ffff000000085730 <sys_call_table>
	uxtw	scno, w8				// syscall number in w8
ffff000000084700:	2a0803fa 	mov	w26, w8
	mov	sc_nr, #__NR_syscalls
ffff000000084704:	d2800079 	mov	x25, #0x3                   	// #3
	bl	enable_irq
ffff000000084708:	9400008e 	bl	ffff000000084940 <enable_irq>
	cmp     scno, sc_nr                     	// check upper syscall limit
ffff00000008470c:	eb19035f 	cmp	x26, x25
	b.hs	ni_sys
ffff000000084710:	54000082 	b.cs	ffff000000084720 <ni_sys>  // b.hs, b.nlast

	ldr	x16, [stbl, scno, lsl #3]		// address in the syscall table
ffff000000084714:	f87a7b70 	ldr	x16, [x27, x26, lsl #3]
	blr	x16					// call sys_* routine
ffff000000084718:	d63f0200 	blr	x16
	b	ret_from_syscall
ffff00000008471c:	1400001b 	b	ffff000000084788 <ret_from_syscall>

ffff000000084720 <ni_sys>:
ni_sys:
	handle_invalid_entry 0, SYSCALL_ERROR
ffff000000084720:	d10443ff 	sub	sp, sp, #0x110
ffff000000084724:	a90007e0 	stp	x0, x1, [sp]
ffff000000084728:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff00000008472c:	a90217e4 	stp	x4, x5, [sp, #32]
ffff000000084730:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff000000084734:	a90427e8 	stp	x8, x9, [sp, #64]
ffff000000084738:	a9052fea 	stp	x10, x11, [sp, #80]
ffff00000008473c:	a90637ec 	stp	x12, x13, [sp, #96]
ffff000000084740:	a9073fee 	stp	x14, x15, [sp, #112]
ffff000000084744:	a90847f0 	stp	x16, x17, [sp, #128]
ffff000000084748:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff00000008474c:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff000000084750:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff000000084754:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff000000084758:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff00000008475c:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff000000084760:	d5384115 	mrs	x21, sp_el0
ffff000000084764:	d5384036 	mrs	x22, elr_el1
ffff000000084768:	d5384017 	mrs	x23, spsr_el1
ffff00000008476c:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff000000084770:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff000000084774:	d28001c0 	mov	x0, #0xe                   	// #14
ffff000000084778:	d5385201 	mrs	x1, esr_el1
ffff00000008477c:	d5384022 	mrs	x2, elr_el1
ffff000000084780:	97fff42a 	bl	ffff000000081828 <show_invalid_entry_message>
ffff000000084784:	1400006b 	b	ffff000000084930 <err_hang>

ffff000000084788 <ret_from_syscall>:
ret_from_syscall:
	bl	disable_irq				
ffff000000084788:	94000070 	bl	ffff000000084948 <disable_irq>
	str	x0, [sp, #S_X0]				// returned x0
ffff00000008478c:	f90003e0 	str	x0, [sp]
	kernel_exit 0
ffff000000084790:	a9505ff6 	ldp	x22, x23, [sp, #256]
ffff000000084794:	a94f57fe 	ldp	x30, x21, [sp, #240]
ffff000000084798:	d5184115 	msr	sp_el0, x21
ffff00000008479c:	d5184036 	msr	elr_el1, x22
ffff0000000847a0:	d5184017 	msr	spsr_el1, x23
ffff0000000847a4:	a94007e0 	ldp	x0, x1, [sp]
ffff0000000847a8:	a9410fe2 	ldp	x2, x3, [sp, #16]
ffff0000000847ac:	a94217e4 	ldp	x4, x5, [sp, #32]
ffff0000000847b0:	a9431fe6 	ldp	x6, x7, [sp, #48]
ffff0000000847b4:	a94427e8 	ldp	x8, x9, [sp, #64]
ffff0000000847b8:	a9452fea 	ldp	x10, x11, [sp, #80]
ffff0000000847bc:	a94637ec 	ldp	x12, x13, [sp, #96]
ffff0000000847c0:	a9473fee 	ldp	x14, x15, [sp, #112]
ffff0000000847c4:	a94847f0 	ldp	x16, x17, [sp, #128]
ffff0000000847c8:	a9494ff2 	ldp	x18, x19, [sp, #144]
ffff0000000847cc:	a94a57f4 	ldp	x20, x21, [sp, #160]
ffff0000000847d0:	a94b5ff6 	ldp	x22, x23, [sp, #176]
ffff0000000847d4:	a94c67f8 	ldp	x24, x25, [sp, #192]
ffff0000000847d8:	a94d6ffa 	ldp	x26, x27, [sp, #208]
ffff0000000847dc:	a94e77fc 	ldp	x28, x29, [sp, #224]
ffff0000000847e0:	910443ff 	add	sp, sp, #0x110
ffff0000000847e4:	d69f03e0 	eret

ffff0000000847e8 <el0_da>:

el0_da:
	bl	enable_irq
ffff0000000847e8:	94000056 	bl	ffff000000084940 <enable_irq>
	mrs	x0, far_el1
ffff0000000847ec:	d5386000 	mrs	x0, far_el1
	mrs	x1, esr_el1			
ffff0000000847f0:	d5385201 	mrs	x1, esr_el1
	bl	do_mem_abort
ffff0000000847f4:	97fff584 	bl	ffff000000081e04 <do_mem_abort>
	cmp x0, 0
ffff0000000847f8:	f100001f 	cmp	x0, #0x0
	b.eq 1f
ffff0000000847fc:	54000360 	b.eq	ffff000000084868 <el0_da+0x80>  // b.none
	handle_invalid_entry 0, DATA_ABORT_ERROR
ffff000000084800:	d10443ff 	sub	sp, sp, #0x110
ffff000000084804:	a90007e0 	stp	x0, x1, [sp]
ffff000000084808:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff00000008480c:	a90217e4 	stp	x4, x5, [sp, #32]
ffff000000084810:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff000000084814:	a90427e8 	stp	x8, x9, [sp, #64]
ffff000000084818:	a9052fea 	stp	x10, x11, [sp, #80]
ffff00000008481c:	a90637ec 	stp	x12, x13, [sp, #96]
ffff000000084820:	a9073fee 	stp	x14, x15, [sp, #112]
ffff000000084824:	a90847f0 	stp	x16, x17, [sp, #128]
ffff000000084828:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff00000008482c:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff000000084830:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff000000084834:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff000000084838:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff00000008483c:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff000000084840:	d5384115 	mrs	x21, sp_el0
ffff000000084844:	d5384036 	mrs	x22, elr_el1
ffff000000084848:	d5384017 	mrs	x23, spsr_el1
ffff00000008484c:	a90f57fe 	stp	x30, x21, [sp, #240]
ffff000000084850:	a9105ff6 	stp	x22, x23, [sp, #256]
ffff000000084854:	d28001e0 	mov	x0, #0xf                   	// #15
ffff000000084858:	d5385201 	mrs	x1, esr_el1
ffff00000008485c:	d5384022 	mrs	x2, elr_el1
ffff000000084860:	97fff3f2 	bl	ffff000000081828 <show_invalid_entry_message>
ffff000000084864:	14000033 	b	ffff000000084930 <err_hang>
1:
	bl disable_irq				
ffff000000084868:	94000038 	bl	ffff000000084948 <disable_irq>
	kernel_exit 0
ffff00000008486c:	a9505ff6 	ldp	x22, x23, [sp, #256]
ffff000000084870:	a94f57fe 	ldp	x30, x21, [sp, #240]
ffff000000084874:	d5184115 	msr	sp_el0, x21
ffff000000084878:	d5184036 	msr	elr_el1, x22
ffff00000008487c:	d5184017 	msr	spsr_el1, x23
ffff000000084880:	a94007e0 	ldp	x0, x1, [sp]
ffff000000084884:	a9410fe2 	ldp	x2, x3, [sp, #16]
ffff000000084888:	a94217e4 	ldp	x4, x5, [sp, #32]
ffff00000008488c:	a9431fe6 	ldp	x6, x7, [sp, #48]
ffff000000084890:	a94427e8 	ldp	x8, x9, [sp, #64]
ffff000000084894:	a9452fea 	ldp	x10, x11, [sp, #80]
ffff000000084898:	a94637ec 	ldp	x12, x13, [sp, #96]
ffff00000008489c:	a9473fee 	ldp	x14, x15, [sp, #112]
ffff0000000848a0:	a94847f0 	ldp	x16, x17, [sp, #128]
ffff0000000848a4:	a9494ff2 	ldp	x18, x19, [sp, #144]
ffff0000000848a8:	a94a57f4 	ldp	x20, x21, [sp, #160]
ffff0000000848ac:	a94b5ff6 	ldp	x22, x23, [sp, #176]
ffff0000000848b0:	a94c67f8 	ldp	x24, x25, [sp, #192]
ffff0000000848b4:	a94d6ffa 	ldp	x26, x27, [sp, #208]
ffff0000000848b8:	a94e77fc 	ldp	x28, x29, [sp, #224]
ffff0000000848bc:	910443ff 	add	sp, sp, #0x110
ffff0000000848c0:	d69f03e0 	eret

ffff0000000848c4 <ret_from_fork>:

.globl ret_from_fork
ret_from_fork:
	bl	schedule_tail
ffff0000000848c4:	97fff695 	bl	ffff000000082318 <schedule_tail>
	cbz	x19, ret_to_user			// not a kernel thread
ffff0000000848c8:	b4000073 	cbz	x19, ffff0000000848d4 <ret_to_user>
	mov	x0, x20
ffff0000000848cc:	aa1403e0 	mov	x0, x20
	blr	x19
ffff0000000848d0:	d63f0260 	blr	x19

ffff0000000848d4 <ret_to_user>:
ret_to_user:
	bl disable_irq				
ffff0000000848d4:	9400001d 	bl	ffff000000084948 <disable_irq>
	kernel_exit 0 
ffff0000000848d8:	a9505ff6 	ldp	x22, x23, [sp, #256]
ffff0000000848dc:	a94f57fe 	ldp	x30, x21, [sp, #240]
ffff0000000848e0:	d5184115 	msr	sp_el0, x21
ffff0000000848e4:	d5184036 	msr	elr_el1, x22
ffff0000000848e8:	d5184017 	msr	spsr_el1, x23
ffff0000000848ec:	a94007e0 	ldp	x0, x1, [sp]
ffff0000000848f0:	a9410fe2 	ldp	x2, x3, [sp, #16]
ffff0000000848f4:	a94217e4 	ldp	x4, x5, [sp, #32]
ffff0000000848f8:	a9431fe6 	ldp	x6, x7, [sp, #48]
ffff0000000848fc:	a94427e8 	ldp	x8, x9, [sp, #64]
ffff000000084900:	a9452fea 	ldp	x10, x11, [sp, #80]
ffff000000084904:	a94637ec 	ldp	x12, x13, [sp, #96]
ffff000000084908:	a9473fee 	ldp	x14, x15, [sp, #112]
ffff00000008490c:	a94847f0 	ldp	x16, x17, [sp, #128]
ffff000000084910:	a9494ff2 	ldp	x18, x19, [sp, #144]
ffff000000084914:	a94a57f4 	ldp	x20, x21, [sp, #160]
ffff000000084918:	a94b5ff6 	ldp	x22, x23, [sp, #176]
ffff00000008491c:	a94c67f8 	ldp	x24, x25, [sp, #192]
ffff000000084920:	a94d6ffa 	ldp	x26, x27, [sp, #208]
ffff000000084924:	a94e77fc 	ldp	x28, x29, [sp, #224]
ffff000000084928:	910443ff 	add	sp, sp, #0x110
ffff00000008492c:	d69f03e0 	eret

ffff000000084930 <err_hang>:


.globl err_hang
err_hang: b err_hang
ffff000000084930:	14000000 	b	ffff000000084930 <err_hang>

ffff000000084934 <irq_vector_init>:
.globl irq_vector_init
irq_vector_init:
	adr	x0, vectors				// load VBAR_EL1 with virtual
ffff000000084934:	10ff7660 	adr	x0, ffff000000083800 <vectors>
	msr	vbar_el1, x0				// vector table address
ffff000000084938:	d518c000 	msr	vbar_el1, x0
	ret
ffff00000008493c:	d65f03c0 	ret

ffff000000084940 <enable_irq>:

.globl enable_irq
enable_irq:
	msr    daifclr, #2 
ffff000000084940:	d50342ff 	msr	daifclr, #0x2
	ret
ffff000000084944:	d65f03c0 	ret

ffff000000084948 <disable_irq>:

.globl disable_irq
disable_irq:
	msr	daifset, #2
ffff000000084948:	d50342df 	msr	daifset, #0x2
	ret
ffff00000008494c:	d65f03c0 	ret

ffff000000084950 <memcpy>:
.globl memcpy
memcpy:
	ldr x3, [x0], #8
ffff000000084950:	f8408403 	ldr	x3, [x0], #8
	str x3, [x1], #8
ffff000000084954:	f8008423 	str	x3, [x1], #8
	subs x2, x2, #8
ffff000000084958:	f1002042 	subs	x2, x2, #0x8
	b.gt memcpy
ffff00000008495c:	54ffffac 	b.gt	ffff000000084950 <memcpy>
	ret
ffff000000084960:	d65f03c0 	ret

ffff000000084964 <memzero>:

.globl memzero
memzero:
	str xzr, [x0], #8
ffff000000084964:	f800841f 	str	xzr, [x0], #8
	subs x1, x1, #8
ffff000000084968:	f1002021 	subs	x1, x1, #0x8
	b.gt memzero
ffff00000008496c:	54ffffcc 	b.gt	ffff000000084964 <memzero>
	ret
ffff000000084970:	d65f03c0 	ret

ffff000000084974 <cpu_switch_to>:
#include "sched.h"

.globl cpu_switch_to
cpu_switch_to:
	mov	x10, #THREAD_CPU_CONTEXT
ffff000000084974:	d280000a 	mov	x10, #0x0                   	// #0
	add	x8, x0, x10
ffff000000084978:	8b0a0008 	add	x8, x0, x10
	mov	x9, sp
ffff00000008497c:	910003e9 	mov	x9, sp
	stp	x19, x20, [x8], #16		// store callee-saved registers
ffff000000084980:	a8815113 	stp	x19, x20, [x8], #16
	stp	x21, x22, [x8], #16
ffff000000084984:	a8815915 	stp	x21, x22, [x8], #16
	stp	x23, x24, [x8], #16
ffff000000084988:	a8816117 	stp	x23, x24, [x8], #16
	stp	x25, x26, [x8], #16
ffff00000008498c:	a8816919 	stp	x25, x26, [x8], #16
	stp	x27, x28, [x8], #16
ffff000000084990:	a881711b 	stp	x27, x28, [x8], #16
	stp	x29, x9, [x8], #16
ffff000000084994:	a881251d 	stp	x29, x9, [x8], #16
	str	x30, [x8]
ffff000000084998:	f900011e 	str	x30, [x8]
	add	x8, x1, x10
ffff00000008499c:	8b0a0028 	add	x8, x1, x10
	ldp	x19, x20, [x8], #16		// restore callee-saved registers
ffff0000000849a0:	a8c15113 	ldp	x19, x20, [x8], #16
	ldp	x21, x22, [x8], #16
ffff0000000849a4:	a8c15915 	ldp	x21, x22, [x8], #16
	ldp	x23, x24, [x8], #16
ffff0000000849a8:	a8c16117 	ldp	x23, x24, [x8], #16
	ldp	x25, x26, [x8], #16
ffff0000000849ac:	a8c16919 	ldp	x25, x26, [x8], #16
	ldp	x27, x28, [x8], #16
ffff0000000849b0:	a8c1711b 	ldp	x27, x28, [x8], #16
	ldp	x29, x9, [x8], #16
ffff0000000849b4:	a8c1251d 	ldp	x29, x9, [x8], #16
	ldr	x30, [x8]
ffff0000000849b8:	f940011e 	ldr	x30, [x8]
	mov	sp, x9
ffff0000000849bc:	9100013f 	mov	sp, x9
	ret
ffff0000000849c0:	d65f03c0 	ret

ffff0000000849c4 <get_el>:
.globl get_el
get_el:
	mrs x0, CurrentEL
ffff0000000849c4:	d5384240 	mrs	x0, currentel
	lsr x0, x0, #2
ffff0000000849c8:	d342fc00 	lsr	x0, x0, #2
	ret
ffff0000000849cc:	d65f03c0 	ret

ffff0000000849d0 <put32>:

.globl put32
put32:
	str w1,[x0]
ffff0000000849d0:	b9000001 	str	w1, [x0]
	ret
ffff0000000849d4:	d65f03c0 	ret

ffff0000000849d8 <get32>:

.globl get32
get32:
	ldr w0,[x0]
ffff0000000849d8:	b9400000 	ldr	w0, [x0]
	ret
ffff0000000849dc:	d65f03c0 	ret

ffff0000000849e0 <delay>:

.globl delay
delay:
	subs x0, x0, #1
ffff0000000849e0:	f1000400 	subs	x0, x0, #0x1
	bne delay
ffff0000000849e4:	54ffffe1 	b.ne	ffff0000000849e0 <delay>  // b.any
	ret
ffff0000000849e8:	d65f03c0 	ret

ffff0000000849ec <set_pgd>:

.globl set_pgd
set_pgd:
	msr	ttbr0_el1, x0
ffff0000000849ec:	d5182000 	msr	ttbr0_el1, x0
	tlbi vmalle1is
ffff0000000849f0:	d508831f 	tlbi	vmalle1is
  	DSB ISH              // ensure completion of TLB invalidation
ffff0000000849f4:	d5033b9f 	dsb	ish
	isb
ffff0000000849f8:	d5033fdf 	isb
	ret
ffff0000000849fc:	d65f03c0 	ret

ffff000000084a00 <get_pgd>:

.globl get_pgd
get_pgd:
	mov x1, 0
ffff000000084a00:	d2800001 	mov	x1, #0x0                   	// #0
	ldr x0, [x1]
ffff000000084a04:	f9400020 	ldr	x0, [x1]
	mov x0, 0x1000
ffff000000084a08:	d2820000 	mov	x0, #0x1000                	// #4096
	msr	ttbr0_el1, x0
ffff000000084a0c:	d5182000 	msr	ttbr0_el1, x0
	ldr x0, [x1]
ffff000000084a10:	f9400020 	ldr	x0, [x1]
	ret
ffff000000084a14:	d65f03c0 	ret
