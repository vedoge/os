BITS 16
ORG 7C00h
JMP BEGIN 
BPB: 
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
	MOV AH, 02h
	MOV AL, 9
	MOV CH, 0
	MOV DH, 0
	MOV CL, 2
	MOV DL, 0
	MOV ES, 0x07C0
	MOV BX, 0x0200
	INT 13h
	;//FAT loaded at 7c0:200 (0000:7e00, 200h/512b above us
	;//load root directory next
	;//loading at 0200:0000 (0x2000)
	MOV ES, 0x0200
	XOR BX, BX

	INT 13h
	XOR DX, DX
	MOV DS, DX 
	MOV SI, 
LBACHS:
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

TIMES 510 - ($-$$) DB 0 
DW AA55h 
