// N64 'Bare Metal' NUS-CIC-6105 Boot Code

arch n64.cpu
endian msb
output "BOOTCODE.BIN", create

origin $00000000
base $A4000040 // Entry Point Of Code
include "LIB/N64.INC" // Include N64 Definitions

// COP0 registers:
constant zero = $00
constant Index = $00
constant Random = $01
constant EntryLo0 = $02
constant EntryLo1 = $03
constant Context = $04
constant PageMask = $05
constant Wired = $06
constant RESERVED_7 = $07
constant BadVAddr = $08
constant Count = $09
constant EntryHi = $0A
constant Compare = $0B
constant Status = $0C
constant Cause = $0D
constant EPC = $0E
constant PRevID = $0F
constant Config = $10
constant LLAddr = $11
constant WatchLo = $12
constant WatchHi = $13
constant XContext = $14
//constant *RESERVED* = $15
//constant *RESERVED* = $16
//constant *RESERVED* = $17
//constant *RESERVED* = $18
//constant *RESERVED* = $19
constant PErr = $1A
constant CacheErr = $1B
constant TagLo = $1C
constant TagHi = $1D
constant ErrorEPC = $1E
//constant *RESERVED* = $1F

// RSP Cop0 Registers
constant SP_MEM_ADDR_REG  = 0
constant SP_DRAM_ADDR_REG = 1
constant SP_RD_LEN_REG    = 2
constant SP_WR_LEN_REG    = 3
constant SP_STATUS_REG    = 4
constant SP_DMA_FULL_REG  = 5
constant SP_DMA_BUSY_REG  = 6
constant SP_SEMAPHORE_REG = 7
constant DPC_STATUS_REG = 11
constant DPC_CLOCK_REG = 12

//  Expected register states from IPL 1 & 2
//  a2: $000000005493FB9A - Unused
//  t3: $FFFFFFFFA4000040 - Pointer to IPL3 bootcode
//  sp: $FFFFFFFFA4001FF0 - Stack Pointer
//  ra: $FFFFFFFFA4001550 - Return address
//  at: $0000000000000000 - Unused
//  v0: $FFFFFFFFF58B0FBF - Checked if value is zero or not
//  v1: $FFFFFFFFF58B0FBF - Unused
//  a0: $0000000000000FBF - Unused
//  t4: $FFFFFFFF9651F81E - Unused
//  t5: $000000002D42AAC5 - Unused
//  t6: $FFFFFFFFC2C20384 - Unused
//  t7: $0000000056584D60 - Unused
//  s6: $0000000000000091 - Gets pushed to the stack
//  t9: $FFFFFFFFCDCE565F - Unused

//============================
// N64 NUS-CIC-6105 Boot Code
//============================

// bootMain

add t1,sp,zero // T1 = Stack Pointer ($FFFFFFFFA4001FF0)

// De-obfuscate RSP assembly code
// Stops when hitting instruction 'lui 11,$B000' (0x3C0BB000)
LAB_A4000044:
lw t0,$F010(t1) // T0 = SP IMEM WORD[$A4001000..] = IPL2 instruction (eg: $3C0DBFC0 'lui 13,$BFC0')
lw t2,$0044(t3) // T2 = SP DMEM WORD[$A4000084..] = Obfuscated RSP instruction (IPL3) (eg: $C0971C7C)
xor t2,t2,t0    // T2 ^= T0
sw t2,$F010(t1) // T0 = SP IMEM WORD[$A4001000..] = De-obfuscated RSP instruction (eg: $40112800 'mfc0 s1,SP_DMA_FULL_REG')
addi t3,t3,$0004 // T3 += 4
andi t0,t0,$0FFF // T0 &= $0FFF
bne t0,zero,LAB_A4000044 // if (t0 != 0) goto $044
addi t1,t1,$0004 // T1 += 4, increments the IPL2 instruction pointer

// Copy the rest
// routine: A4000064
lw t0,$0044(t3) // T0 = SP DMEM WORD[$A40000A4..] = IPL3 RSP instruction $40113000
lw t2,$0048(t3) // T2 = SP DMEM WORD[$A40000A8..] = IPL3 RSP instruction $0800046E
sw t0,$F010(t1) // SP IMEM WORD[$A4001020..] = $40113000
sw t2,$F014(t1) // SP IMEM WORD[$A4001024..] = $0800046E
bltz ra,LAB_A40000B8 // if (ra < 0) goto $0B8, it jumps because -1543498416 is less than 0
sw zero,$F018(t1) // SP IMEM WORD[$A4001028..] = 0 'nop'

nop
nop

// RSP assembly, partially obfuscated
// Copied to RSP IMEM by the LAB_A4000044 routine
insert "RspObfuscated.BIN"
mfc0 s1,SP_DMA_BUSY_REG   // RAW: $40113000
j $A00011B8  // Goto $1B8 // RAW: $0800046E

// Unknown CPU routine
// Related to debugging on the ultra64 dev board?
lui t3,$A4B0 // T3 = $A4B00000 (Unused memory section)
jr t3
add s7,s7,s3

LAB_A40000B8:
// Zero Co-Processor Exception & Timer Registers
mtc0 zero,Cause
mtc0 zero,Count
mtc0 zero,Compare

// go to A4000488 if RI Select is not zero
lui t0,RI_BASE // T0 = RI_BASE ($A4700000)
addiu t0,0 // T0 = RI_BASE ($A4700000)
lw t1,RI_SELECT(t0) // T1 = RI_SELECT WORD[$A470000C]
bnez t1,LAB_A4000488 // IF (RI_SELECT != 0) A4000410
nop // Delay Slot

//Ri select is 0

// Store S3..S7 Passed From PIF ROM To STACK
subiu sp,24 // Decrement STACK 6 WORDS
sw s3,$00(sp)
sw s4,$04(sp)
sw s5,$08(sp)
sw s6,$0C(sp)
sw s7,$10(sp)

lui t0,RI_BASE // T0 = RI_BASE ($A4700000)
addiu t0,0 // T0 = RI_BASE ($A4700000)
lui t2,$A3F8 // T2 = $A3F80000
lui t3,RDRAM_BASE // T3 = RDRAM_BASE ($A3F00000)
lui t4,MI_BASE // T4 = MI_BASE ($A4300000)
addiu t4,0 // T4 = MI_BASE ($A4300000)
ori t1,r0,$40 // T1 = $40
sw t1,RI_CONFIG(t0) // WORD[$A4700004] RI_CONFIG = $40

// Delay 24000 Cycles
addiu s1,r0,$1F40 // S1 = $1F40
LAB_A4000114:
  nop // Delay
  subi s1,1 // S1--
  bnez s1,LAB_A4000114 // IF (S1 != 0) LAB_A4000114
  nop // Delay Slot

// A4000124
sw r0,RI_CURRENT_LOAD(t0) // WORD[$A4700008] RI_CURRENT_LOAD = 0
ori t1,r0,$14 // T1 = $14
sw t1,RI_SELECT(t0) // WORD[$A470000C] RI_SELECT = $14
sw r0,RI_MODE(t0) // WORD[$A4700000] RI_MODE = $00

// Delay 12 Cycles
addiu s1,r0,4 // S1 = 4
LAB_A4000138:
  nop // Delay
  subi s1,1 // S1--
  bnez s1,LAB_A4000138 // IF (S1 != 0) LAB_A4000138
  nop // Delay Slot

ori t1,r0,$0E // T1 = $0E
sw t1,RI_MODE(t0) // WORD[$A4700000] RI_MODE = $0E (Stop T Active, Stop R Active, Operating Mode 2)

