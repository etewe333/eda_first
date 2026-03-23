---
name: riscv-testbench-compile
description: RISC-V RTL Testbench生成和编译技能。当需要编写Verilator C++ testbench并编译仿真可执行文件时使用此技能，这是RISC-V RTL自动化流水线的第5步。
---

# RISC-V RTL Testbench生成和编译技能

此技能合并了Testbench生成和仿真编译两个步骤，对应 CLAUDE.md 中自动化指令流水线的第5步。

## 技能功能

1. **Testbench生成**: 编写符合规范的 Verilator C++ testbench
   - 检查生成的头文件 (`V<模块名>.h`) 中的实际端口定义
   - 包含必需的 `double sc_time_stamp() { return 0; }` 函数
   - 编写测试用例，使用程序化方式计算期望值
   - 使用规范的日志格式输出

2. **仿真编译**: 编译 Verilator 仿真可执行文件
   - 使用 `verilator --cc` 命令编译 Verilog 代码
   - 链接 C++ testbench 文件
   - 生成可执行仿真文件
   - 指定正确的临时目录避免权限问题
既然你提到了之前的边界测试内容有误，我们需要回归 **RV32I 的标准补码逻辑（2's Complement Wrap-around）**。

在 RV32I 中，ALU **不处理**溢出异常，也不进行饱和截断。它只是单纯地完成 32 位位运算，并允许结果“回卷”（Wrap-around）。

以下是为你重写的 **“验证策略”** 部分，你可以直接替换到你的 Skill 文件中：


## 2. 验证策略说明 
在编写 `5.1 Testbench` 时，必须严格按照 RV32I 补码标准设计以下三类测试场景，以排除常见的符号位处理错误：

### A. 算术回卷与溢出测试 (Arithmetic Wrap-around)
*   **正数回卷 (Positive Wrap-around)**：
    *   输入：`A = 0x7FFFFFFF` (Max Positive), `B = 0x00000001`
    *   操作：`ADD`
    *   **预期结果**：`0x80000000` (变成最小负数)。*注意：不是 0x7FFFFFFF，硬件不进行饱和处理。*
*   **负数回卷 (Negative Wrap-around)**：
    *   输入：`A = 0x80000000` (Min Negative), `B = 0x00000001`
    *   操作：`SUB`
    *   **预期结果**：`0x7FFFFFFF` (变成最大正数)。
*   **零值跨越**：
    *   输入：`A = 0xFFFFFFFF` (-1), `B = 0x00000001`
    *   操作：`ADD`
    *   **预期结果**：`0x00000000`，且此时 **`zero` 标志位必须为 1**。

### B. 有符号比较测试 (SLT Signed Logic)
*   **跨符号比较 (正 vs 负)**：
    *   输入：`A = 0x00000001` (+1), `B = 0xFFFFFFFF` (-1)
    *   操作：`SLT`
    *   **预期结果**：`0` (因为 +1 不小于 -1)。*常见错误是将其误判为 1。*
*   **同号比较 (负 vs 负)**：
    *   输入：`A = 0xFFFFFFFE` (-2), `B = 0xFFFFFFFF` (-1)
    *   操作：`SLT`
    *   **预期结果**：`1` (因为 -2 小于 -1)。
*   **相等性检查**：
    *   输入：`A = 0x80000000`, `B = 0x80000000`
    *   操作：`SLT`
    *   **预期结果**：`0` (相等时不满足小于条件)。

### C. 逻辑运算与零标志位 (Logic & Zero Flag)
*   **按位取反模拟**：
    *   输入：`A = 0x55555555`, `B = 0xFFFFFFFF`
    *   操作：`XOR`
    *   **预期结果**：`0xAAAAAAAA`。
*   **零标志位严苛测试**：
    *   输入：`A = 0x00000001`, `B = 0x00000000`
    *   操作：`AND`
    *   **预期结果**：`0x00000000`，**`zero` 标志位必须为 1**。
    *   输入：`A = 0x80000000`, `B = 0x80000000`
    *   操作：`XOR`
    *   **预期结果**：`0x00000000`，**`zero` 标志位必须为 1**。

