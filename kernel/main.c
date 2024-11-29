/* temporarily contains routines intended to test different bits of the OS. */
#ifndef __CONFIG_H
#include <config.h>
#endif
#ifndef __VGA_H
#include <hw/vga/vga.h>
#endif
#ifndef __INTERRUPTS_H
#include <arch/i386/interrupts.h>
#endif
#ifndef __GDT_H
/* #include <arch/i386/gdt.h> */
#endif
#ifndef __I8259_H
#include <hw/i8259/i8259.h>
#endif
#ifndef __I8042_H
#include <hw/i8042/i8042.h>
#endif
#ifndef __IO_H
#include <arch/i386/io.h>
#endif

/* 
 * Triple faults because the handler has a not-present selector...?
 * maybe I need to reload the GDT again. Anyway, me out.
 * The problem turned out to be really silly. I messed up the pointer
 * arithmetic (forgot that C changes pointers by sizeof(*p) when
 * incrementing or decrementing, not just 1).
 * Rookie mistake that shows just how rusty I am with this sort of thing.
 * Next is trying to get the PIC to do things.
 * */
idt_entry ivt_entry_list[NR_INTERRUPTS];
idt_entry * const idt = &ivt_entry_list[0];
int main(void) {
	/* TO ADD - set up GDT with TSS */
	char * hello = "hello, ELF World!\n";		/* test string */
	vga_puts(hello,VGA_ATTRIB(VGA_BLINK | VGA_BLACK, VGA_BRIGHT | VGA_WHITE));
	init_interrupts(idt);				/* fill with default handler */
	
	cli();
	init_8259();					/* initialise the PIC */
	lidt(idt);
	init_8042();					/* initialise the keyboard controller */
	sti();						/* enable interrupts */
	init_82077a();					/* initialise the floppy controller */
	void * sect = read_sectors(1,1,0);
	for(;;)
		asm volatile ("hlt");				/* stop here and wait for interrupts */
}
