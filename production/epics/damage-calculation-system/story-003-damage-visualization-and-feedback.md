# Story 003: 伤害可视化与反馈

> **Epic**: 伤害计算系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: UI
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/damage-calculation-system.md`
**Requirement**: `TR-dmg-calc-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的UI系统和粒子系统提供伤害可视化，利用音频系统提供反馈

**Control Manifest Rules (this layer)**:
- Required: 伤害反馈必须与伤害事件同步，延迟不超过50ms
- Forbidden: 禁止播放过多特效导致性能下降
- Guardrail: 可视化系统不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/damage-calculation-system.md`, scoped to this story:*

- [x] 伤害数字颜色正确（不同伤害类型对应不同颜色）
- [x] 暴击特效正常（数字放大、闪烁金色）
- [x] 伤害预览功能正常（战斗菜单中的预估值）
- [x] 详细伤害分解界面（显示完整计算过程）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用DamageVisualizationManager节点管理伤害可视化效果
- 实现show_damage_number(damage_value, damage_type, is_critical)方法显示伤害数字
- 实现show_damage_preview(expected_damage)方法显示伤害预览
- 实现show_detailed_damage_breakdown(damage_data)方法显示详细分解
- 实现play_damage_feedback(damage_type, is_critical)方法播放特效和音效
- 实现damage_visualized信号通知其他系统
- 与CombatSystem、UISystem和AudioSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 伤害类型与公式（处理基础伤害计算）
- Story 002: 伤害倍率与修正（处理乘法修正系数）
- 核心战斗逻辑（由战斗系统处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For UI stories — evidence specs]:**

- **AC-1**: 伤害数字颜色正确
  - Given: 角色受到外功伤害
  - When: 伤害计算完成
  - Then: 伤害数字显示为白色
  - Edge cases: 内功伤害（蓝色）、暴击（金色）、真实伤害（红色）

- **AC-2**: 暴击特效正常
  - Given: 玩家触发暴击
  - When: 伤害数字显示
  - Then: 数字放大并闪烁金色
  - Edge cases: 不同暴击倍数、连续暴击、屏幕空间限制

- **AC-3**: 伤害预览功能正常
  - Given: 玩家在战斗菜单选中技能
  - When: 查看技能描述
  - Then: 显示"对当前目标造成约XXX点伤害"
  - Edge cases: 多个目标、不同状态、装备变化

- **AC-4**: 详细伤害分解界面
  - Given: 玩家开启伤害分解界面
  - When: 查看伤害计算过程
  - Then: 显示完整的伤害计算步骤和系数
  - Edge cases: 复杂计算、性能影响、界面布局

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- Evidence: `production/qa/evidence/damage-visualization-and-feedback-evidence.md` — must exist and pass

**Status**: [x] Completed

---

## Dependencies

- Depends on: Story 001 (伤害类型与公式), Story 002 (伤害倍率与修正)
- Unlocks: None