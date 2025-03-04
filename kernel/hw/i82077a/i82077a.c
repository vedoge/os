#include <stdint.h>
#include <stdbool.h>
//#include <mm/memory.h>
#include <hw/i82077a/i82077a.h>
#include <hw/i8259/i8259.h>
#include <arch/i386/io.h>
#include <arch/i386/interrupts.h>
#include <hw/vga/vga.h>
#include <config.h>
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
static inline chs_t lbachs(uint16_t lba) {
	chs_t retval; 
	retval.c = lba / (hpc * spt);
	retval.h = ((lba % (hpc * spt)) / spt);
	retval.s = ((lba % (hpc * spt)) % spt + 1);
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
static inline void sense_interrupt(void) {
	for(int i = 0; i < 4; i++){ 
		send_command(SENSE_INT);
		rec_byte(); 
		rec_byte(); 
	}
}
static bool mota = false;
void motor_on(void) {
	register uint8_t __res asm ("%al");
	if(mota) return;
	inb(DOR, __res);
	__res |= 0x10;
	outb(DOR, __res);
	mota = true;
	return;
}
void motor_off(void) {
	register uint8_t __res asm("%al");
	if (mota) {
		inb (DOR, __res);
		__res &= ~(0x10);
		outb (DOR, __res);
		mota = false;
	}
}

static inline uint8_t results_phase (void) {
	register uint8_t __res asm ("%al");
	int retries = 1000;
loop:	inb (MSR, __res);
	__res &= 0x90; 
	if(__res == 0x90) {
		goto end;
	}
	if(!--retries) {
		goto fail; 
	}
	goto loop;
end:	inb (FIFO, __res); 
	return __res;
fail:
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
	irq6_flipflop = false;
	send_param (0);			/* drive no */
wait:	wait_for_irq6(irq6_flipflop);
	sense_interrupt(); 		/* sense interrupt */
}
void init_82077a(void) {
	/* first run only */
	/* currently initialises drive 0 only */
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
	send_command (CONFIGURE); 
	send_param (0);			/* first byte is 0 */
	send_param (0b01011100);	/* implied seek, FIFO, FIFOTHR 0x8
						(IRQ issued at 8 bytes)
						disable drive polling*/
	send_param (0);		/* precompensation starts at track 0 */
try_lock:
	send_command (LOCK);	/* make configuration persistent */
	__res = rec_byte();
	if (!__res) goto try_lock;
	wait_for_irq6 (irq6_flipflop);	/* wait for bool to go true */
	if (irq6_flipflop) goto reset;
	outb (CCR, 0x0);		/* Default */
	wait_for_irq6(irq6_flipflop);
	irq6_flipflop = false;
	/* this breaks, idk why */
	send_command (SPECIFY);
	/* these are safe options. A superb driver would adapt them based on how well the drive was performing. */
	send_param (0);			/* SRT 7-4 | HLT 3-0 */
	send_param (0);			/* HUT 7-1 | NDMA 0 */
	inb(DOR, __res);
	__res |= 0x10;			/* Turn on the first motor & select drive 0 */
	outb(DOR, __res);
	io_delay();
	io_delay();
	io_delay();
	io_delay();			/* wait a long time */
recal:	send_command (RECALIBRATE);	/* seek track 0 */
	send_param (0);			/* drive no. */
	wait_for_irq6(irq6_flipflop);	/* wait for IRQ */
	send_command (SENSE_INT);	/* receive bytes lmao */
	__res = rec_byte(); 
	if (!(__res & 0x20)) goto recal;
	rec_byte(); 
	inb (DOR, __res);
	__res &= ~(0x10);		/* switch off MOTA */
	outb (DOR, __res);
	return;
retry: 
	rec_byte();
	goto reset;
}


void * read_sectors(uint16_t lba, size_t count) {
	/* switch on the motor and rely on the rest not being quick */

	register uint8_t __res asm ("%al");
	motor_on();
	/* get page allocated */
	size_t nr_pages = (count / 2) + (count % 2);
	/* first 4mb at least is idpaged */
	/*void * phys_addr = get_free_dma_pages (nr_pages, ALLOC_RING0 | ALLOC_WR);*/
	uint32_t phys_addr = 0xf000;
	if (phys_addr == NULL) return NULL;

	outb(0x8,0x14);				/* dma disable */
	outb(0x0b, 0x46);			/* write to main memory */
	chs_t first_sector = lbachs(lba);
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

	//send_param (first_sector.c);		/*floppy cylinder */

	//send_param (first_sector.h);		/* floppy head */
	//send_param (first_sector.s);		/* floppy sector */
	send_param((first_sector.h << 2) | 0);	/* head<<2 and drive number (HDS | DS1 | DS0) */
	send_param(first_sector.c);	/* cylinder / track (C) */
	send_param(first_sector.h);	/* head (H) */

	outb (0x0c,0xff);			/* DMA flip flop */ /* here */			


	outb (0x4,phys_addr & 0xff);	/* DMA low byte of addr */

	phys_addr >>= 8;		/* next byte */

	outb (0x4, phys_addr & 0xff);	/* DMA high byte of addr */
	
	send_param (first_sector.s);	/* sector (R) */
	
	phys_addr >>= 8;		/* next byte */

	outb (0x81,phys_addr & 0xff);	/* DMA page reg */

	send_param(0x2);			/* sector size (N) */

	size_t dma_count = count * 512 - 1;	/* bidmas */

	outb(0x0c, 0xff);			/* flipflop */ 

	outb (0x5,dma_count & 0xff);		/* DMA count LSB */

	send_param (spt);			/* EOT */

	outb (0x5, dma_count & 0xff00);		/* DMA count MSB works*/

	send_param (0x1b);			/* GPL (always 0x1b) */


	outb (0x0a, 0x02); 			/* tell DMA to go */

	outb(0x08, 0x10);			/* actually tell DMA to go */

	send_param (0xff); 			/* DTL tell floppy to go */
	/* read happens */
	wait_for_irq6 (irq6_flipflop);		/* wait for the interrupt */
	irq6_flipflop = false;
	motor_off();
	/* no sense interrupts (drive polling mode disable) */
	asm("hlt");
	vga_putchar(results_phase(), 0x4f);	/*st0*/
	results_phase(); 	/*st1*/
	results_phase();	/*st2*/
	results_phase();	/*c*/
	results_phase();	/*h*/
	results_phase();	/*r*/
	results_phase();	/*n*/
}
