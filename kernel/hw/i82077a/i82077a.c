#include <stdint.h>
#include <i82077a.h>
#include <arch/x86/io.h> 
#include <arch/x86/interrupts.h>
void init_floppy(void) {
	reset_floppy();
	outb((uint8_t) , dsr);
}
void reset_floppy(void) {
	uint8_t dsr = 0;
	dsr |= 0x80;
	outb((uint8_t) DSR, dsr);
	
	/* need irq6 */
	return;
}


void * read_sectors(uint16_t lba, size_t count, size_t drive) {

}
