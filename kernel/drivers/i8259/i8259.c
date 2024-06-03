/* the driver for the intel i8259 PIC */
#include "stdint.h"
#include "i8259.h"
void eoi(uint8_t irq) {
	if(irq & 0x8) outb(PIC2_COM, 0x20);
	outb(PIC1_COM, 0x20);
}
// PIC init done initially by PICS
void set_mask(uint8_t irq) {
	//setting a mask means it is set high
	uint8_t val;
	if (irq & 8) {						/* high IRQ - PIC2*/
		inb (PIC2_DATA, mask);
	outb(PIC2_DATA,mask | (1 << (irq-8)));
	}
	else {
		inb (PIC1_DATA, mask);
		outb (PIC2_DATA, mask | (1 << (irq-8)));
	}
}

