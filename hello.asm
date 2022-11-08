[BITS 16]
[ORG 7C00h]
JMP ENTRY
;BIOS parameter block
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
VolumeLabel: 	        DB "MOS FLOPPY "
FileSystem: 	        DB "FAT12   "
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

TIMES 510 - ($-$$) DB 0
DW 0xAA55

