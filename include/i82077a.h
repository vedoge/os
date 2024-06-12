/*
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
#define __I82077A_H
typedef enum {
	read_track	= 0x2,
	specify		= 0x3,
	sense_status	= 0x4,
	write_data	= 0x5,
	read_data	= 0x6,
	recalibrate	= 0x7,
	sense_interrupt	= 0x8,
	write_del_data	= 0x9,
	read_id		= 0xa,
	read_del_data	= 0xb,
	format_track	= 0xd,
	dumpreg		= 0xe,
	seek		= 0xf,
	version		= 0x10,
	scan_equal	= 0x11,
	perpendicular	= 0x12,
	configure	= 0x13,
	lock		= 0x14,
	verify		= 0x16,
	scan_le		= 0x19,
	scan_he		= 0x1d
} floppy_command;

void init_floppy (void);		/* initialise floppy controller */
void reset_floppy(void);
void read_sectors(uint16_t lba, size_t count, size_t drive);
void motor_on(void)
void motor_off(void)

