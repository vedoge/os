# Helper and generator programs
## What is this? 
This directory contains source code I have used to help me generate output that has gone directly into my code. 
Any code in this directory is not included in the final product, but its output may have been. 
This directory also contains any linker scripts that I have used to link binaries. 
## Where can I use it? 
Run this on your host system if you want to see it working. 
Use your native compiler, not the cross-compiler (NOT `i386-elf` but `your-system's-triplet`) and check the output, if you would like, against parts commented in the source code. For easy serching, grep "GENERATED" and look in each file.
***
- Helper program #1: testkern.asm
This program doesn't agree _per se_ with what was written above, but it is a simple flat binary piece of test code. 
It is assembled with `nasm -f bin` and is placed in the kernel directory as `KERNEL  BIN`. 
Please note that this may stop working with future versions of the bootloader. To this end, I may come back later rewrite this later.
# NB This file is, for now, part of the actual operating system. It may return in the future. 
***
