/* the below is handwritten assembly */
.code32
.text
.globl kbd_interrupt_handler
.type kbd_interrupt_handler, @function
.extern vga_puts
.extern eoi
.type vga_puts, @function
.type eoi, @function
kbd_interrupt_handler:
	/* first the stack frame */
	push %ebp
	movl %esp, %ebp
	/* then the registers */
	push %eax
	push %ebx
	push %ecx
	push %edx
	/* now receive the 8042 byte */
	movb $0x60, %dl
	movzbl %dl, %edx
	inb %dx, %al
	/* check if the byte received is part of a multibyte sequence */
	cmp $0, (key_up_flip_flop)
	jne key_up
	cmp $0, (extended_key_flip_flop)
	jne extended_key
	cmp $0, (pause_key_flip_flop)
	jne pause_key
	/* now check if the byte received begins a multibyte sequence */
	cmp $0xf0, %al
	je set_key_up_flip_flop		/* if key-up code */ 
	cmp $0xe0, %al
	je set_extended_key_flip_flop
	cmp $0xe1, %al
	je set_pause_key_flip_flop
	/* if we reached here, the byte is normal and needs translation */
	movl $scancode_table, %ebx	/* translate the sequence */
	xlatb				/* mov al, [ds:ebx + al] */ 
	mov %al, (string_print)		/* put the character in a sequence */
	push $0x3f			/* vga attributes byte */
	push $string_print		/* send directly to the screen */
	call vga_puts
	addl $8, %esp			/* clean up stack */ 
end:
	push $1 
	call eoi 			/* send end of interrupt to PIC */
	add $4, %esp 			/* stack clean up */ 
	/* restore registers */
	pop %edx
	pop %ecx
	pop %ebx
	pop %eax
	leave
	iret
/* jump (ish) table for handling different cases */
set_key_up_flip_flop:
	/* just settle this and leave */
	movb $1, (key_up_flip_flop)
	jmp end
key_up:
	/* settle and leave - need to implement key repeat / key holding */
	movb $0, (key_up_flip_flop)
	jmp end
set_extended_key_flip_flop:
	movb $1, (extended_key_flip_flop)
	jmp end
extended_key:
	/* need to handle this */
	movb $0, (extended_key_flip_flop)
	jmp end
set_pause_key_flip_flop:
	movb $3, pause_key_flip_flop	/* check this */
	jmp end
pause_key: 
	subb $1, pause_key_flip_flop 	/* also check this */
	jmp end
.data
scancode_table:
.byte 0,0,0,0,0,0,0,0,0,0,0,0
.ascii	"\0","\t","`","\0","\0","\0","\0","\0","\0","q"
.ascii	"1", "\0","\0","\0","z", "s", "a"
.ascii	"w", "2", "\0", "\0", "c", "x"
.ascii	"d","e","4","3","\0","\0"," ","v"
.ascii	"f","t","r","5", "\0","\0","n","b"
.ascii	"h","g","y","6","\0","\0","\0","m","j"
.ascii	"u", "7", "8", "\0", "\0", ",", "k"
.ascii	"i", "o", "0","9","\0","\0",".","/","l"
.ascii	";","p","-","\0","\0","\0","\"","\0","[","=","\0"
.ascii	"\0","\0","\0","\n","]","\0"
.ascii	"\\","\0","\0","\0","\0","\0","\0","\0","\0","\b","\0","\0","1"
.ascii	"\0","4","7","\0","\0","\0","0",".","2"
.ascii	"5","6","8","\0" ,"\0" 
.ascii	"\0" ,"+","3","-","*","9","\0" 
.ascii	"\0","\0","\0","\0","\0"
map_pressed:
.fill 15,1,0
string_print: 
.asciz "\0"		/* null terminated string length 1 */
/* state machines for the driver */
key_up_flip_flop: .byte 0
extended_key_flip_flop: .byte 0
pause_key_flip_flop: .byte 0
