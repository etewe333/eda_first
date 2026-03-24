# RISC-V RTL 自动化流水线准则

## 1. 项目概述
实现从自然语言描述到符合RV32I标准的硬件逻辑的自动生成、编译、语法检查及仿真验证的全自动化流程。

## 2. 技术栈与工具
- 编程语言: Chisel (Scala)
- 构建工具: sbt
- 硬件转换: firtool (用于将 FIRRTL 转为 Verilog)
- 语法检查: Verilator (lint 模式)

## 3. 架构约定 (目录规范)
- Chisel 源码: `src/main/scala/`
- RTL 产物: `generated/`
- Testbench: `sim/testbench/`
- 仿真产物: `sim/build/`
- 仿真日志: `sim/logs/sim_result.log`
- **环境配置**: `.claude/env_info.json` 
- **Agent 日志**: `agent/logs/` 

## 4. 自动化指令流水线
此技能按顺序执行以下7个步骤，且自动连续执行直到结果正确

1. **环境自适应探测与工具检查** - 根据技能`riscv-env-check`校验环境指纹（`.claude/env_info.json`）并验证工具链（node, java, sbt, firtool, verilator）。
2. **目录初始化** - 根据技能`riscv-dir-init`创建规范定义的文件夹（src, generated, sim, agent等）。
3. **代码生成与构建配置** - 根据技能`riscv-code-generate`生成符合规范的 Chisel Scala 代码并配置固定的 `build.sbt`。
4. **RTL生成与语法检查** - 根据技能`riscv-rtl-lint`执行 sbt 生成 Verilog，并使用 Verilator 进行 Lint 静态检查。
5. **检查是否符合RV32I规范** - 根据技能`riscv-rv32i-check`检查是否符合规范。
6. **Testbench开发与编译** - 根据技能`riscv-testbench-compile`编写包含特定规约的 C++ Testbench，并使用 Verilator 编译仿真可执行文件。
7. **仿真验证执行** - 根据技能`riscv-sim-run`运行编译后的仿真程序，实时捕获输出。
8. **结果保存与日志记录** - 根据技能`riscv-log-save`将仿真结果保存至 `sim/logs/`，并在 `agent/logs/` 记录需求分析与执行痕迹。

## 5. 输出格式

每个步骤执行时，遵循以下格式：
```
开始执行第X步: [步骤名称]
...执行过程内容...
完成执行第X步: [步骤名称] - [成功/失败]
```

## 6. 注意事项
1. **中断处理**: 若有一步产生错误，严格根据错误的要求进行后续处理。
2. **严格顺序执行**：必须逐一按照顺序执行步骤，如果因为A步骤的错误返回之前的B步骤，则从B步骤重新开始顺序执行

## 7. 验证质量标准
- **Lint**: 所有模块必须通过 Verilator --lint-only 检查。
- **RV32I**: 必须通过RV32I规范检查
- **C++**: testbench编译通过。
- **输出格式**: `[TEST id] Op: ... | expect: ... got: ... | PASS/FAIL`，输出结果中无FAIL。
