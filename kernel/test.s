	.file	"test.c"
	.text
	.section	.rodata
	.type	VGA_COLS, @object
	.size	VGA_COLS, 1
VGA_COLS:
	.byte	80

	.type	VGA_ROWS, @object
	.size	VGA_ROWS, 1
VGA_ROWS:
	.byte	25
.LC0:
	.string	"hello world!"
	.text
	.globl	main
	.type	main, @function
main:
	leal	4(%esp), %ecx
	andl	$-16, %esp
	pushl	-4(%ecx)
	pushl	%ebp
	movl	%esp, %ebp
	pushl	%ecx
	subl	$20, %esp
	movl	$.LC0, -12(%ebp)
	subl	$12, %esp
	pushl	-12(%ebp)
	call	strlen
	addl	$16, %esp
	movzbl	%al, %eax
	movl	%eax, -16(%ebp)
	pushl	$0
	pushl	$0
	pushl	$143
	pushl	$104
	call	vga_putchar
	addl	$16, %esp
	pushl	$0
	pushl	$0
	pushl	$143
	pushl	-12(%ebp)
	call	vga_puts
	addl	$16, %esp
	movl	$0, %eax
	movl	-4(%ebp), %ecx
	leave
	leal	-4(%ecx), %esp
	ret
	.size	main, .-main
	.ident	"GCC: (GNU) 13.2.0"
