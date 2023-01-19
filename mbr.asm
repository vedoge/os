[BITS 16]
[ORG 7C00h]
JMP ENTRY
;BIOS parameter block
VolumeLabel: 	        DB "VOS FLOPPY "
BytesPerSector:  	DW 512
SectorsPerCluster: 	DB 1
ReservedSectors: 	DW 1
NumberOfFATs: 	DB 2
RootEntries: 	DW 224
TotalSectors: 	DW 2880
Media: 		DB 0xF0
SectorsPerFAT: 	DW 9
SectorsPerTrack: 	DW 18
HeadsPerCylinder: 	DW 2
HiddenSectors: 	DD 0
TotalSectorsBig:     DD 0
DriveNumber: 	        DB 0
Unused: 		DB 0
ExtBootSignature: 	DB 0x29
SerialNumber:	        DD 0xa0a1a2a3
FileSystem: 	        DB "FAT12   "
BPRINT:	;DS:SI must contain a pointer to a null terminated string
	LODSB
	OR AL, AL
	JZ _BPRINTDONE
	MOV AH, 0xE
	INT 0x10
	JMP PRINT
_BPRINTDONE:
	RET
LBACHS:
	;AX contains your correct values
	;put stuff in ready for int 13h
	;dl=drive, dh=head, cl=sector, ch= cylinder.
	CLI				;we can have no clobber				
	PUSH BX
	MOV DX, 0			;to prevent x86 from misunderstanding divisor
	DIV WORD [SectorsPerTrack]	;division
	INC DX				;+1 - sectors begin at 1
	PUSH DX				;save for later
	MOV DX, 0			;again for the division
	DIV [HeadsPerCylinder]
	POP BX				;bl = sector
	MOV DH, DL			;set head
	MOV CH, AL			;cylinder
	MOV CL, BL			;sector
	POP BX				;restore old content
	STI				;interrupts on
	RET				;bye!
ENTRY:
	CLI				;can get messy otherwise
	PUSH CS
	POP SS
	MOV SP, 0x07C0			;stack directly below us
	STI
	MOV AH, 0
	MOV DL, 0
	INT 0x13			;go!
	MOV AX, 19
	CALL LBACHS
	XOR BX, BX
	MOV ES, BX
	MOV BX, 0x7E00
	INT 0x13		;go!
_SEARCHROOTDIR:			;where file?
	MOV SI, KernName
	XCHG SI, AX
	MOV AX, 0
_INTLOOP:			;REP CMPSB needs CX, so DX is our dustbin
	PUSH AX
	XCHG CX, DX
	MOV CX, 11
	REP CMPSB
	JE FOUND_FILE
	XCHG CX, DX		;don't actually eat stuff from the dustbin irl.
	POP AX
_NEXT:
	ADD AX, 32
	MOV SI, AX
	LOOP _INTLOOP
_FOUND_FILE:
	MOV AX, [DI+0x0F]
	MOV [Cluster], AX	;just in case we get clobbered
_LOAD_FAT:
	MOV AX, 1
	CALL LBACHS
	MOV BX, 0
	MOV ES, BX
	MOV BX, 0x7E00
	MOV AX, 0x200
	MUL 0xE
	ADD BX
	MOV BX, AX
	MOV AX, 0x902
	PUSHA
	INT 0x13
	POPA
_CALC_FAT:
	
KernName: db "VOS     SYS"
Cluster: dw 0
TIMES 510 - ($-$$) DB 0
DW 0xAA55
