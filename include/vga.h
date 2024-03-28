#define __VGA_H
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
extern "C" void vga_putchar(uint8_t uc, uint8_t attrib, uint8_t x, uint8_t y); 
extern "C" void vga_puts(unsigned char * string, uint8_t attrib, uint8_t x, uint8_t y);
extern "C" size_t strlen(const char * string);

