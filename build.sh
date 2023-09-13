#!/bin/bash
nasm -f bin mbr.asm -o mbr.bin
nasm -f bin kernel.asm -o kernel.bin
touch floppy.img
dd if=/dev/zero bs=512 count=2880 of=floppy.img
mkfs.fat -F12 floppy.img
dd bs=512 count=1 conv=notrunc if=mbr.bin of=floppy.img
mkdir loopdevice
mount -o loop floppy.img loopdevice
cp kernel.bin loopdevice
umount loopdevice