// Delay 64 Cycles
addiu s1,r0,$20 // S1 = $20
LAB_A4000154:
  subi s1,1 // S1--
  bnez s1,LAB_A4000154 // IF (S1 != 0) LAB_A4000154
  ori t1,r0,$010F // T1 = $010F (Delay Slot)

// A4000160
sw t1,MI_INIT_MODE(t4) // WORD[$A4300000] MI_INIT_MODE = $010F
lui t1,$1808 // T1 = $18080000
ori t1,$2838 // T1 = $18082838
sw t1,RDRAM_DELAY(t2) // WORD[$A3F80008] RDRAM_DELAY = $18082838
sw r0,RDRAM_REF_ROW(t2) // WORD[$A3F80014] RDRAM_REF_ROW = 0
lui t1,$8000 // T1 = $80000000
sw t1,RDRAM_DEVICE_ID(t2) // WORD[$A3F80004] RDRAM_DEVICE_ID = $80000000

or t5,r0,r0 // T5 = 0
or t6,r0,r0 // T6 = 0
lui t7,RDRAM_BASE // T7 = RDRAM_BASE ($A3F00000)
or t8,r0,r0 // T8 = 0
lui t9,RDRAM_BASE // T9 = RDRAM_BASE ($A3F00000)
lui s6,RDRAM // S6 = RDRAM $A0000000
or s7,r0,r0 // S7 = 0
lui a2,RDRAM_BASE // A2 = RDRAM_BASE ($A3F00000)
lui a3,RDRAM // A3 = RDRAM $A0000000
or s2,r0,r0 // S2 = 0
lui s4,RDRAM // S4 = RDRAM $A0000000

// FP = SP
subiu sp,72 // Decrement STACK 18 WORDS
or s8,sp,r0

lui s0,MI_BASE // S0 = MI_BASE ($A4300000)
lw s0,MI_VERSION(s0) // S0 = MI_VERSION WORD[$A4300004]
lui s1,$0101 // S1 = $01010000
addiu s1,$0101 // S1 = $01010101
bne s0,s1,LAB_A40001D8 // IF (MI_VERSION != $01010101) Version >= 2 RCP
nop // Delay Slot

  // ELSE Version 1 RCP
  addiu s0,r0,$0200 // S0 = $0200
  ori s1,t3,$4000 // S1 = $A3F04000
  b LAB_A40001E0 // GOTO $168
  nop // Delay Slot

  LAB_A40001D8: // Version >=2 RCP
    addiu s0,r0,$0400 // S0 = $0400
    ori s1,t3,$8000 // S1 = $A3F08000

LAB_A40001E0:
  sw t6,4(s1) // WORD[$A3F04004/$A3F08004 Depending On Version] = 0
  addiu s5,t7,RDRAM_MODE // S5 = RDRAM_MODE ($A3F0000C)
  jal LAB_A400087C // CALL($778)
  nop // Delay Slot
  beqz v0,LAB_A40002D4 // IF (CALL($778) V0 == 0) GOTO $25C
  nop // Delay Slot

  // ELSE (CALL($778) V0 != 0)
  sw v0,$00(sp) // STACK WORD[$00] = V0 (TMP1 = RET)
  addiu t1,r0,$2000 // T1 = $2000
  sw t1,MI_INIT_MODE(t4) // WORD[$A4300000] MI_INIT_MODE = $2000 (RDRAM REG MODE)
  lw t3,RDRAM_DEVICE_TYPE(t7) // T3 = RDRAM_DEVICE_TYPE WORD[$A3F00000]
  lui t0,$F0FF // T0 = $F0FF0000
  and t3,t0 // T3 = RDRAM_DEVICE_TYPE & $F0FF0000
  sw t3,$04(sp) // STACK WORD[$04] = T3 (TMP2 = T3)
  addi sp,8 // Increment STACK 2 WORDS

  addiu t1,r0,$1000 // T1 = $1000
  sw t1,MI_INIT_MODE(t4) // WORD[$A4300000] MI_INIT_MODE = $1000 (CLEAR RDRAM REG MODE)
  lui t0,$B019 // T0 = $B0190000
  bne t3,t0,LAB_A4000258 // IF (TMP2 != $B0190000) GOTO LAB_A4000258
  nop // Delay Slot

  // ELSE (TMP2 == $B0190000)
  lui t0,$0800 // T0 = $08000000
  add t8,t0 // T8 += $08000000
  add t9,s0 // T9 += S0*2 ($200/$400 Depending On Version)
  add t9,s0
  lui t0,$0020 // T0 = $00200000
  add s6,t0 // S6 = A0200000 (2MB RAM)
  add s4,t0 // S4 = A0200000 (2MB RAM)
  sll s2,1 // S2 <<= 1
  addi s2,1 // S2 = 1
  b LAB_A4000260 // GOTO $260
  nop // Delay Slot

  LAB_A4000258:
    lui t0,$0010 // T0 = $00100000
    add s4,t0 // S4 = A0100000 (1MB RAM)

// RDRAM CONFIG
LAB_A4000260:
  addiu t0,r0,$2000 // T0 = $2000
  sw t0,MI_INIT_MODE(t4) // WORD[$A4300000] MI_INIT_MODE = $2000 (RDRAM REG MODE)
  lw t1,RDRAM_DEVICE_MANUF(t7) // T1 = RDRAM_DEVICE_MANUF WORD[$A3F00024]
  lw k0,RDRAM_DEVICE_TYPE(t7) // K0 = RDRAM_DEVICE_TYPE WORD[$A3F00000]
  addiu t0,r0,$1000 // T0 = $1000
  sw t0,MI_INIT_MODE(t4) // WORD[$A4300000] MI_INIT_MODE = $1000 (CLEAR RDRAM REG MODE)
  andi t1,$FFFF // T1 = RDRAM_DEVICE_MANUF & $FFFF
  addiu t0,r0,$0500 // T0 = $0500
  bne t1,t0,LAB_A40002A8 // IF (T1 != $0500) GOTO $2A8
  nop // Delay Slot

  lui k1,$0100 // K1 = $01000000
  and k0,k1 // K0 &= $01000000
  bnez k0,LAB_A40002A8 // IF ((K0 & $01000000) != 0) GOTO $2A8
  nop // Delay Slot

  lui t0,$101C // T0 = $101C0000
  ori t0,$0A04 // T0 = $101C0A04
  sw t0,RDRAM_RAS_INTERVAL(t7) // WORD[$A3F00018] RDRAM_RAS_INTERVAL = $101C0A04
  b LAB_A40002B4 // GOTO $2B4

  // ELSE ((T1 == $0500) && (K0 & $01000000) == 0))
  LAB_A40002A8:
    lui t0,$080C // T0 = $080C0000 (Delay Slot)
    ori t0,$1204 // T0 = $080C1204
    sw t0,RDRAM_RAS_INTERVAL(t7) // WORD[$A3F00018] RDRAM_RAS_INTERVAL = $080C1204

LAB_A40002B4:
  lui t0,$0800 // T0 = $08000000
  add t6,t0 // T6 += $08000000
  add t7,s0 // T7 += S0*2 ($200/$400 Depending On Version)
  add t7,s0
  addiu t5,1 // T5++
  sltiu	t0,t5,8
  bnez t0,LAB_A40001E0 // IF (++T5 < 8) GOTO $1E0
  nop // Delay Slot

