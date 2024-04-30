bits 32
org 0x2000
start:
	cli
	in al, 0x20	; save state registers: first and second PIC
	jmp $+2		; eb 00
	jmp $+2		; eb 00
	push eax
	in al, 0xa0
	jmp $+2
	jmp $+2
	push eax
	mov al, 1	//ICW1: to first and second PIC
	out 0x20, al
	jmp $+2
	jmp $+2
	out 0xa0, al
	jmp $+2
	jmp $+2
	mov al, 0x04	
	out 0x21, al 
	jmp $+2
	jmp $+2
	mov al, 0x02
	out 0xa1, al
	jmp $+2
	jmp $+2
	pop eax
	out 0x20, al
	pop eax
	out 0xa0, al
	; phew, not fun! let's get moving.
	; PIT programming - TODO
	; find our kernel ELF; chuck it into memory; set up paging; and head there for our interrupts
	; interfacing with a floppy disk is famously a pain
floppy_reset:
	mov al, 0x80
	out 0x3F4, al	; reset our floppy disk
	jmp $+2
	jmp $+2
	; continue with our read
	; first seek
	in al, 0x3F4 
	and al, 0xc0
	cmp al, 0x80
	jne floppy_reset
	mov al, 0xf
	out 0x3f5, al
	jmp $+2
	jmp $+2
	in al, 0x3f5
	cmp al, 0x90
	jne fatal_floppy_error
	; finish reading code and actually do something useful with the floppy disk
