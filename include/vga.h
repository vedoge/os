#define __VGA_H
#ifndef __STDINT_H
#include "stdint.h"
#endif
/* TODO use enum */
#define VGA_BLACK	0x0
#define VGA_BLUE	0x1
#define VGA_GREEN 	0x2
#define VGA_CYAN	0x3
#define VGA_RED		0x4
#define VGA_MAGENTA	0x5
#define VGA_BROWN 	0x6
#define VGA_WHITE	0x7
#define VGA_GRAY	0x8
#define VGA_BRIGHT	0x8
#define VGA_BLINK	0x8		/* for whatever reason this doesn't work */
#define VGA_COLS	80
#define VGA_ROWS	25
#define VGA_ATTRIB(bg,fg) (uint8_t)fg | ((uint8_t)bg<<4)		/* pack both into one byte */
extern void vga_putchar(uint8_t uc, uint8_t attrib, uint8_t x, uint8_t y); 
extern size_t vga_puts(const char * string, uint8_t attrib);	/* returns the number of characters printed */
extern size_t strlen(const char * string);
extern void update_cursor(uint16_t pos);		/* pos is the last */
