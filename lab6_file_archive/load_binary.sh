#!/bin/bash
 
# Usage: ./upload_bin.sh <binary_file> <start_address>
 
set -e
 
BINARY_FILE="$1"
START_ADDR="$2"
 
if [ -z "$BINARY_FILE" ] || [ -z "$START_ADDR" ]; then
    echo "Usage: $0 <binary_file> <start_address>"
    exit 1
fi
 
if [ ! -f "$BINARY_FILE" ]; then
    echo "Error: File '$BINARY_FILE' not found!"
    exit 1
fi
 
ADDR=$((START_ADDR))
 
# Read the binary file 4 bytes at a time (32 bits)
# and write each word to memory using devmem
 
# Read file as raw hex words
xxd -p -c 4 "$BINARY_FILE" | while read WORDHEX; do
    if [ -n "$WORDHEX" ]; then
        # Convert from little-endian to CPU endianess if needed
        BYTE1="${WORDHEX:6:2}"
        BYTE2="${WORDHEX:4:2}"
        BYTE3="${WORDHEX:2:2}"
        BYTE4="${WORDHEX:0:2}"
        WORD32="0x${BYTE1}${BYTE2}${BYTE3}${BYTE4}"
 
        echo "Writing $WORD32 to address 0x$(printf "%08x" $ADDR)"
        
        devmem "$ADDR" 32 "$WORD32"
 
        ADDR=$((ADDR + 4))
    fi
 
done
 
echo "Upload complete."
