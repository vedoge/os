#!/bin/bash 
nasm -f bin kernel/boot/stage2.asm -o stage2.bin 
/usr/opt/cross/bin/i686-elf-gcc -static -fno-pie -I./include -nostdlib -O0 -w -c kernel/main.c -o main.o
/usr/opt/cross/bin/i686-elf-gcc -static -fno-pie -I./include -nostdlib -O0 -w -c kernel/hw/vga/vga.c -o vga.o
/usr/opt/cross/bin/i686-elf-gcc -static -fno-pie -I./include -nostdlib -O0 -w -c kernel/hw/i8259/i8259.c -o i8259.o
/usr/opt/cross/bin/i686-elf-gcc -static -fno-pie -I./include -nostdlib -O0 -w -mgeneral-regs-only -c kernel/arch/i386/interrupts.c -o interrupts.o
/usr/opt/cross/bin/i686-elf-gcc -static -fno-pie -I./include -nostdlib -O0 -w -c kernel/hw/i8042/i8042.c -o i8042.o
/usr/opt/cross/bin/i686-elf-gcc -static -fno-pie -I./include -nostdlib -O0 -w -c kernel/mm/memory.c -o memory.o
/usr/opt/cross/bin/i686-elf-gcc -static -fno-pie -I./include -nostdlib -O0 -w -c kernel/hw/i8042/i8042_isr.s -o i8042_isr.o
/usr/opt/cross/bin/i686-elf-gcc -static -fno-pie -I./include -nostdlib -O0 -w -mgeneral-regs-only -c kernel/hw/i82077a/i82077a.c -o i82077a.o
# /usr/opt/cross/bin/i686-elf-gcc -static -fno-pie -I./include -nostdlib -c kernel/arch/i386/gdt.c -o gdt.o
/usr/opt/cross/bin/i686-elf-ld main.o vga.o interrupts.o gdt.o i8259.o i8042.o i8042_isr.o i82077a.o memory.o -e main -o main

sudo mount -o loop floppy.img floppy
sudo cp stage2.bin floppy/stage2.bin
sudo cp main floppy/kernel.bin
sudo umount floppy
sync
