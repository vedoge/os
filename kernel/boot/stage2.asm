; caps = real mode code
; lowercase = pmode / paged code
bits 16
org 0xC000
jmp entry16




; data area
	FNAME: DB "KERNEL  BIN"
	CLUST: DW 0
; general definitions
	stage2_base	equ 0xc000	; where we are
	pt_base		equ 0x1000	; where our page tables begin
	pt_ceil		equ 0x6ffc	; where our page tables end
	ROOTDIRENTRIES	EQU 224		; no. of FAT rootdir entries
	kern_base	equ 0x40000	; phys / idpaged kernel addr
	vga_off 	equ 0xb8000	; vga mmio text buffer addr
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
	p_offset	equ 0x4
	p_vaddr		equ 0x8
	p_paddr		equ 0xc
	p_filesz	equ 0x10
	p_memsz		equ 0x14
	p_flags		equ 0x18
	p_align		equ 0x1c
	p_size		equ 0x20

; PIC offsets 
	pic1_com	equ 0x20
	pic1_data	equ 0x21
	pic2_com	equ 0xa0
	pic2_data	equ 0xa1

entry16:				; load the kernel ELF at 0x40000
	; copied from the bootloader
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
LOADFAT:			; find the kernel cluster
	MOV AX, [ES:DI+0xF]	; 11 (file length) + 15 (random info) = 26 (cluster offset)
	PUSH AX
SETUP:				; setup to read kernel
	; define the segmentation of the kernel. 
	PUSH 0x09A0		; FAT location
	POP DS			; in DS
	PUSH 0x4000	; kernel loaded at 40000 (610 KiB limit)
	POP ES			; in ES
	XOR BX, BX		; buffer address pointer is ES:0

LOAD:				; load the kernel file into memory
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
LBACHS:				; convert LBA to CHS addressing for INT 13h
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


LOADED:				; arrange kernel in memory
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
	lidt [idtr]
	lgdt [gdtr] 
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	jmp 0x8:start		; reload CS and begin execution in 32-bit mode
bits 32
start:
	mov eax, 0x10		; segment selectors
	mov ds, eax
	mov es, eax
	mov fs, eax
	mov ss, eax
	mov esp, 0xf000
	mov ebp, esp
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

; paging code
	std			; ensure that rep stosd goes downwards in memory (faster and easier to process)
	mov edi, 0x0ffc
	mov eax, 0x00000002
	mov ecx, edi
	shr ecx, 2		; ecx = ecx div 4
	inc ecx			; include 0th entry
rep	stosd			; rep stosd
	; the range 0x0000-0x0fff now contains 1000 not-present page directory entries
	mov edi, pt_ceil
	mov ecx, edi
	sub ecx, pt_base
	shl ecx, 10		; ecx = page frame / bits 31-12 of physaddr
	shr ecx, 12		; net shift right of 2 (division by 4 of the pointer)

	mov dword [highest_phys_frame], ecx
				; store the highest mapped physical frame 
	inc ecx			; for entry 0

;	hlt			; NOTE DEBUGGING STOP
.loop:
	mov eax, ecx
	dec eax			; so 0x0 is mapped to 0x0 and not pt_base
	shl eax, 12		; 3 nibbles left (eax = ecx * 4KiB)
	or eax, 0x03		; mark present and writable
	stosd
loop	.loop

;	cli
;	hlt			; NOTE DEBUGGING STOP
; page directory code
	mov ecx, stage2_base
	sub ecx, pt_base
	shr ecx, 0xc
	lea edi, [ecx*4-4]
.repeat:
	mov eax, ecx
	shl eax, 12
	or eax, 3
	stosd
	loop .repeat

;	hlt			; NOTE DEBUGGING STOP
;	switch to paged
	; load base of page directory into cr3
	mov ecx, cr3
	xor ecx, ecx
	mov cr3, ecx		; flush tlb
	; enable PG bit in cr0
	mov eax, cr0
	or eax, 0x80000000
	mov cr0, eax		; PG_ENABLE
	jmp 0x8:pg_enabled
pg_enabled:
	; if we page fault now, we're toast

	cli
	; show something on screen (debugging purposes)
	mov esi, paged
	call vgaprint
;	hlt			; NOTE DEBUGGING STOP

; check elf magic number
	mov esi, 0x40000	; location of file we loaded in RealMode
	push esi 		; save it for later
	mov edi, elf_mag	; elf magic number for comparing
	cld			; compare forwards in memory
	cmpsd			; speed
	jne noelf
	std
	pop esi
;	hlt			; NOTE DEBUGGING STOP
; prepare to loop through the program header table
	movzx ecx, word [esi+e_phnum]
	mov eax, [esi+e_phoff]	; store program header offset
	lea esi, [esi+eax*1-p_size]
				; get the effective address of the ph table-32
phdr:
	add esi, p_size		; search next table
	cmp dword [esi], 1
	je .loadseg
	loopnz phdr		; null/unknown entry, ignore
	; error- a segment that shouldn't be here
