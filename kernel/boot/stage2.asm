bits 16
org 0x4000
jmp entry16

pic1_com	equ 0x20
pic1_data	equ 0x21
pic2_com	equ 0xa0
pic2_data	equ 0xa1


; data area
FNAME: DB "KERNEL  BIN"
CLUST: DW 0
; general definitions
stage2_base	equ 0x4000
ROOTDIRENTRIES	EQU 224
; elf definitions

; ELF header

e_ident		equ 0		; 0	begins 0x7f 'E' 'L' 'F'
e_type		equ 0x10	; 16	must be 2 (no relocations)
e_machine	equ 0x12	; 18	must be 0x03 for us
e_version	equ 0x14	; 20	must be 1
e_entry		equ 0x18	; 24
e_phoff		equ 0x1c	; 28
e_shoff		equ 0x20	; 32
e_flags		equ 0x24	; 36
e_ehsize	equ 0x28	; 40
e_phentsize	equ 0x2a	; 42
e_phnum		equ 0x2c	; 44
e_shentsize	equ 0x2e	; 46
e_shnum		equ 0x30	; 48
e_shstrndx	equ 0x32	; 50
e_ehdrend	equ 0x34	; 52

; program header

p_type		equ 0x0
p_offset	equ 0x2
p_vaddr		equ 0x6
p_paddr		equ 0xa
p_filesz	equ 0xe
p_memsz		equ 0x10
p_flags		equ 0x12
p_align		equ 0x14

; section header

sh_name		equ 0x0		; 0
sh_type		equ 0x2		; 2
sh_flags	equ 0x4		; 4
sh_addr		equ 0x6		; 6
sh_off		equ 0xa
sh_size		equ 0xe
sh_link		equ 0x10
sh_info		equ 0x12
sh_addralign	equ 0x14
sh_entsize	equ 0x16


entry16:
; copied from the bootloader
; load the kernel image proper at 0x8000 (temporary location)
READROOTDIR:
	PUSH 0x07E0
	POP ES
	PUSH CS
	POP DS			; ensure CS=DS (for proper addressing of the kernel filename at DS:SI)
	XOR DI, DI		; ES:DI
	MOV CX, ROOTDIRENTRIES; loop through all the root entries available (224 in this case) 
	XOR AX, AX		; AX is our offset

SEARCH:
	PUSH AX			; store offset at beginning of code
	MOV SI, FNAME	; DS:SI contains reference string, ES:DI points to root dir.
	MOV DX, 11
	XCHG CX, DX		; exchange loop indices (entry is stored safely in DX, while CX is used by REP)
REP	CMPSB			; compare the CX characters at DS:SI and ES:DI
	JE LOADFAT		; exit the loop if equal (we have a match safely in ES:DI)

	POP AX			; if not, prepare to offset the index.
	ADD AX, 32
	MOV DI, AX		; next entry
	XCHG CX, DX		; external index (looping through the root directory entries themselves)
LOOP	SEARCH
LOADFAT:
	MOV AX, [ES:DI+0xF]	; 11 (file length) + 15 (random info) = 26 (cluster offset)
	PUSH AX
SETUP:
	; define the segmentation of the kernel. 
	PUSH 0x09A0		; FAT location
	POP DS			; in DS
	PUSH 0xB00		; kernel loaded at b000(610 kb limit)
	POP ES			; in ES
	XOR BX, BX		; buffer address pointer is ES:0

LOAD:
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
	JGE LOADED
	PUSH AX			; save cluster for next iteration
	JMP LOAD 
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


LOADED:				; kernel is loaded - we just need to arrange it in memory using the ELF headers
	; jump into protected mode
	; put the gdt into place
	; page
	; put the elf into a loadable format
	; jump there
	cli
	push 0
	pop ds
	push ds			; whoops - forgot these! Doesn't work otherwise :)
	pop es
;------------------------------------------------------------------------------
	lidt [idtr]
;------------------------------------------------------------------------------
	lgdt [gdtr] 
;------------------------------------------------------------------------------
	mov eax, cr0
	or eax, 1
	mov cr0, eax
;------------------------------------------------------------------------------
	jmp 0x8:start		; reload CS and begin execution in 32-bit mode
bits 32
start:
	mov eax, 0x10		; segment selectors
	mov ds, eax
	mov es, eax
	mov fs, eax
	mov ss, eax
	mov esi, message
	call vgaprint
	; PIC initialisation
	; PIC masks are not saved as they will be masked and set up later
	mov al, 0x11 		; ICW1_INIT | ICW1_ICW4
	out pic1_com, al
	jmp $+2
	jmp $+2
	out pic2_com, al
	jmp $+2
	jmp $+2

	mov al, 0x20		; IVT offset: PIC1 (0x20-0x27)
	out pic1_data, al
	jmp $+2
	jmp $+2
	or al, 0x08		; IVT offset: PIC2 (0x28-0x2f)
	out pic2_data, al
	jmp $+2
	jmp $+2

	mov al, 0x04		;ICW3: tell first PIC identity
	out pic1_data, al 
	jmp $+2
	jmp $+2
	mov al, 0x02		;ICW3: tell second PIC identity
	out pic2_data, al
	jmp $+2
	jmp $+2

	mov al, 0x01		; ICW4: x86 mode
	out pic1_data, al	; pic1 in x86 mode
	jmp $+2
	jmp $+2
	out pic2_data, al	; pic2 also
	jmp $+2
	jmp $+2

	mov al, 0xff
	out pic1_data, al	; mask all interrupts while we set up
	jmp $+2
	jmp $+2
	out pic2_data, al	;same for pic2
