;//Note to self: 
;//This program loads into memory as normal, but for whatever reason fails to print. 
;//Whatever, i'll fix it tomorrow. 
;//VG- 23:04 UTC+08
ORG 0x20000
;//The below order is critical for proper functioning of the operating system.
;//this system adopts a model similar to that of Unix.
JMP ENTRY
ENTRY:
	MOV AX, 0x2000
	CLI
	MOV SS, AX
	MOV SP, 0
	MOV BP, SP
	STI
	PUSH CS
	POP DS
	MOV SI, MSG
	CALL BPRINT
	CLI
	HLT
BPRINT:
	MOV AH, 0x0E
	LODSB
	CMP AL, 0
	JE .DONE
	INT 0x10
	JMP BPRINT
.DONE:	RET
MSG:	DB "YAYYYYYY! FIRST STAGE OF OSDEV COMPLETE!", 0
