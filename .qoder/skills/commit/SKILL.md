---
name: commit
description: 按仓库约定创建中文 Conventional Commit。仅在用户显式调用 /commit 时使用。
disable-model-invocation: true
---

按仓库 Git 约定生成并执行一次提交。$ARGUMENTS 可选，为额外的提交说明要点。

## 步骤

1. `git status` + `git diff --cached --stat` 查看已暂存内容；若无暂存文件，列出改动文件并向用户确认要暂存哪些，不要自行 `git add -A`。
2. `git log --oneline -10` 对齐既有风格。
3. 起草 commit message，规则：
   - Conventional Commits 前缀：feat / fix / refactor / test / docs / chore / asset-pipeline
   - 冒号后用**简体中文**概括，聚焦"为什么"而非罗列文件
   - 参考风格：`feat: 敌人种类扩充 + 技能系统`、`fix: 主线任务连续接取导致无限升级`
   - 能关联故事 ID 或设计文档时在 body 中注明（如 `Refs: design/gdd/xxx.md`）
4. 向用户展示草稿，获得明确同意后再执行 `git commit`（HEREDOC 传 message）。
5. 未经用户指示不得 push。
