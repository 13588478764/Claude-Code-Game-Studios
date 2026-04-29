# Story 002: 战斗菜单交互

> **Epic**: 战斗UI系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: UI
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/combat-ui.md`
**Requirement**: `TR-combat-ui-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的输入系统处理菜单交互，利用信号系统传递用户选择

**Control Manifest Rules (this layer)**:
- Required: 菜单交互必须响应迅速，按键延迟不超过100ms
- Forbidden: 禁止在战斗动画播放期间接受输入
- Guardrail: 菜单交互不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/combat-ui.md`, scoped to this story:*

- [x] 武学指令菜单正常显示（技能列表、消耗、冷却）
- [x] 目标选择光标正确工作（高亮、切换、确认）
- [x] 键盘快捷键正常（WASD移动、Enter确认、Esc取消）
- [x] 鼠标交互正常（悬停预览、点击选择）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用CombatMenuManager节点管理战斗菜单交互
- 实现show_martial_arts_menu(skill_data)方法显示武学菜单
- 实现handle_target_selection(target_data)方法处理目标选择
- 实现process_input(input_event)方法处理用户输入
- 实现menu_interaction_completed信号通知战斗系统
- 与CombatSystem、MartialArtsSystem和InputManager系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 战斗HUD显示（处理HUD元素显示）
- Story 003: 战斗反馈系统（处理特效和音效反馈）
- 核心战斗逻辑（由战斗系统处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For UI stories — evidence specs]:**

- **AC-1**: 武学指令菜单正常显示
  - Given: 轮到玩家行动
  - When: 武学指令菜单弹出
  - Then: 显示可用技能及其消耗、冷却信息
  - Edge cases: 无可用技能、技能数量过多、特殊状态限制

- **AC-2**: 目标选择光标正确工作
  - Given: 玩家选择攻击技能
  - When: 目标选择模式激活
  - Then: 可选目标被高亮，可通过WASD切换
  - Edge cases: 无有效目标、友军目标、范围技能目标

- **AC-3**: 键盘快捷键正常
  - Given: 战斗菜单激活
  - When: 玩家按下WASD键
  - Then: 光标在菜单项间正确移动
  - Edge cases: 组合键、长按、按键冲突

- **AC-4**: 鼠标交互正常
  - Given: 鼠标悬停在技能图标上
  - When: 悬停时间超过0.5秒
  - Then: 显示技能详细描述
  - Edge cases: 移动设备、高DPI屏幕、多显示器

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- Evidence: `production/qa/evidence/combat-menu-interactions-evidence.md` — manual test walkthrough and sign-off

**Status**: [ ] Pending

---

## Dependencies

- Depends on: Story 001 (战斗HUD显示)
- Unlocks: Story 003 (战斗反馈系统)