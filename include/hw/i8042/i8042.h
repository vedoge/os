#define __I8042_H

#ifndef __INTERRUPTS_H
#include <arch/i386/interrupts.h>
#endif

#define COM_8042 		0x64
#define STATUS_8042 		0x64
#define DATA_8042 		0x60

#define SYSTEM_RESET		0xFE

#define DISABLE_KBD 		0xAD
#define ENABLE_KBD 		0xAE
#define DISABLE_MOUSE		0xA7
#define ENABLE_MOUSE		0xA8

#define SELF_TEST_8042		0xAA

#define READ_CCB		0x20
#define WRITE_CCB		0x60

#define READ_OUTPUT_PORT	0xD0

#define KBD_SCANCODE		0xF0
#define KBD_SCAN_OFF		0xF5
#define KBD_SCAN_ON		0xF4

#define KBD_SELF_TEST		0xFF
#define KBD_ID			0xF2
#define KBD_ECHO		0xEE
#define KBD_RESEND		0xFE
#define KBD_ACK 		0xFA
/*
static inline void wait_until_8042_ready(void);
static inline void wait_until_8042_expects_byte(void);
static inline void discard_8042_input(void);
*/
extern void init_8042(void);
extern __attribute__ ((interrupt)) void kbd_interrupt_handler(isr_savedregs * regs);
extern __attribute__ ((noreturn)) void cold_reset(void); 	/*cold reboot*/
