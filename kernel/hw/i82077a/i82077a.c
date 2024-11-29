#ifndef __STDINT_H
#include <stdint.h>
#endif
#ifndef __STDBOOL_H
#include <stdbool.h>
#endif
#ifndef __MEMORY_H
#include <mm/memory.h>
#endif
#ifndef __I82077A_H
#include <hw/i82077a/i82077a.h>
#endif
#ifndef I8259_H
#include <hw/i8259/i8259.h>
#endif
#ifndef __IO_H
#include <arch/i386/io.h>
#endif
#ifndef __INTERRUPTS_H
#include <arch/i386/interrupts.h>
#endif
#ifndef __VGA_H
#include <hw/vga/vga.h>
#endif
#ifndef __CONFIG_H
#include <config.h>
#endif
/*
 * For HLT, HUT, and SRT, the highest time possible is denoted by 0. 
 * The lowest possible time is denoted by 1, and the second-highest time is
 * denoted by the highest possible value. 
 * A good driver would keep failure-rate statistics about the drive's usage and
 * change the parameters set by SPECIFY respectively.
 */
/* I don't think flipflop is accepted terminology but oh well */
/* later note: it's actually called an irq. */
const char * too_old = \
"Your computer is from the paleolithic era.\nStop tampering with the results of archaelogical expeditions.";
static volatile bool irq6_flipflop = false;
static volatile bool mota_flipflop = false;
static volatile bool motb_flipflop = false;
static volatile bool motc_flipflop = false; 
static volatile bool motd_flipflop = false;
const uint8_t nr_sense_interrupts = 4;
static inline chs_t lbachs(uint16_t lba, int floppy) {
	chs_t retval; 
	retval.c = lba / (hpc[floppy] * spt[floppy]);
	retval.h = ((lba % (hpc[floppy] * spt[floppy])) / spt[floppy]);
	retval.s = ((lba % (hpc[floppy] * spt[floppy])) % spt[floppy] + 1);
	return retval;
}

static inline bool send_command (uint8_t command_byte) {
	/* poll MSR and spin until RQM = 1 and DIO = 0, or reset and retry */
	/* I have become an assembly monkey. I do not understand C anymore. */
	/* any attempt of mine to use C constructs (like loops) has ended in abject failure. */
	/* I resort to goto as my last refuge. */
	uint8_t msr;	/* variable to store the main status register of the floppy drive */
	int retries = 1000;
loop:	inb (MSR, msr);
	msr &= 0xd0;
	if (msr == 0x80)
	{
		goto end;
	}
	if(!--retries) {
		goto fail;
	}
	goto loop;
end:
	outb (FIFO, command_byte);
	return true;
fail:
	reset_floppy();
	return false;
}
static inline bool send_param (uint8_t param) {
	uint8_t msr;	/* variable to store the main status register of the floppy drive */
	int retries = 1000;
loop:	inb (MSR, msr);
	msr &= 0xd0;
	if (msr == 0x90) {
		goto end;
	}
	if(!--retries) {
		goto fail;
	}
	goto loop;
end:
	outb (FIFO, param);
	return true;
fail:
	reset_floppy();
	return false;
}

