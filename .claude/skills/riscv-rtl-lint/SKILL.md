---
name: riscv-rtl-lint
description: RISC-V RTL 构建和语法检查技能。当需要使用sbt生成Verilog RTL代码并进行Verilator语法检查时使用此技能，这是RISC-V RTL自动化流水线的第4步。
---

# RISC-V RTL 构建和语法检查技能

此技能合并了RTL生成和语法检查两个步骤，对应 CLAUDE.md 中自动化指令流水线的第4步。

## 技能功能

1. **RTL构建**: 使用 sbt 生成 Verilog RTL 代码
   - 执行 `sbt "runMain <模块名>Gen"`
   - 生成 Verilog 文件到 `generated/` 目录
   - 验证生成结果

2. **语法检查**: 使用 Verilator 进行 RTL 语法检查
   - 运行 `verilator --lint-only` 命令
   - 使用 `--top-module` 参数指定顶层模块
   - 检查语法错误和潜在问题

## 执行步骤

**开始执行第4步: RTL构建和语法检查**

### 子步骤4.1: 生成 RTL

1. **准备生成环境**：
   - 确保 `build.sbt` 文件存在
   - 确保 Scala 源代码文件存在
   - 确保 `generated/` 目录存在

2. **执行 sbt 命令**：
   ```bash
   sbt "runMain <模块名>Gen"
   ```
   - `<模块名>` 必须与 Scala 代码中的模块名一致
   - 生成的 Verilog 文件将保存到 `generated/` 目录

3. **验证生成结果**：
   - 检查 `generated/` 目录中是否生成了 `.sv` 或 `.v` 文件
   - 验证文件内容是否完整
   - 检查是否有编译错误

4. **文件命名约定**：
   - 通常生成的文件名为 `<模块名>.sv` 或 `<模块名>.v`
   - 确保文件名与模块名一致

**完成执行第4.1步: 生成 RTL - [成功/失败]**

> **注意**: 如果步骤4.1失败，将跳过步骤4.2的语法检查。

### 子步骤4.2: 语法检查 (Lint)

1. **准备检查环境**：
   - 确保 `generated/` 目录中存在 Verilog 文件（由上一步生成）
   - 确保 verilator 工具可用
   - 从 `.claude/env_info.json` 读取 `msys_root` 和 `msystem`

2. **执行 lint 命令**：
   ```powershell
   & "$msys_root\usr\bin\bash.exe" -c "export PATH='/$($msystem.ToLower())/bin:/usr/bin:`$PATH' && export LC_ALL=C && verilator --lint-only -Igenerated generated/<文件>.sv --top-module <模块名>"
   ```

   命令参数说明：
   - `-Igenerated`: 包含 generated 目录作为头文件搜索路径
   - `generated/<文件>.sv`: 要检查的 Verilog 文件路径
   - `--top-module <模块名>`: 指定顶层模块名（必须使用）

3. **分析检查结果**：
   - 检查命令退出码
   - 分析输出中的警告和错误
   - 判断是否通过 lint 检查

4. **关键要求**：
   - **必须使用 `--top-module <当前设计的模块名>`**，否则在多个模块时会触发 MULTITOP 错误
   - 必须通过 MSYS2 bash 绝对路径调用 verilator
   - 必须使用正确的环境变量设置

**完成执行第4.2步: 语法检查 (Lint) - [成功/失败]**

**完成执行第4步: RTL构建和语法检查 - [成功/失败]**


## 输出示例

```
开始执行第4步: RTL构建和语法检查

=== 子步骤4.1: 生成 RTL ===
检查 build.sbt... 存在
检查 Scala 源代码... src/main/scala/Adder.scala
执行 sbt 命令: sbt "runMain AdderGen"
[info] welcome to sbt 1.9.7
[info] loading settings for project proj_f from build.sbt ...
[info] compiling 1 Scala source to target/scala-2.13/classes ...
[info] running AdderGen
[info] Elaborating design...
[info] Done elaborating.
生成完成
验证生成结果: generated/Adder.sv 存在
文件大小: 15.2 KB
完成执行第4.1步: 生成 RTL - 成功

=== 子步骤4.2: 语法检查 (Lint) ===
读取环境变量: msys_root=C:/msys64, msystem=MINGW64
检查文件: generated/Adder.sv
执行 lint 命令...
%Warning-LITENDIAN: Generated/Adder.sv:12: Little bit endian vector: foo
%Warning-UNUSED: Generated/Adder.sv:25: Signal is not used: bar
检查完成，退出码: 0
警告数量: 2，错误数量: 0
完成执行第4.2步: 语法检查 (Lint) - 成功

完成执行第4步: RTL构建和语法检查 - 成功
```

## 成功标准

### 步骤4.1成功标准
1. sbt 命令执行成功（退出码为 0）
2. 在 `generated/` 目录中生成了 `.sv` 或 `.v` 文件
3. 生成的文件大小合理（非空）
4. 文件内容包含 Verilog 模块定义

### 步骤4.2成功标准
1. verilator 命令执行成功（退出码为 0）
2. 没有语法错误（可能有警告）
3. 模块通过基本语法检查

## 常见错误处理

### 步骤4.1错误
1. **sbt 命令找不到**：确保 sbt 已安装并添加到 PATH
2. **模块名不匹配**：检查 Scala 代码中是否正确定义了 `object <模块名>Gen`
3. **编译错误**：检查 Scala 代码语法和逻辑错误

### 步骤4.2错误
1. **MULTITOP 错误**：确保正确使用 `--top-module <模块名>` 参数
2. **语法错误**：修复 Scala/Chisel 代码中的逻辑错误
3. **未定义模块**：检查文件路径和模块名
4. **环境配置错误**：确保正确设置 PATH 和 LC_ALL 环境变量

## 注意事项

1. **步骤依赖**：步骤4.2依赖于步骤4.1的成功执行
2. **环境变量**：步骤4.2必须使用正确的 MSYS2 bash 环境变量设置
3. **首次运行**：sbt 首次运行可能需要下载依赖，时间较长

## 相关技能

- `riscv-code-generate` - 代码生成技能（上一步，生成 Scala 代码）
- `riscv-riscv-rv32i-check` - 检查规范（下一步，检查规范）


