/* this assembly file is my early attempt at integrating assembly and C code, and getting the two to work together */
/* to this end, I have chosen to write assembly routines, which will be assembled by our GAS cross-compiler into an object file */
/* to successfully pass the test, this code must successfully work with GCC-compiled code to produce a working VGA write */
/* to be compiled using target-triplet: i686-elf-gcc (with a headless cross compiler) */

.globl vga_puts, vga_putchar, strlen
.extern VGA_COLS, VGA_ROWS 	/* as defined in header, NOT AS A MACRO NOTE */
.text
.type	vga_putchar, @function
.type	strlen, @function
.type	vga_puts, @function
.type	VGA_COLS, @object
.type	VGA_ROWS, @object
vga_putchar:
	/* void vga_putchar (unsigned char uc, unsigned char attrib, uint8_t x, uint8_t y); */
	/* we have to set up our stack for us - arguments are above ebp in left-to-right order */
	/* cdecl guarantees that our arguments are in left-to-right order with increasing memory, starting at [esp + 4] */
	/* a small problem - gcc emits code that requires stack to be aligned to a 16-bit boundary. I'm not sure if this is a problem but the behaviour of gcc must be considered here. */
	/* I need to do some research on this */
 /*	Note: so I did a little thingummy. anyway:
	We should be okay. GCC sets up our stack more or less as expected.
	I'm a lil suspicious about our VGA printing functions because GCC puts dwords on the stack instead of bytes, but that sounds like a GCC skill issue */
	pushl %ebp			/* save old stack frame */
	movl %esp, %ebp			/* start new stack frame */
	pushl %esi			/* store */
	pushl %edi			/* callee-saved registers */
	movb $8(%ebp), %ah		/* that's our VGA attrib byte */
	movb $4(%ebp), %al		/* store character in low byte without disturbing the rest of eax */
	movl $16(%ebp), %edi		/* start with pointer arithmetic - load the row coordinate */
	imul $(VGA_COLS), %edi		/* multiply row by number of columns */
	addl $12(%ebp), %edi		/* add our column variable */
	imul $2, %edi			/* 2 bytes per entry */
	addl $0xb8000, %edi		/* add our VGA address in */
	stosw				/* put the loaded value in AX into the calculated address */
	pop %edi			/* restore callee-saved registers */
	pop %esi			/* Ditto */
	mov %ebp, %esp			/* stack 0 */
	pop %ebp			/* restore old stack frame; esp now points to the return address */
	ret
	
strlen:
	/* size_t strlen (const char * str); */
	pushl %ebp
	movl %esp, %ebp			/* start new stack frame */
	pushl %esi			/* callee-saved register */
	movl $4(%ebp), %esi		/* get dword ptr to our string from old stack */
	movl $0xffff, %ecx		/* -1 in 2's complement; maximum strlen of 2^32-1 */
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
	pushl %ebp
	movl %esp, %ebp			/* same old */
	pushl %esi
	pushl %edi			/* callee-saved registers */
	movl $4(%ebp), %esi		/* store your pointer in %esi for later */
	movb $8(%ebp), %ah		/* put the vga attrib byte in ah (to be elaborated on later */
	movl $16(%ebp), %edi		/* ugly pointer arithmetic that is most likely wrong - fix? */
	imul $(VGA_COLS), %edi		/* NOTE */
	addl $12(%ebp), %edi		/* add x */
	imul $2, %edi
	addl $0xb8000, %edi
	movl %ecx, $0xffff		/* -1 in 2's complement to store our string length */
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

