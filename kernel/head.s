.globl	_entry
.type	_entry, @function 
/*
.extern div_zero, step, nmi, breakpoint, bound, instr_inval, x87_absent
.extern double_fault, segment_overrun, tss_inval, segment_absent
.extern overflow, gpf, page_fault,  x87_err
*/
.org 0x4000
_entry:
	//this file is written as the start of the kernel. 
	//we are currently at offset 0x4000 (todo), so page tables won't overwrite us.
	//our job is to initialise a dummy IDT (drivers will put themselves into
	//the IDT as they please)
	//we will also reprogram the 8259s, and point them to interrupt vectors
	//0x20-0x3F (assuming a double-PIC system)
	cli			//can't be too cautious
	//first 8 MiB is identity paged, all interrupt vectors here
	//everything else is demand-paging
	//device drivers have a reserved section somewhere for a jump table
	//rest is paged
	//reprogram 8259s
	inb $0x20 ,%al		//save the dom PIC's identity
	push %eax		//on the stack
	inb $0xa0, %al		//save the sub PIC's identity
	push %eax		//on the stack
	movb  $0x11, %al	//ICW1_INIT|ICW4_PRESENT
	outb %al, $0x20		//send out
	nop; nop		//delay so things are ready
	outb %al, $0xa0		//send to sub PIC
	nop; nop 
	movb $0x20, %al		//ICW2: vector offset
	outb %al, $0x21		//send the vector offset to the dom PIC
	or $0xf, %eax		//add for the vector offset of sub PIC
	outb %al, $0xa1		//send to sub PIC
	nop; nop
				//ICW3: IDENTITY
	movb $0x04, %al
	outb %al, $0x21		//tell dom PIC its identity and where its sub PIC is
	nop; nop
	movb $0x02, %al		//sub PIC
	outb %al, $0xa1		//haha u r not dom PIC
	nop; nop
	pop %eax
	outb %al, $0xa1		//restore the identities
	nop; nop
	pop %eax
	outb %al, $0x21		//restore the identity things
	nop; nop
	//PICs are now configured 
	//set up IDT
	movl $0x0fff, %edi	//fill up 1000 bytes
	movl %edi, %ecx		//for performance / size reasons
	movl $0x2, %eax		//no page directory
rep 	stosl			//throwing it at memory
	//our page directory now contains 1024 not-present tables
	//from 0x0000 to 0x0fff
	cld			//makes maths easier
	movl $0x1000, %edi
	movl $0x0fff, %ecx
	mov -0x1000(%edi), %eax
	shr $0x10, %eax
 	or $3, %eax
rep	stosl			//first entry (first page) is present
	orl $0x1, (0x0)
	xor %eax, %eax
	movl %eax, %cr3		//load cr3 with our page directory offset (0)
	movl %cr0, %eax 	//load the machine status dword
	or $0x80000000, %eax	//PG_ENABLE
	movl %eax, %cr0		//put it back so changes are in effect
	ljmp *main		//go!
gdtr:	.long 0	
	.word 0
