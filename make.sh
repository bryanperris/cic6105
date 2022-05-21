#!/bin/bash

# Assemble and verify the bootrom
echo "Assemble BootCode"
bass RspObfuscated.asm
bass BOOTCODE.asm
md5sum --check BOOTCODE.BIN.md5