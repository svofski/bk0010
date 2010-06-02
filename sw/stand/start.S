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
	.globl	_bootdev
    .globl  _savedsp
	.globl	_main
	.data
_bootdev: .word	0
_savedsp: .word 0


/-----------------------
/ System starts here.
/
	.text
init:
	mov	r0,*$_bootdev		/ save boot floppy number
    mov sp,*$_savedsp

	mov	$_edata,r0		/ clear bss and stack
1:	clr	(r0)+
	cmp	r0,$ TOPSYS
	blo	1b

	mov	r0,sp			/ set up stack pointer
	jsr	pc,_main
    mov *$_savedsp, sp
	rts pc
