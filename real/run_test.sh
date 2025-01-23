#!/bin/bash

nasm -Werror "$1.asm" -f bin -o "$1.bin" && qemu-system-x86_64 -nographic -drive "format=raw,file=$1.bin"
