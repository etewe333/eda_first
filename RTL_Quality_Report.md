# RTL 质量报告：ALU 模块

**报告日期**：2026-03-28  
**RTL 产物**：`generated/ALU.sv`  
**仿真脚本**：`sim/testbench/ALU_tb.cpp`  
**仿真结果**：`sim/logs/sim_result.log`

---

## 一、RTL 产物分析（generated/ALU.sv）

### 1.1 基本信息

| 项目 | 内容 |
|------|------|
| 文件 | `generated/ALU.sv` |
| 生成工具 | CIRCT firtool-1.62.0 |
| 行数 | 25 行（含注释） |
| 模块名 | `ALU` |
| 电路类型 | 纯组合逻辑（无时序元件） |

### 1.2 端口列表

从 `generated/ALU.sv` 第 3–9 行提取的端口定义：

```systemverilog
input         clock,          // 时钟（纯组合逻辑，未使用）
              reset,          // 复位（纯组合逻辑，未使用）
input  [31:0] io_a,           // 操作数 A（32 位）
              io_b,           // 操作数 B（32 位）
input  [3:0]  io_alu_op,      // 操作码（4 位）
output [31:0] io_result,      // 运算结果（32 位）
output        io_zero         // 零标志位（1 位）
```

| 端口 | 方向 | 位宽 | 说明 |
|------|------|------|------|
| `clock` | Input | 1 | Chisel Module 自动生成，本模块未使用 |
| `reset` | Input | 1 | Chisel Module 自动生成，本模块未使用 |
| `io_a` | Input | 32 | 操作数 A |
| `io_b` | Input | 32 | 操作数 B |
| `io_alu_op` | Input | 4 | 操作码 `{sub_enable, funct3[2:0]}` |
| `io_result` | Output | 32 | 运算结果 |
| `io_zero` | Output | 1 | 零标志位（`result == 0` 时为 1） |

### 1.3 RTL 结构分析

生成的 Verilog 核心为一个 **8 路查找表（LUT）**，以 `io_alu_op[2:0]`（即 funct3）作为索引：

```systemverilog
wire [7:0][31:0] _GEN =
    {{io_a & io_b},                                    // 索引 [7] → funct3=111: AND
     {io_a | io_b},                                    // 索引 [6] → funct3=110: OR
     {32'h0},                                          // 索引 [5] → funct3=101: 未实现
     {io_a ^ io_b},                                    // 索引 [4] → funct3=100: XOR
     {32'h0},                                          // 索引 [3] → funct3=011: 未实现
     {{31'h0, $signed(io_a) < $signed(io_b)}},         // 索引 [2] → funct3=010: SLT
     {32'h0},                                          // 索引 [1] → funct3=001: 未实现
     {io_alu_op[3] ? io_a - io_b : io_a + io_b}};     // 索引 [0] → funct3=000: ADD/SUB
```

结果选择与零标志位生成：

```systemverilog
wire [31:0] io_result_0 = _GEN[io_alu_op[2:0]];       // 按 funct3 索引选择
assign io_result = io_result_0;
assign io_zero   = io_result_0 == 32'h0;               // 零标志
```

### 1.4 操作码映射验证

逐项核对 RTL 查找表的索引与 RV32I funct3 编码的对应关系：

| 索引 | funct3 | RV32I 规范操作 | RTL 实际实现 | 一致性 |
|------|--------|----------------|-------------|--------|
| [0] | 000 | ADD/SUB | `io_alu_op[3] ? io_a - io_b : io_a + io_b` | ✅ 一致 |
| [1] | 001 | SLL | `32'h0`（未实现） | ⚠️ 返回 0 |
| [2] | 010 | SLT | `{31'h0, $signed(io_a) < $signed(io_b)}` | ✅ 一致 |
| [3] | 011 | SLTU | `32'h0`（未实现） | ⚠️ 返回 0 |
| [4] | 100 | XOR | `io_a ^ io_b` | ✅ 一致 |
| [5] | 101 | SRL/SRA | `32'h0`（未实现） | ⚠️ 返回 0 |
| [6] | 110 | OR | `io_a \| io_b` | ✅ 一致 |
| [7] | 111 | AND | `io_a & io_b` | ✅ 一致 |

**结论**：已实现的 6 种操作（ADD/SUB/SLT/XOR/OR/AND）的 funct3 映射**全部正确**。ADD/SUB 通过 `io_alu_op[3]`（sub_enable）区分，符合 RV32I R-type 指令的 funct7[5] 编码。

### 1.5 RTL 关键特性