## 执行步骤

**开始执行第5步: Testbench生成和编译**

### 子步骤5.1: Testbench 编写

1. **生成头文件并检查**：
   - 查找 `generated/` 目录或 `sim/build/` 目录中的 `V<模块名>.h` 文件
   - 如果没有的话执行指令
   ```powershell
   & "$msys_root\usr\bin\bash.exe" -c "export PATH='/$($msystem.ToLower())/bin:/usr/bin:`$PATH' && export LC_ALL=C && mkdir -p tmp && export TMP=`$PWD/tmp \
   && verilator --cc generated/<文件>.sv --top-module <你的模块名> -Mdir sim/build" 2>&1
   ```
   - 分析头文件中的端口定义（不能假设简单的信号命名）
   - 理解模块的接口和信号类型

2. **编写 testbench 框架**：
   - 包含必要的头文件
   - **必须包含**：`double sc_time_stamp() { return 0; }`
   - 创建 main 函数
   - 实例化 Verilated 模块

3. **编写测试用例**：
   - 设计合理的测试场景
   - **期望值应通过程序化方式计算**或使用计算器验证，避免手工计算导致的算术错误
   - 覆盖主要功能路径
   - **包含各种极端情况的测试**

4. **实现日志输出**：
   - 使用规范格式：`[TEST id] <OP>: a=<VAL> b=<VAL> | expect=<VAL> got=<VAL> | PASS/FAIL`
   - 每个测试用例都有明确的标识和结果

5. **保存 testbench 文件**：
   - 保存到 `sim/testbench/<模块名>_tb.cpp`

**完成执行第5.1步: Testbench 编写 - [成功/失败]**

> **注意**: 如果步骤5.1失败，将跳过步骤5.2的仿真编译。

### 子步骤5.2: 编译仿真

1. **准备编译环境**：
   - 确保 `generated/<文件>.sv` 存在（由步骤4.1生成）
   - 确保 `sim/testbench/<cpp>.cpp` 存在（由步骤5.1生成）
   - 确保 `sim/build/` 目录存在
   - 从 `.claude/env_info.json` 读取 `msys_root` 和 `msystem`

2. **执行编译命令**：
   ```powershell
   & "$msys_root\usr\bin\bash.exe" -c "export PATH='/$($msystem.ToLower())/bin:`$PATH' && export LC_ALL=C && mkdir -p tmp && export TMP=`$PWD/tmp && verilator --cc generated/<文件>.sv --top-module <模块名> --exe sim/testbench/<cpp>.cpp --build -j -Mdir sim/build"
   ```

   命令参数说明：
   - `--cc generated/<文件>.sv`: 指定要编译的 Verilog 文件
   - `--exe sim/testbench/<cpp>.cpp`: 指定 testbench 文件
   - `--build`: 构建可执行文件
   - `-j`: 使用多线程编译
   - `-Mdir sim/build`: 指定输出目录

3. **关键环境设置**：
   - `mkdir -p tmp`: 创建临时目录
   - `export TMP=$PWD/tmp`: 手动指定 TMP 环境变量以避开权限问题
   - 必须通过 MSYS2 bash 绝对路径调用

4. **验证编译结果**：
   - 检查 `sim/build/` 目录中是否生成了可执行文件
   - 验证可执行文件 `V<模块名>` 是否存在
   - 检查编译是否有错误

**完成执行第5.2步: 编译仿真 - [成功/失败]**

**完成执行第5步: Testbench生成和编译 - [成功/失败]**

## 命令模板

### 步骤5.1关键要求
- **必须包含的函数**: `double sc_time_stamp() { return 0; }`
- **端口定义检查**: 不能假设简单的信号命名，必须检查实际生成的头文件
- **期望值计算**: 必须通过程序化方式计算或使用计算器验证
- **日志格式**: `[TEST id] <OP>: a=<VAL> b=<VAL> | expect=<VAL> got=<VAL> | PASS/FAIL`，结尾处示例
```
=== TEST SUMMARY ===
Passed: 5/5
Failed: 0/5
```
- **测试用例设计**: 设计全面的测试场景，包括正常功能测试、边界值测试等

### 步骤5.2命令（必须使用MSYS2 bash模板）
```powershell
& "$msys_root\usr\bin\bash.exe" -c "export PATH='/$($msystem.ToLower())/bin:`$PATH' && export LC_ALL=C && mkdir -p tmp && export TMP=`$PWD/tmp && verilator --cc generated/<文件>.sv --exe sim/testbench/<cpp>.cpp --build -j -Mdir sim/build"
```

## 输出示例

```
开始执行第5步: Testbench生成和编译

