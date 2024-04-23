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
	movl $0x0fff, %edi
	movl $0x0fff, %ecx
	movl $0x2, %eax		//no page directory
rep 	stosd
	//our page directory now contains 1024 not-present tables
	//from 0x0000 to 0x0fff
	cld			//makes maths easier
	movl $0x1000, %edi
	movl $0x0fff, %ecx
	mov -0x1000(%edi), %eax
	shr $0x10, %eax
 	or $3, %eax
rep	stosd
	or $0x1, ($0x0)
	movl %cr0, %eax 
	or $0x80000000, %eax
	movl %eax, %cr0 
	movl $0, %eax
	movl %eax, %cr3		//paging table 
	movl %
