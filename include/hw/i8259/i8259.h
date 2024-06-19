#define __I8259_H
#define PIC1_COM 0x20
#define PIC1_DATA 0x21
#define PIC2_COM 0xa0
#define PIC2_DATA 0xa1

#define ICW1_ICW4	0x01		/* presence of ICW4 */
#define ICW1_SNGL	0x02
#define ICW1_SCALE4	0x04
#define ICW1_LEVEL	0x08		/* edge triggered / level triggered */
#define ICW1_INIT	0x10		/* indicates ICW1 */
 
#define ICW4_8086	0x01
#define ICW4_AUTOEOI	0x02
#define ICW4_BUF_SLAVE	0x08
#define ICW4_BUF_MASTER	0x0c
#define ICW4_SFNM	0x10

extern void eoi(uint8_t irq);
extern void init_8259(void); /* to be implemented; unsure if still needed */
extern void mask_all(void);
extern void clear_mask(uint8_t irq);
extern void set_mask(uint8_t irq);

