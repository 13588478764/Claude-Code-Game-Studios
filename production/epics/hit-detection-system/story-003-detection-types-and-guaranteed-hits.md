# Story 003: 检测类型与强制命中

> **Epic**: 命中检测系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/hit-detection-system.md`
**Requirement**: `TR-hit-det-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数值计算系统实现不同检测类型和强制命中机制

**Control Manifest Rules (this layer)**:
- Required: 所有检测类型必须遵循GDD中定义的规则
- Forbidden: 禁止绕过强制命中检查机制
- Guardrail: 不同检测类型应有明确的区分和处理逻辑

---

## Acceptance Criteria

*From GDD `design/gdd/hit-detection-system.md`, scoped to this story:*

- [x] 实现普通攻击命中检测
- [x] 实现技能命中检测（单体、范围、持续）
- [x] 实现反击/连携命中检测
- [x] 实现强制命中机制

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用HitDetectionManager节点管理命中检测逻辑
- 实现check_basic_attack_hit()方法处理普通攻击命中
- 实现check_skill_hit()方法处理技能命中（单体、范围、持续）
- 实现check_counter_link_hit()方法处理反击/连携命中
- 实现check_guaranteed_hit_conditions()方法检查强制命中条件
- 与CombatSystem、DamageCalculationSystem、HealthDefenseSystem、EquipmentSystem、CharacterProgressionSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 命中机制与概率（处理基础命中率计算和随机判定）
- Story 002: 影响因素与修正（处理角色属性、装备加成、状态效果等修正）
- UI显示（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现普通攻击命中检测
  - Given: 玩家使用普通攻击
  - When: 系统进行命中检测
  - Then: 正确应用普通攻击命中规则
  - Edge cases: 不同武器类型、攻击距离、基础命中率

- **AC-2**: 实现技能命中检测
  - Given: 玩家使用技能攻击
  - When: 系统进行命中检测
  - Then: 正确区分单体、范围、持续技能并应用相应规则
  - Edge cases: 范围技能对多个目标独立检测、持续技能首次命中后无需再次检测

- **AC-3**: 实现反击/连携命中检测
  - Given: 触发反击或连携攻击
  - When: 系统进行命中检测
  - Then: 正确应用反击/连携命中规则
  - Edge cases: 反击命中加成、连携触发条件、队友位置

- **AC-4**: 实现强制命中机制
  - Given: 满足强制命中条件
  - When: 系统进行命中检测
  - Then: 无视闪避率直接判定为命中
  - Edge cases: 破防状态、眩晕状态、冻结状态、Sure_Hit标签

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/detection_types_and_guaranteed_hits_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (命中机制与概率), Story 002 (影响因素与修正)
- Unlocks: None