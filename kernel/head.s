_entry:
	//this file is written as the start of the kernel. 
	//we are currently at offset 0x2000 (todo), so page tables won't overwrite us.
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
	outb $0x20, %al		//send out
	nop; nop		//delay so things are ready
	outb $0xa0, %al		//send to sub PIC
	nop; nop 
	movb $0x20, %al		//ICW2: vector offset
	outb $0x21, %al		//send the vector offset to the dom PIC
	or $0xf, %eax		//add for the vector offset of sub PIC
	outb $0xa1, %al		//send to sub PIC
	nop; nop
				//ICW3: IDENTITY
	movb $0x04, %al
	outb $0x21, %al		//tell dom PIC its identity and where its sub PIC is
	nop; nop
	movb $0x02, %al		//sub PIC
	outb $0xa1, %al		//haha u r not dom PIC
	nop; nop
	pop %eax
	outb $0xa1, %al	
	nop; nop
	pop %eax
	outb $0x21, %al
	nop; nop
	//PICs are now configured 
	//set up IDT
	movl $0x0fff, %edi	//fill up 1000 bytes
	movl %edi, %ecx		//for performance / size reasons
	movl $0x2, %eax		//no page directory
rep 	stosd			//throwing it at memory
	//our page directory now contains 1024 not-present tables
	//from 0x0000 to 0x0fff
	cld			//makes maths easier
	movl $0x1000, %edi
	movl $0x0fff, %ecx
	mov -0x1000(%edi), %eax
	shr $0x10, %eax
 	or $3, %eax
rep	stosd			//first entry (first page) is present
	or $0x1, ($0x0)
	xor %eax, %eax
	movl %eax, %cr3		//load cr3 with our page directory offset (0)
	movl %cr0, %eax 	//load the machine status dword
	or $0x80000000, %eax	//PG_ENABLE
	movl %eax, %cr0		//put it back so changes are in effect
	jmp *pg_enabled		//make sure paging is enabled
pg_enabled:
	//main will set up interrupts and drivers for us, possibly
	//otherwise, we're more or less done here
	//move the GDT to where it should be (0x2000, overwriting the first portion of this code) 
	sgdt [gdtr]
	movzwd [gdtr+4], %ecx
	movl [gdtr], %esi
	movl $0x2000, %edi
	movl %edi, [gdtr]
	shl %ecx, 2		//get dwords. If this discards bits then we have other problems
rep movsd
	ldgt [gdtr]		//load the gdt in its rightful place (MAY NEED FIXING)
idt: .fill 1024, 0		//1024 IDT addresses with no interrupts
idtr: 	dd idt
	dw $-idtr
gdtr:	.dword 0	
	.word 0
