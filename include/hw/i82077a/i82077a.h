#ifndef __I82077A_H
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
#define	READ_TRACK	0x2		/* read a track */
#define	SPECIFY		0x3		/* specify config */
#define	SENSE_STATUS	0x4
#define	WRITE_DATA	0x5
#define	READ_DATA	0x6
#define	RECALIBRATE	0x7
#define	SENSE_INT	0x8
#define	WRITE_DEL_DATA	0x9
#define	READ_ID		0xa
#define	READ_DEL_DATA	0xb
#define	FORMAT_TRACK	0xd
#define	DUMPREG		0xe
#define	SEEK		0xf
#define	VERSION		0x10
#define	SCAN_EQUAL	0x11
#define	PERPENDICULAR	0x12
#define	CONFIGURE	0x13
#define	LOCK		0x94
#define UNLOCK		0x14
#define	VERIFY		0x16
#define	SCAN_LE		0x19
#define	SCAN_HE		0x1d

#define IBM_350_1440	0

#define ST_A	0x3F0 /* ro */
#define	ST_B	0x3F1 /* ro */
#define	DOR	0x3F2 /* rw */
#define	TAPE	0x3F3 /* rw */
#define	MSR	0x3F4 /* ro */
#define	DSR	0x3F4 /* wo */
#define	FIFO	0x3F5 /* rw */
#define	DIR	0x3F7 /* ro */
#define	CCR	0x3F7 /* wo */
/* add your floppy config here */
#define wait_for_irq6(flipflop) { \
	int mangled_name = 10000; \
	for(; mangled_name != 0; --mangled_name) { \
		if (flipflop) break; \
		else io_delay(); \
	} \
	flipflop = !(mangled_name); \
	/* if the flipflop remains true after the IRQ then we timed out, else all is well */ \
}
/* for the 3.5" 1.44MB diskette*/
#define hpc 2 /* heads per cylinder */
#define spt 18/* sectors per track */
#define gpl 27/* gap length */
typedef struct {
	uint8_t c; 
	uint8_t h;
	uint8_t s;
} __attribute__ ((packed)) chs_t;
extern void init_floppy (void);		/* initialise floppy controller */
extern void reset_floppy(void);		/* reset upon failure */
extern void *read_sectors(uint16_t lba, size_t count);
extern void motor_on(void);
extern void motor_off(void);
extern __attribute__ ((interrupt)) void flipflop_upon_irq (isr_savedregs * regs); 
#endif

