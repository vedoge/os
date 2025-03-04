/* temporarily contains routines intended to test different bits of the OS. */
/* I'll eventually have this initialise usermode and hand off to INIT.BIN and CMD.BIN */
#include <config.h>
#include <hw/vga/vga.h>
#include <arch/i386/interrupts.h>
/* #include <arch/i386/gdt.h> */
#include <hw/i8259/i8259.h>
#include <hw/i8042/i8042.h>
#include <hw/i82077a/i82077a.h>
#include <arch/i386/io.h>

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
	read_sectors(0,1);
	for(;;)
		asm volatile ("hlt");				/* stop here and wait for interrupts */
}
