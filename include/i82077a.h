#define __I82077A_H
#include <stdint.h>
#include <arch/i386/interrupts.h>
/*
the contents of this comment originally resided in stage2.asm
i82077a commands
read_track	equ 0x2
specify		equ 0x3
sense_status	equ 0x4
write_data	equ 0x5
read_data	equ 0x6
recalibrate	equ 0x7		; seek to 0
sense_interrupt	equ 0x8
write_del_data	equ 0x9
read_id		equ 0xa
read_del_data	equ 0xb
format_track	equ 0xd
dumpreg		equ 0xe
seek		equ 0xf
version		equ 0x10
scan_equal	equ 0x11
perpendicular	equ 0x12
configure	equ 0x13
lock		equ 0x14
verify		equ 0x16
scan_le		equ 0x19
scan_he		equ 0x1d
*/
#define	read_track	0x2		/* read a track */
#define	specify		0x3		/* */
#define	sense_status	0x4
#define	write_data	0x5
#define	read_data	0x6
#define	recalibrate	0x7
#define	sense_interrupt	0x8
#define	write_del_data	0x9
#define	read_id		0xa
#define	read_del_data	0xb
#define	format_track	0xd
#define	dumpreg		0xe
#define	seek		0xf
#define	version		0x10
#define	scan_equal	0x11
#define	perpendicular	0x12
#define	configure	0x13
#define	lock		0x14
#define	verify		0x16
#define	scan_le		0x19
#define	scan_he		0x1d

#define ST_A		0x3F0 /* ro */
#define	ST_B		0x3F1 /* ro */
#define	DOR		0x3F2 /* rw */
#define	TAPE		0x3F3 /* rw */
#define	MSR		0x3F4 /* ro */
#define	DSR		0x3F4 /* wo */
#define	FIFO		0x3F5 /* rw */
#define	DIR		0x3F7 /* ro */
#define	CCR		0x3F7 /* wo */

extern void init_floppy (void);		/* initialise floppy controller */
extern void reset_floppy(void);		/* reset upon failure */
extern void *read_sectors(uint16_t lba, size_t count, size_t drive);
extern void motor_on(void);
extern void motor_off(void);
extern __attribute__ ((interrupt)) void irq6_handler(struct regs * regs); 
