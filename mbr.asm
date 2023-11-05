BITS 16
ORG 0x7C00
JMP BEGIN 
NOP
;//revised memory map 
;//the bootloader in a 16 bit bios system is loaded at 0x7c00. After lengthy experimentation, 
;//I figured the 7bff bytes beforehand are probably not free for my own use. 
;//oops. 
;//Keeping this in mind, I have begun to assign new memory addresses to everything. 
;//Root dir is the 0x1800 (0x200*0xC) bytes after 0x7e00. 
;//After the root dir we store the FAT table beginning 0x9600 onwards. 
;//we load the operating system, as is convention, at 0x2000:0000 (0x20000)
;//keep in mind that this bootloader was originally written with different offsets in mind, so bugs may be found elsewhere later in the process. 
BPB:
;//written with help from the good folks at Wikipedia (thanks btw) and random documentation I found online
;//Mountable on Linux; maybe not so on MS-DOS (windows)
OEMLBL: DB "VOSFLP  "
BYTESPERSECTOR: DW 512
SECTORSPERCLUSTER: DB 1
RESERVEDSECTORS: DW 1
NUMBEROFFATS: DB 2
ROOTDIRENTRIES: DW 224
SECTORS: DW 2880
MEDIADESCRIPTOR: DB 0xF0
SECTORSPERFAT: DW 9
;//end DOS 2.0 BPB
;//begin DOS 3.31 BPB 
SECTORSPERTRACK: DW 18
HEADS: DW 2
HIDDENSECTORS: DD 0
LARGESECTORS: DD 0
DRIVENO: DB 0
EXTBOOTSIGNATURE: DB 0x29
SERIAL: DD 0xACDC
LABEL: DB "VOSFLOPPY  "		;//volume label ALWAYS 11 CHARS
FILESYSTEM: DB "FAT12   "
BEGIN:
	CLI			;//if an interrupt catches us while our stack is messed up we're toast
	MOV AX, CS
	MOV SS, AX
	MOV AX, 0x7C00		;//stack grows directly below us
	MOV SP, AX
	STI

	;//reset the floppy system
	MOV AH, 0
	MOV DL, 0
	INT 0x13
	
	
	MOV AX, 19		;//root dir starts at LBA 19
	CALL LBACHS		;//convert into params for INT 0x13
	MOV AX, 0x07E0		
	MOV ES, AX		;//set up memory
	MOV AH, 0x02
	MOV AL, 14
	XOR BX, BX		;//ES:BX = 07E0:0000 (0x7E00), first free block of memory
	INT 0x13
	JNC READROOTDIR
	MOV AX, CS
	MOV DS, AX
	MOV SI, FLOPPYERROR	;//floppy error string
	CALL BPRINT		;//print it
	CLI			;//halt and catch fire
	HLT


READROOTDIR:
	PUSH CS
	POP DS			;//ensure CS=DS (for proper addressing of the kernel filename at DS:SI)
	MOV AX, 0x07E0
	MOV ES, AX		;//07E0:0000 (0x7E00)
	XOR DI, DI
	MOV CX, [ROOTDIRENTRIES];//loop through all the root entries available (224 in this case) 
	MOV AX, 0		;//AX is our offset
SEARCHKERN:
	PUSH AX			;//store offset at beginning of code
	MOV SI, KERNFNAME	;//DS:SI contains reference string, ES:DI points to root dir.
	MOV DX, 11
	XCHG CX, DX		;//exchange loop indices (entry is stored safely in DX, while CX is used by REP)
REP	CMPSB			;//compare the CX characters at DS:SI and ES:DI
	JE LOADFAT		;//exit the loop if equal (we have a match safely in ES:DI)
	POP AX			;//if not, prepare to offset the index.
	ADD AX, 32
	MOV DI, AX		;//offset ES:DI using our search index
	XCHG CX, DX
