[BITS 16]
[ORG 7C00h]
JMP ENTRY
;BIOS parameter block
VolumeLabel: 	        DB "MOS FLOPPY "
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
LBACHS:
	;AX contains your correct values
	;put stuff in ready for int 13h
	;dl=drive, dh=head, cl=sector, ch= cylinder.
	PUSH CX
	CMP AX, 2880
	JGE _INVALIDADDR
	MOV DX, 0
	DIV 0x5A0	;find the head (1440=0x05a0)
	MOV DH, AL
	PUSH DX
	MOV AL, DL	;max quotient from div by 1440 = 1 R 2439
	MOV DX, 0
	MOV AH, 0
	DIV 0x50	;tracks per head (80)
	MOV CH, AL	;cylinder - won't ever use high bits of cl
	MOV CL, AH	;remainder makes up the sector (with some exceptions)
ENTRY:
	CLI
	PUSH CS
	POP SS
	MOV SP, 0x7C00
	STI
	MOV AH, 0
	MOV DL, 0
	INT 0x13
	;reset the disk system
	;Prepare to read the fat file system
	;load the root directory and then the fat table
	MOV AX, [RootEntries]
	MUL  0x10	;mul by 2^9 and div by 2^5
	XCHG AX, CX
	MOV AX, WORD [SectorsPerFAT]
	MUL BYTE [NumberOfFATS]
	ADD 2		;skip past bootsector and 1 reserved sector
	CALL LBACHS
TIMES 510 - ($-$$) DB 0
DW 0xAA55
