BITS 16
ORG 0x7C00
JMP ENTRY
;BIOS parameter block 
BytesPerSector: DW 512
SectorsPerCluster: DB 1
ReservedSectors: DW 1
NumberOfFATs: DB 1
RootDirEntries: DW 224
TotalSectors: DW 2880
MediaDescriptor: DB 0xF0
SectorsPerFAT: DW 9
SectorsPerTrack: DW 18
HeadsPerCylinder: DW 2
HiddenSectors: DD 0
BigSectors: DD 0
; Extended Boot Signature
DriveNo: DB 0
ExtBootSig: DB 0x29
SerialNo: DD 0xDEADBEEF
Label: DB "VOS FLOPPY "
Filesystem: DB "FAT12   "
ENTRY:




