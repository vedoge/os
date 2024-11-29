/* 
 * This driver has the known issue that the character is double-printed; 
 * I'm entirely unsure how, but it is. The IRQ is raised twice, 
 * once on key press and once on key release (and more times on repeat),
 * but the character gets printed twice even the ISR checks for 
 * the key release code (0xf0, and then the scancode), and explicitly
 * _does not_ print anything upon seeing this code. 
 * Additionally, this slipshod piece of work means even the Shift
 * key is printed (even though special characters like 0xE0 are 
 * *explicitly checked for*). Rather dissappointing. 
 * Even worse is that the multiple "iret"s that should be emitted 
 * by the compiler-assembler-linker are simply nowhere to be seen. 
 * The control flow slips and slides nicely through the print. 
 * I found the issue, I think - the 8042 issues 1 IRQ per byte sent.
 * - Me, 18/06/2024, 23:38
 * Use a damn flip-flop for the thing. The 8042 sends 1 interrupt per 
 */

#include <hw/i8042/i8042.h>
#ifndef __STDINT_H
#include <stdint.h>
#endif 

#ifndef __SCANCODES_H
#include <hw/i8042/scancodes.h>
#endif
#ifndef __I8259_H
#include <hw/i8259/i8259.h>
#endif

#ifndef __INTERRUPTS_H
#include <arch/i386/interrupts.h>
#endif

#ifndef __IO_H
#include <arch/i386/io.h>
#endif
#ifndef __CONFIG_H
#include <config.h>
#endif
#ifndef __VGA_H
#include <hw/vga/vga.h> 
#endif
#ifndef __STDBOOL_H
#include <stdbool.h>
#endif
bool mouse_support = HAS_MOUSE;
char * const sth = "\0\0";
static inline void wait_until_8042_expects_read(void) {
	uint8_t res = 0; 
	while (true) {
		inb (STATUS_8042, res);
		if (res & 0x1) return;
		io_delay();
	}
}
static inline void wait_until_8042_expects_write(void) {
	uint8_t res = 0; 
	while (true) {
		inb (STATUS_8042, res);
		if (!(res & 0x2)) return;	/* ie buffer is empty */
		io_delay(); 
	}
}
static inline void discard_8042_output(void) {
	uint8_t res = 0; 
	while(true) {
		inb (STATUS_8042, res);
		if(res & 0x1) return; 
		io_delay();
	}
}
void init_8042(void) {
	uint8_t res;

	outb (COM_8042, DISABLE_KBD);
	wait_until_8042_expects_write(); 

	outb (COM_8042, DISABLE_MOUSE);
	wait_until_8042_expects_write();

	while(true) {
		inb (STATUS_8042, res); 
		if (!(res & 0x1)) break;
		inb (DATA_8042, res);
	}

step1:	outb (COM_8042, SELF_TEST_8042);
	wait_until_8042_expects_read();
	inb (DATA_8042, res);
	if (res != 0x55) goto step1;	/* passes */
	wait_until_8042_expects_write(); /* passes */
	outb (COM_8042, READ_CCB);
	wait_until_8042_expects_read();
	inb (DATA_8042, res);

	res &= 0b00110111;
	res |= 0b00000001;

	outb (COM_8042, WRITE_CCB);
	wait_until_8042_expects_write();
	outb (DATA_8042, res);
	wait_until_8042_expects_write();

step2: 	outb (DATA_8042, KBD_SCAN_OFF); 
	wait_until_8042_expects_read(); 
	inb (DATA_8042, res); 
	if (res != KBD_ACK) goto step2; 

step3: 	outb (DATA_8042,KBD_SELF_TEST); 
	wait_until_8042_expects_read();
	inb (DATA_8042, res); 
	if (res != KBD_ACK) goto step3; 
	wait_until_8042_expects_read(); 
	inb (DATA_8042, res); 
	if (res != 0xAA) asm volatile ("jmp ."); /* passes */

step4: 	outb (DATA_8042, KBD_SCANCODE); /* passes */
	wait_until_8042_expects_write(); 
	outb (DATA_8042, 0x2); /* passes */
	wait_until_8042_expects_read(); 
	inb (DATA_8042, res); /* passes */
	if (res != KBD_ACK) goto step4; 
	
	while(true) {
		inb (STATUS_8042, res); 
		if (!(res & 0x1)) break;
		inb (DATA_8042, res);
	}
step5:
	wait_until_8042_expects_write(); 
	outb(DATA_8042,KBD_SCAN_ON); 
	wait_until_8042_expects_read(); 
	inb (DATA_8042, res);
	if (res != KBD_ACK) goto step5;
	wait_until_8042_expects_write();
	outb (COM_8042, ENABLE_KBD);
	set_idt_entry((idt+PIC1_OFF+1), 0x8, 0x0, INTERRUPT_GATE, &kbd_interrupt_handler);
	clear_mask (1);
	return;
}
/*
__attribute__ ((interrupt)) void kbd_interrupt_handler(isr_savedregs * regs) {
	
	 
	uint8_t scancode1 = 0, scancode2 = 0; 
	inb(DATA_8042, scancode1);
	if(scancode1 == 0xF0) {
		inb (0x60, scancode2);
		charmap[scancode2 / 8] &= ~(0x80 >> (scancode2 % 8));
		eoi(1); 
		return; 
	}
	else if (scancode1 == 0xE1) {
		discard_8042_input(); 
		eoi(1); 
		return; 
	}
	else if (scancode1 == 0xE0){
		inb(DATA_8042, scancode2);
		eoi(1);
		return; 
	}
	else {
		*sth = (int) ansi_scancodes[scancode1];
		charmap[scancode1 / 8] |= 0x80 >> (scancode1 % 8);
		print (sth, 0x3f);
		eoi(1);
		return; 
	}
}
*/
__attribute__ ((noreturn)) void cold_reset(void) {
	wait_until_8042_expects_write(); 
	outb(COM_8042, SYSTEM_RESET);
	/* system should never reach this point */
}

void disable_kbd(void) {
	outb(COM_8042, DISABLE_KBD);
	wait_until_8042_expects_write();
}
void enable_kbd(void) {
	outb(COM_8042, ENABLE_KBD);
	wait_until_8042_expects_write();
}
void disable_mouse(void) {
	outb(COM_8042, DISABLE_MOUSE);
	wait_until_8042_expects_write(); 
}
void enable_mouse(void) {
	outb(COM_8042, ENABLE_MOUSE);
	wait_until_8042_expects_write();
}
