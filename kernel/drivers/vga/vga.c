#include "vga.h"
#include "arch/i386/io.h"
char * const vga_buffer = 0xb8000;
static uint16_t index = 0;
size_t strlen(const char * string) {
	/* a standard algorithm. */
	/* TODO implement in assembly to optimise speed */
	size_t retval = 0;
		asm volatile ("	\
		 repnz scasb;	\
		 not %%ecx;	\
		 dec %%ecx;	\
		"		\
		: "=c" (retval)	/* output ecx in retval*/ \
		: "a" (0),				\
		  "c" (-1),				\
		  "S" (string)				\
		 :	/* everything clobbered is listed above */  	\
	);
	return retval;
	/*
	for (; *(string + retval); retval++) continue;
	return --retval;
	*/
}
size_t vga_puts(const char * string, uint8_t attrib, uint8_t x, uint8_t y) {
	size_t i = 0;
	for (; i <= strlen(string); i++) {
		if (*(string+i) == '\n') index = ((index / VGA_COLS)+1)*VGA_COLS;
		*(vga_buffer + index*2 + i*2) = ((attrib << 8) | *(string+i));
	}
	update_cursor(index);
	return i; 
}
void vga_putchar (uint8_t uc, uint8_t attrib, uint8_t x, uint8_t y) {
	/* don't update index */
	int loc = (x + (y * VGA_COLS))*2;			/* offset of character */
	*(vga_buffer + loc) = ((attrib << 8) | uc);
	return;  

}
void update_cursor(uint16_t loc) {				/* move the cursor */
	outb(0x3D4, 0x0F);
	outb(0x3D5, (uint8_t) (loc & 0xFF));
	outb(0x3D4, 0x0E);
	outb(0x3D5, (uint8_t) ((loc >> 8) & 0xFF));
}

