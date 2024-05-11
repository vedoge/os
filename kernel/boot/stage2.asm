bits 32
org 0x2000

pic1_com	equ 0x20
pic1_data	equ 0x21
pic2_com	equ 0xa0
pic2_data	equ 0xa1

floppy_port	equ 0x3F0
st0 		equ 0x0		; read only
st1		equ 0x1		; read only
dor		equ 0x2
msr		equ 0x4		; when reading
ddr		equ 0x4		; when writing
fifo		equ 0x5		; where we get our data
dir		equ 0x7		; digital input register
ccr		equ 0x7		; 

root_dir	equ 0x7e00	; where the bootloader put our root dir
fat		equ 0x9a00	; where our bootloader put our fat table
start:
	cli
	mov eax, 0x10
	mov ds, eax
	mov es, eax
	mov fs, eax

	mov al, 1		; ICW1: to first and second PIC
	out pic1_com, al
	jmp $+2
	jmp $+2
	out pic2_com, al
	jmp $+2
	jmp $+2

	mov al, 0x20
	out pic1_data, al
	jmp $+2
	jmp $+2
	or al, 0x08
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
	; phew, not fun! let's get moving.
	call init_floppy	; todo
	; find our kernel ELF; chuck it into memory; set up paging; and head there for our interrupts
	; interfacing with a floppy disk is famously a pain
parse_table:			; we loaded all of the tables we'll need earlier on, so let's use those to save time. 
	push ds
	pop es			; make sure DS = ES
	xor eax, eax
	mov esi, kern_name
	mov edi, root_dir
	mov ecx, 224
.parse:
	xchg ecx, edx
	mov ecx, 11
rep	cmpsb
	je .done
	add eax, 32
	mov di, [root_dir+eax]
	xchg ecx, edx
	loop .parse
.done:
	mov ax, word [edi + 0xf]; start of file here
	mov word [clust], ax	; store in memory
findsect:			; next sector
				; calculate offset in memory of next sector in FAT table

	mov ax, word [clust]	; load from memory

	; maths - each entry is 12 bits packed. 
	xor dx, dx
	mov bx, 0x3
	mul bx
	xor dx, dx
	and bx, 0x2
	div bx

	mov eax, [ds:esi]	; get next entry from the table
	cmp dx, 0		; check remainder - is it odd?
	jne .odd

.even:				; offset is even - least significant nibble is part of another entry.  
	shr eax, 4		; discard bottom nibble
	; [[FALLTHROUGH]]

.odd:				; offset is odd - most significant nibble is part of another entry
	and eax, 0xfff
	cmp eax, 0xff0		; everything bigger than ff0 is not a valid offset
	jge .end		; let's assume it's an end of file. 
	add si, eax
	mov ax, word [ds:esi]	;new offset
	mov word [clust], ax	; store in [clust]
	add ax, 34		; offset for FAT-LBA conversion
	call load_file_sector	; load the sector
	jmp findsect		; loop until whole file is loaded

.end:
	; todo: read elf file, find entry point, jump there. 
	; floppy routines rely on 
floppy_reset:
	in al, 0x3f2	; select the disk
	and al, 0xfd	; do some bit flipping
	or al, 0x01	; insert drive no 1 into the DOR
	out al, 0x3f2
	jmp $+2
	jmp $+2

	mov al, 0x80
	out 0x3F4, al	; reset our floppy disk
	jmp $+2
	jmp $+2
	; continue with our read
	; configure (fifo = 1, threshold = 8, precomp = 0)
	mov al, 0x13
	out 0x3f
	; first seek
	in al, 0x3F4 
	and al, 0xc0
	cmp al, 0x80
	jne floppy_reset
	mov al, 0xf
	out 0x3f5, al
	jmp $+2
	jmp $+2
	in al, 0x3f5
	cmp al, 0x90	; read version
	je no_error
	cmp al, 0xff	; our port went wrong
	je .read_controller_version
	
	; finish reading code and actually do something useful with the floppy disk
	in al, 0x3f2
	or al, 0x10	; MOTA - start the floppy motor
	out al, 0x3f2
	mov ecx, 32
.spin1: loop spin1
	
; issue a seek command 
	
