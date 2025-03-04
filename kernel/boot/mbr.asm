; Dear reader, 
; The fact that this is a resounding success is evident from the dearth of comments here. 
; However, much work is still to be done.
; This bootloader must account for the fact that floppy reads on actual systems fail very, very often.
; It is not unusual to find that 3-4 rereads are needed to get a sector right. 
; This bootloader is not ready to be run on a physical system. This comment may be removed later.
; Until then, run this at your own risk. If you understand the code, read it, paying particular attention to disk I/O. 
; It is however worth noting that this code is perfectly safe to run on a virtual system.
; Yours truly, 
; Vedant G, Singapore, 22:22 UTC+08 2023-11-23.
BITS 16
ORG 0x7C00
JMP BEGIN 
NOP
BPB:
; written with help from the good folks at OSDev and Wikipedia (thanks btw) and random documentation I found online
; Mountable on Linux; maybe not so on MS-DOS (Windows)
OEMLBL: DB "VOSFLP  "
BYTESPERSECTOR: DW 512
SECTORSPERCLUSTER: DB 1
RESERVEDSECTORS: DW 1		; that's us! 
NUMBEROFFATS: DB 2		; as is standard on all FAT12 systems
ROOTDIRENTRIES: DW 224		; total theoretical root dir entries.
SECTORS: DW 2880		; Total sectors
MEDIADESCRIPTOR: DB 0xF0	; am floppy
SECTORSPERFAT: DW 9
; end DOS 2.0 BPB
; begin DOS 3.31 BPB 
SECTORSPERTRACK: DW 18
HEADS: DW 2
HIDDENSECTORS: DD 0
LARGESECTORS: DD 0
DRIVENO: DB 0			; am floppy!!
EXTBOOTSIGNATURE: DB 0x29	; AM FLOPPY!!1!!!1!
SERIAL: DD 0xACDC		; yes
LABEL: DB "VOSFLOPPY  "		; volume label ALWAYS 11 CHARS
FILESYSTEM: DB "FAT12   "
BEGIN:
	CLI			; if an interrupt catches us while our stack is messed up we're toast
	MOV AX, CS
	MOV SS, AX
	MOV AX, 0x7000		; stack grows directly below us
	MOV SP, AX
	STI			; 0xC00 bytes = 12 * 256 = 3096 bytes of stack should be plenty

	; reset the floppy system
	XOR AH, AH		; reset
	XOR DL, DL		; drive 0

	INT 0x13

	PUSH 0x7E0
	POP ES
	XOR BX, BX		; ES:BX = 07E0:0000 (0x7E00), first free block of memory

	MOV AX, 0x13		; sector 19
	CALL LBACHS
	MOV AH, 0x02		; read sectors
	MOV AL, 14		; 14 sectors
	INT 0x13
	JNC READROOTDIR		; if no error, proceed. 

	MOV AX, CS
	MOV DS, AX
	MOV SI, FLOPPYERROR	; floppy error string
	CALL BPRINT		; print it
	CLI			; halt and catch fire
	HLT


READROOTDIR:
	PUSH CS
	POP DS			; ensure CS=DS (for proper addressing of the kernel filename at DS:SI)
	XOR DI, DI
	MOV CX, [ROOTDIRENTRIES]; loop through all the root entries available (224 in this case) 
	XOR AX, AX		; AX is our offset

SEARCHSTAGE:
	PUSH AX			; store offset at beginning of code
	MOV SI, STAGEFNAME	; DS:SI contains reference string, ES:DI points to root dir.
	MOV DX, 11
	XCHG CX, DX		; exchange loop indices (entry is stored safely in DX, while CX is used by REP)
REP	CMPSB			; compare the CX characters at DS:SI and ES:DI
	JE LOADFAT		; exit the loop if equal (we have a match safely in ES:DI)

	POP AX			; if not, prepare to offset the index.
	ADD AX, 32
	MOV DI, AX		; next entry
	XCHG CX, DX		; external index (looping through the root directory entries themselves)
LOOP	SEARCHSTAGE
LOADFAT:
	MOV AX, [ES:DI+0xF]	; 11 (file length) + 15 (random info) = 26 (cluster offset)
	PUSH AX
	MOV AX, 1
	CALL LBACHS
	MOV AH, 2		; read sectors from drive
	MOV AL, 9		; 9 sectors per FAT
	PUSH 0x09A0		; 0x7E00 (first available offset) + 0x1C00 (length of root dir) gives 0x9A00 as FAT address
	POP ES			; load the FAT into memory at 0x9A00
	XOR BX, BX		; buffer address pointer now goes to the right place
	INT 0x13
SETUPSTAGE:
	; define the segmentation of the kernel. 
	PUSH ES
	POP DS
	PUSH 0xc00
	POP ES
	XOR BX, BX		; ensure buffer address pointer is set to 0 (kernel size limit of 640KiB) 

