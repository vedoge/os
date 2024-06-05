#include "vga.h"
int main() { 
	char * hello = "hi!\n";		//test string
	vga_puts(hello,VGA_ATTRIB(VGA_BLINK | VGA_BLACK, VGA_BRIGHT | VGA_WHITE), 0, 0); 
	asm("cli;hlt");			//stop here
}
