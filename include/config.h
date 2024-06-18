#define __CONFIG_H
#define MAXMEM 16777216		// bytes of memory mapped 
/*
 * A static memory configuration is used
 * as the amount of memory is unlikely to change over time. 
 * For hobbyists, it is trivial to change this number 
 * in the source code, so this simple solution is good enough. 
*/
#define NR_INTERRUPTS 256
/* 
 * map all the interrupt gates; most of them will probably be unused.
 * Over time, I hope to develop an interrupt handler that can 
 * kill the offending process and display a message to the console. 
 * This would be a lot easier for the end user to cope with.
*/
#define NR_GDT_ENTRIES 7
/*
 * Using 7 GDT entries gives room for 5 user segments and 2 TSS
 * which should be more than enough (if a call is nested) 
 * more than 3 control transfers in, that call can be written
 * in a much better way.
*/
/* controls whether i8042 driver enables mouse ever.*/
#define HAS_MOUSE 0

#define PIC1_OFF 0x20
#define PIC2_off 0x28
