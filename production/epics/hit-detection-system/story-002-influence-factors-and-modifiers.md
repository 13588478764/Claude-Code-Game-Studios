# Story 002: 影响因素与修正

> **Epic**: 命中检测系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/hit-detection-system.md`
**Requirement**: `TR-hit-det-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数值计算系统实现各种影响因素和修正值的计算

**Control Manifest Rules (this layer)**:
- Required: 所有影响因素修正必须遵循GDD中定义的公式
- Forbidden: 禁止修正值导致命中率超出5%-95%的范围
- Guardrail: 修正值计算必须考虑多种因素的叠加效果

---

## Acceptance Criteria

*From GDD `design/gdd/hit-detection-system.md`, scoped to this story:*

- [x] 实现角色属性影响（身法、福缘）
- [x] 实现装备加成影响（武器、饰品）
- [x] 实现状态效果影响（增益、减益）
- [x] 实现武学特性影响（范围攻击、远程攻击）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用HitDetectionManager节点管理命中检测逻辑
- 实现calculate_stat_modifiers()方法计算角色属性修正
- 实现calculate_equipment_modifiers()方法计算装备加成修正
- 实现calculate_status_modifiers()方法计算状态效果修正
- 实现calculate_skill_modifiers()方法计算武学特性修正
- 与CombatSystem、EquipmentSystem、CharacterProgressionSystem、StatusEffectSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 命中机制与概率（处理基础命中率计算和随机判定）
- Story 003: 检测类型与强制命中（处理普通攻击、技能、范围攻击等检测类型）
- UI显示（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现角色属性影响
  - Given: 攻击方和防御方的身法、福缘属性
  - When: 系统计算属性修正
  - Then: 正确应用身法和福缘对命中率的影响
  - Edge cases: 属性极值、福缘波动边界、身法系数变化

- **AC-2**: 实现装备加成影响
  - Given: 攻击方和防御方的装备
  - When: 系统计算装备修正
  - Then: 正确应用装备提供的命中/闪避修正
  - Edge cases: 多件装备加成叠加、装备特殊词条、武器命中修正

- **AC-3**: 实现状态效果影响
  - Given: 攻击方和防御方的状态效果
  - When: 系统计算状态修正
  - Then: 正确应用增益和减益对命中率的影响
  - Edge cases: 多个状态效果叠加、冲突状态效果、持续时间结束

- **AC-4**: 实现武学特性影响
  - Given: 使用的武学技能特性
  - When: 系统计算技能修正
  - Then: 正确应用范围攻击、远程攻击等特性修正
  - Edge cases: 范围攻击命中修正、远程攻击距离修正、技能标签影响

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/influence_factors_and_modifiers_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (命中机制与概率)
- Unlocks: Story 003 (检测类型与强制命中)