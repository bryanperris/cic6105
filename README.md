# cic6105
CIC 6105 resources

# What you find in this repo:
* IPL3 bass assembly sources
* 6105 Authentication C source thanks to XScale

# Requires
The ARM9/bass assembler v17+
The `data.bin` file: `dd bs=1 skip=$((0xCB0)) if=<z64 file> of=data.bin`

# Notes
* Most of BOOTCODE.asm assembly source has been copied from krom's 6102 assembly source
* data.bin not included: it is unknown, looks encrypted
* This chipset features a built in authentication algorithm that can access via the PIF RAM

# Credits
* Peter Lemon (krom) - For his help and his 6102 assembly source
* XScale - figuring out the challenge-response authentication algorithm

