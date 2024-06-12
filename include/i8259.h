#define __8259_H__
void eoi(uint8_t irq);
void init(void);
void mask_all(void);
void clear_mask(uint8_t irq);
void set_mask(uint8_t irq);


