# Story 001: 生命值与架势机制

> **Epic**: 生命值/防御系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/health-defense-system.md`
**Requirement**: `TR-health-def-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的节点系统实现生命值和架势值管理，利用信号机制处理状态变化

**Control Manifest Rules (this layer)**:
- Required: 生命值和架势值必须遵循GDD中定义的计算公式
- Forbidden: 禁止在单场战斗中自动恢复生命值（除非使用特定技能或道具）
- Guardrail: 架势值归零时必须触发破防状态

---

## Acceptance Criteria

*From GDD `design/gdd/health-defense-system.md`, scoped to this story:*

- [x] 实现生命值机制（HP条、归零即死亡）
- [x] 实现架势值机制（Poise条、破防状态）
- [x] 实现架势值受损和恢复机制
- [x] 实现破防状态触发和效果

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用HealthPoiseManager节点管理生命值和架势值
- 实现calculate_max_hp()方法计算最大生命值
- 实现calculate_max_poise()方法计算最大架势值
- 实现apply_damage_to_hp()方法处理生命值伤害
- 实现apply_damage_to_poise()方法处理架势值伤害
- 实现trigger_break_state()方法触发破防状态
- 与CombatSystem、DamageCalculationSystem、EquipmentSystem、CharacterProgressionSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 防御类型与减伤（处理护甲减伤、抗性减免等）
- Story 003: 恢复与状态效果（处理战斗内外恢复机制）
- UI显示（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现生命值机制
  - Given: 玩家角色受到攻击
  - When: 系统应用伤害到生命值
  - Then: 生命值正确减少，归零时触发死亡状态
  - Edge cases: 伤害溢出、生命值为0时的处理、负生命值处理

- **AC-2**: 实现架势值机制
  - Given: 玩家角色受到攻击
  - When: 系统应用伤害到架势值
  - Then: 架势值正确减少，归零时触发破防状态
  - Edge cases: 重攻击对架势值的额外削减、架势值恢复机制

- **AC-3**: 实现架势值受损和恢复机制
  - Given: 玩家角色在战斗中
  - When: 选择防御或蓄力指令
  - Then: 架势值按规则恢复
  - Edge cases: 战斗外自动恢复、回合结束时恢复

- **AC-4**: 实现破防状态触发和效果
  - Given: 角色架势值归零
  - When: 系统触发破防状态
  - Then: 角色无法行动，下一次伤害增加
  - Edge cases: 破防状态持续时间、破防后伤害加成

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/health_and_poise_mechanics_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (防御类型与减伤), Story 003 (恢复与状态效果)