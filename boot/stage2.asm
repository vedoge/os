bits 16
org 0
entry:
	sti		;//restore interrupts
	push cs		
	pop ds		;//CS=DS for addressing
	mov si, string	;//address of string in SI
	call bprint	;//call our routine
	cli		;//no interrupts
	hlt		;//halt
bprint:
	;//function head.
	cld		;//DF=0 so lodsb moves forward through memory.
.bprintloop:
	lodsb		;//mov byte [ds:si], al; inc si
	cmp al, 0	;//assuming null-terminated string
	je .bprintdone	;//if it is, end
	mov ah, 0x0e	//Write to screen
	int 0x10	;//write to screen
	jmp .bprintloop	;//loop for next character
.bprintdone:
	std		;//DF=1 for standards (stack grows downwards)
	ret		;//quick end
;//data area
string: db "hello world!", 13, 10, 0
	
