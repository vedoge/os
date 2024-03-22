#define _KERNEL32_H
#define inb(port,val) /* receive input from the port "port" in "val" */ \
	asm volatile (	"inb %%dx, %%al;"  	\
			:"=a" (val)		/* map al to var that stores it is the value being received */ \
			:"d" (port) 		/* map the port to dx, as it is the port being listened to */ \
			: "memory"		/* memory clobber */)
#define outb(port, val) /* send value val to port port */ \
	asm volatile (	"outb %%dx, %%al" \
			:"=a" (val) 		/* val mapped to al (data being sent) */ \
			: "a" (port) 		/* port mapped to dx (port in question) */ \
			: "memory" 		/* memory clobber*/)