LOOP	SEARCHKERN
LOADFAT:
	MOV AX, [ES:DI+0xF]	;//11 (file length) + 15 (random info) = 26 (cluster offset)
	MOV [KERNCLUST], AX 	;//save the kernel cluster in memory
	MOV AX, 2		;//logical sector 2 - fat copy #1
	CALL LBACHS		;//fill in CHS table
	MOV AH, 2		;//read sectors from drive
	MOV AL, 9		;//9 sectors per FAT
	MOV BX, 0x09A0		;//0x7E00 (first available offset) + 0x1C00 (length of root dir) gives 0x9A00 as FAT address
	MOV ES, BX		;//load the FAT into memory at 0x9A00
	XOR BX, BX
	INT 0x13
	JNC SETUPKERN		;//begin loading kernel sectors into memory
	;//something went wrong
	PUSH CS
	POP DS			;//CS=DS
	MOV SI, FLOPPYERROR	;//floppy error string
	CALL BPRINT		;//print it
	CLI			;//halt and catch fire
	HLT
SETUPKERN:
	;//define the segmentation of the kernel. 
	PUSH CS
	POP DS
	MOV SI, KERNELDEBUG
	CALL BPRINT 
	CLI 
	HLT
	MOV AX, 0x09A0
	MOV DS, AX		;//DS=FAT addressing (DS:SI is our buffer pointer to use when calculating next clusters)
	MOV AX, 0xAC0		;//0x9A00 + 0x9*0x200=0xAC00
	MOV ES, AX		;//ES=buffer address segment (ES:BX is the buffer address pointer for INT 0x13)
	XOR BX, BX		;//ensure buffer address pointer is set to 0 (kernel size limit of 640KiB) 
LOADKERN:
	MOV AX, WORD [KERNCLUST];//retrieve the kernel cluster from memory
	PUSH AX			;//put it on the stack for later
	;//load the specified sector
	ADD AX, 31		;//constant to cope with offset due to MBR, FATs, and root dir
	CALL LBACHS 		;//calculate CHS
	MOV AH, 2		;//read sectors
	MOV AL, 1		;//1 sector
	;//*******************************************************************************************************************
	;//OFFENDING CALL FIXME
	INT 0x13
	;//OFFENDING CALL FIXME
	;//*******************************************************************************************************************
	MOV AX, WORD [KERNCLUST]
	ADD BX, 0x200		;//add 512 bytes to ES:BX to get address to load next sector
	;//ax contains cluster number
	MOV DX, 0
	MOV BX, 3
	MUL BX
	MOV DX, 0
	MOV BX, 2		;//12 packed bits per entry = 3/2 the offset
	DIV BX
	MOV AX, WORD [DS:SI]	;//read value from FAT table
	MOV [KERNCLUST], AX
	OR DX, DX
	JZ EVEN		;//if remainder of division by 2 is 0 entry is even
	;//entry is odd
	;//lowest nibble not needed, shift out
	SHR AX, 4
	CMP AX, 0x0FF8
	JAE ENTER
	JMP LOADKERN
EVEN:
	AND AX, 0x0FFF	;//mask highest nibble
	CMP AX, 0x0FF8
	JAE ENTER
	JMP LOADKERN
;//PROBLEM INPUTS TO LBACHS FIXME FIXME FIXME TODO TODO TODO
;//AX=0x0022 (34)
;//INT 0x13 DOESN'T LIKE AND PROGRESSES INTO INFINITE LOOP
LBACHS:	
	;//function is specific to small disk geometries and must be modified
	;//puts CHS parameters in the right place for INT 0x13 to use
	PUSH BX
	MOV DX, 0
	MOV BX, 18
	DIV BX		;//remainder ranges between 0 and 17, and is the sector -1
	INC DX		;//add 1 to make it 1-18 for proper addressing
	MOV CL, DL
	MOV DX, 0 
	MOV BX, 2
	DIV BX
	MOV DH, DL
	MOV CH, AL
	XOR DL, DL
	POP BX
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
ENTER:
	PUSH CS
	POP DS
	MOV SI, KERNELDEBUG
	CALL BPRINT
	CLI
	HLT
FLOPPYERROR:	DB "Floppy error!", 0
KERNELDEBUG: DB "Checkpoint", 0
KERNCLUST: DW 0
DB 0
KERNFNAME: DB "KERNEL  BIN"
BUF:				;//General purpose temporary data storage
TIMES 510 - ($-$$) DB 0 
DW 0xAA55 