| 检查项 | 结果 | 说明 |
|--------|------|------|
| 锁存器推断 | ✅ 无 | 纯组合逻辑，所有输出均有确定赋值 |
| 位宽匹配 | ✅ 正确 | 输入/输出均为 32 位，无截断或扩展问题 |
| 有符号比较 | ✅ 正确 | SLT 使用 `$signed()` 类型转换 |
| 溢出行为 | ✅ 正确 | ADD/SUB 结果自动模 2³² 截断 |
| 默认路径 | ✅ 安全 | 未实现的 funct3 索引返回 `32'h0` |
| 未驱动信号 | ✅ 无 | 所有输出端口均有完整驱动链 |

### 1.6 Verilator 静态检查

基于历史执行记录（`agent/logs/session_20260328_080100.log`）：

```
命令: verilator --lint-only -Igenerated generated/ALU.sv --top-module ALU
错误 (Error):   0
警告 (Warning): 0
```

| 检查维度 | 结果 |
|----------|------|
| 语法正确性 | ✅ 通过 |
| 综合可行性 | ✅ 通过 |
| 信号驱动完整性 | ✅ 通过 |
| 位宽一致性 | ✅ 通过 |

---

## 二、仿真验证分析

### 2.1 Testbench 架构（sim/testbench/ALU_tb.cpp）

| 项目 | 内容 |
|------|------|
| 文件 | `sim/testbench/ALU_tb.cpp` |
| 行数 | 144 行 |
| 语言 | C++（Verilator 原生 API） |
| 仿真模型 | `VALU`（Verilator 自动生成的 C++ 模型） |

**Testbench 结构**：

```
ALU_tb.cpp
├── Verilator 模型实例化 (VALU)
├── 测试辅助函数 test_alu()
│   ├── 设置输入 (io_alu_op, io_a, io_b)
│   ├── 组合评估 (top->eval())
│   ├── 结果对比 (got vs expected)
│   └── 格式化输出 ([TEST id] OP ... | PASS/FAIL)
├── 操作码常量定义
│   ├── OP_ADD = 0x0  (funct3=000, sub=0)
│   ├── OP_SUB = 0x8  (funct3=000, sub=1)
│   ├── OP_SLT = 0x2  (funct3=010)
│   ├── OP_XOR = 0x4  (funct3=100)
│   ├── OP_OR  = 0x6  (funct3=110)
│   └── OP_AND = 0x7  (funct3=111)
├── 20 个测试用例（4 类）
└── 测试统计与退出码
```

**验证方法**：
- 纯组合逻辑直接激励（不涉及时钟周期）
- 双重校验：同时检查 `io_result` 和 `io_zero` 两个输出
- 退出码反馈：`return failed > 0 ? 1 : 0`，便于 CI 集成

### 2.2 测试用例设计

共 **20 个测试用例**，按验证目标分为 4 类：

#### 类别 A：基础功能验证（Test 1–7）

覆盖全部 6 种已实现操作的基本正确性。

| # | 操作 | A | B | 期望 result | 期望 zero | 验证目标 |
|---|------|---|---|-------------|-----------|----------|
| 1 | ADD | 0x5 | 0x3 | 0x8 | 0 | 基础加法 |
| 2 | SUB | 0xA | 0x4 | 0x6 | 0 | 基础减法 |
| 3 | AND | 0xFF0F | 0xF0FF | 0xF00F | 0 | 按位与 |
| 4 | OR | 0x0F0F | 0xF0F0 | 0xFFFF | 0 | 按位或 |
| 5 | XOR | 0xAAAA | 0x5555 | 0xFFFF | 0 | 按位异或 |
| 6 | SLT | 0x5 | 0xA | 0x1 | 0 | 有符号小于（真） |
| 7 | SLT | 0xA | 0x5 | 0x0 | 1 | 有符号小于（假） |

#### 类别 B：算术溢出回卷测试（Test 8–10）

验证 RV32I 规范要求的模 2³² 溢出行为。

| # | 操作 | A | B | 期望 result | 期望 zero | 验证目标 |
|---|------|---|---|-------------|-----------|----------|
| 8 | ADD | 0x7FFFFFFF | 0x1 | 0x80000000 | 0 | 正溢出回卷 |
| 9 | SUB | 0x80000000 | 0x1 | 0x7FFFFFFF | 0 | 负溢出回卷 |
| 10 | ADD | 0xFFFFFFFF | 0x1 | 0x0 | 1 | 溢出至零 |

#### 类别 C：SLT 有符号逻辑测试（Test 11–13）