LAB_A40002D4:
  lui t0,$C400 // T0 = $C4000000
  sw t0,RDRAM_MODE(t2) // WORD[$A3F8000C] RDRAM_MODE = $C4000000
  lui t0,$8000 // T0 = $80000000
  sw t0,RDRAM_DEVICE_ID(t2) // WORD[$A3F80004] RDRAM_DEVICE_ID = $80000000

or sp,s8,r0 // SP = FP
or v1,r0,r0 // V1 = 0

LAB_A40002EC:
  lw t1,4(sp) // T1 = TMP2
  lui t0,$B009 // T0 = B0090000
  bne t1,t0,LAB_A4000350 // IF (TMP2 != $B0090000) GOTO $350
  nop // Delay Slot

  // ELSE (TMP2 == $B0090000)
  sw t8,4(s1) // WORD[$A3F04004/$A3F08004 Depending On Version] = $08000000
  addiu s5,t9,$C // S5 = T9 + $C
  lw a0,0(sp) // A0 = TMP1
  addi sp,8 // Increment STACK 2 WORDS
  addiu a1,r0,1 // A1 = 1
  jal LAB_A4000B44 // CALL($A40)(TMP1, 1)
  nop // Delay Slot

  lw t0,0(s6) // T0 = WORD[$A0200000]
  lui t0,$0008 // T0 = $00080000
  add t0,s6 // T0 = $A0280000
  lw t1,0(t0) // T1 = WORD[$A0280000]
  lw t0,0(s6) // T0 = WORD[$A0200000]
  lui t0,$0008 // T0 = $00080000
  add t0,s6 // T0 = $A0280000
  lw t1,0(t0) // T1 = WORD[$A0280000]
  lui t0,$0400 // T0 = $04000000
  add t6,t0 // T6 += $04000000
  add t9,s0 // T9 += S0
  lui t0,$0010 // T0 = $00100000
  add s6,t0 // S6 = $A0300000 (3MB RAM)
  b LAB_A40003D4 // GOTO $3D4

LAB_A4000350:
  sw s7,4(s1) // WORD[$A3F04004/$A3F08004 Depending On Version] = 0 (Delay Slot)
  addiu s5,a2,$0C // S5 = RDRAM_MODE ($A3F0000C)
  lw a0,0(sp) // A0 = TMP1
  addi sp,8 // Increment STACK 2 WORDS
  addiu	a1,r0,1 // A1 = 1
  jal LAB_A4000B44 // CALL($A40)(TMP1, 1)
  nop // Delay Slot

  lw t0,0(a3) // T0 = WORD[$A0000000]
  lui t0,$0008 // T0 = $00080000
  add t0,a3 // T0 = $A0080000
  lw t1,0(t0) // T1 = WORD[$A0080000]
  lui t0,$0010 // T0 = $00100000
  add t0,a3 // T0 = $A0010000
  lw t1,0(t0) // T1 = WORD[$A0010000]
  lui t0,$0018 // T0 = $00180000
  add t0,a3 // T0 = $A0180000
  lw t1,0(t0) // T1 = WORD[$A0180000]
  lw t0,0(a3) // T0 = WORD[$A0000000]
  lui t0,$0008 // T0 = $00080000
  add t0,a3 // T0 = $A0080000
  lw t1,0(t0) // T1 = WORD[$A0080000]
  lui t0,$0010 // T0 = $00100000
  add t0,a3 // T0 = $A0010000
  lw t1,0(t0) // T1 = WORD[$A0010000]
  lui t0,$0018 // T0 = $00180000
  add t0,a3 // T0 = $A0180000
  lw t1,0(t0) // T1 = WORD[$A0180000]
  lui t0,$0800 // T0 = $00800000
  add s7,t0 // S7 = $00800000
  add a2,s0 // A2 += S0*2 ($200/$400 Depending On Version)
  add a2,s0 // A2 = $A3F00400/$A3F00800 Depending On Version
  lui t0,$0020 // T0 = $00200000
  add a3,t0 // A3 = $A0200000 (2MB RAM)

LAB_A40003D4:
  addiu v1,1 // V1++
  slt t0,v1,t5
  bnez t0,LAB_A40002EC // IF (V1 < T5) GOTO $2EC
  nop // Delay Slot

  lui t2,RI_BASE // T2 = RI_BASE ($A4700000)
  sll s2,19 // S2 <<= 19
  lui t1,$0006 // T1 = $00060000
  ori t1,$3634 // T1 = $00063634
  or t1,s2 // T1 |= S2
  sw t1,RI_REFRESH(t2) // WORD[$A4700010] RI_REFRESH = T1
  lw t1,RI_REFRESH(t2) // T1 = RI_REFRESH WORD[$A4700010]

  lui t0,RDRAM // T0 = RDRAM ($A0000000)
  ori t0,$03F0 // T0 = $A00003F0
  lui t1,$0FFF // T1 = $0FFF0000
  ori t1,$FFFF // T1 = $0FFFFFFF
  and s6,t1 // S6 = $00300000
  sw s6,$00(t0) // WORD[$A0000300] = $00300000 (osMemSize)

  or sp,s8,r0 // SP = FP

  // Load S3..S7 From STACK
  addiu sp,72 // Increment STACK 18 WORDS
  lw s3,$00(sp)
  lw s4,$04(sp)
  lw s5,$08(sp)
  lw s6,$0C(sp)
  lw s7,$10(sp)
  addiu sp,24 // Increment STACK 6 WORDS

  // Store I-Cache Tag 0/0 For 16KB Of Main Memory In 32 Byte Chunks Starting At $80000000
  lui t0,$8000 // T0 = $80000000
  addiu t0,0 // T0 = $80000000
  addiu t1,t0,$4000 // T1 = $80004000
  subiu t1,32 // T1 -= 32
  mtc0 r0,TagLo
  mtc0 r0,TagHi
  LAB_A4000450:
    cache $08,0(t0) // CACHE 0(T0), I, Index Store Tag ($08)
    sltu at,t0,t1
    bnez at,LAB_A4000450 // IF (T0 < T1) GOTO $450
    addiu t0,32 // T0 += 32 (Delay Slot)

  // Store D-Cache Tag 0/0 For 8KB Of Main Memory In 16 Byte Chunks Starting At $80000000
  lui t0,$8000 // T0 = $80000000
  addiu t0,0 // T0 = $80000000
  addiu t1,t0,$2000 // T1 = $80002000
  subiu t1,16 // T1 -= 16
  LAB_A4000470:
    cache $09,0(t0) // CACHE 0(T0), D, Index Store Tag ($09)
    sltu at,t0,t1
    bnez at,LAB_A4000470 // IF (T0 < T1) GOTO $470
    addiu t0,16 // T0 += 16 (Delay Slot)
    b LAB_A40004D0 // GOTO $4D0
    nop // Delay Slot

// Store I-Cache Tag 0/0 For 16KB Of Main Memory In 32 Byte Chunks Starting At $80000000
LAB_A4000488:
  lui t0,$8000 // T0 = $80000000
  addiu t0,0 // T0 = $80000000
  addiu t1,t0,$4000 // T1 = $80004000
  subiu t1,32 // T1 -= 32
  mtc0 r0,TagLo
  mtc0 r0,TagHi
  LAB_A40004A0:
    cache $08,0(t0) // CACHE 0(T0), I, Index Store Tag ($08)
    sltu at,t0,t1
    bnez at,LAB_A40004A0 // IF (T0 < T1) GOTO $4A0
    addiu t0,32 // T0 += 32 (Delay Slot)

  // Store D-Cache Tag 0/0 For 8KB Of Main Memory In 16 Byte Chunks Starting At $80000000
  lui t0,$8000 // T0 = $80000000
  addiu t0,0 // T0 = $80000000
  addiu t1,t0,$2000 // T1 = $80002000
  subiu t1,16 // T1 -= 16
  LAB_A40004C0:
    cache $01,0(t0) // CACHE 0(T0), D, Index Writeback Invalidate ($01)
    sltu at,t0,t1
    bnez at,LAB_A40004C0 // IF (T0 < T1) GOTO $4C0
    addiu t0,16 // T0 += 16 (Delay Slot)