static inline uint8_t rec_byte (void) {
	uint8_t msr;	/* variable to store the main status register of the floppy drive */
	int retries = 1000;
	uint8_t retval; 
loop:	inb (MSR, msr);
	msr &= 0xc0;
	if (msr == 0xc0)		/* RQM | DIO | BSY */
	{
		goto end;
	}
	if(!--retries) {
		goto fail;
	}
	goto loop;
end:
	inb (FIFO, retval);
	return retval;
fail:
	reset_floppy();
	return -1;
}
/* does not send sense interrupt commands */
__attribute__ ((interrupt)) void flipflop_upon_irq (isr_savedregs * regs) {
	irq6_flipflop = true;
	eoi(1); 
	return;
}
void reset_floppy(void) {
	/* function below but without version checking */
	register uint8_t __res asm ("%al");
retry:	sti();
	outb (DOR, 0x0);		/* clear reset bit (controller enters reset mode) */
	io_delay();			/* maybe the RTC or the PIT can control this interval later */
	io_delay();
	outb (DOR, 0xc);		/* IRQ & DMA bit set */
	wait_for_irq6 (irq6_flipflop);
	send_command (SPECIFY);
	send_param (0);
	send_param (0);			/* default (highest) */
	inb (DOR, __res); 
	__res |= 0x10;			/* MOTA */
	outb (DOR, __res);
	io_delay(); 
	io_delay();
loop:	send_command (RECALIBRATE); 
	send_param (0);			/* drive no */
	irq6_flipflop = false;
wait:	wait_for_irq6(irq6_flipflop);
}
void init_82077a(void) {
	/* first run only */
	register uint8_t __res asm ("%al");
	/* issue sense interrupts upon interrupt */
	set_idt_entry(idt+PIC1_OFF+6, 0x8, 0, INTERRUPT_GATE, &flipflop_upon_irq);
	clear_mask (6);
	sti();
	send_command (VERSION);
	__res = rec_byte();
	if (__res < 0x90) {
		vga_puts(too_old, 0x4f);
		cli();
		for(;;) asm volatile ("hlt");
	}
	send_command (CONFIGURE); 
	send_param (0);			/* first byte is 0 */
	send_param (0b01011100);	/* implied seek, FIFO, FIFOTHR 0x8
						(IRQ issued at 8 bytes)
						disable drive polling*/
	send_param (0);		/* precompensation starts at track 0 */
reset:	outb (DOR, 0x0);		/* clear reset bit (controller enters reset mode) */
	io_delay(); 
	io_delay();
	outb (DOR, 0xc);		/* IRQ & DMA bit set */
try_lock:
	send_command (LOCK);
	__res = rec_byte();
	if (!__res) goto try_lock;
	wait_for_irq6 (irq6_flipflop);	/* wait for bool to go true */
	if (irq6_flipflop) goto reset;
	outb (CCR, 0x0);		/* Default */
	wait_for_irq6(irq6_flipflop);
	irq6_flipflop = false;
	/* this breaks, idk why */
	send_command (SPECIFY);
	send_param (0);
	send_param (0);			/* default (highest) */
recal:	send_command (RECALIBRATE); 
	send_param (0);
	wait_for_irq6(irq6_flipflop);
	send_command (SENSE_INT);
	__res = rec_byte(); 
	if (!(__res & 0x20)) goto retry;
	rec_byte(); 
	inb (DOR, __res);
	__res &= ~(0x10);		/* switch off MOTA */
	outb (DOR, __res);
	return;
retry: 
	rec_byte();
	goto recal;
}


void * read_sectors(uint16_t lba, size_t count, size_t drive) {
	/* switch on the motor and rely on the rest not being quick */

	register uint8_t __res asm ("%al");
	asm volatile ("hlt");
	inb (DOR, __res);
	__res |= 0x10 << drive; /* switch on motor */
	outb (DOR, __res);
	uint16_t floppy_type = floppies[drive];
	/* get page allocated for first byte */
	size_t nr_pages = (count / 2) + (count % 2);
	/* first 4mb at least is idpaged */
	void * phys_addr = get_free_dma_pages (nr_pages, ALLOC_RING0 | ALLOC_WR);
	if (phys_addr == NULL) return NULL;
	outb (0x0a, 0x06);			/* dma mask channel 2*/
	chs_t first_sector = lbachs(lba,floppies[drive]);

	/* 
	 * the following commands are interspersed with DMA controller
	 * commands. This is because the I/O bus of the processor
	 * needs a delay if two consecutive operations need to be conducted
	 * on the same I/O port. Since two different devices need to be set
	 * up simultaneously thanks to the architecture of the IBM PC,
	 * this makes it quite convenient to set up the DMA controller
	 * and the floppy disk controller for the read simultaneously.
	 * The calls have been commented for readability.
	 */
	send_command (READ_DATA);		/* floppy read command */

	send_param (first_sector.c);		/*floppy cylinder*/

	outb (0xd8,0xff);			/* DMA flip flop */			

	send_param (first_sector.h);		/* floppy head */

	outb (0x4,(uint32_t)phys_addr & 0x0000ff);	/* DMA low byte of addr */

	send_param (first_sector.s);		/* floppy sector */

	outb (0x4, (uint32_t)phys_addr & 0x00ff00);	/* DMA high byte of addr */

	outb (0xd8, 0xff); 			/* DMA flip-flop reset */
	/* count of bytes - 1 */
	send_param (0x2);			/* sector size = 512 */
	size_t dma_count = count * 512 - 1;	/* bidmas */
	outb (0x5,dma_count & 0xff);		/* DMA count LSB */

	send_param (spt[floppy_type]);		/* floppy sectors per track */

	outb (0x5, dma_count & 0xff00);		/* DMA count MSB*/

	send_param (0x1b);			/* floppy GPL1 (always 0x1b) */

	outb (0x80, (uint32_t)phys_addr & 0xff0000);	/* DMA page reg */

	send_param (0xff); 			/* tell floppy to go */

	outb (0x0a, 0x02); 			/* tell DMA to go */
	/* read happens */
	wait_for_irq6 (irq6_flipflop);		/* wait for the interrupt */
	irq6_flipflop = false;
	inb (DOR, __res);
	__res &= ~(0x10);
	outb (DOR, __res);			/* turn off motor*/
	/* no sense interrupts (drive polling mode disable) */
	rec_byte();	/*st0*/
	rec_byte(); 	/*st1*/
	rec_byte();	/*st2*/
	rec_byte();	/*c*/
	rec_byte();	/*h*/
	rec_byte();	/*r*/
	rec_byte();	/*n*/

}
