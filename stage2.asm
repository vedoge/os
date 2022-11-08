[BITS 16]
[ORG 0x1000]
CLI
MOV AX, 0
MOV DS, AX
PUSH DS
POP ES
MOV DI, 0x1100
CALL BINPUT
CALL BPRINT
CLI 
HLT
BPRINT:	;DS:SI must contain a pointer to a null terminated string
	LODSB
	OR AL, AL
	JZ _PRINTDONE
	MOV AH, 0xE
	INT 0x10
	JMP PRINT
_PRINTDONE:
	RET
BINPUT:
	;ES:DI gets written; ensure said pointer is not in bios-critical area or high memory.
	MOV AH, 0
	INT 0x16
	CMP AL, 0x10
	JE _INDONE
	STOSB 
	JMP INPUT
_BINDONE:
	MOV AL, 0
	STOSB
	RET
