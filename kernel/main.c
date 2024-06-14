#include <vga.h>
#ifndef __INTERRUPTS_H
#include <arch/i386/interrupts.h>
#endif
/* Triple faults because the handler has a not-present selector...?
 * maybe I need to reload the GDT again. Anyway, me out.  	*/
int main(void) {
	asm("hlt");
	idt_entry ivt_entry_list[256];			/* mostly here to reserve space at compile time */
	idt_entry * idt = &ivt_entry_list[0];		/* pointer to iterate */
	init_interrupts(idt);
	char * hello = "hello, ELF World!\n";		/* test string */
	vga_puts(hello,VGA_ATTRIB(VGA_BLINK | VGA_BLACK, VGA_BRIGHT | VGA_WHITE));
	asm("hlt;int $0x13");
	asm("cli;hlt");					/* stop here */
}
