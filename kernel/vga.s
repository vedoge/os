/* this assembly file is my early attempt at integrating assembly and C code, and getting the two to work together */
/* to this end, I have chosen to write assembly routines, which will be assembled by our GAS cross-compiler into an object file */
/* to successfully pass the test, this code must successfully work with GCC-compiled code to produce a working VGA write */
/* to be compiled using target-triplet: i686-elf-gcc (with a headless cross compiler) */

.globl vga_puts, vga_putchar, strlen
.section .rodata
.extern VGA_COLS, VGA_ROWS 	/* as defined in header, NOT AS A MACRO NOTE */
.type	VGA_COLS, @object
.size	VGA_COLS, 1
.type	VGA_ROWS, @object
.size	VGA_ROWS, 1
.text
.type	vga_putchar, @function
.type	strlen, @function
.type	vga_puts, @function
	/* we have to set up our stack for us - arguments are above ebp in left-to-right order */
	/* cdecl guarantees that our arguments are in left-to-right order with increasing memory, starting at [esp + 4] */
	/* a small problem - gcc emits code that requires stack to be aligned to a 16-bit boundary. I'm not sure if this is a problem but the behaviour of gcc must be considered here. */
	/* I need to do some research on this */
 /*	Note: so I did a little digging. anyway:
	We should be okay. GCC sets up our stack more or less as expected.
	I'm a little suspicious about our VGA printing functions because GCC puts dwords on the stack instead of bytes, but that sounds like a GCC skill issue */
	/* Either way, I've modified the functions to fit this */
vga_putchar:
	/* size_t vga_putchar (unsigned char uc, unsigned char attrib, uint8_t x, uint8_t y); */
	/* returns number of characters actually printed */
	push %ebp			/* save old stack frame */
	movl %esp, %ebp			/* start new stack frame */

	push %esi			/* store */
	push %edi			/* callee-saved registers */

	movb 20(%ebp), %ah		/* store y in ah */
	movb 16(%ebp), %al		/*  store x in al */
	call compute_vga_pointer	/* function below */

	stosw				/* put the loaded value in AX into the calculated address */

	pop %edi			/* restore callee-saved registers */
	pop %esi			/* Ditto */

	mov %ebp, %esp			/* stack 0 */
	pop %ebp			/* restore old stack frame; esp now points to the return address */
	ret
	
strlen:
	/* size_t strlen (const char * str); */
	push %ebp
	movl %esp, %ebp			/* start new stack frame */

	push %esi			/* callee-saved register */

	movl 8(%ebp), %esi		/* get dword ptr to our string from old stack */
	movl $-1, %ecx		/* -1 in 2's complement; maximum strlen of 2^32-1 */

	cld				/* scan forwards */
repnz	scasb				/* scan for 0; decrement ecx */
	std				/* at this point, ecx contains -(strlen+2) (-strlen + original -1 + null-terminator) */

	not %ecx			/* 2's complement, but without the "add 1" - gives you (strlen + 1) */
	dec %ecx			/* decrement once more to get (strlen) */
	movl %ecx, %eax			/* put in return value */ 

	popl %esi			/* restore callee-saved register */

	movl %ebp, %esp
	pop %ebp

	ret				/* return */
vga_puts:	
	/* void vga_puts (char * str, unsigned char attrib, uint8_t x, uint8_t y); */	
	push %ebp
	movl %esp, %ebp			/* same old */

	push %esi
	push %edi			/* callee-saved registers */

	movb 20(%ebp), %ah		/* put the y-coordinate into edi for some pointer arithmetic */
	movb 16(%ebp), %al		/* add x */
	call compute_vga_pointer	/* function below (result in edi) */

	movb 12(%ebp), %ah		/* put the vga attrib byte in ah (to be elaborated on later )*/

	movl 8(%ebp), %esi		/* store your pointer in %esi for later */

	movl $-1, %ecx			/* -1 in 2's complement to store our string length */
	cld
.loop:					/* this loop structure is awkward but sorta works */	
	lodsb				/* put the byte at esi (our string address) into al and increment esi */
					/* ax now contains our vga word consisting of high attributes byte and low character */
	cmp $0, %al			/* check if we hit the null terminator */
	je .done

	stosw				/* if we didn't, put into memory at (0xb8000 + (row * VGA_COLS) + col) */
	loop .loop			/* decrement ecx and jump back (slow, but we kill two birds with one stone) */
.done:
	std				/* restore our original direction flag */
	not %ecx
	dec %ecx			/* same string manip trick as detailed in strlen */
	mov %ecx, %eax			/* return number of characters printed */
	pop %edi
	pop %esi			/* clean up */
	movl %ebp, %esp
	pop %ebp
	ret
compute_vga_pointer:
	/* al = x
	   ah = y
	   result in edi */
	push %ebx

	movzbl %al, %ebx
	shl $8, %eax
	imul $(VGA_COLS), %eax
	addl %ebx, %eax
	imul $2, %eax
	addl $0xb8000, %eax
	popl %ebx
	movl %eax, %edi
	ret
