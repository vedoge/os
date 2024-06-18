#define __INTERRUPTS_H
#ifndef __STDINT_H
#include <stdint.h>
#endif
#ifndef __CONFIG_H
#include <config.h>
#endif
#define INTERRUPT_GATE	0xe
#define TRAP_GATE 	0xf

typedef struct {
	uint16_t length;
	void * table;
} __attribute__((packed)) idtr_t;

typedef struct {
	uint16_t offset_low;	/* low word of ISR address */
	uint16_t selector;	/* GDT selector */
	uint8_t  reserved; 	/* ALWAYS 0 */
	uint8_t  options_byte;	/* options */
	uint16_t offset_high;	/* high word of ISR address */
} __attribute__((packed)) idt_entry;

typedef struct {
	uint32_t eip;
 	uint32_t cs;
	uint32_t eflags;
	uint32_t esp;	/* when DPL=3 this is a different story, I think */
	uint32_t ss;
} __attribute__((packed)) isr_savedregs;

typedef struct {
	uint32_t eip;
	uint32_t cs;
	uint32_t eflags;
	uint32_t esp;
	uint32_t ss;
	uint32_t error_code;
} __attribute__ ((packed)) exception_savedregs;	/**/

extern void lidt(idt_entry * idt);		/* load IDTR register */
extern void set_idt_entry(idt_entry * idt,uint16_t selector, uint8_t dpl, uint8_t gate_type, void * off);
extern __attribute__((interrupt)) void generic_interrupt_handler(isr_savedregs * u);
extern void init_interrupts(idt_entry * idt);
extern __attribute__((interrupt)) void kbd_interrupt_handler(isr_savedregs * u);

extern idt_entry * const idt;
