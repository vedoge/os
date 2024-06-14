#!/bin/bash 
nasm -f bin kernel/boot/stage2.asm -o stage2.bin 
/usr/opt/cross/bin/i686-elf-gcc -static -fno-pie -I./include -nostdlib -c kernel/main.c -o main.o
/usr/opt/cross/bin/i686-elf-gcc -static -fno-pie -I./include -nostdlib -c kernel/drivers/vga/vga.c -o vga.o
/usr/opt/cross/bin/i686-elf-gcc -static -fno-pie -I./include -nostdlib -mgeneral-regs-only -c kernel/arch/i386/interrupts.c -o interrupts.o
/usr/opt/cross/bin/i686-elf-gcc -static -fno-pie -I./include -nostdlib -c kernel/arch/i386/gdt.c -o gdt.o
/usr/opt/cross/bin/i686-elf-ld main.o vga.o interrupts.o gdt. o -e main -o main
sudo mount -o loop floppy.img floppy
sudo cp stage2.bin floppy/stage2.bin
sudo cp main floppy/kernel.bin
sudo umount floppy
sync