// Copy Routine At $554-$888 In Bootcode (Lockout Finale & Program Loader) To Uncached RAM, Address Zero, & Jump To It
LAB_A40004D0:
  addiu t2,zero,$00CE // T2 = $00CE
  lui at,SP_BASE      // AT = SP_BASE ($A4040000)
  sw t2,$0010(at)     // WORD[$A4040010] = $00CE
  lui t2,SP_MEM_BASE  // T2 = SP_MEM_BASE ($A4000000)
  addiu t2,0          // T2 = SP_MEM_BASE ($A4000000)
  lui t3,$FFF0        // T3 = $FFF00000
  lui t1,$0010        // T1 = $00100000
  and t2,t3           // T2 = SP_MEM_BASE ($A4000000)
  lui t0,SP_MEM_BASE  // T0 = SP_MEM_BASE ($A4000000)
  subiu t1,1          // T1 = $000FFFFF
  lui t3,SP_MEM_BASE  // T3 = SP_MEM_BASE ($A4000000)
  addiu t0,$0554      // T0 = $A4000554
  addiu t3,$0888      // T3 = $A4000888
  and t0,t1           // T0 = $00000554
  and t3,t1           // T3 = $00000774
  lui at,SP_PC_BASE   // AT = $A4080000
  lui t1,RDRAM        // T1 = $A0000000
  sw zero,$0000(at)   // WORD[$A4080000] = 0
  or t0,t2            // T0 = $A00004C0
  or t3,t2            // T3 = $A0000888
  addiu t1,t1,$0004   // T1 = $A0000004

  // Copy memory loop
  // T0 starts at address $A00004C0
  LAB_A4000524:
    lw t5,0(t0)    // T5 = WORD[$A00004C0..]
    addiu t0,4     // T0 += 4 (Increment Bootcode Pointer)
    sltu at,t0,t3  // AT = 1, if T0 is less than $A0000888, else AT = 0
    addiu t1,4     // T1 += 4 (Increment RDRAM Pointer)
    bnez at,LAB_A4000524 // Loop while AT does not equal 0
    sw t5,-4(t1)   // WORD[$A0000000..] = Bootcode Word T5 (Delay Slot)

  lui t4,$8000         // T4 = $80000000
  addiu t2,zero,$00AD  // T2 = $00AD
  lui at,SP_BASE       // AT = $A4040000 (SP_BASE)
  addiu t4,t4,$0004    // T4 = $80000004
  jr t4                // Jump to boot code
  sw t2,SP_STATUS(at)  // WORD[SP_STATUS] = $AD (Delay Slot) (Clear halt, Clear broke, Clear intr, Clear sstep, Clear intr on break)

// This Loader Is Copied To RDRAM Address Zero From $4C0..$774 In The 6105 Bootcode,
// & Executes From RDRAM To Load The 1st 1MB Of The Program, Verify Its integrity, & Execute It

// Read 3rd Word Of Cart Header, Which Is The Program Start Address In RAM
lui t3,CART_DOM1_ADDR2 // T3 = CART_DOM1_ADDR2 ($B0000000)
lw t1,8(t3) // T1 = Boot Address Offset WORD[$B0000008]
lui t2,$1FFF // T2 = $1FFF0000
ori t2,$FFFF // T2 = $1FFFFFFF
lui at,PI_BASE // AT = PI_BASE ($A4600000)
and t1,t2 // T1 = Boot Address Offset & $1FFFFFFF
sw t1,PI_DRAM_ADDR(at) // WORD[$A4600000] PI_DRAM_ADDR = T1

// Check PI Status IO Busy
lui t0,PI_BASE // T0 = PI_BASE ($A4600000)
LAB_A4000574:
  // WHILE ((*$A4600010 & 2)) Loop (Wait For PI No I/O Busy)
  lw t0,PI_STATUS(t0) // T0 = PI_STATUS WORD[$A4600010]
  andi t0,$02 // T0 &= Status IO Busy Bit
  bnezl t0,LAB_A4000574 // IF (T0 != 0) GOTO $574
  lui t0,PI_BASE // T0 = PI_BASE ($A4600000) (Delay Slot)

// DMA 1MB Of Program Code, From Cartridge ROM, To RDRAM, Starting At Offset $1000
// *$A4600004 = $10001000 (PI DMA Cart Address)
addiu t0,r0,$1000 // T0 = $1000
add t0,t3 // T0 = $B0001000
and t0,t2 // T0 = $10001000
lui at,PI_BASE // AT = PI_BASE ($A4600000)
sw t0,PI_CART_ADDR(at) // WORD[$A4600004] PI_CART_ADDR = $10001000
// *$A460000C = $000FFFFF (PI DMA Write Length 1MB)
lui t2,$0010 // T2 = $00100000
subiu t2,1 // T2 = $000FFFFF
lui at,PI_BASE // AT = PI_BASE ($A4600000)
sw t2,PI_WR_LEN(at) // WORD[$A460000C] PI_WR_LEN = $000FFFFF

LAB_A40005A8:
  // Wait 16 Cycles
  nop // Delay
  nop // Delay
  nop // Delay
  nop // Delay
  nop // Delay
  nop // Delay
  nop // Delay
  nop // Delay
  nop // Delay
  nop // Delay
  nop // Delay
  nop // Delay
  nop // Delay
  nop // Delay
  nop // Delay
  nop // Delay
  // While ((*$A4600010 & 1)) (Wait For PI No DMA Busy Status)
  lui t3,PI_BASE // T3 = PI_BASE ($A4600000)
  lw t3,PI_STATUS(t3) // T3 = PI_STATUS WORD[$A4600010]
  andi t3,1 // T3 &= Status DMA Busy Bit
  bnez t3,LAB_A40005A8 // IF (T3 != 0) GOTO $5A8
  nop // Delay Slot

// Starting At Program Start Address In RAM, Perform Checksum Seeded With A1=S6*$5D588B65
// Over 1st $100000 (1MB) Bytes Of Program (Checksum Routine Places Results In A3 & S0)

// Clear the RSP Semaphore
lui at,SP_BASE // AT = SP_BASE ($04040000)
sw zero,SP_SEMAPHORE(at)

// CRC Check
lui t3,CART_DOM1_ADDR2 // T3 = CART_DOM1_ADDR2 ($B0000000)
// A0 = 3rd Word Of Cart Header (Boot Address)
lw a0,8(t3) // A0 = Boot Address Offset WORD[$B0000008]
// A1 = S6 * $5D588B65
or a1,s6,r0 // A1 = S6
lui at,$5D58 // AT = $5D580000
ori at,$8B65 // AT = $5D588B65
multu a1,at // A1 * AT
// RA To Stack, S0 To Stack
subiu sp,32 // Decrement Stack 8 WORDS
sw ra,$1C(sp) // STACK WORD[$1C] = RA
sw s0,$14(sp) // STACK WORD[$14] = S0
lui s6,RDRAM // S6 = RDRAM ($00000000)
addiu s6,s6,$0200 // S6 = $00000200
// RA = $00100000 (Length To Checksum Over, Starting At Cart Header)
lui ra,$0010 // RA = $00100000
or v1,r0,r0 // V1 = 0
or t0,r0,r0 // T0 = 0
or t1,a0,r0 // T1 = A0
mflo v0 // V0 = A1 * AT
addiu v0,1 // V0++
or a3,v0,r0 // A3 = V0
or t2,v0,r0 // T2 = V0
or t3,v0,r0 // T3 = V0
or s0,v0,r0 // S0 = V0
or a2,v0,r0 // A2 = V0
or t4,v0,r0 // T4 = V0
addiu t5,r0,32 // T5 = 32

