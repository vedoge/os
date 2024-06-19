#include <arch/i386/interrupts.h>
#ifndef __VGA_H
#include <hw/vga/vga.h>
#endif
/* 
 * whatever is commented out below was formerly used for testing,
 * but is now superseded by an actual keyboard driver in i8042.c 
 * that also implements the requisite ISR
 */
/*
#include <hw/i8259/i8259.h>
#include <arch/i386/io.h>
*/
void lidt(idt_entry * idt) {
	idtr_t idtr;
	idt_entry * ranger; 
	while(ranger->options_byte) ranger++;
	
	idtr.table = idt;
	idtr.length = (ranger - idt)/8-1;
	asm volatile ("lidt (%0)" \
			: /* no output */ \
			: "r" (&idtr) \
			: /* no clobber */ \
			);
	return; 

}
void set_idt_entry(idt_entry * idt, uint16_t selector, uint8_t dpl, uint8_t gate_type, void *off) {
	idt->offset_low = (uint16_t)((uint32_t)off & 0xffff);	/*low word */
	idt->offset_high = (uint16_t)((uint32_t)off >> 16);	/* high word */
	idt->reserved = 0;		/* DO NOT TOUCH */
	idt->selector = selector;		/* selector*/
	idt->options_byte = (1<<7) | (dpl << 5) | gate_type;
	return;
}

__attribute__((interrupt)) void generic_interrupt_handler(isr_savedregs * u)
{
	/* this works but is an annoyance at best. Replace with device 
	 * driver ISR at the soonest
	 */
	/* __asm__ volatile ("hlt"); */
	vga_puts("Interrupt\n",0x4f);
	return;
}
void init_interrupts(idt_entry *  const idt) {
	/* faulty pointer arithmetic was the culprit here - ptr+i increments ptr by i*sizeof(*ptr)
	 * as opposed to just plain old i; using i*sizeof(ptr) as the index here was causing only
	 * every eighth interrupt to be enabled, leading to triple faults upon calling ISR 0x33, 
	 * for example. 
	 * Silly mistake - shows just how rusty I am with C.
	 */
	for(int i = 0; i <= NR_INTERRUPTS; i++) {
		set_idt_entry((idt+i),0x8, 0x0, INTERRUPT_GATE, &generic_interrupt_handler);
	}
}
/* 
 * whatever is below was formerly used for testing, but is now superseded
 * by an actual keyboard driver under i8042.c that also implements 
 * the requisite ISR
 */
/*
__attribute__((interrupt)) void kbd_interrupt_handler(isr_savedregs * u) {
	uint8_t garbag;
	inb (0x64,garbag);
	vga_puts("Keyboard interrupt\n",0x5f);
	eoi(1);
}
*/
