# Story 002: 伤害倍率与修正

> **Epic**: 伤害计算系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/damage-calculation-system.md`
**Requirement**: `TR-dmg-calc-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数学计算功能实现伤害修正，利用数据结构管理各种修正系数

**Control Manifest Rules (this layer)**:
- Required: 伤害修正必须遵循GDD中定义的乘法修正公式
- Forbidden: 禁止在修正计算中引入新的伤害来源
- Guardrail: 修正计算不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/damage-calculation-system.md`, scoped to this story:*

- [x] 暴击系数正确应用（1.5-2.0倍）
- [x] 连击系数正确应用（最高30%加成）
- [x] 弱点系数正确应用（1.5倍克制）
- [x] 状态效果修正正确（易伤、破防等）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用DamageMultiplierManager节点管理伤害倍率和修正
- 实现calculate_critical_multiplier(critical_chance, critical_damage)方法计算暴击系数
- 实现calculate_combo_multiplier(combo_count)方法计算连击系数
- 实现calculate_weakness_multiplier(attack_element, target_weakness)方法计算弱点系数
- 实现calculate_status_multiplier(status_effects)方法计算状态修正
- 实现multiplier_applied信号通知其他系统
- 与CombatSystem、StatusEffectSystem和MartialArtsSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 伤害类型与公式（处理基础伤害计算）
- Story 003: 伤害可视化与反馈（处理UI显示和特效）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 暴击系数正确应用
  - Given: 玩家触发暴击
  - When: 伤害计算系统应用修正系数
  - Then: 最终伤害乘以暴击系数（1.5-2.0）
  - Edge cases: 不同暴击倍数、暴击率计算、暴击伤害加成

- **AC-2**: 连击系数正确应用
  - Given: 玩家连击数达到3
  - When: 释放武学技能
  - Then: 伤害增加15%（每段5%）
  - Edge cases: 不同连击数、连击上限、连击中断

- **AC-3**: 弱点系数正确应用
  - Given: 玩家攻击敌人弱点属性
  - When: 伤害计算系统检测克制关系
  - Then: 伤害乘以1.5倍
  - Edge cases: 无克制关系、多重克制、元素相克

- **AC-4**: 状态效果修正正确
  - Given: 敌人处于易伤状态
  - When: 计算伤害
  - Then: 伤害增加20%-50%
  - Edge cases: 多种状态、状态叠加、状态冲突

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/damage_multipliers_and_corrections_test.gd` — must exist and pass

**Status**: [x] Completed

---

## Dependencies

- Depends on: Story 001 (伤害类型与公式)
- Unlocks: Story 003 (伤害可视化与反馈)