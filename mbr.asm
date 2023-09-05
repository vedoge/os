BITS 16
ORG 7C00h
JMP BEGIN 
BPB:
	;//stolen from the good folks at Wikipedia (thanks btw) and random documentation I found online
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
SERIAL: DD 0
LABEL: DB "VOSFLOPPY  "
FS: "FAT12   "

BEGIN:
	MOV AH, 0
	MOV DL, 0
	INT 13h 
	MOV AX, 0
	CALL LBACHS
	MOV AH, 0x02
	MOV AL, 9
	MOV ES, 0x0050		
	XOR BX, BX		;//ES:BX = 0050:0000 (0x500), first free block of memory
	INT 0x13		;//IVT ends at 3FFh though
	JNC READROOTDIR
	MOV DS, CS
	MOV SI, FATERROR
	CALL BPRINT
	CLI
	HLT
	;//FAT loaded at 7c0:200 (0000:7e00, 200h/512b above us
	;//load root directory next
tt566	;//loading at 0200:0000 (0x2000)
READROOTDIR:
	MOV AX, 19		;//starting at LBA 19
	CALL LBACHS
	MOV AH, 0x02
	MOV AL, 14		;//read 14 sectors in root dir.
	MOV ES, 0x0170		;//contiguous block afer the FAT table, ending 0x3300 (kernel loading point). 
	XOR BX, BX		
	INT 13h
	JNC SEARCHDIR
	MOV DS, CS
	MOV SI, ROOTDIRERROR
	CALL BPRINT
	CLI
	HLT
SEARCHDIR:
	MOV DS, CS		;//DS=CS
	MOV SI, KERNFNAME
	XOR DI, DI
	MOV ES, 0x0170		;//ES:DI addresses 0170:0000 (0x01700) which is where we loaded our root directory
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
	LEA AX, [ES:DI+0xF]	;//11 (file length) + 15 (random info) = 26 (cluster offset)
	MOV WORD [KERNCLUST], AX;//keep it safe
	MOV AX, 0x330
	MOV ES, AX
	
LBACHS:	

;//Function needs to be corrected for HDD geometry; top two C bits have to go into the top two bits in CL
;//FIXME FIXME FIXME
	MOV BX, AX
	MOV DX, 0
	DIV WORD [SECTORSPERTRACK]
	INC DX
	MOV CL, DL
	MOV DX, 0 
	DIV [HEADS]
	MOV DH, DL
	MOV CH, AL
	XOR DL, DL
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
TIMES 510 - ($-$$) DB 0 
DW AA55h 
