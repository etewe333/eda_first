---
name: riscv-rv32i-check
description: Check if generated ALU code conforms to RV32I standard. Use when user asks to verify RISC-V RV32I compliance, check ALU against RV32I specification, or validate RISC-V compatibility. This skill reads Chisel source and Verilog files, compares them against RV32I ALU specifications, and reports any deviations.
---

# RV32I 标准检查技能

此技能检查生成的 ALU 代码是否符合 RISC-V RV32I 标准。

## 功能

1. **读取源文件** - 读取 Chisel (.scala) 和 Verilog (.sv) 文件
2. **对比 RV32I 规范** - 检查操作码映射和指令实现
3. **符号处理检查** - 验证有符号/无符号操作
4. **生成检查报告** - 输出详细的符合性分析

## 执行步骤

### 步骤1: 定位源文件

1. 查找 Chisel 源文件和查找生成的 Verilog

### 步骤2: 分析操作码映射

根据 RV32I 规范，ALU 操作码 (funct3) 映射如下：

| funct3 | 操作 | 描述 | 必需 |
|--------|------|------|------|
| 000 | ADD/SUB | 加减法 | ✓ |
| 001 | SLL | 逻辑左移 | 可选 |
| 010 | SLT | 小于置位（有符号） | ✓ |
| 011 | SLTU | 小于置位（无符号） | 可选 |
| 100 | XOR | 异或 | ✓ |
| 101 | SRL/SRA | 右移 | 可选 |
| 110 | OR | 或 | ✓ |
| 111 | AND | 与 | ✓ |

非必选项缺失不算错误，但是如果操作码映射错误则需要重写

**⚠️ 重要：Verilog 数组索引方向**

当分析生成的 Verilog 中 `_GEN` 数组时，必须注意 Verilog 位拼接 `{ }` 的索引方向：

- `wire [N:0] arr = {a, b, c, ...}` 中，第一个元素 `a` 对应最高索引 `[N]`，最后一个元素对应最低索引 `[0]`
- 检查时要将数组元素顺序**反向映射**到索引 0-N

### 步骤3: 符号处理检查

检查以下内容：

1. **ADD/SUB 溢出**：
   - 应使用 32 位无符号运算（自动截断）
   - 例如：0xFFFFFFFF + 0xFFFFFFFF = 0xFFFFFFFE

2. **SLT 实现**：
   - 必须使用有符号比较 (`asSInt` 或 `$signed()`)
   - 结果：a < b → 1，否则 0

3. **Zero 标志位**：
   - 结果为 0 时置 1，否则 0

### 步骤4: 生成报告

输出格式：

```
=== RV32I 合规性检查报告 ===

文件: <源文件路径>
生成文件: <Verilog文件路径>

【操作码映射检查】
| funct3 | 期望操作 | 实际实现 | 状态 |
|--------|----------|----------|------|
| 000    | ADD      | ADD      | ✓    |
| 010    | SLT      | SLT      | ✓    |
| ...    | ...      | ...      | ...  |

【符号处理检查】
- ADD 溢出: ✓ 正确 (自动截断)
- SUB 结果: ✓ 正确 (补码表示)
- SLT 比较: ✓ 正确 (有符号)

【必需指令】
- ADD: ✓ 实现
- SLT: ✓ 实现
- XOR: ✓ 实现
- OR:  ✓ 实现
- AND: ✓ 实现

【结论】
符合 RV32I 标准: [是/否]
```

## 错误反馈
   - 如果发现不符合RV32I标准，需要回到第3步骤重新修改scala代码

## 参考资料

- RV32I 规范: `references/rv32i-alu.md`

## 相关技能

- `riscv-rtl-lint` - RTL构建和语法检查技能（上一步，确保 RTL 语法正确）
- `riscv-testbench-compile` - Testbench开发与编译技能

