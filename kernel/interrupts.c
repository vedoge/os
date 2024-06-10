#include "include/arch/i386/interrupts.h"
#include "include/vga.h"
extern idt_entry * interrupt_table asm("ivt"); /* ptr to ivt */
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
void set_idt_entry(idt_entry * idt, uint8_t n, uint16_t selector, uint8_t dpl, uint8_t gate_type, void *off) {
	__asm__ volatile ("cli":/*no output*/:/*no input*/:/*no clobber*/);
	(idt+n*8)->offset_low = (uint16_t)((uint32_t)off & 0xffff);	/*low word */
	(idt+n*8)->offset_high = (uint16_t)((uint32_t)off >> 16);	/* high word */
	(idt+n*8)->reserved = 0;		/* DO NOT TOUCH */
	(idt+n*8)->selector = selector;		/* selector*/
	(idt+n*8)->options_byte = (1<<7) | (dpl << 5) | gate_type;
	/* asm ("sti") */
	return;
}
__attribute__((interrupt)) void generic_interrupt_handler(regs * u)
{
	__asm__ volatile ("hlt");
	vga_puts("helo\n",0x8f);
	return;
}
void init_interrupts(idt_entry * idt) {
	for(int i = 0; i < NR_INTERRUPTS; i++) {
		set_idt_entry(idt, i, 0x8, 0x0, 0xe, &generic_interrupt_handler);
	}
	lidt(idt);
}