验证 `$signed()` 比较在跨符号边界场景下的正确性，这是 ALU 实现中最易出错的部分。

| # | 操作 | A（有符号） | B（有符号） | 期望 result | 期望 zero | 验证目标 |
|---|------|-------------|-------------|-------------|-----------|----------|
| 11 | SLT | +1 | -1 (0xFFFFFFFF) | 0 | 1 | 正数 > 负数 |
| 12 | SLT | -2 (0xFFFFFFFE) | -1 (0xFFFFFFFF) | 1 | 0 | 负数 < 负数 |
| 13 | SLT | INT_MIN (0x80000000) | INT_MIN (0x80000000) | 0 | 1 | 相等比较 |

#### 类别 D：零标志位与边界值测试（Test 14–20）

验证 `io_zero` 在各操作产生零结果时的正确性，以及位操作的边界行为。

| # | 操作 | A | B | 期望 result | 期望 zero | 验证目标 |
|---|------|---|---|-------------|-----------|----------|
| 14 | AND | 0x1 | 0x0 | 0x0 | 1 | AND 产生零 |
| 15 | XOR | 0x80000000 | 0x80000000 | 0x0 | 1 | XOR 相等产生零 |
| 16 | SUB | 0xA | 0xA | 0x0 | 1 | SUB 相等产生零 |
| 17 | AND | 0x80000000 | 0x80000000 | 0x80000000 | 0 | 符号位保留 |
| 18 | OR | 0x80000000 | 0x7FFFFFFF | 0xFFFFFFFF | 0 | 全一结果 |
| 19 | XOR | 0x55555555 | 0xFFFFFFFF | 0xAAAAAAAA | 0 | 位翻转 |
| 20 | SLT | -1 (0xFFFFFFFF) | +1 (0x1) | 1 | 0 | 负数 < 正数 |

### 2.3 测试覆盖率评估

| 覆盖维度 | 覆盖情况 | 评级 |
|----------|----------|------|
| **操作覆盖** | 6/6 已实现操作全部测试 | ✅ 完整 |
| **zero=1 场景** | 7 个用例 (Test 7,10,11,13,14,15,16) | ✅ 充分 |
| **zero=0 场景** | 13 个用例 | ✅ 充分 |
| **正溢出** | Test 8 (MAX_INT + 1) | ✅ 覆盖 |
| **负溢出** | Test 9 (MIN_INT - 1) | ✅ 覆盖 |
| **零值跨越** | Test 10 (0xFFFFFFFF + 1 = 0) | ✅ 覆盖 |
| **符号边界 SLT** | Test 11,12,13,20 (正vs负/负vs负/相等) | ✅ 充分 |
| **位操作边界** | Test 14-19 (零输入/符号位/全一/位翻转) | ✅ 充分 |
| **未实现操作** | 未测试 funct3=001/011/101 返回 0 | ⚠️ 未覆盖 |

---

## 三、仿真结果（sim/logs/sim_result.log）

### 3.1 完整仿真日志

```
=== RV32I ALU Testbench ===
[TEST 1] ADD: a=0x5 b=0x3 | expect=0x8 got=0x8 zero_exp=0 got=0 | PASS
[TEST 2] SUB: a=0xa b=0x4 | expect=0x6 got=0x6 zero_exp=0 got=0 | PASS
[TEST 3] AND: a=0xff0f b=0xf0ff | expect=0xf00f got=0xf00f zero_exp=0 got=0 | PASS
[TEST 4] OR: a=0xf0f b=0xf0f0 | expect=0xffff got=0xffff zero_exp=0 got=0 | PASS
[TEST 5] XOR: a=0xaaaa b=0x5555 | expect=0xffff got=0xffff zero_exp=0 got=0 | PASS
[TEST 6] SLT: a=0x5 b=0xa | expect=0x1 got=0x1 zero_exp=0 got=0 | PASS
[TEST 7] SLT: a=0xa b=0x5 | expect=0x0 got=0x0 zero_exp=1 got=1 | PASS
[TEST 8] ADD: a=0x7fffffff b=0x1 | expect=0x80000000 got=0x80000000 zero_exp=0 got=0 | PASS
[TEST 9] SUB: a=0x80000000 b=0x1 | expect=0x7fffffff got=0x7fffffff zero_exp=0 got=0 | PASS
[TEST 10] ADD: a=0xffffffff b=0x1 | expect=0x0 got=0x0 zero_exp=1 got=1 | PASS
[TEST 11] SLT: a=0x1 b=0xffffffff | expect=0x0 got=0x0 zero_exp=1 got=1 | PASS
[TEST 12] SLT: a=0xfffffffe b=0xffffffff | expect=0x1 got=0x1 zero_exp=0 got=0 | PASS
[TEST 13] SLT: a=0x80000000 b=0x80000000 | expect=0x0 got=0x0 zero_exp=1 got=1 | PASS
[TEST 14] AND: a=0x1 b=0x0 | expect=0x0 got=0x0 zero_exp=1 got=1 | PASS
[TEST 15] XOR: a=0x80000000 b=0x80000000 | expect=0x0 got=0x0 zero_exp=1 got=1 | PASS
[TEST 16] SUB: a=0xa b=0xa | expect=0x0 got=0x0 zero_exp=1 got=1 | PASS
[TEST 17] AND: a=0x80000000 b=0x80000000 | expect=0x80000000 got=0x80000000 zero_exp=0 got=0 | PASS
[TEST 18] OR: a=0x80000000 b=0x7fffffff | expect=0xffffffff got=0xffffffff zero_exp=0 got=0 | PASS
[TEST 19] XOR: a=0x55555555 b=0xffffffff | expect=0xaaaaaaaa got=0xaaaaaaaa zero_exp=0 got=0 | PASS
[TEST 20] SLT: a=0xffffffff b=0x1 | expect=0x1 got=0x1 zero_exp=0 got=0 | PASS
=== TEST SUMMARY ===
Passed: 20/20
Failed: 0/20
```

