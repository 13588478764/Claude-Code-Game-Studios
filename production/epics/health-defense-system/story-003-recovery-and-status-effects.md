# Story 003: 恢复与状态效果

> **Epic**: 生命值/防御系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/health-defense-system.md`
**Requirement**: `TR-health-def-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的计时器和状态机系统实现恢复机制和状态效果

**Control Manifest Rules (this layer)**:
- Required: 战斗内外恢复机制必须遵循GDD中定义的规则
- Forbidden: 禁止在单场战斗中自动恢复生命值（除非使用特定技能或道具）
- Guardrail: 状态效果必须有明确的持续时间或触发条件

---

## Acceptance Criteria

*From GDD `design/gdd/health-defense-system.md`, scoped to this story:*

- [x] 实现战斗内恢复机制（架势值恢复）
- [x] 实现战斗外恢复机制（HP和Poise自动恢复）
- [x] 实现休息点恢复机制（土地庙、客栈）
- [x] 实现状态效果管理（破防、濒死等）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用RecoveryStatusManager节点管理恢复和状态效果
- 实现combat_recovery_handler()方法处理战斗内恢复
- 实现out_of_combat_recovery_handler()方法处理战斗外恢复
- 实现rest_point_recovery_handler()方法处理休息点恢复
- 实现status_effect_manager()方法管理系统状态效果
- 实现apply_recovery_to_hp()方法应用HP恢复
- 实现apply_recovery_to_poise()方法应用Poise恢复
- 与CombatSystem、HealthPoiseManager、EquipmentSystem、CharacterProgressionSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 生命值与架势机制（处理HP和Poise机制）
- Story 002: 防御类型与减伤（处理防御机制）
- UI显示（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现战斗内恢复机制
  - Given: 玩家角色在战斗中
  - When: 回合结束或选择防御指令
  - Then: 架势值按规则恢复
  - Edge cases: 选择不同指令对恢复的影响、连续防御的效果

- **AC-2**: 实现战斗外恢复机制
  - Given: 玩家角色脱离战斗状态
  - When: 等待3-5秒后
  - Then: HP和Poise开始自动恢复
  - Edge cases: 战斗状态重新激活、恢复速度变化

- **AC-3**: 实现休息点恢复机制
  - Given: 玩家角色到达休息点
  - When: 选择休息操作
  - Then: 完全恢复所有状态并保存游戏
  - Edge cases: 休息点被敌人占据、休息过程被打断

- **AC-4**: 实现状态效果管理
  - Given: 角色进入不同状态
  - When: 状态条件满足
  - Then: 正确应用状态效果并管理持续时间
  - Edge cases: 状态叠加、状态冲突、状态持续时间结束

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/recovery_and_status_effects_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (生命值与架势机制), Story 002 (防御类型与减伤)
- Unlocks: None