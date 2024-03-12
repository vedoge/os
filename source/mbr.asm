;//Dear reader, 
;//The fact that this is a resounding success is evident from the dearth of comments here. 
;//However, much work is still to be done.
;//This bootloader must account for the fact that floppy reads on actual systems fail very, very often.
;//It is not unusual to find that 3-4 rereads are needed to get a sector right. 
;//This bootloader is not ready to be run on a physical system. This comment may be removed later.
;//Until then, run this at your own risk. If you understand the code, read it, paying particular attention to disk I/O. 
;//It is however worth noting that this code is perfectly safe to run on a virtual system.
;//Yours truly, 
;//Vedant G, Singapore, 22:22 UTC+08 2023-11-23.
BITS 16
ORG 0x7C00
JMP BEGIN 
NOP
BPB:
;//written with help from the good folks at OSDev and Wikipedia (thanks btw) and random documentation I found online
;//Mountable on Linux; maybe not so on MS-DOS (Windows)
OEMLBL: DB "VOSFLP  "
BYTESPERSECTOR: DW 512
SECTORSPERCLUSTER: DB 1
RESERVEDSECTORS: DW 1		;//that's us! 
NUMBEROFFATS: DB 2		;//as is standard on all FAT12 systems
ROOTDIRENTRIES: DW 224		;//total theoretical root dir entries.
SECTORS: DW 2880		;//Total sectors
MEDIADESCRIPTOR: DB 0xF0
SECTORSPERFAT: DW 9
;//end DOS 2.0 BPB
;//begin DOS 3.31 BPB 
SECTORSPERTRACK: DW 18
HEADS: DW 2
HIDDENSECTORS: DD 0
LARGESECTORS: DD 0
DRIVENO: DB 0			;//am floppy
EXTBOOTSIGNATURE: DB 0x29	;//am floppy!!1!!!1!
SERIAL: DD 0xACDC		;//yes
LABEL: DB "VOSFLOPPY  "		;//volume label ALWAYS 11 CHARS
FILESYSTEM: DB "FAT12   "
BEGIN:
	CLI			;//if an interrupt catches us while our stack is messed up we're toast
	MOV AX, CS
	MOV SS, AX
	MOV AX, 0x7000		;//stack grows directly below us
	MOV SP, AX
	CLD			;//stack (and searches) incrementing upwards towards us
	STI			;//0xC00 bytes = 12 * 256 = 3096 bytes of stack should be plenty

	;//reset the floppy system
	MOV AH, 0		;//reset
	MOV DL, 0		;//drive 0
	INT 0x13

	PUSH BX
	MOV AX, [SECTORSPERFAT]	;//sectors taken up by 1 FAT
	MOV BX, [NUMBEROFFATS]	;//sectors per FAT * number of FATS = total sectors taken up by FATS
	MUL BX			;//I don't think multiplication can be done with [mem16] unless imul is used, sooo
	INC AX			;//+1 for the boot sector
	POP BX			;//restore old value of BX
	CALL LBACHS		;//convert into params for INT 0x13
	MOV AX, 0x07E0		
	MOV ES, AX		;//set up memory
	MOV AH, 0x02
	MOV AL, 14
	XOR BX, BX		;//ES:BX = 07E0:0000 (0x7E00), first free block of memory
	INT 0x13
	JNC READROOTDIR		;//if no error, proceed. 

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
	MOV DI, AX		;//next entry
	XCHG CX, DX		;//external index (looping through the root directory entries themselves)
LOOP	SEARCHKERN
LOADFAT:
	MOV AX, [ES:DI+0xF]	;//11 (file length) + 15 (random info) = 26 (cluster offset)
	MOV [KERNCLUST], AX 	;//save the kernel cluster in memory
	MOV AX, 1		;//logical sector 2 - first sector of fat copy #1
	CALL LBACHS		;//fill in CHS table
	MOV AH, 2		;//read sectors from drive
	MOV AL, 9		;//9 sectors per FAT
	MOV BX, 0x09A0		;//0x7E00 (first available offset) + 0x1C00 (length of root dir) gives 0x9A00 as FAT address
	MOV ES, BX		;//load the FAT into memory at 0x9A00
	XOR BX, BX
	INT 0x13
SETUPKERN:
	;//define the segmentation of the kernel. 
	PUSH ES
	POP DS
	MOV AX, 0x1000		;//0x9A00 + 0x9*0x200=0xAC00 which is first address after FAT
	MOV ES, AX		;//ES=buffer address segment (ES:BX is the buffer address pointer for INT 0x13)
	XOR BX, BX		;//ensure buffer address pointer is set to 0 (kernel size limit of 640KiB) 
