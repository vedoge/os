.globl	_entry
.type	_entry, @function 
_entry:
	//this file is written as the start of the kernel. 
	//we are currently at offset 0x2000, so page tables won't overwrite us.
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
	movb  $1, %al		//ICW1: INIT, ICW4_PRESENT
	outb %al, $0x20		//send out
	nop; nop		//delay so things are ready
	outb %al, $0xa0		//send to sub PIC
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
	lidt ($idtr)		//load a dummy IDT
	//I'll assume stuff will set itself up as it pleases
	//set up paging
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
	orl $0x1, (0x0)		//set P=1 for the first page directory entry
	xor %eax, %eax		//our page directory offset
	movl %eax, %cr3		//load cr3 with our page directory offset (0)

	movl %cr0, %eax 	//load the machine status dword
	or $0x80000000, %eax	//PG_ENABLE
	movl %eax, %cr0		//put it back so changes are in effect

	ljmp *pg_enabled	//flush the prefetch queue (no longer valid)
	//we will triple fault if something goes wrong here
	//todo get this to actually worked
pg_enabled:
	//main will set up interrupts and drivers for us, possibly
	//otherwise, we're more or less done here
idt: .fill 1024, 0		//1024 IDT addresses with no interrupts
idtr: 	.long idt		//starting address of IDT
	.word idtr-idt		//length of IDT in bytes
gdtr:	.long 0	
	.word 0