=== 子步骤5.1: Testbench 编写 ===
检查生成的头文件: 查找 VAdder.h
分析端口定义: a[31:0], b[31:0], sum[31:0], clk, reset
编写 testbench 框架
添加必需函数: double sc_time_stamp()
设计测试用例: 5个测试场景
计算期望值: 使用程序化计算
实现日志输出: 使用规范格式
保存文件: sim/testbench/Adder_tb.cpp
完成执行第5.1步: Testbench 编写 - 成功

=== 子步骤5.2: 编译仿真 ===
读取环境变量: msys_root=C:/msys64, msystem=MINGW64
检查输入文件: generated/Adder.sv ✓
检查 testbench: sim/testbench/Adder_tb.cpp ✓
创建临时目录: tmp/
执行编译命令...
%Warning: ...
%Info: ...
编译完成
验证输出文件: sim/build/VAdder ✓
文件大小: 2.3 MB
完成执行第5.2步: 编译仿真 - 成功

完成执行第5步: Testbench生成和编译 - 成功
```

## 成功标准

### 步骤5.1成功标准
1. testbench 文件成功创建在 `sim/testbench/<模块名>_tb.cpp`
2. 包含必需的 `sc_time_stamp()` 函数
3. 使用实际的端口名称（从生成的头文件检查）
4. 测试用例设计合理，期望值计算准确
5. 日志格式符合规范

### 步骤5.2成功标准
1. 编译命令执行成功（退出码为 0）
2. 在 `sim/build/` 目录中生成了可执行文件 `V<模块名>`
3. 可执行文件大小合理（非空）
4. 没有编译错误

## 常见错误处理

### 步骤5.1错误
1. **头文件找不到**: 确保已运行过 verilator 编译步骤，或手动指定头文件路径
2. **端口名称不匹配**: 检查实际的头文件，使用实际的端口名称
3. 注意Zero标志位:只关心结果是否为0，与具体操作逻辑无关(ADD/SUB/AND/0R/XOR/SLT 任何结果为0时zero=1)

### 步骤5.2错误
1. **文件找不到**: 检查文件路径，确保 `generated/<文件>.sv` 和 `sim/testbench/<cpp>.cpp` 存在
2. **权限问题**: 使用 `export TMP=$PWD/tmp` 指定项目内的临时目录
3. **编译错误**: 检查语法错误，可能需要返回步骤4修复
4. **头文件错误**: 确保 testbench 使用正确的头文件包含方式

## 注意事项

1. **步骤依赖**: 步骤5.2依赖于步骤5.1的成功执行
2. **环境变量**: 步骤5.2必须使用正确的 MSYS2 bash 环境变量设置
3. **临时目录**: 必须手动指定 `TMP` 环境变量以避开权限问题
4. **头文件检查**: 步骤5.1必须检查实际生成的头文件，不能假设端口命名
5. **时间戳函数**: testbench 必须包含 `sc_time_stamp()` 函数

## 验证质量标准

根据 CLAUDE.md：
- **C++**: 必须包含 `double sc_time_stamp() { return 0; }`
- **输出格式**: `[TEST id] Op: ... | expect: ... got: ... | PASS/FAIL`
- **编译要求**: 必须生成可执行的仿真文件

## 相关技能

- `riscv-riscv-rv32i-check` - 检查规范（上一步，检查规范）
- `riscv-sim-run` - 仿真运行技能（下一步，运行仿真验证）