/* the driver for the intel i8259 PIC */
#include <stdint.h>
#include <hw/i8259/i8259.h>
#ifndef __IO_H
#include <arch/i386/io.h>
#endif
void init_8259(void) {
 
	outb(PIC1_COM, ICW1_INIT | ICW1_ICW4);
	outb(PIC2_COM, ICW1_INIT | ICW1_ICW4);

	outb(PIC1_DATA, 0x20);
	outb(PIC2_DATA, 0x28);

	outb(PIC1_DATA, 0x04);
	outb(PIC2_DATA, 0x02);
	
 
	outb(PIC1_DATA, ICW4_8086);
	outb(PIC2_DATA, ICW4_8086);
	
	mask_all();
}

void eoi(uint8_t irq) {
	if(irq & 0x8) outb(PIC2_COM, 0x20);
	outb(PIC1_COM, 0x20);
}
void mask_all (void) {
	outb(PIC1_DATA, 0xff);
	outb(PIC2_DATA, 0xff);

}
// PIC init done initially by PICS
void set_mask(uint8_t irq) {
	//setting a mask means it is set high
	uint8_t mask;
	asm volatile ("hlt");
	if (irq & 0x08) {				/* high IRQ - PIC2 */
		inb (PIC2_DATA, mask);
		outb(PIC2_DATA,mask | (1 << (irq-8)));
	}
	else {
		inb (PIC1_DATA, mask);
		outb (PIC1_DATA, mask | (1 << irq));
	}
}
void clear_mask (uint8_t irq) {
	uint8_t mask;
	if (irq & 0x08) {				/* high IRQ - PIC2 */
		inb (PIC2_DATA, mask);
		outb(PIC2_DATA,mask & ~(1 << (irq-8)));
	}
	else {
		inb (PIC1_DATA, mask);
		outb (PIC1_DATA, mask & ~(1 << irq));
	}
}

