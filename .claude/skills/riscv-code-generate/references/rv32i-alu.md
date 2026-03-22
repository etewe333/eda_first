# RV32I ALU 指令集规范

## 概述

RISC-V RV32I 中寄存器为32位，基础整数指令集包含 47 条指令，其中 ALU 相关指令如下：

## ALU 操作指令

### 1. ADD / ADDI (加法)

```
ADD rd, rs1, rs2   # rd = rs1 + rs2
ADDI rd, rs1, imm  # rd = rs1 + imm
```

- ** funct3 **: 000
- ** 说明 **: 两个寄存器值相加，结果存入 rd
- ** 溢出处理 **: 模 2^32，溢出时截断

### 2. SUB (减法)

```
SUB rd, rs1, rs2   # rd = rs1 - rs2
```

- ** funct3 **: 000 (与 ADD 相同，通过 funct7=0100000 区分)
- ** 说明 **: rs1 减去 rs2，结果存入 rd
- ** 溢出处理 **: 模 2^32，溢出时截断

### 3. SLT / SLTI (有符号小于)

```
SLT rd, rs1, rs2   # rd = (rs1 < rs2) ? 1 : 0  (有符号比较)
SLTI rd, rs1, imm  # rd = (rs1 < imm) ? 1 : 0   (有符号比较)
```

- ** funct3 **: 010
- ** 说明 **: 将 rs1 和 rs2 作为有符号数比较

### 4. SLTU / SLTIU (无符号小于)

```
SLTU rd, rs1, rs2  # rd = (rs1 < rs2) ? 1 : 0  (无符号比较)
SLTIU rd, rs1, imm # rd = (rs1 < imm) ? 1 : 0   (无符号比较)
```

- ** funct3 **: 011
- ** 说明 **: 将 rs1 和 rs2 作为无符号数比较
- ** 重要 **: 立即数 imm 被视为无符号数

### 5. AND / ANDI (与)

```
AND rd, rs1, rs2   # rd = rs1 & rs2
ANDI rd, rs1, imm  # rd = rs1 & imm
```

- ** funct3 **: 111
- ** 说明 **: 位与操作

### 6. OR / ORI (或)

```
OR rd, rs1, rs2    # rd = rs1 | rs2
ORI rd, rs1, imm   # rd = rs1 | imm
```

- ** funct3 **: 110
- ** 说明 **: 位或操作

### 7. XOR / XORI (异或)

```
XOR rd, rs1, rs2   # rd = rs1 ^ rs2
XORI rd, rs1, imm  # rd = rs1 ^ imm
```

- ** funct3 **: 100
- ** 说明 **: 位异或操作

### 8. SLL / SLLI (逻辑左移)

```
SLL rd, rs1, rs2   # rd = rs1 << rs2[4:0]
SLLI rd, rs1, shamt # rd = rs1 << shamt
```

- ** funct3 **: 001
- ** 说明 **: 逻辑左移，低位补 0

### 9. SRL / SRLI (逻辑右移)

```
SRL rd, rs1, rs2   # rd = rs1 >> rs2[4:0]
SRLI rd, rs1, shamt # rd = rs1 >> shamt
```

- ** funct3 **: 101
- ** 说明 **: 逻辑右移，高位补 0

### 10. SRA / SRAI (算术右移)

```
SRA rd, rs1, rs2   # rd = rs1 >>> rs2[4:0]
SRAI rd, rs1, shamt # rd = rs1 >>> shamt
```

- ** funct3 **: 101 (与 SRL 相同，通过 funct7=0100000 区分)
- ** 说明 **: 算术右移，高位补符号位

## funct3 编码汇总

| funct3 | 操作 |
|--------|------|
| 000 | ADD, SUB |
| 001 | SLL |
| 010 | SLT |
| 011 | SLTU |
| 100 | XOR |
| 101 | SRL, SRA |
| 110 | OR |
| 111 | AND |

## 溢出行为

### 有符号溢出 vs 无符号溢出

在硬件层面，加法和减法的行为是相同的（模 2^32 截断）：

```
示例: 0x7FFFFFFF + 0x00000001 = 0x80000000

有符号解释:
- 0x7FFFFFFF = +2147483647
- 0x80000000 = -2147483648
结果有符号溢出

无符号解释:
- 0x7FFFFFFF = 2147483647
- 0x80000000 = 2147483648
结果无符号溢出
```

**关键点**: ALU 本身不区分有符号/无符号溢出，软件层面解释结果。

## Zero 标志位

ALU 通常提供 Zero 标志位：

```
zero = (result == 0) ? 1 : 0
```

用途：
- 条件跳转 (BEQ, BNE)
- 减法比较结果判断