LOADSTAGE:
	POP AX
	PUSH AX

	ADD AX, 31		; offset to cope with the way LBACHS calculates (LBA 34 = first data sector)
	CALL LBACHS		; put things in the right places

	MOV AH, 0x02
	MOV AL, 0x01
	INT 0x13

	ADD BX, 0x200		; bump buffer address pointer by 512 bytes

	POP AX

	PUSH BX
	XOR DX, DX		; zero upper byte
	MOV BX, 3
	MUL BX
	MOV BX, 2
	DIV BX
	POP BX

	MOV SI, AX
	MOV AX, [DS:SI]		; for copying and comparing
	OR DX, 0
	JZ EVEN
ODD:
	SHR AX, 4		; low nibble is part of another entry
	; fallthrough, but it makes no difference anyways. 
EVEN:
	AND AX, 0x0FFF		; high nibble is part of another entry
	CMP AX, 0x0FF0
	JGE ENTER
	PUSH AX			; save cluster for next iteration
	JMP LOADSTAGE 
LBACHS:	
	; function is specific to 3.5" diskette format and must be modified to fit larger and more general disks. 
	; puts CHS parameters in the right place for INT 0x13 to use
	PUSH BX		; put away BX as a garbage register
	; there seems to be a problem here
	XOR DX, DX	; ensure high word is not set else 32-bit division
	MOV BX, 18	; sectors per track - some memory clashes happen here that need to be sorted out!
			; methinks the BIOS parameter block is overwritten by the stack. 
	DIV BX		; remainder ranges between 0 and 17 (DX = sector - 1)
	INC DX		; add 1 to make it 1-18 for proper addressing
	MOV CL, DL	; put in place
	XOR DX, DX	; ensure high word is not set, else 32-bit division
	MOV BX, 2	; calculate head and cylidner
	DIV BX		; double-sided hence the divide
	MOV DH, DL	; remainder is the head (where we are supposed to be), 0 or 1
	MOV CH, AL	; quotient is our cylinder (how far out we are supposed to be)
	XOR DL, DL	; zero real quick
	POP BX		; restore old BX
	RET		; bye

BPRINT:
	PUSH AX		; bprint clobbers AX
.BPRINTLOOP:
	MOV AH, 0x0E	; AH=0x0E, print to screen
	LODSB		; MOV AL, [DS:SI]; INC SI
	CMP AL, 0	; assuming null-terminated string
	JE .BPRINTDONE	; if it is, end
	INT 0x10	; write to screen
	JMP .BPRINTLOOP	; loop for next character
.BPRINTDONE:
	POP AX
	RET		; quick end
ENTER: 
	CLI
	; enable A20 line before protected mode switching
	; this method interfaces with the PS/2 controller in the computer to do things to magically turn on the A20. 
	; idk how it works tho
	CALL PS2COMAWAIT
	MOV AL, 0xD0	; read from status buffer
	OUT 0x64, AL	; send command
	IN AL, 0x60	; read
	CALL PS2DATAAWAIT
	OR AL, 0x02	; A20 line enable
	SHL AX, 8	; result in AH
	CALL PS2COMAWAIT; wait
	MOV AL, 0xD1	; write output register
	OUT 0x64, AL	; send command to 8042 PS/2 controller
	SHR AX, 8	; put original status register back
	CALL PS2COMAWAIT; wait
	OUT 0x60, AL	; send new output register to I/O port
;	LIDT [IDTR]	; load IDT with offset 0, length 0, one gate with contents P=0 (no interrupt handlers).
;	LGDT [GDTR]	; load GDT with dummy registers
;	MOV EAX, CR0
;	OR EAX, 1	;PE=1 (protection enable) 
;	MOV CR0, EAX
;	JMP 0x8:0x4000	; go! perform a long jump to the starting address with the CODESEG selected
	JMP 0x0:0xC000	;go to memory address 0xC000

; data area
FLOPPYERROR:	DB "Floppy error!", 0
STAGEFNAME:	DB "STAGE2  BIN"
PS2COMAWAIT:
	PUSH AX		; PS2COMAWAIT clobbers AX
	IN AL, 0x64	; receive status register.
	TEST AL, 2	; test bit at 0x02
	JZ COMREADY	; if zero, go to common RET routine in BPRINT.
	JMP PS2COMAWAIT	; loop. If it hangs, then the 8042 controller is destroyed anyway so it's pointless
PS2DATAAWAIT:	
	PUSH AX
	IN AL, 0x64
	TEST AL, 1
	JZ COMREADY
	JMP PS2DATAAWAIT
COMREADY:	
	POP AX
	RET 
NOA20:
	DB "A20 LINE ENABLE FAIL"
				; if the A20 line fails to enable the routine should catch it and print this 
	TIMES 510 - ($-$$) DB 0	; pad to 510 bytes (1 sector - bootsector magic number) 
	DW 0xAA55		; magic number for bootsector at 0x200. Actually 0x55 0xaa but NASM packs as little endian. 
