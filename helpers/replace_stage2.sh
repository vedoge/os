#!/bin/bash 
nasm -f bin kernel/boot/stage2.asm -o stage2.bin 
sudo mount -o loop floppy.img floppy
sudo cp stage2.bin floppy/stage2.bin
sudo umount floppy
