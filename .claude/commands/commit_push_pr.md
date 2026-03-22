# Skill: Submit Code Workflow

## 目标
自动完成代码提交、推送的标准化流程。

## 执行步骤
1. **分析变更**: 运行 `git diff --staged`。如果暂存区为空，提醒用户先执行 `git add`。
2. **生成信息**: 根据变更内容，生成符合 Conventional Commits 规范的提交信息：
   - 格式：`<type>(scope): <中文描述>` (例如: `feat(ui): 增加登录按钮`)
   - 必须包含：变更摘要、测试建议。
3. **执行提交**: 运行 `git commit -m "<message>"`。
4. **推送代码**: 运行 `git push origin HEAD`。如果失败（如远程有更新），提示用户执行 `git pull --rebase`。

## 异常处理
- 如果用户提供了额外说明 `$ARGUMENTS`，将其融入 PR 正文。
- 如果 Diff 过大，请先对变更进行分类总结。