// Start Checksum Loop
LAB_A4000664:
  // V0 = *T1 (Next Word In Program Code To Checksum)
  lw v0,0(t1) // V0 = WORD[Boot Address Offset]
  addu v1,a3,v0 // V1 = A3 + V0
  sltu at,v1,a3
  beqz at,LAB_A400067C // IF (V1 < A3) GOTO $67C
  or a1,v1,r0 // A1 = V1 (Delay Slot)
  addiu t2,1 // T2++

  LAB_A400067C:
    andi v1,v0,$1F // V1 = V0 & $1F
    subu t7,t5,v1 // T7 = T5 - V1
    srlv t8,v0,t7 // T8 = V0 >> T7
    sllv t6,v0,v1 // T6 = V0 << V1
    or a0,t6,t8 // A0 = T6 | T8
    sltu at,a2,v0
    or a3,a1,r0 // A3 = A1
    xor t3,v0 // T3 ^= V0
    beqz at,LAB_A40006B0 // IF (A2 < V0) GOTO $6B0
    addu s0,a0 // S0 += A0 (Delay Slot)
    xor t9,a3,v0 // T9 = A3 ^ V0
    b LAB_A40006B4 // GOTO $6B4
    xor a2,t9,a2 // A2 = T9 ^ A2 (Delay Slot)

    LAB_A40006B0:
      xor a2,a0 // A2 ^= A0

  LAB_A40006B4:
    lw t7,$0000(s6)  // T7 = WORD[$A0000200]
    addiu t0,4       // T0 += 4
    addiu s6,4       // S6 += 4
    xor t7,v0,t7     // T7 = V0 ^ T7
    addu t4,t7,t4    // T4 = T7 + T4
    lui t7,RDRAM     // T7 = RDRAM ($00000000)
    ori t7,$02FF     // T7 = $A00002FF
    addiu t1,4       // T1 += 4
    bne t0,ra,LAB_A4000664 // IF (T0 != RA) GOTO $664
    and s6,t7        // S6 &= T7

xor t6,a3,t2 // T6 = A3 ^ T2
xor a3,t6,t3 // A3 = T6 ^ T3

// Unmask All MI Interrupts & Clear Each One Individually
// Differences from 6102: Section to here from around A40006BC to here
lui t3,$00AA     // T3 = $00AA0000
ori t3,t3,$AAAE  // T3 = $00AAAAAE
lui at,SP_BASE   // AT = SP_BASE ($04040000)
sw t3,SP_STATUS(at) // WORD[04040010] = $00AAAAAE (Set Halt & Clear Broke & Clear Intr & Clear SStep & Clear Intr on Break & Clear Signal0 & Clear Signal1 & Clear Signal2 & Clear Signal3 & Clear Signal4 & Clear Signal5 & Clear Signal6 & Clear Signal7)
lui at,MI_BASE // AT = MI_BASE ($04300000)
addiu t0,zero,$0555 // T0 = $0555
sw t0,MI_INTR_MASK(at) // Clear all RCP interrupts
lui at,SI_BASE // AT = SI_BASE ($A4800000)
sw zero,SI_STATUS(at) // Clear Serial interface status registers
lui at,AI_BASE
sw zero,AI_STATUS(at) // Clear Audio interface status registers
lui at,MI_BASE // AT = MI_BASE
addiu t1,zero,$0800  // T1 = $0800
sw t1,MI_INIT_MODE(at)  // Clear DP interrupt
addiu t1,zero,$0002 // T1 = $0802
lui at,PI_BASE // AT = PI_BASE
sw t1,PI_STATUS(at) // Clear interrupt
lui t0,RDRAM // T0 = RDRAM
ori t0,$0300 // T0 = RDRAM[$0300]
xor t8,s0,a2 // T8 = S0 ^ A2
addiu t1,zero,$17D9 // T1 = $17D9
xor s0,t8,t4 // S0 = T8 ^ T4
sw t1,$0010(t0) // WORD[$A000310] = $17D9
sw s4,$0000(t0) // WORD[$A000300] = S4
sw s3,$0004(t0) // WORD[$A000304] = S3
sw s5,$000C(t0) // WORD[$A00030C] = S5
beq s3,zero,LAB_A4000760 // GOTO $760 if S3 == 0
sw s7,$0014(t0) // WORD[$A000314] = S7

// Disk Drive
lui t1,CART_DOM1_ADDR1 // T1 = CART_DOM1_ADDR1 ($A6000000)
b LAB_A4000768 // GOTO $768
addiu t1,t1,$0000 // T1 += 0 (64-bit sign extend)

// Cartridge
LAB_A4000760:
lui t1,CART_DOM1_ADDR2 // T1 = CART_DOM1_ADDR2 ($B0000000)
addiu t1,t1,$0000 // T1 += 0 (64-bit sign extend)

LAB_A4000768:
sw t1,$0008(t0) // WORD[$A000308] = address of either DD or cart
lw t1,$00F0(t0) // T1 = WORD[$A0003F0]
lui t3,CART_DOM1_ADDR2 // T3 = CART_DOM1_ADDR2 ($B0000000)
sw t1,$0018(t0) // WORD[$A000318] = T1
lw t0,$0010(t3) // T0 = WORD[$B000310]

// IF (A3 != To The 1st Checksum Word In Cart Header)
// OR IF (S0 != To 2nd Checksum Word In Cart Header) Loop Forever (Halt)

bne a3,t0,LAB_A4000798  // IF (A3 != COMPLEMENT CHECK) GOTO $798 (COMPLEMENT CHECK FAILED)
nop

lw t0,$0014(t3) // T0 = CHECKSUM WORD[$B0000014]
bne s0,t0,LAB_A4000798 // IF (S0 != CHECKSUM) GOTO $798 (CHECKSUM FAILED)
nop // Delay Slot

// ELSE (COMPLEMENT CHECK/CHECKSUM PASSED)
  bgezal zero,LAB_A40007A0 // GOTO $690
  nop

// Infinite Loop
// CHECKSUM DID NOT PASS
LAB_A4000798:
  bgezal zero,LAB_A4000798
  nop

// OS Setup
LAB_A40007A0:
  lui t0,SP_MEM_BASE // T0 = SP_MEM_BASE ($A4000000)
  addiu t0,$0000 // T0 += 0 (64-bit sign extend)
  lw s0,$0014(sp) // S0 = STACK WORD[$14] (TMP1)
  lw ra,$001C(sp) // RA = STACK WORD[$1C]
  addiu sp,32 // Increment STACK 8 WORDS (Delay Slot)
  addi t1,t0,$2000 // T1 = T0 + $2000

  // Differences from 6102 here:
  // Removed code that checks if the RSP needs to be halted
  // Removed clear RSP memory (they )

