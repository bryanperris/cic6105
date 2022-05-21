// Assembles obfuscated RSP code

endian msb
output "RspObfuscated.BIN", create

origin $00000000
base $00000000
include "LIB/N64.INC" // Include N64 Definitions
include "LIB/N64_RSP.INC" // RSP Definitions

constant SP_DMA_FULL_REG = 5
constant SP_MEM_ADDR_REG = 0
constant SP_DRAM_ADDR_REG = 1
constant SP_RD_LEN_REG = 2
constant SP_DMA_BUSY_REG = 6

macro read_inst(variable x) {
    parent variable inst = 0;
    variable val = 0;

    val = read(x)
    inst = inst | (val << 24)

    val = read(x + 1)
    inst = inst | (val << 16)

    val = read(x + 2)
    inst = inst | (val << 8)

    val = read(x + 3)
    inst = inst | (val << 0)

    print "Inst ", hex:inst, "\n"
}

macro obfuscate(variable a, variable b) {
    parent variable result = a ^ b
    print "Result: ", hex:result, "\n"

    dw result
}

print "RSP Instructions\n"
arch n64.rsp
mfc0 s1,SP_DMA_FULL_REG
dw $1620FFFE // bne s1,r0,$FFFC
addi s1,r0,$1120
mtc0 s1,SP_MEM_ADDR_REG
addi s1,r0,$01E8
mtc0 s1,SP_DRAM_ADDR_REG
mtc0 s1,SP_RD_LEN_REG
bnez s1,$001C

read_inst($0)
constant rsp_inst_1 = read_inst.inst
read_inst($4)
constant rsp_inst_2 = read_inst.inst
read_inst($8)
constant rsp_inst_3 = read_inst.inst
read_inst($C)
constant rsp_inst_4 = read_inst.inst
read_inst($10)
constant rsp_inst_5 = read_inst.inst
read_inst($14)
constant rsp_inst_6 = read_inst.inst
read_inst($18)
constant rsp_inst_7 = read_inst.inst
read_inst($1C)
constant rsp_inst_8 = read_inst.inst

print "\nIPL2 instructions\n"
arch n64.cpu
lui t5,PIF_BASE // T1 = PIF ROM ($BFC00000)
lw t0,$07FC(t5) // T0 = WORD[PIF RAM $3C]
addiu t5,t5,PIF_RAM // T5 = PIF RAM ($BFC007C0)
andi t0,t0,$0080 // T0 &= $80
dw $5500FFFC // 'bnel t0,r0,$FFFC', if (T0 != 0) goto $FFFC
lui t5,PIF_BASE // T5 = $BFC00000, nullifed is branch not taken
lw t0,$0024(t5) // T0 = $1FC00024
lui t3,CART_DOM1_ADDR2 // T3 = CART_DOM1_ADDR2 ($0xB0000000)

read_inst($20)
constant ipl2_inst_1 = read_inst.inst
read_inst($24)
constant ipl2_inst_2 = read_inst.inst
read_inst($28)
constant ipl2_inst_3 = read_inst.inst
read_inst($2C)
constant ipl2_inst_4 = read_inst.inst
read_inst($30)
constant ipl2_inst_5 = read_inst.inst
read_inst($34)
constant ipl2_inst_6 = read_inst.inst
read_inst($38)
constant ipl2_inst_7 = read_inst.inst
read_inst($3C)
constant ipl2_inst_8 = read_inst.inst

output "RspObfuscated.BIN", create

print "\nObfuscation\n"
obfuscate(ipl2_inst_1, rsp_inst_1)
obfuscate(ipl2_inst_2, rsp_inst_2)
obfuscate(ipl2_inst_3, rsp_inst_3)
obfuscate(ipl2_inst_4, rsp_inst_4)
obfuscate(ipl2_inst_5, rsp_inst_5)
obfuscate(ipl2_inst_6, rsp_inst_6)
obfuscate(ipl2_inst_7, rsp_inst_7)
obfuscate(ipl2_inst_8, rsp_inst_8)