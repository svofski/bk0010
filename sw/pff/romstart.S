/*
 * Startup code for standalone programs usable in monitor
 * without RAM extensions. 
 * Requires TOPSYS to be defined * e.g. -DTOPSYS=040000
 *
 * This file is based on BKUNIX project. 
 */

/*
 * This file is part of BKUNIX project, which is distributed
 * under the terms of the GNU General Public License (GPL).
 * See the accompanying file "COPYING" for more details.
 */


	.globl	_edata
	.globl	_main
	.data

    KISA = 0177600
    MMUCTL = 0177700

/-----------------------
/ System starts here.
/
	.text
init:
    / init ram map: linear, all writable (bit 15 set)
    mov $0100000, r0
    mov $KISA, r1
9:
    mov r0, (r1)+
    add $0200, r0
    bit $02000, r0
    beq 9b

    / enable mapping
    / bis $2, *$MMUCTL  

    / copy self to ram area at 01000
    mov $0100000, r0
    mov $01000, r1
    mov $4096, r3 / decimal
5:  mov (r0)+,(r1)+
    sob r3, 5b

	mov	$_edata,r0		/ clear bss and stack
1:	clr	(r0)+
	cmp	r0,$ TOPSYS
	blo	1b

	mov	r0,sp			/ set up stack pointer

    / call main and make it return into 01000-space
    mov $Lret, r0
    jsr r0, *$_main

Lret:
    / this will execute in 01000-space after return from main
    / disable shadow 
    bic $1, *$MMUCTL
    / enable mapping
    bis $2, *$MMUCTL
    / boot bios
    jmp *$0100000
