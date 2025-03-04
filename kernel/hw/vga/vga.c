#include <hw/vga/vga.h>
#include <arch/i386/io.h>
char * const vga_buffer = 0xb8000;		/* vga mmio address */
static uint16_t index = 0;			/* where our cursor is atm - must implement wraparound */
size_t strlen(const char * string) {
	/* a standard algorithm. */
	/* TODO implement in assembly to optimise speed */
	size_t retval = 0;
		asm volatile ("	\
		 cld;		\
		 repnz scasb;	\
		 std;		\
		 not %%ecx;	\
		 dec %%ecx;	\
		"		\
		: "=c" (retval)	/* output ecx in retval*/ \
		: "a" (0),				\
		  "c" (-1),				\
		  "D" (string)				\
		 :	/* everything clobbered is listed above */  	\
	);
	return retval;
	/*
	for (; *(string + retval); retval++) continue;
	return --retval;
	*/
}
size_t vga_puts(const char * string, uint8_t attrib) {
	size_t i = 0;
	for (; i < strlen(string); i++) {
loop:		switch (*(string+i)) {
		case '\n':
			index = ((index / VGA_COLS)+1)*VGA_COLS-2;
			index = index >= (VGA_ROWS*VGA_COLS) ? 0 : index;		/* wrap around */ 
			update_cursor(index);
			++i;
			goto loop;	/* repeat without printing or incrementing */
			break;
		case '\b':
			index--;
			++i;
			goto loop;
			
		}
		index = index >= (VGA_ROWS*VGA_COLS) ? 0 : index;		/* wrap around */ 
		/* typecasting black magick incoming */
		*(uint16_t *)(vga_buffer + index*2 + i*2) = (uint16_t)(*(string+i)) | ((uint16_t)(attrib) << 8);
	}
	index += i;
	update_cursor(index);
	return i;
}
void vga_putchar (uint8_t uc, uint8_t attrib) {
	/* don't update index */
	*(uint16_t *)(vga_buffer + index*2) = ((attrib << 8) | uc);
	++index;
	return;
}
void update_cursor(uint16_t loc) {				/* move the cursor */
	outb(0x3D4, 0x0F);
	outb(0x3D5, (uint8_t) (loc & 0xFF));			/* low byte */
	outb(0x3D4, 0x0E);
	outb(0x3D5, (uint8_t) ((loc >> 8) & 0xFF));		/* high byte */
	return;
}