// While t0 is != t1 ($A4002000)
LAB_A40007B8:
  addiu t0,$0004  //T0
  bne t0,t1,LAB_A40007B8 // GOTO $7B8 if T0 != T1
  sw t1,-4(t0) // WORD[$A4000000..A4002000] = $A4002000
  // For 6102: they write 0 instead

// Jump To Program Start Address In RAM (From Cart Header)
lui t3,CART_DOM1_ADDR2 // T3 = CART_DOM1_ADDR2 ($B0000000)
lw t1,8(t3) // T1 = Boot Address Offset WORD[$B0000008]
jr t1 // GOTO Boot Address Offset
nop // Delay Slot

// RSP assembly, starts at RSP IMEM 0x1BC
// -----------------
arch n64.rsp
mfc0 t0,SP_SEMAPHORE_REG // T0 = Semaphore
mfc0 t3,SP_DRAM_ADDR_REG // T3 = RSP DMA RDRAM Address
lqv v12[e0],$0000(r0) // V12 = VECTOR $0000
lw a0,$0040(r0) //  A0 = WORD[$04]
nop
nop

// Clear RSP DMA registers
mtc0 r0,SP_MEM_ADDR_REG // Clear RSP DMA SP Address
xori v1,r0,$0180 // V1 = $180
mtc0 v1,SP_DRAM_ADDR_REG // RSP SMA RDRAM Address = $180
mtc0 r0,SP_RD_LEN_REG  // Clear DMA Read Length

// Wait for CPU signal, timeout after 2097152 cycles
lui a1,$0020 // A1 = $00200000
LAB_A4000800:
  bltz a1,LAB_A4000870 // If (A1 < 0) goto $870
  mfc0 v1,SP_SEMAPHORE_REG // Read the semaphore
  bne v1,r0,LAB_A4000800 // if (V1 != 0) goto $800
  addi a1,a1,$FFFF // A1--

// Perform a RDRAM to SP DMA operation
lw a2,$0000(r0) // A2 = WORD[$00000000]
mtc0 r0,SP_MEM_ADDR_REG // RSP DMA SP Address = 0
xori v1,r0,$0400 // V1 = $400
mtc0 v1,SP_DRAM_ADDR_REG // RSP DMA RDRAM Address = $400
xori v1,r0,$0FFF // V1 = $FFF
mtc0 v1,SP_RD_LEN_REG // RSP DMA Read Length = $FFF

// Wait for RSP DMA to complete
LAB_A4000828:
  mfc0 v1,SP_DMA_BUSY_REG // V1 = RSP DMA BUSY flag
  bne v1,zero,LAB_A4000828 // if RSP DMA is busy goto $828
  xori v1,zero,$0FF0 // V1 = $FF0

vsub v13,v13,v13[e0] // V13 -= V13

LAB_A4000838:
  lqv v14[e0],$00(v1) // V14 = VECTOR $FF0
  addi v1,v1,$FFF0 // V1 += $FFF0
  bgez v1,LAB_A4000838 // if (V1 >= 0) goto $838
  vaddc v13,v13,v14[e0] // V13 += V14

// Start RSP -> RDRAM DMA operation
xori v1,r0,$B120 // V1 = $B120
mtc0 v1,SP_MEM_ADDR_REG // RSP DMA SP Address = $B120
lui v1,$B12F // V1 = $B12F0000
xori v1,v1,$B1F0 // V1 = $B12FB1F0
mtc0 v1,SP_DRAM_ADDR_REG // RSP DMA RDRAM Address = $B12FB1F0
lui v1,$FE81 // V1 = $FE810000
xori v1,v1,$7000 // V1 = $FE817000
mtc0 v1,SP_WR_LEN_REG // RSP DMA Write Length = $FE817000

xori v1,r0,$0240 // V1 = $240
mtc0 v1,DPC_STATUS_REG // DPC Status = Clear TMEM counter, Clear Clock Counter

LAB_A4000870:
break $00000000 // Break and halt the RSP

arch n64.cpu
// -----------------

nop
nop

// Save Registers To STACK
LAB_A400087C:
  subiu sp,160 // Decrement STACK 40 WORDS
  sw s0,$40(sp) // STACK WORD[$40] = S0
  sw s1,$44(sp) // STACK WORD[$44] = S1
  or s1,r0,r0 // S1 = 0
  or s0,r0,r0 // S0 = 0
  sw v0,$00(sp) // STACK WORD[$00] = V0
  sw v1,$04(sp) // STACK WORD[$04] = V1
  sw a0,$08(sp) // STACK WORD[$08] = A0
  sw a1,$0C(sp) // STACK WORD[$0C] = A1
  sw a2,$10(sp) // STACK WORD[$10] = A2
  sw a3,$14(sp) // STACK WORD[$14] = A3
  sw t0,$18(sp) // STACK WORD[$18] = T0
  sw t1,$1C(sp) // STACK WORD[$1C] = T1
  sw t2,$20(sp) // STACK WORD[$20] = T2
  sw t3,$24(sp) // STACK WORD[$24] = T3
  sw t4,$28(sp) // STACK WORD[$28] = T4
  sw t5,$2C(sp) // STACK WORD[$2C] = T5
  sw t6,$30(sp) // STACK WORD[$30] = T6
  sw t7,$34(sp) // STACK WORD[$34] = T7
  sw t8,$38(sp) // STACK WORD[$38] = T8
  sw t9,$3C(sp) // STACK WORD[$3C] = T9
  sw s2,$48(sp) // STACK WORD[$48] = S2
  sw s3,$4C(sp) // STACK WORD[$4C] = S3
  sw s4,$50(sp) // STACK WORD[$50] = S4
  sw s5,$54(sp) // STACK WORD[$54] = S5
  sw s6,$58(sp) // STACK WORD[$58] = S6
  sw s7,$5C(sp) // STACK WORD[$5C] = S7
  sw s8,$60(sp) // STACK WORD[$60] = S8
  sw ra,$64(sp) // STACK WORD[$64] = RA

// Context restore
LAB_A40008F0:
  jal LAB_A4000984 // CALL($984)
  nop // Delay Slot
  addiu s0,1 // S0++
  slti t1,s0,4
  bnez t1,LAB_A40008F0 // IF (S0 < 4) GOTO $8F0
  addu s1,v0 // S1 += V0 (Delay Slot)

  srl a0,s1,2 // A0 = S1 >> 2
  jal LAB_A4000B44 // CALL($B44)
  addiu a1,r0,1 // A1 = 1 (Delay Slot)

// Load Registers From STACK
lw ra,$64(sp) // RA = STACK WORD[$64]
srl v0,s1,2 // V0 = S1 >> 2
lw s1,$44(sp) // S1 = STACK WORD[$44]
lw v1,$04(sp) // V1 = STACK WORD[$04]
lw a0,$08(sp) // A0 = STACK WORD[$08]
lw a1,$0C(sp) // A1 = STACK WORD[$0C]
lw a2,$10(sp) // A2 = STACK WORD[$10]
lw a3,$14(sp) // A3 = STACK WORD[$14]
lw t0,$18(sp) // T0 = STACK WORD[$18]
lw t1,$1C(sp) // T1 = STACK WORD[$1C]
lw t2,$20(sp) // T2 = STACK WORD[$20]
lw t3,$24(sp) // T3 = STACK WORD[$24]
lw t4,$28(sp) // T4 = STACK WORD[$28]
lw t5,$2C(sp) // T5 = STACK WORD[$2C]
lw t6,$30(sp) // T6 = STACK WORD[$30]
lw t7,$34(sp) // T7 = STACK WORD[$34]
lw t8,$38(sp) // T8 = STACK WORD[$38]
lw t9,$3C(sp) // T9 = STACK WORD[$3C]
lw s0,$40(sp) // S0 = STACK WORD[$40]
lw s2,$48(sp) // S2 = STACK WORD[$48]
lw s3,$4C(sp) // S3 = STACK WORD[$4C]
lw s4,$50(sp) // S4 = STACK WORD[$50]
lw s5,$54(sp) // S5 = STACK WORD[$54]
lw s6,$58(sp) // S6 = STACK WORD[$58]
lw s7,$5C(sp) // S7 = STACK WORD[$5C]
lw s8,$60(sp) // S8 = STACK WORD[$60]
jr ra // GOTO RA
addiu sp,160 // Increment STACK 40 WORDS

