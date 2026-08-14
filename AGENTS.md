# AGENTS.md

This file provides guidance to the AI agent when working with code in this repository.

## 语言规范

- 与用户交流、文档、代码注释一律使用**简体中文**；代码标识符（类/变量/文件名）用英文。
- 术语映射：代码用 `martial_arts`（武学）、`encounter`（奇遇/仙缘）、`internal_energy`（内力）、`realm`（境界）；叙事文档用「修真功法」「仙缘」「修真界」。完整术语表见 `CLAUDE.md`。

## 项目概况

- Godot 4.6 + GDScript，修真武侠RPG《武侠奇遇录》。主场景 `src/scenes/ui/main_menu.tscn`。`godot` 已在 PATH（4.6.2）。
- 目标平台：Steam PC + iOS（UI 需适配 1920x1080 与 iOS 安全区/触摸）。
- 更细的规范见 `CLAUDE.md` 与 `.claude/docs/`（coding-standards、technical-preferences、directory-structure）。

## 架构要点

- 系统以 Autoload 单例注册（见 `project.godot` [autoload]：GameEvents、CharacterSystem、CombatSystem、QuestSystem、SaveSystem 等 20+ 个），跨系统调用直接引用这些全局名，不要重复新建管理器。
- 游戏数值必须数据驱动（`data/` 下的外部配置），不得硬编码。
- 每个新系统需在 `docs/architecture/` 留 ADR。
- 训练数据早于 Godot 4.6：使用引擎 API 前先查 `docs/engine-reference/godot/`，不要凭记忆猜签名。
- 美术资源经 `tools/` 脚本管线生成（规格在 `assets/specs/`，母版在 `assets/ui/_masters/`）。

## 测试

- 框架：GUT（`addons/gut`）。测试放 `tests/`（unit/integration/smoke/manual），不放 `src/`。
- 运行：`godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/unit -ginclude_subdirs -glog=1`（集成测试换成 `-gdir=tests/integration`）。必须带 `-ginclude_subdirs`，否则只跑顶层脚本、漏掉各子系统目录。
- 命名：文件 `[system]_[feature]_test.gd`；函数 `test_[scenario]_[expected]`。
- 格式化/lint：`~/.qoder/gdtools/bin/gdformat <file>` / `gdlint <file>`（编辑后的 .gd 会被 hook 自动格式化；勿批量重排存量代码，会产生大量无关 diff）。
- 逻辑/集成类改动必须有通过的自动化测试；UI 改动用截图验证。测试必须确定性、互相独立、自建自清状态。

## 协作协议（重要）

- 遵循 问题 → 选项 → 决策 → 草案 → 批准 流程；写入/修改文件前先征得用户同意；未经用户指示不得 commit/push。
- gameplay 系统先写测试（验证驱动开发）。

## Git 约定

- Conventional Commits + 中文描述，如 `feat: 敌人种类扩充 + 技能系统`、`fix: 主线任务连续接取导致无限升级`。
- commit 信息尽量关联对应故事 ID 或设计文档。
- main/develop 受保护：CI（`.github/workflows/tests.yml`）跑 GUT 测试，不过不许合入；不得跳过或禁用失败测试让 CI 通过。