LOADKERN:
	;//FIXME FIXME FIXME
	;//me, 10:15 pm: It appears to be a problem with this function somehow. My loop appears to break. 
	;//TODO TODO TODO 
	;//I'll work this out tomorrow. Right now, no bren. 
	;//Me, signing off. 
	MOV AX, WORD [KERNCLUST]	;//for the loop
	PUSH AX			;//save for later
	ADD AX, 34		;//offset to cope with the way LBACHS calculates (LBA 35 = first data sector)
	CALL LBACHS		;//put things in the right places
				;//bx is missing, find it
	MOV AH, 0x02
	MOV AL, 0x01
	INT 0x13
	ADD BX, 0x200		;//bump buffer address pointer by 512 bytes
	POP AX
	PUSH BX
	MOV DX, 0		;//zero upper byte
	MOV BX, 3
	MUL BX
	MOV DX, 0		;//zero upper byte, again
	MOV BX, 2		;//multiply by 3/2 as each FAT entry is 12 bits each, with two entries packed into three bytes
	DIV BX
	MOV SI, AX
	MOV AX, [DS:SI]		;//for copying and comparing
	CMP DX, 0
	JNZ ODD
EVEN:
	SHR AX, 4		;//low nibble is part of another entry
	;//fallthrough, but it makes no difference anyways. 
ODD:
	AND AX, 0x0FFF		;//high nibble is part of another entry
	CMP AX, 0x0FF0
	JGE ENTER
	MOV [KERNCLUST], AX
	POP BX			;//restore old value of BX for the buffer address pointer
	JMP LOADKERN 
LBACHS:	
	;//function is specific to 3.5" diskette format and must be modified to fit larger and more general disks. 
	;//puts CHS parameters in the right place for INT 0x13 to use
	PUSH BX		;//put away BX as a garbage register
	;//there seems to be a problem here
	MOV DX, 0	;//ensure high word is not set else 32-bit division
	MOV BX, 18	;//sectors per track - some memory clashes happen here that need to be sorted out!
			;//methinks the BIOS parameter block is overwritten by the stack. 
	DIV BX		;//remainder ranges between 0 and 17 (DX = sector - 1)
	INC DX		;//add 1 to make it 1-18 for proper addressing
	MOV CL, DL	;//put in place
	MOV DX, 0	;//ensure high word is not set, else 32-bit division
	MOV BX, 2	;//calculate head and cylidner
	DIV BX		;//double-sided hence the divide
	MOV DH, DL	;//remainder is the head (where we are supposed to be), 0 or 1
	MOV CH, AL	;//quotient is our cylinder (how far out we are supposed to be)
	XOR DL, DL	;//zero real quick
	POP BX		;//restore old BX
	RET		;//bye

BPRINT:
	MOV AH, 0x0E	;//AH=0x0E, print to screen
	LODSB		;//MOV AL, [DS:SI]; INC SI
	CMP AL, 0	;//assuming null-terminated string
	JE .BPRINTDONE	;//if it is, end
	INT 0x10	;//write to screen
	JMP BPRINT	;//loop for next character
.BPRINTDONE:
	RET		;//quick end
ENTER:
	CLI
	MOV EAX, 0
	LEA EAX, CS:GDT	;//add linear address into EAX
	MOV DWORD [GDTADDR + 2], EAX
	MOVZX BX, [LENGDT]
	ADD EAX, EBX
	MOV WORD [GDTADDR], AX	
	LGDT [GDTADDR]		;//load the gdt
	SMSW AX 
	OR AX, 0x01		;//protection enable bit
	LMSW AX			;//go!
BITS 32
	JMP 0x8:0x10000	;//Kernel entry point (also clear instruction pipeline, which would otherwise contain garbage)
BITS 16
FLOPPYERROR:	DB "Floppy error!", 0
KERNCLUST: DW 0
DB 0
KERNFNAME: DB "KERNEL  BIN"
GDT: 
	DQ 0			;//null gdt entry
	DD 0xFFFF0000		;//base 0xYYYY0000h, limit 0xYFFFF
	DD 0x00CF9A00		;//base 00000000h, limit FFFFFh (=1048576), access byte = 0xC (system), flags = 0x9A (DPL 0, code)
	DD 0xFFFF0000		;//same settings for memory
	DD 0x00CF9200		;//flags 0xC, access 0x92 - System, DPL 0, Write bit, no execute
	DD 0XFFFF0000		;//same memory
	DD 0x00CFFA00		;//flag A - no System bit set
	DD 0xFFFF0000		
	DD 0x00CFF200		;//Flags 0xC, DPL 3 (user), type A (data) 
LENGDT: DB $-GDT			;//length of gdt
GDTADDR:
	DW 0
	DD 0
BUF:				;//General purpose temporary data storage (guaranteed at least 192 bytes)
TIMES 510 - ($-$$) DB 0 
DW 0xAA55 
