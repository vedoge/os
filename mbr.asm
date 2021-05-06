BITS 16
ORG 07C00h
;Declaration
KERNEL_OFFSET EQU 1000H
JMP SHORT CODE
NOP
;BIOS param block
OEMLabel		DB "VOS"
BytesPerSector	DB 512
SectorsPerCluster	DB 1	
ReservedForBoot		DW 1		
NumberOfFats		DB 2
RootDirEntries		DW 224	
; (224 * 32 = 7168 = 14 sectors to read)
LogicalSectors		DW 2880	
MediumByte		DB 0F00H
SectorsPerFat		DW 9		
SectorsPerTrack		DW 18		
Sides			DW 2
HiddenSectors		DD 0		
LargeSectors		DD 0		 
DriveNo			DW 0		
Signature		DB 41		
VolumeID		DD 0x00000000
VolumeLabel		DB "THEOS      "
;11 CHARS ONLY
FileSystem		DB "FAT12   "       ;Do not change!


CODE:
MOV			AX, 0x7C00
ADD			AX,544
MOV			SS, AX
MOV			SP, 4096
;4K of stack space directly above us
PUSHA
;Back up registers
MOV			AH,2
;read from Drive
MOV			AL,SectorsPerFat
MOV			DL,0
MOV			BX,0x7C00
ADD			BX,544
ADD			BX,4098	;Directly above SS:SP (stack)
;Load FAT above the stack
LOAD:INT		13
JNC FLOPPYOK
DISK_ERROR:
	INT		13H
	JNC		LOADROOTDIR
DOUBLE_FAULT:
	XOR		AH,AH
	INT		13H
	JNC		LOAD
TRIPLE_FAULT:
LOADROOTDIR:
	MOV AH, 19
	;Find KERNEL and load it into memory(at 0x1000)
	
BOOTEND:
TIMES 510 - ($-$$) DB 0
DW              AA55H