.loadseg:
	push ecx
	push esi 
	push dword [esi+p_align]
	push dword [esi+p_memsz]
	push dword [esi+p_vaddr]
	call modify_page_table	; modify the page table to fit the kernel layout

	mov ebx, [esi+p_align]	; alignment (most probably, page alignment
				; as specified in the linker script)
	mov eax, [esi+p_filesz] 
	xor edx, edx
	mov ecx, 4
	div ecx			; need remainder in edx
	mov ecx, eax
	mov edi, [esi+p_vaddr]
	mov esi, [esi+p_offset]
	add esi, 0x40000
	cld
	rep movsd		; move in dwords
	mov ecx, edx
	rep movsb
	std
	pop esi			; return to rightful place
	pop ecx			; return loop index
	loop physaddr		; next entry

	mov esi, 0x40000
	push 0x8		; code segment, DPL=0
	push dword [esi+e_entry]; e_entry
	retf			; far return (far calls triple fault for whatever reason)
	

; subroutines and data


noelf:

	mov esi, elferror
	call vgaprint

	cli
	hlt		; end
modify_page_table:
	push ebp
	mov ebp, esp
	; first, compute the number of pages
	mov eax, dword [ebp+12]
	shr eax, 12		; divide by 0x1000 (4KiB, one page)
	inc eax
	mov dword [.nr_pages], eax
	; get virtual address and compute the page directory entry first
	mov eax, dword [ebp+8]	; p_vaddr
	mov ebx, [ebp+16]
	neg ebx
	and eax, ebx		; probably unnecessary but
	push eax		; push it
	; now compute the page directory entry
	and eax, 0xffc00000	; top 10 bits, mark present & writable
	shr eax, 0x16		; turn into index for page directory
	mov dword [eax*4], ((pt_ceil+4)|3)
				; store configured ceiling + 4 and present / writable
	pop eax
	and eax,0x003ff000	; bits 21-12
	shr eax, 12		; get page frame
	mov ebx, dword [highest_phys_frame]
				; assign to first unassigned physical frame
	shl ebx, 12
	push ecx
	mov ecx, [.nr_pages]
				; nr of pages to allocate for segment
	lea edi, [eax*4+pt_ceil+4]
.loop:				; allocate nr_pages
	add ebx, 0x1000
	mov eax, ebx		
	or eax, 3		; present and writable
	stosd
	loop modify_page_table.loop
	;endloop
	shr ebx, 12
	mov [highest_phys_frame], ebx
				; store the highest physical frame mapped
	pop ecx

.done:
	mov esp, ebp		; quickly clean up garbage on stack
	pop ebp
	std
	ret 12			; free 12 bytes from stack (avail on 386+)
.nr_pages: dd 0th		; store nr_pages to allocate per segment


; PMode data/subroutines area
message:
	db "h", 0x8f,"e", 0x8f, "l", 0x8f, "l", 0x8f, "o", 0x8f, "!", 0x8f, 0xa, 0x8f, 0, 0

paged:	db "p", 0x8f, "a", 0x8f, "g", 0x8f, "e", 0x8f, "d", 0x8f, 0xa, 0x8f, 0xa, 0x8f, 0, 0

elferror:
	db 'u', 0x8f, 'n', 0x8f, 'k', 0x8f, 'n', 0x8f, 'o', 0x8f, 'w', 0x8f
	db 'n', 0x8f, ' ', 0x8f, 's', 0x8f, 'e', 0x8f, 'g', 0x8f, 'm', 0x8f
	db 'e', 0x8f, 'n', 0x8f, 't', 0x8f, '!', 0x8f, 0, 0

elf_mag:
	db 0x7f, 'E', 'L', 'F' 



vgaprint:
	cli
	push eax
	push ebx
	mov eax, [.idx]
	lea edi, [vga_off+eax*2]
	xor ecx, ecx
	not ecx
	cld
.loop:
	
	lodsw
	cmp ax, 0
	je .done
	cmp al, 0xa		;\n
	je .newline
	stosw
	inc word [.idx]
	loop .loop

.newline:
	;hlt			; DEBUGGING STOP


	mov eax, dword [.idx]
	mov ebx, 80
	xor edx, edx		; note: "div r/m32" uses edx:eax
	div ebx			; as its implicit operand, so zero it.
	cmp eax, 25		; end of screen

;	cmovge eax, 0		; would simplify this structure, but cmovcc is
				; P/K5+ only

	jge .wrapscr		; print starting from next row col 0 again

	add eax, 1		; next line (remainder is discarded)
	mov ebx, 80
	xor edx, edx

	mul ebx			; need to zero edx here also for "mul r/m32"


	lea edi, [vga_off+eax*2]; load our new pointer
	mov dword [.idx], eax	; store as idx
	loop vgaprint.loop	; affect ecx (count as character) 

.wrapscr:
	xor eax, eax
	mov dword [.idx], eax
	lea edi, [vga_off+eax*2]
	loop vgaprint.loop		; clobber ecx (count as character)

.done:
	neg ecx
	dec ecx			; account for the -1

	pop ebx			; also restore
	pop eax

	std

	ret
.idx: dd 0

highest_phys_frame: dd 0


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

end:
