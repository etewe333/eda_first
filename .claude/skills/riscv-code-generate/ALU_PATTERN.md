# RISC-V ALU 代码生成技术总结

## 问题背景

firtool (CIRCT) 会对 `switch` + `VecInit` 组合进行操作重排序优化，导致生成的 Verilog 中操作顺序与 Chisel 代码中的 case 顺序不一致。


## 解决方案：使用 MuxCase

**核心原理：** `MuxCase` 是基于条件的多路选择器，firtool 不会对基于条件的选择器进行重新排序。

## 关键设计模式

### 1. ADD/SUB 合并
- 使用 4 位操作码：`alu_op = {sub_enable, funct3}`
- `sub_enable = 0`: ADD
- `sub_enable = 1`: SUB
- funct3 均为 000

### 2. funct3 常量定义
```scala
val FUNCT3_ADD_SUB = 0.U(3.W)  // 000
val FUNCT3_SLL     = 1.U(3.W)  // 001 (不支持)
val FUNCT3_SLT     = 2.U(3.W)  // 010
val FUNCT3_SLTU    = 3.U(3.W)  // 011 (不支持)
val FUNCT3_XOR     = 4.U(3.W)  // 100
val FUNCT3_SRL_SRA = 5.U(3.W)  // 101 (不支持)
val FUNCT3_OR      = 6.U(3.W)  // 110
val FUNCT3_AND     = 7.U(3.W)  // 111
```

### 3. 有符号比较
```scala
val slt_result = Mux(io.a.asSInt < io.b.asSInt, 1.U(32.W), 0.U(32.W))
```

### 4. 未实现操作返回 0
```scala
io.result := MuxCase(0.U(32.W), Seq(
  // ... 已实现的操作
  // 未实现的操作自动返回默认值 0
))
```

## 操作码映射

| alu_op[3:0] | 操作 | 说明 |
|-------------|------|------|
| 0000 | ADD | funct3=000, sub_enable=0 |
| 1000 | SUB | funct3=000, sub_enable=1 |
| 0010 | SLT | funct3=010 |
| 0100 | XOR | funct3=100 |
| 0110 | OR  | funct3=110 |
| 0111 | AND | funct3=111 |

## 禁止使用的模式

❌ **禁止使用 `switch` + `VecInit` 索引方式：**
```scala
// 错误！firtool 会重排序
val opTable = VecInit(addRes, subRes, andRes, ...)
result := opTable(io.opCode)
```

✅ **正确使用 `MuxCase`：**
```scala
// 正确！基于条件，不会被重排序
io.result := MuxCase(0.U, Seq(
  (condition1) -> value1,
  (condition2) -> value2
))
```