align 	4			; something something funky pointer arithmetic
pg_overwrite_limit:		; maximum offset that the page table can overwrite
; paging code
	std			; ensure that rep stosd goes downwards in memory (faster and easier to process)
	mov edi, 0x3ffc
	mov eax, 0x00000002
	mov ecx, edi
	shr ecx, 2		; ecx = ecx div 4
	inc ecx			; include 0th entry
rep	stosd			; rep stosd
	; the range 0x0000-0x0fff now contains 1000 not-present page directory entries
	mov edi, pg_overwrite_limit
	mov ecx, edi
	sub ecx, stage2_base
	shr ecx, 2

	; store the memory address that will be mapped to 0xb8000 (VGA page)
	shl ecx, 12		; shift left to give memory address from index
	mov dword [vga_off], ecx
	shr ecx, 12 		; undo the shift

	inc ecx			; for entry 0
.loop:
	mov eax, ecx
	dec eax			; so 0x0 is mapped to 0x0 and not 0x1000
	shl eax, 12		; 3 nibbles left (eax = ecx * 4KiB)
	or eax, 0x03		; mark present and writable
	stosd
	loop .loop
	cli
	
;	hlt			; NOTE DEBUGGING STOP
	mov dword [pg_overwrite_limit], 0xb8003

	; we need to fill it with the corresponding memory addresses
	; this is a fine way of doing it imho - the PIC code alone is 70 bytes. 
	; the PIC stuff alone gives us enough space to identity page 
	; from 0x0 to 0x11000 (which is enough for now). 
	; my educated guess is that there's 300 bytes of code above us,
	; which should map everything from 0x0 to 0x4b000 (which EVERY OS has)
	; additionally, a page must be reserved for the VGA system at 0xb8000
	; further map reservations should probably be made by most OSes from 
	; BIOS/CMOS/Multiboot memory maps 
	; but that's mostly for things that we won't interfere with
	; as a simple embedded system, so i'll ignore it for now. 
	; We'll later remap some of low memory up to 0xC0000000 (higher half)
	; for simplicity, but for now it's not worth the hassle
	; we identity page the first few KiB of memory to remove the need
	; to translate virtual addresses to physical ones in assembly, 
	; but C should deal with this just fine. 
	; note- addresses 0x00000000-0x00044000 are available and id paged
	; (~1/3rd the real address space). 
	; address 0x00045000 is mapped to the VGA page at phys. 0xb8000. 
	; the kernel will upon initialisation fill this section with pages
	; until 0x5000, which gives us memory access until 0x0040'0000 
	; (4 MiB), and map itself to 0xC0000000 (higher half) 
	mov eax, 0x4000		; address of first page table
	or eax, 3		; present, rw
	mov dword [ds:0], eax		; place in page directory
	mov ecx, cr3
	xor ecx, ecx
	mov cr3, ecx		; flush tlb
	mov eax, cr0
	or eax, 0x80000000
	mov cr0, eax		; PG_ENABLE
	jmp 0x8:pg_enabled
pg_enabled:
	cli
	; map VGA to address
	mov esi, message
	call vgaprint
	hlt
message:
	db "h", 0x8f,"e", 0x8f, "l", 0x8f, "l", 0x8f, "o", 0x8f, "!", 0x8f, 0, 0

vgaprint:
	push eax
	push edx
	mov eax, [.idx]
	mov edx, [vga_off]
	lea edi, [edx+eax*2]
	xor ecx, ecx
	not ecx
	cld
.loop:
	lodsw
	cmp ax, 0
	je .done
	stosw
	inc word [.idx]
	loop .loop
.done:
	neg ecx
	dec ecx
	pop edx
	pop eax
	std
	ret
.idx:	dw 0
%if 0				; "multiline comment" 
pic1_com	equ 0x20
pic1_data	equ 0x21
pic2_com	equ 0xa0
pic2_data	equ 0xa1

read_track	equ 0x2
specify		equ 0x3
sense_status	equ 0x4
write_data	equ 0x5
read_data	equ 0x6
recalibrate	equ 0x7		; seek to 0
sense_interrupt	equ 0x8
write_del_data	equ 0x9
read_id		equ 0xa
read_del_data	equ 0xb
format_track	equ 0xd
dumpreg		equ 0xe
seek		equ 0xf
version		equ 0x10
scan_equal	equ 0x11
perpendicular	equ 0x12
configure	equ 0x13
lock		equ 0x14
verify		equ 0x16
scan_le		equ 0x19
scan_he		equ 0x1d
%endif
gdt:
	DQ 0

	DW 0xFFFF
	DW 0x0000
	DW 0x9A00
	DW 0x00C0

	DW 0xFFFF
	DW 0x0000
	DW 0x9200
	DW 0x00C0

	DW 0xFFFF
	DW 0x0000
	DW 0xFA00
	DW 0x00C0

	DW 0xFFFF
	DW 0x0000
	DW 0xF200
	DW 0x00C0
; need task state segment
gdtr:
	dw gdtr-gdt-1
	dd gdt

idtr:	dw 0
	dq 0
vga_off: dd 0xb8000
end:
