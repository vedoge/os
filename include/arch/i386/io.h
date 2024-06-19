#define _IO_H
#define inb(port,val) /* receive input from the port "port" in "val" */ \
	asm volatile (	"inb %%dx, %%al"  								\
			: "=a" (val)		/* map al to var that stores it is the value being received */ \
			: "d" (port) 		/* map the port to dx, as it is the port being listened to */ \
			: 			/* no clobber */ \
			)
#define outb(port, val) /* send value val to port port */ \
	asm volatile (	"outb %%al, %%dx" \
			:			/* no output operands */		\
			: "d" (port),		/* port mapped to dx (port in question) */ \
			  "a" (val) 		/* val mapped to al (data being sent) */ \
			:  		/* no clobber*/ \
			)
#define io_delay() \
	asm volatile ("jmp 1f; 1: jmp 2f;2:"); /*jmp $+2 x3*/