LAB_A4000984:
  subiu sp,32 // Decrement STACK 8 WORDS
  sw ra,$1C(sp) // STACK WORD[$1C] = RA
  or t1,r0,r0 // T1 = 0
  or t3,r0,r0 // T3 = 0
  or t4,r0,r0 // T4 = 0

  LAB_A4000998:
    slti k0,t4,64 // FOR (T4 = 0; T4 < 64;)
    beqzl k0,LAB_A4000A00 // IF (K0 == 0) GOTO $A00
    or v0,r0,r0 // V0 = 0 (Delay Slot)

    jal LAB_A4000A10 // CALL($A10)(S4)
    or a0,t4,r0 // A0 = T4 (Delay Slot)

    blezl v0,LAB_A40009D0 // IF (V0 <= 0) GOTO $9D0
    slti k0,t1,$50 // Delay Slot
    subu k0,v0,t1 // K0 = V0 - T1
    multu k0,t4 // K0 * T4
    or t1,v0,r0 // T1 = V0
    mflo k0 // K0 = K0 * T4
    addu t3,k0 // T3 += K0
    nop // Delay Slot

    slti k0,t1,$0050

    LAB_A40009D0:
      bnez k0,LAB_A4000998 // IF (K0 != 0) GOTO $994
      addiu t4,1 // T4++ (Delay Slot)

sll a0,t3,2 // A0 = T3 << 2
subu a0,t3 // A0 -= T3
sll a0,2 // A0 <<= 2
subu a0,t3 // A0 -= T3
sll a0,1 // A0 <<= 1
jal LAB_A4000A84 // CALL($A84)(A0, A1, S5)
subiu a0,880 // A0 -= 880

b LAB_A4000A04 // GOTO $A04
lw ra,$1C(sp) // RA = STACK WORD[$1C] (Delay Slot)

or v0,r0,r0 // V0 = 0
LAB_A4000A00:
  lw ra,$1C(sp) // RA = STACK WORD[$1C]

LAB_A4000A04:
  addiu sp,32 // Increment STACK 8 WORDS
  jr ra // GOTO RA
  nop // Delay Slot

LAB_A4000A10:
  subiu sp,40 // Decrement STACK 10 WORDS
  sw ra,$1C(sp) // STACK WORD[$1C] = RA
  or v0,r0,r0 // V0 = 0
  jal LAB_A4000B44 // CALL($B44)(A0, A1, S5)
  addiu a1,r0,2 // A1 = 2 (Delay Slot)

or s8,r0,r0 // S8 = 0
subiu k0,r0,1 // K0 = $FFFFFFFF
LAB_A4000A2C:
  sw k0,4(s4) // WORD[S4 + 4] = K0 ($FFFFFFFF)
  lw v1,4(s4) // V1 = WORD[S4 + 4] ($FFFFFFFF)
  sw k0,0(s4) // WORD[S4 + 0] = K0
  sw k0,0(s4) // WORD[S4 + 0] = K0
  or gp,r0,r0 // GP = 0
  srl v1,16 // V1 >>= 16 ($0000FFFF)

  LAB_A4000A44:
    andi k0,v1,1 // K0 = V1 & 1
    beqzl k0,LAB_A4000A58 // IF (K0 == 0) GOTO $A58
    addiu gp,1 // GP++ (Delay Slot)

    addiu v0,1 // V0++
    addiu gp,1 // GP++

    LAB_A4000A58:
      slti k0,gp,8 // WHILE ((V1 & 1) && GP++ < 8, V1 >>= 1)
      bnez k0,LAB_A4000A44 // IF (K0 != 0) GOTO $A44
      srl v1,1 // V1 >>= 1 (Delay Slot)

    addiu s8,1 // FP++
    slti k0,s8,10 // WHILE (FP < 10)
    bnezl k0,LAB_A4000A2C // IF (K0 != 0) GOTO $A2C
    subiu k0,r0,1 // K0 = $FFFFFFFF (Delay Slot)

lw ra,$1C(sp) // RA = STACK WORD[$1C]
addiu sp,40 // Increment STACK 10 WORDS
jr ra // GOTO RA
nop // Delay Slot

LAB_A4000A84:
  subiu sp,40 // Decrement STACK 10 WORDS
  sw ra,$1C(sp) // STACK WORD[$1C] = RA
  sw a0,$20(sp) // STACK WORD[$20] = A0
  sb r0,$27(sp) // STACK BYTE[$27] = 0
  or t0,r0,r0 // T0 = 0
  or t2,r0,r0 // T2 = 0
  ori t5,r0,$C800 // T5 = $C800
  or t6,r0,r0 // T6 = 0
  slti k0,t6,64 // WHILE (T6 < 64)

  LAB_A4000AA8:
    bnezl k0,LAB_A4000ABC // IF (K0 != 0) GOTO $ABC
    or a0,t6,r0 // A0 = T6 (Delay Slot)

    b LAB_A4000B34 // GOTO $B34
    or v0,r0,r0 // V0 = 0 (Delay Slot)

    or a0,t6,r0 // A0 = T6
    LAB_A4000ABC:
      jal LAB_A4000B44 // CALL($B44)

      addiu a1,r0,1 // A1 = 1
      jal LAB_A4000BD4 // CALL($BD4)
      addiu a0,sp,$27 // A0 = SP + $27 (Delay Slot)

      jal LAB_A4000BD4 // CALL($BD4)
      addiu a0,sp,$27 // A0 = SP + $27 (Delay Slot)

    lbu k0,$27(sp) // K0 = STACK BYTE[$27]
    addiu k1,r0,$0320 // K1 = $0320
    lw a0,$20(sp) // A0 = STACK WORD[$20]
    multu k0,k1 // K0 * K1
    mflo t0 // T0 = K0 * K1
    subu k0,t0,a0 // K0 = T0 + A0
    bgezl k0,LAB_A4000AFC // IF (K0 >= 0) GOTO $AFC
    slt k1,k0,t5 // WHILE (K0 < T5) (Delay Slot)

    subu k0,a0,t0 // K0 = A0 - T0
    slt k1,k0,t5 // WHILE (K0 < T5)

    LAB_A4000AFC:
      beqzl k1,LAB_A4000B10 // IF (K1 == 0) GOTO $B10
      lw a0,$20(sp) // A0 = STACK WORD[$20] (Delay Slot)

      or t5,k0,r0 // T5 = K0
      or t2,t6,r0 // T2 = T6
      lw a0,$20(sp) // A0 = STACK WORD[$20]

      LAB_A4000B10:
        slt k1,t0,a0 // WHILE (T0 < A0)
        beqzl k1,LAB_A4000B30 // IF (K1 == 0) GOTO $A2C
        addu v0,t2,t6 // V0 = T2 + T6 (Delay Slot)

    addiu t6,1 // T6++
    slti k1,t6,$41 // WHILE (T6 < $41)
    bnezl k1,LAB_A4000AA8
    slti k0,t6,$40 // WHILE (T6 < $40) (Delay Slot)

  addu v0,t2,t6 // V0 = T2 + T6
