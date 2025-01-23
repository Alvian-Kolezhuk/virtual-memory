#!/bin/bash

nasm -Werror custom_unreal_bootloader.asm -f bin -o custom_unreal_bootloader.bin &&
tail -n +2 "$1.asm" > "$1$2_raw.asm" &&
tail -n +2 "$3.asm" > "$3$4_raw.asm" &&
tail -n +2 "$5.asm" > "$5$6_raw.asm" &&
tail -n +2 "$7.asm" > "$7$8_raw.asm" &&
echo "org 0x7e00" | cat - "$1$2_raw.asm" > "$1$2_raw_.asm" &&
echo "org 0x8600" | cat - "$3$4_raw.asm" > "$3$4_raw_.asm" &&
echo "org 0x8e00" | cat - "$5$6_raw.asm" > "$5$6_raw_.asm" &&
echo "org 0x9600" | cat - "$7$8_raw.asm" > "$7$8_raw_.asm" &&
rm "$1$2_raw.asm" &&
rm "$3$4_raw.asm" &&
rm "$5$6_raw.asm" &&
rm "$7$8_raw.asm" &&
nasm -d "MODE=$2" -Werror "$1$2_raw_.asm" -f bin -o "$1$2_raw.bin" &&
nasm -d "MODE=$4" -Werror "$3$4_raw_.asm" -f bin -o "$3$4_raw.bin" &&
nasm -d "MODE=$6" -Werror "$5$6_raw_.asm" -f bin -o "$5$6_raw.bin" &&
nasm -d "MODE=$8" -Werror "$7$8_raw_.asm" -f bin -o "$7$8_raw.bin" &&
rm "$1$2_raw_.asm" &&
rm "$3$4_raw_.asm" &&
rm "$5$6_raw_.asm" &&
rm "$7$8_raw_.asm" &&
cat custom_unreal_bootloader.bin "$1$2_raw.bin" "$3$4_raw.bin" "$5$6_raw.bin" "$7$8_raw.bin" > "4_tests.bin" &&
rm "$1$2_raw.bin" &&
rm "$3$4_raw.bin" &&
rm "$5$6_raw.bin" &&
rm "$7$8_raw.bin" &&
qemu-system-x86_64 -drive "format=raw,file=4_tests.bin"
