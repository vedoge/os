;//this piece of code is supposed to test to ensure the bootloader sets up the A20 line correctly. 
;//I will add other protected-mode tests as I become aware of them. 
;//For now, this is not the working kernel and will not be included in the final product. 
;//as such, it will be placed under helpers.
;//I may later reuse the vgaprint routine in my actual code, but now that I have verified the A20 line gets set up correctly, I no longer need to worry. 
bits 32
org 0x1000
	cli
	hlt
	std				;//downwards
	mov eax, 0x10
	mov ds, eax
	mov es, eax
	mov fs, eax
	mov gs, eax
	mov ss, eax
;//test for A20
	mov eax, 0xdeadbeef		;//test dword
	mov dword [ds:0x100001], eax	;//0b0000 0000 0001 0000 0000 0000 0000 0001
	mov ebx, dword [ds:0x000001]	;//0b0000 0000 0000 0000 0000 0000 0000 0001
	cmp eax, ebx			;//check if A20+1 == (!A20)+1 (A20 line stuck either high or low)
	je .a20dead
	push ebp
	mov esp, ebp			;//set up a new stack frame
	push string			;//put the argument on it
	call vgaprint			;//call
	add esp, 4			;//remove the argument
	pop ebp				;//restore orignal stack frame
	hlt
.a20dead:
	push ebp 
	mov esp, ebp
	push erra20
	call vgaprint
	add esp, 4
	pop ebp
	hlt
;//vga print
vgaprint:				;//void vgaprint(const char * str)
	cld
	mov esi, dword [esp+4]		;//retrieve argument from stack (const char * string)
	mov edi, 0xb8000		;//VGA text buffer (destination)
.loop:
	lodsw				;//load a word (character + vga byte) into ax
	cmp ax, 0			;//is it end of string?
	je .die
	stosw				;//it's not, so keep going
	jmp .loop
.die:	std				;//direction back to normal
	ret





string:	db "h", 0x07, 'e', 0x07, 'l', 0x07, 'l', 0x07, 'o', 0x07, ' ', 0x07, 'w', 0x07, 'o', 0x07, 'r', 0x07, 'l', 0x07, 'd', 0x07, 0, 0
erra20:	db 'N', 0x8f, 'o', 0x8f, ' ', 0x8f, 'A', 0x8f, '2', 0x8f, '0', 0x8f, '!', 0x8f, 0, 0

