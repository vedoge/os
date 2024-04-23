#include <vga.h>
const uint8_t VGA_ROWS, VGA_COLS;
int main () {
	const char * thing = "hello world!";
	int length = strlen(thing);
	unsigned char h = 'h';
	vga_putchar((unsigned char) 'h',(uint8_t) VGA_ATTRIB(VGA_BLINK | VGA_BLACK, VGA_BRIGHT | VGA_WHITE), (uint8_t) 0, (uint8_t) 0);
	vga_puts(thing, (uint8_t) VGA_ATTRIB(VGA_BLINK | VGA_BLACK, VGA_BRIGHT | VGA_WHITE), (uint8_t) 0, (uint8_t) 0);
	return 0;
}

