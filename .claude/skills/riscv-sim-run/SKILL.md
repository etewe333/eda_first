---
name: riscv-sim-run
description: RISC-V RTL 仿真运行技能。当需要运行Verilator仿真验证时使用此技能，这是RISC-V RTL自动化流水线的第6步。
---

# RISC-V RTL 仿真运行技能

此技能运行 Verilator 仿真验证，对应 CLAUDE.md 中自动化指令流水线的第6步。

## 技能功能

运行编译好的仿真可执行文件：
- 执行 `./sim/build/V<模块名>` 仿真程序
- 捕获输出到日志文件 `sim/logs/sim_result.log`
- 分析仿真结果

## 执行步骤

**开始执行第6步: 执行验证**

1. **准备运行环境**：
   - 确保 `sim/build/V<模块名>` 可执行文件存在
   - 确保 `sim/logs/` 目录存在
   - 从 `.claude/env_info.json` 读取 `msys_root` 和 `msystem`

2. **执行仿真命令**：
   ```powershell
   & "$msys_root\usr\bin\bash.exe" -c "export PATH='/$($msystem.ToLower())/bin:/usr/bin:`$PATH' && export LC_ALL=C && mkdir -p sim/logs && ./sim/build/V<模块名> 2>&1 | tee sim/logs/sim_result.log"
   ```

   命令参数说明：
   - `mkdir -p sim/logs`: 确保日志目录存在
   - `./sim/build/V<模块名>`: 运行仿真可执行文件
   - `2>&1`: 将标准错误重定向到标准输出
   - `| tee sim/logs/sim_result.log`: 同时输出到终端和文件

3. **分析仿真结果**：
   - 检查仿真程序的退出码
   - 分析输出中的测试结果
   - 统计 PASS/FAIL 数量
   - 检查是否有运行时错误

4. **验证日志文件**：
   - 检查 `sim/logs/sim_result.log` 文件是否创建
   - 验证日志内容完整性
   - 确保日志包含所有测试输出

**完成执行第6步: 执行验证 - [成功/失败]**

## 命令模板

根据 CLAUDE.md，所有涉及 MSYS2、verilator 的指令必须使用以下模板：

### 基本结构
```powershell
& "$msys_root\usr\bin\bash.exe" -c "export PATH='/$($msystem.ToLower())/bin:/usr/bin:`$PATH' && export LC_ALL=C && mkdir -p sim/logs && ./sim/build/V<模块名> 2>&1 | tee sim/logs/sim_result.log"
```

## 输出示例

```
开始执行第6步: 执行验证
读取环境变量: msys_root=C:/msys64, msystem=MINGW64
检查可执行文件: sim/build/VAdder ✓
创建日志目录: sim/logs/
运行仿真...
[TEST 1] ADD: a=0x10 b=0x20 | expect=0x30 got=0x30 | PASS
[TEST 2] SUB: a=0x30 b=0x10 | expect=0x20 got=0x20 | PASS
[TEST 3] AND: a=0xFF b=0x0F | expect=0x0F got=0x0F | PASS
[TEST 4] OR:  a=0xF0 b=0x0F | expect=0xFF got=0xFF | PASS
[TEST 5] XOR: a=0xFF b=0xFF | expect=0x00 got=0x00 | PASS

=== TEST SUMMARY ===
Passed: 5/5
Failed: 0/5
仿真完成，退出码: 0
保存日志: sim/logs/sim_result.log
完成执行第6步: 执行验证 - 成功
```

## 结果判断标准

### 成功标准
1. 仿真程序执行成功（退出码为 0）
2. 所有测试用例通过（PASS）
3. 日志文件正确生成并包含完整输出
4. 没有运行时错误或断言失败

### 失败标准
1. 仿真程序执行失败（退出码非 0）
2. 有测试用例失败（FAIL）
3. 运行时错误或断言失败
4. 日志文件生成失败


## 常见错误及处理

### 可执行文件找不到
```
bash: ./sim/build/VAdder: No such file or directory
```
**原因**: 可执行文件路径不正确或未编译
**解决方案**: 检查步骤5的编译结果，确保文件存在

### 运行时错误
```
Segmentation fault (core dumped)
```
**原因**: 内存访问错误或 testbench 逻辑错误
**解决方案**: 回到步骤5，检查 testbench 代码，特别是指针和数组访问

### 断言失败
```
Assertion failed: (condition), function main, file testbench.cpp, line 45
```
**原因**: testbench 中的断言条件不满足
**解决方案**: 检查测试用例和期望值计算

### 验证失败
```
结果日志中包含FAIL
```
**解决方案**: 1、首先检查测试用例和期望值计算，若发现错误则回到第五步
2、若测试用例没有错误，则回到第三步，检查chisel代码是否符合要求

## 日志文件格式

日志文件 `sim/logs/sim_result.log` 应包含：
1. 所有测试用例输出（格式：`[TEST id] <OP>: a=<VAL> b=<VAL> | expect=<VAL> got=<VAL> | PASS/FAIL`）
2. 测试总结
3. 任何错误或警告信息
4. 仿真时间和统计信息（如果 testbench 提供）

## 相关技能

- `riscv-testbench-compile` - Testbench开发与编译技能（第5步）
- `riscv-log-save` - 日志保存技能（第7步，保存结果）