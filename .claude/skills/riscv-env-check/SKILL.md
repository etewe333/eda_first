---
name: riscv-env-check
description: RISC-V RTL 环境自适应探测技能。当需要探测环境配置和工具链时使用此技能，包括环境指纹校验和工具版本检查。这是RISC-V RTL自动化流水线的第1步。
---

# RISC-V RTL 环境自适应探测技能

此技能执行环境自适应探测，包括环境指纹校验和工具检查，对应 CLAUDE.md 中自动化指令流水线的第1步。

## 技能功能

**环境自适应探测** - 自动化探测和验证硬件设计环境：
1. **环境指纹校验** - 检查 `.claude/env_info.json` 文件，验证环境配置
2. **工具检查** - 检查 node、java、sbt、firtool、verilator 工具是否可用

## 执行步骤

**开始执行环境自适应探测**

### 子步骤1: 环境指纹校验

1. **读取环境信息文件**：
   - 尝试读取 `.claude/env_info.json`
   - 如果文件不存在，视为环境已变化

2. **失效判定**：
   - 运行`check_env.ps1`，判断环境是否变化

3. **处理结果**：
   - 如果校验通过：读取 .claude/env_info.json 并将其内容作为后续所有步骤的上下文参数。
   - 如果环境已变化：运行 `detect_env.ps1`，如果运行结果失败则中断对话
   根据运行结果提醒verilator或msys2未正确安装

### 子步骤2: 工具检查

依次检查以下工具：

1. **node**: 使用 `node --version`
2. **java**: 使用 `java --version`
3. **sbt**: 使用 `sbt --version`
4. **firtool**: 使用 `firtool --version`
5. **verilator**: 使用
```
"$msys_root\usr\bin\bash.exe" --login -c "export PATH='/$($msystem.ToLower())/bin:/usr/bin:`$PATH' && export LC_ALL=C && verilator --version"
```
命令进行检查

**注意事项**：
- 注意所有相关脚本均放置在.claude/scripts文件夹中
- 如果跳出系统未找到指定路径不予理会，只要跳出版本号就说明配置无问题
- 如果发现存在工具未配置，不要进行安装，应当结束会话告诉用户遗漏了哪些工具

**完成执行环境自适应探测 - [成功/失败]**

## 环境变量要求

从 `.claude/env_info.json` 读取以下变量：
- `msys_root`: MSYS2 安装根目录
- `msystem`: MSYS2 系统类型 (如 MINGW64)
- `computer_name`: 计算机名
- `user_name`: 用户名
- `proj_root`: 项目根目录

## 输出示例

```
开始执行第1步: 环境指纹校验
检查 .claude/env_info.json 文件... 存在
执行 check_env.ps1...环境指纹校验通过
执行
完成执行第1步: 环境指纹校验 - 成功

开始执行第2步: 工具检查
检查 node... v18.17.1 ✓
检查 java... openjdk 11.0.23 ✓
检查 sbt... sbt version 1.12.5 ✓
检查 firtool... firtool-1.142.0 ✓
检查 verilator... Verilator 5.040 ✓
所有工具检查通过
完成执行第2步: 工具检查 - 成功
```

## 错误处理

如果环境检查失败，终止对话并输出：
```
完成执行第X步: [步骤名称] - 失败
原因: [具体原因]
建议: [解决建议]
```

## 相关技能

- `riscv-pipeline-main` - 主协调技能
- `riscv-dir-init` - 目录初始化技能（下一步）