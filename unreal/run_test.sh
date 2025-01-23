#!/bin/bash

nasm -Werror unreal_bootloader.asm -f bin -o unreal_bootloader.bin &&
nasm -Werror "$1.asm" -f bin -o "$1_raw.bin" &&
cat unreal_bootloader.bin "$1_raw.bin" > "$1.bin" &&
rm "$1_raw.bin" &&
qemu-system-x86_64 -drive "format=raw,file=$1.bin"