### 3.2 结果统计

| 统计项 | 数据 |
|--------|------|
| 总测试数 | 20 |
| 通过数 | **20** |
| 失败数 | **0** |
| 通过率 | **100%** |
| 仿真退出码 | **0**（成功） |

### 3.3 按操作统计

| 操作 | 测试数 | 通过数 | 失败数 |
|------|--------|--------|--------|
| ADD | 3 (Test 1,8,10) | 3 | 0 |
| SUB | 3 (Test 2,9,16) | 3 | 0 |
| AND | 3 (Test 3,14,17) | 3 | 0 |
| OR | 2 (Test 4,18) | 2 | 0 |
| XOR | 3 (Test 5,15,19) | 3 | 0 |
| SLT | 6 (Test 6,7,11,12,13,20) | 6 | 0 |

---

## 四、质量总结

### 4.1 RTL 产物质量

| 评估项 | 结果 | 依据 |
|--------|------|------|
| Verilator Lint | ✅ 通过（0 错误 / 0 警告） | 历史执行记录 |
| funct3 映射正确性 | ✅ 全部正确 | RTL 查找表逐项核对 |
| 有符号比较实现 | ✅ 正确使用 `$signed()` | `generated/ALU.sv` 第 18 行 |
| ADD/SUB 区分机制 | ✅ 正确使用 `io_alu_op[3]` | `generated/ALU.sv` 第 20 行 |
| 零标志位 | ✅ `io_result_0 == 32'h0` | `generated/ALU.sv` 第 23 行 |
| 未实现操作默认值 | ✅ 返回 `32'h0`（安全） | `generated/ALU.sv` 第 15,17,19 行 |

### 4.2 仿真验证质量

| 评估项 | 结果 | 依据 |
|--------|------|------|
| 操作覆盖率 | ✅ 6/6 (100%) | Testbench 覆盖全部已实现操作 |
| 测试通过率 | ✅ 20/20 (100%) | `sim/logs/sim_result.log` |
| 溢出场景覆盖 | ✅ 正/负/零 | Test 8,9,10 |
| 有符号边界覆盖 | ✅ 4 种场景 | Test 11,12,13,20 |
| 零标志覆盖 | ✅ 双向验证 | 7 个 zero=1 + 13 个 zero=0 |

### 4.3 综合评价

**整体质量等级：✅ 优秀**

- RTL 代码结构紧凑（25 行），无冗余逻辑
- 操作码映射与 RV32I 规范完全一致
- 仿真 20 个测试用例 100% 通过，覆盖基础功能、算术边界、有符号比较、零标志位等关键场景

### 4.4 已知限制

| 限制项 | 说明 | 影响 |
|--------|------|------|
| SLL/SLTU/SRL/SRA 未实现 | funct3=001/011/101 返回 0 | 不影响已实现功能，但不是完整 RV32I ALU |
| 未实现操作未测试 | Testbench 未验证 funct3=001/011/101 返回 0 | 建议补充 |
| 无时序分析 | 纯功能验证，未含 STA | 综合后需另行验证 |
| clock/reset 未使用 | Chisel Module 自动生成 | 可通过 RawModule 消除 |
