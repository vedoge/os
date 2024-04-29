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
	MOV AH, 0		; reset
	MOV DL, 0		; drive 0
	INT 0x13

	PUSH BX
	MOV AX, [SECTORSPERFAT]	; sectors taken up by 1 FAT
	MOV BX, [NUMBEROFFATS]	; sectors per FAT * number of FATS = total sectors taken up by FATS
	MUL BX			; I don't think multiplication can be done with [mem16] unless imul is used, sooo
	INC AX			; +1 for the boot sector
	POP BX			; restore old value of BX
	CALL LBACHS		; convert into params for INT 0x13
	MOV AX, 0x07E0		
	MOV ES, AX		; set up memory
	MOV AH, 0x02
	MOV AL, 14
	XOR BX, BX		; ES:BX = 07E0:0000 (0x7E00), first free block of memory
	INT 0x13
	JNC READROOTDIR		; if no error, proceed. 

	MOV AX, CS
	MOV DS, AX
	MOV SI, FLOPPYERROR	; floppy error string
	CALL BPRINT		; print it
	CLI			; halt and catch fire
	HLT


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
	PUSH CS
	POP DS		; CS=DS
	MOV AX, 0xBEEF
	PUSH 0xFFFF
	POP ES
	MOV WORD [ES:0010], AX
			; probably not the best idea to be using memory address 0000, but oh well
	MOV BX, WORD [DS:0000]
	CMP AX, BX
	JNE .WORKED
	; probably no A20 line
	MOV SI, NOA20
	CALL BPRINT
	CLI
	HLT		; debugging purposes
.WORKED:
	LIDT [IDTR]	; load IDT with offset 0, length 0, one gate with contents P=0 (no interrupt handlers).
	LGDT [GDTR]	; load GDT with dummy registers
	MOV EAX, CR0
	OR EAX, 1	;PE=1 (protection enable) 
	MOV CR0, EAX	
	JMP 0x8:0x1000	; go! perform a long jump to the starting address with the CODESEG selected
; data area
FLOPPYERROR:	DB "Floppy error!", 0
KERNCLUST:	DW 0
KERNFNAME:	DB "KERNEL  BIN"
IDTR:	DW 0
	DD 0		; dummy IDT
GDT:
	DQ 0
	DW 0xFFFF
	DW 0x0000
	DW 0x9A00
	DW 0x00C0
	DW 0xFFFF
	DW 0x0000
	DW 0x9200
	DW 0x00C0
GDTR:
	DW $-GDT
	DD GDT
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
