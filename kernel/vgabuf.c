#ifndef __VGABUF_H
#include "vgabuf.h"
#endif
#define VGA_BLACK	0x0
#define VGA_BLUE	0x1
#define VGA_GREEN 	0x2
#define VGA_CYAN	0x3
#define VGA_RED		0x4
#define VGA_MAGENTA	0x5
#define VGA_BROWN 	0x6
#define VGA_WHITE	0x7
#define VGA_GRAY	0x8
#define VGA_BRIGHT	0x8				//VGA_BRIGHT is a bitmask to be combined with the other colours to give bright versions
#define VGA_BLINK	0x80
#define VGA_COLUMNS	80
#define VGA_ROWS	25
#define VGA_ATTRIB(fg,bg) fg | (bg<<8)
static inline size_t strlen(unsigned char * string) 
{
	int i = 0;
	while(*(string + i)) i++;
	return i;
 }
static inline void vga_putchar (attrib, uc, x, y)
	//Arguments are provided in this format as it became increasingly unreadable in the function definition
	uint8_t attrib;
	unsigned char uc;
	unsigned int x;
	unsigned int y;
{
	uint16_t* fb = 0xB8000;
	if(++x > vga_columns) {
		y++; 
		x = 0;
	}
	fb += ((y * VGA_COLUMNS) + x) * 2;
	*fb = ((uint16_t)attrib << 8) + (uint16_t) uc;
}
inline void vga_print (attrib, string, x, y)
	//Arguments are provided in this format as it became increasingly unreadable in the function definition
	uint8_t attrib;
	unsigned char * string;
	unsigned int x;
	unsigned int y;
{
	if(++x + strlen(string) > VGA_COLUMNS) {
		x = 0;
 		y++;
	}
	for(int i = 0; i < strlen(string); i++)
	{
		vga_putchar(attrib,*(string+i),x+i, y); 
	}
	return;
}

