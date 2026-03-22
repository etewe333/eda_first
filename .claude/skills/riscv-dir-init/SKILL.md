---
name: riscv-dir-init
description: RISC-V RTL 目录初始化技能。当需要创建规范定义的文件夹结构时使用此技能，这是RISC-V RTL自动化流水线的第2步。
---

## 技能功能

按照 CLAUDE.md 中的架构约定创建以下目录结构：

### 核心目录
- `src/main/scala/` - Chisel 源码目录
- `generated/` - RTL 产物目录

### 仿真相关目录
- `sim/testbench/` - Testbench 文件目录
- `sim/build/` - 仿真产物目录
- `sim/logs/` - 仿真日志目录

### 配置和日志目录
- `.claude/` - 环境配置目录（已存在）
- `agent/logs/` - Agent 日志目录

## 执行步骤

**开始执行第2步: 目录初始化**

1. **检查并创建核心目录**：
   - 创建 `src/main/scala/`（如果不存在）
   - 创建 `generated/`（如果不存在）

2. **检查并创建仿真目录**：
   - 创建 `sim/testbench/`（如果不存在）
   - 创建 `sim/build/`（如果不存在）
   - 创建 `sim/logs/`（如果不存在）

3. **检查并创建日志目录**：
   - 创建 `agent/logs/`（如果不存在）

4. **验证目录结构**：
   - 检查所有目录是否成功创建
   - 验证目录权限

**完成执行第2步: 目录初始化 - [成功/失败]**

## 目录结构说明

```
项目根目录/
├── .claude/                    # 环境配置
│   ├── env_info.json          # 环境信息文件
│   └── skills/                # 技能目录
├── src/main/scala/            # Chisel 源码
├── generated/                 # RTL 产物（Verilog文件）
├── sim/
│   ├── testbench/             # Testbench 文件
│   ├── build/                 # 仿真产物
│   └── logs/                  # 仿真日志
└── agent/logs/                # Agent 日志
```

## 输出示例

```
开始执行第2步: 目录初始化
创建 src/main/scala/... ✓
创建 generated/... ✓
创建 sim/testbench/... ✓
创建 sim/build/... ✓
创建 sim/logs/... ✓
创建 agent/logs/... ✓
所有目录创建成功
完成执行第2步: 目录初始化 - 成功
```

## 错误处理

如果目录创建失败，终止对话，输出：
```
完成执行第2步: 目录初始化 - 失败
原因: [具体原因，如权限不足、磁盘空间不足等]
```

## 注意事项

1. 使用 `-p` 参数确保创建完整的目录路径
2. 如果目录已存在，不视为错误
3. 检查目录创建后的权限和可访问性

## 相关技能

- `riscv-env-check` - 环境检查技能（上一步）
- `riscv-code-generate` - 代码生成技能（下一步）