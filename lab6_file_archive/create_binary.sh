#!/bin/bash
 
# Usage: ./build.sh <your_source_file.c>
 
set -e
 
C_FILE="$1"
 
if [ -z "$C_FILE" ]; then
    echo "Usage: $0 <source_file.c>"
    exit 1
fi
 
BASENAME=$(basename "$C_FILE" .c)
 
riscv64-linux-gnu-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -ffreestanding -c start.S -o start.o
riscv64-linux-gnu-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -ffreestanding -c "$C_FILE" -o "$BASENAME.o"
riscv64-linux-gnu-ld -m elf32lriscv -T link.ld start.o "$BASENAME.o" -o "$BASENAME.elf"
riscv64-linux-gnu-objcopy -O binary "$BASENAME.elf" "$BASENAME.bin"
 
echo "Build complete: $BASENAME.bin"

