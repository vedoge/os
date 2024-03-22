;//this piece of code is supposed to test to ensure the bootloader sets up the A20 line correctly. 
;//I will add other protected-mode tests as I become aware of them. 
;//For now, this is not the working kernel and will not be included in the final product. 
;//as such, it will be placed under helpers/.
bits 32
org 0x1000
	cli
	mov eax, 0x10
	push eax
	push eax
	push eax
	push eax
	pop es
	pop fs
	pop gs
	pop ds
;//test for A20
	mov eax, 0xdeadbeef
	mov dword [ds:0x100001], eax	;//0b0000 0000 0001 0000 0000 0000 0000 0001
	mov ebx, dword [ds:0x000001]	;//0b0000 0000 0000 0000 0000 0000 0000 0001
	cmp eax, ebx			;//check if A20+1 == (!A20)+1 (A20 line stuck either high or low)
	jne .a20_pass
;//vga print
	mov esi, erra20		;//no a20 line
	mov edi, 0xb8000	;//VGA text buffer
repnz	movsw
	hlt			;//die forever
.a20_pass:
	mov esi, string
	mov edi, 0xb8000
repne	movsw				;//let's try this
	hlt





string:	db "h", 0x07, 'e', 0x07, 'l', 0x07, 'l', 0x07, 'o', 0x07, ' ', 0x07, 'w', 0x07, 'o', 0x07, 'r', 0x07, 'l', 0x07, 'd', 0x07, 0, 0
erra20:	db 'N', 0x8f, 'o', 0x8f, ' ', 0x8f, 'A', 0x8f, '2', 0x8f, '0', 0x8f, '!', 0x8f, 0, 0

