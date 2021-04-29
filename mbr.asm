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
MediumByte		DB 0F0h		
SectorsPerFat		DW 9		
SectorsPerTrack		DW 18		
Sides			DW 2		
HiddenSectors		DD 0		
LargeSectors		DD 0		 
DriveNo			DW 0		
Signature		DB 41		
VolumeID		DD 00000000H
VolumeLabel		DB "THEOS      "
;11 CHARS ONLY
FileSystem		DB "FAT12   "


CODE:
    ;Setup Stack
    MOV         BP,9000H
    MOV         SP,BP
    ;Horrible stack setup but we don't really need more; SP and BP will be reorganised either way



    ; Load KERNEL.BIN into memory(at 0x1000)
TIMES 510 - ($-$$) DB 0
DW              AA55H