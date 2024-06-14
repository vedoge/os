#define __INTERRUPTS_H
#include "stdint.h"

#define NR_INTERRUPTS 256	/* max number of interrupts (int 0x0-0xff) */

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
	uint32_t useresp;
	uint32_t ss;
} __attribute__((packed)) regs; 
/* CPU saved regs */

extern void lidt(idt_entry * idt);		/* load IDTR register */
extern void set_idt_entry(idt_entry * idt,uint8_t n,uint16_t selector, uint8_t dpl, uint8_t gate_type, void * off);
extern __attribute__((interrupt)) void generic_interrupt_handler(regs * u);
extern void init_interrupts(idt_entry * idt);