LAB_A4000B30:
  srl v0,1 // V0 >>= 1

LAB_A4000B34:
  lw ra,$1C(sp) // RA = STACK WORD[$1C]
  addiu sp,40 // Increment STACK 10 WORDS
  jr ra // GOTO RA
  nop // Delay Slot

LAB_A4000B44:
  subiu	sp,40 // Decrement STACK 10 WORDS
  andi a0,$FF // A0 &= $FF
  addiu k1,r0,1 // K1 = 1
  xori a0,$3F // A0 ^= $3F
  sw ra,$1C(sp) // STACK WORD[$1C] = RA
  bne a1,k1,LAB_A4000B68 // IF (A1 != 1) GOTO $B68
  lui t7,$4600 // T7 = $46000000 (Delay Slot)

  lui k0,$8000 // K0 = $80000000
  or t7,k0 // T7 = $C6000000
LAB_A4000B68:
  // T7 |= (A0 & 1) << 6
  andi k0,a0,1 // K0 = A0 & 1
  sll k0,6 // K0 <<= 6
  or t7,k0 // T7 |= K0
  // T7 |= (A0 & 2) << 13
  andi k0,a0,2 // K0 = A0 & 2
  sll k0,13 // K0 <<= 13
  or t7,k0 // T7 |= K0
  // T7 |= (A0 & 4) << 20
  andi k0,a0,4 // K0 = A0 & 4
  sll k0,20 // K0 <<= 20
  or t7,k0 // T7 |= K0
  // T7 |= (A0 & 8) << 4
  andi k0,a0,8 // K0 = A0 & 8
  sll k0,4 // K0 <<= 4
  or t7,k0 // T7 |= K0
  // T7 |= (A0 & $10) << 11
  andi k0,a0,$10 // K0 = A0 & $10
  sll k0,11 // K0 <<= 11
  or t7,k0 // T7 |= K0
  // T7 |= (A0 & $20) << 18
  andi k0,a0,$20 // K0 = A0 & $20
  sll k0,18 // K0 <<= 18
  or t7,k0 // T7 |= K0
  addiu k1,r0,1 // K1 = 1
  bne a1,k1,LAB_A4000BC4 // IF (A1 != 1) GOTO $BC4
  sw t7,0(s5) // WORD[S5] = T7 (Delay Slot)


lui k0,MI_BASE // K0 = MI_BASE ($A4300000)
sw r0,MI_INIT_MODE(k0) // WORD[$A4300000] MI_INIT_MODE = 0

LAB_A4000BC4:
  lw ra,$1C(sp) // RA = STACK WORD[$1C]
  addiu sp,40 // Increment STACK 10 WORDS
  jr ra // GOTO RA
  nop // Delay Slot

LAB_A4000BD4:
  subiu sp,40 // Decrement STACK 10 WORDS
  sw ra,$1C(sp) // STACK WORD[$1C] = RA
  addiu k0,r0,$2000 // K0 = $2000
  lui k1,MI_BASE // K1 = MI_BASE ($A4300000)
  sw k0,MI_INIT_MODE(k1) // WORD[$A4300000] MI_INIT_MODE = $2000 (MI Set RDRAM)
  or s8,r0,r0 // S8 = 0
  lw s8,0(s5) // S8 = WORD[S5]
  addiu k0,r0,$1000 // K0 = $1000
  sw k0,MI_INIT_MODE(k1) // WORD[$A4300000] MI_INIT_MODE = $1000 (MI Clear RDRAM)
  // K0 = (*S5 & $40) >> 6
  addiu k1,r0,$40 // K1 = $40
  and k1,s8 // K1 &= S8
  srl k1,6 // K1 >>= 6
  // K0 |= (*S5 & $4000) >> 13
  or k0,r0,r0 // K0 = 0
  or k0,k1 // K0 |= K1
  addiu k1,r0,$4000 // K1 = $4000
  and k1,s8 // K1 &= S8
  srl k1,13 // K1 >>= 13
  // K0 |= (*S5 & $00400000) >> 20
  or k0,k1 // K0 |= K1
  lui k1,$0040 // K1 = $00400000
  and k1,s8 // K1 &= S8
  srl k1,20 // K1 >>= 20
  or k0,k1 // K0 |= K1
  // K0 |= (*S5 & $80) >> 4
  addiu k1,r0,$80 // K1 = $80
  and k1,s8 // K1 &= S8
  srl k1,4 // K1 >>= 4
  or k0,k1 // K0 |= K1
  // K0 |= (*S5 & $8000) >> 11
  ori k1,r0,$8000 // K1 = $8000
  and k1,s8 // K1 &= S8
  srl k1,11 // K1 >>= 11
  or k0,k1 // K0 |= K1
  // K0 |= (*S5 & $00800000) >> 18
  lui k1,$0080 // K1 = $00800000
  and k1,s8 // K1 &= S8
  srl k1,18 // K1 >>= 18
  or k0,k1 // K0 |= K1
  // MSB(*A0) = K0 & $FF
  sb k0,0(a0) // BYTE[A0] = K0
  lw ra,$1C(sp) // RA = STACK WORD[$1C]
  addiu sp,40 // Increment STACK 10 WORDS
  jr ra // GOTO RA
  nop // Delay Slot

// RSP Assembly Code
// ------------------------------
arch n64.rsp

// Wait for RSP DMA completion
LAB_A4000C70:
  mfc0 gp,SP_DMA_BUSY_REG
  bne gp,zero,LAB_A4000C70
  xori at,zero,$B120 // AT = $B120

// Read RDP clock, perform RSP DMA SP->RDRAM operation
mtc0 at,SP_MEM_ADDR_REG // RSP DMA SP Address = $B120
mfc0 t0,SP_SEMAPHORE_REG // T0 = semaphore
mfc0 t3,SP_DRAM_ADDR_REG // T3  RSP DMA RDRAM Address
mfc0 t2,DPC_CLOCK_REG // T2 = RDP clock
lw a0,$0040(zero) // A0 = WORD[$40]
lui s8,$B12F // S8 = $B12F0000
xori s8,s8,$B1F0 // S8 = $B12FB1F0
mtc0 s8,SP_DRAM_ADDR_REG // RSP DMA RDRAM Address = $B12FB1F0
lui v1,$FE81 // V1 = $FE810000
xori v1,v1,$7000 // V1 = $FE817000
mtc0 v1,SP_WR_LEN_REG // RSP DMA Write Length = $FE817000

xori t1,zero,$0240 // T1 = $240
mtc0 t1,DPC_STATUS_REG // DPC Status = Clear TMEM counter, Clear Clock Counter
lui a1,$7FFF // A1 = $7FFF0000
ori a1,a1,$0000 // A1 = $7FFF0000

bltz a1,LAB_A4000CC8 // if (A1 < 0) goto $CCB
mfc0 a2,SP_SEMAPHORE_REG // A2 = semaphore

beq a2,zero,LAB_A4000CC8 // if (A2 == 0) goto $CCB
addi a1,a1,$FFFF // A1--

LAB_A4000CC8:
  break $00000000 // Break and halt the RSP

arch n64.cpu
// ------------------------------

nop
nop
nop
nop
nop
nop
nop
nop
nop

// Looks like encrypted data
// A4000CF0 ... A4000FFC
insert "data.bin"