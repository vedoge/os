.code32
.text
.globl kbd_interrupt_handler
.type kbd_interrupt_handler, @function
.extern vga_puts
.extern eoi
.type vga_puts, @function
kbd_interrupt_handler: 
	push %ebp
	movl %esp, %ebp
	push %eax
	push %ebx
	push %ecx
	push %edx
	movb $0x60, %dl
	movzbl %dl, %edx
	inb %dx, %al
	cmp $0, (flip_flop)
	jne unset_flip_flop
	cmp $0xf0, %al
	je set_flip_flop		/* if end of code */ 
	cmp $0xe0, %al
	je extended_key
	cmp $0xe1, %al
	je pause_key
	movl $scancode_table, %ebx
	xlatb
	mov %al, (string_print)
	push $0x3f
	push $string_print
	call vga_puts
	addl $8, %esp
unset_flip_flop:
	movl $0, (flip_flop)
end:
	push $1 
	call eoi
	add $4, %esp
	pop %edx
	pop %ecx
	pop %ebx
	pop %eax
	leave
	iret
set_flip_flop:
	movl $1, (flip_flop)
	jmp end
pause_key:
	movb $0x60, %dl
	movzbl %dl, %edx
	inb %dx, %al
	inb %dx, %al
extended_key: 
	movb $0x60, %dl
	movzbl %dl, %edx
	in %dx, %al
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
.asciz "\0"
flip_flop: .long 0
