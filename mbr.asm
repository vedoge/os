BITS 16
ORG 7C00h
JMP BEGIN 
BPB:
	;//written with help from the good folks at Wikipedia (thanks btw) and random documentation I found online
BYTESPERSECTOR: DW 512
SECTORSPERCLUSTER: DB 1
RESERVEDSECTORS: DW 0
NUMBEROFFATS: DB 2
ROOTDIRENTRIES: DW 244
MEDIADESCRIPTOR: DB 0xF0
SECTORSPERFAT: DW 9
;//end DOS 2.0 BPB
;//begin DOS 3.31 BPB 
SECTORSPERTRACK: DW 18
HEADS: DW 2
HIDDENSECTORS: DD 0
LARGESECTORS: DD 0
DRIVENO: DB 0
FLAGS: DB 0
EXTBOOTSIGNATURE: DB 0x29
SERIAL: DD 0				;//any 32 bits
LABEL: DB "VOSFLOPPY  "			;//volume label ALWAYS 11 CHARS
FILESYSTEM: DB "FAT12   "
BEGIN:
	CLI				;//interrupts may cause problems when changing stack
	MOV AX, CS
	MOV SS, AX
	MOV AX, 0x7C00	;//stack grows directly below us
	MOV SP, AX
	STI
	MOV AH, 0
	MOV DL, 0
	INT 13h 
	MOV AX, 0
	CALL LBACHS
	MOV AX, 0x0050		
	MOV ES, AX
	MOV AH, 0x02
	MOV AL, 0x9
	XOR BX, BX		;//ES:BX = 0050:0000 (0x500), first free block of memory
	INT 0x13		;//IVT ends at 3FFh though
	JNC READROOTDIR
	MOV AX, CS
	MOV DS, AX
	MOV SI, FLOPPYERROR	;//floppy error string
	CALL BPRINT		;//print it
	CLI			;//halt and catch fire
	HLT
	;//loading at 0200:0000 (0x2000)
READROOTDIR:
	MOV AX, 19		;//starting at LBA 19
	CALL LBACHS
	MOV AH, 0x02
	MOV AL, 14		;//read 14 sectors in root dir.
	MOV BX, 0x0170	;//contiguous block afer the FAT table, ending 0x3300 (kernel loading point). 
	MOV ES, BX
	XOR BX, BX		
	INT 13h
	JNC SEARCHDIR
	;//if carry (read failed for whatever reason)
	;//halt and catch fire
	MOV AX, CS
	MOV DS, AX
	MOV SI, FLOPPYERROR
	CALL BPRINT
	CLI
	HLT
SEARCHDIR:
	MOV AX, CS
	MOV DS, AX
	MOV SI, KERNFNAME
	XOR DI, DI
	MOV AX, 0x0170
	MOV ES, AX
	MOV CX, [ROOTDIRENTRIES]
	MOV AX, 0
SEARCHKERN:
	MOV DX, 11
	XCHG CX, DX
REP	CMPSB
	JE KERNFOUND
	ADD AX, 32
	MOV DI, AX
	XCHG CX, DX
LOOP	SEARCHKERN
KERNFOUND:
	MOV AX, [ES:DI+0xF]	;//11 (file length) + 15 (random info) = 26 (cluster offset)
	PUSH AX
	MOV AX, 0x330
	MOV ES, AX
	XOR BX, BX			;//ES:BX is loadpoint of starting (first) sector
	POP AX
	MOV WORD [KERNCLUST], AX
LOADKERN:
	CALL LBACHS
	INT 13h
	ADD BX, 0x200
	MOV AX, WORD [KERNCLUST]
	CALL NEXTCLUSTER
	CMP AX, 0x0FFF			;//compare to FAT12 EOF character
	JE STARTKERN
	JMP LOADKERN
STARTKERN: 
	JMP 0x0330:0000			;//kernel loading address.
LBACHS:	

;//Function needs to be corrected for HDD geometry; top two C bits have to go into the top two bits in CL
;//FIXME FIXME FIXME
	MOV BX, AX
	MOV DX, 0
	DIV WORD [SECTORSPERTRACK]
	INC DX
	MOV CL, DL
	MOV DX, 0 
	DIV WORD [HEADS]
	MOV DH, DL
	MOV CH, AL
	XOR DL, DL
	RET
NEXTCLUSTER:
	;//ax contains cluster number
	MOV DX, 0
	MOV BX, 3
	MUL BX
	MOV DX, 0
	MOV BX, 2
	DIV BX
	MOV SI, 0x500
	MOV DS, SI
	XOR SI, SI
	MOV SI, AX
	MOV AX, [DS:SI]
	OR DX, DX
	JZ EVEN
	;//entry is odd
	;//lowest nibble not needed, shift out
	SHR AX, 4
	RET
EVEN:
	AND AX, 0x0FFF	;//mask highest nibble
	RET

BPRINT:
	MOV AH, 0x0E
	LODSB
	CMP AL, 0
	JE .BPRINTDONE
	INT 10h
	JMP BPRINT
.BPRINTDONE:
	RET
FLOPPYERROR:	DB "Floppy error!", 0
KERNCLUST: DW 0
KERNFNAME: DB "KERNEL  BIN"
TIMES 510 - ($-$$) DB 0 
DW 0xAA55 
