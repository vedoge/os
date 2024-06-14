# ENTRY(_entry)
SECTIONS {
	. = 0x8048000;
	.text BLOCK(4K) : ALIGN(4K) {
		*(.text)
		ivt = .;
		. += 0x800;		# store space for the interrupt vector table (which is code)
	}
	.rodata BLOCK(4K) : ALIGN(4K) {
		*(.rodata)
	}
	.data BLOCK(4K) : ALIGN(4K) {
		*(.data)
	}
	.bss BLOCK(4K) : ALIGN(4K) {
		*(COMMON)
		*(.bss)
	}
}

