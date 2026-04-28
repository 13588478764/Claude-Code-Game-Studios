# Story 001: 命中机制与概率

> **Epic**: 命中检测系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/hit-detection-system.md`
**Requirement**: `TR-hit-det-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的随机数生成器和数值计算系统实现命中概率判定

**Control Manifest Rules (this layer)**:
- Required: 命中率计算必须遵循GDD中定义的公式
- Forbidden: 禁止命中率超出5%-95%的范围
- Guardrail: 命中判定必须使用随机数生成器确保公平性

---

## Acceptance Criteria

*From GDD `design/gdd/hit-detection-system.md`, scoped to this story:*

- [x] 实现基础命中率计算（属性对抗概率）
- [x] 实现随机数判定机制
- [x] 实现强制命中检查机制
- [x] 实现命中结果反馈

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用HitDetectionManager节点管理命中检测逻辑
- 实现calculate_hit_chance()方法计算命中率
- 实现is_guaranteed_hit()方法检查强制命中条件
- 实现perform_hit_check()方法执行命中判定
- 实现get_hit_result()方法返回命中结果
- 与CombatSystem、DamageCalculationSystem、HealthDefenseSystem、EquipmentSystem、CharacterProgressionSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 影响因素与修正（处理角色属性、装备加成、状态效果等修正）
- Story 003: 检测类型与强制命中（处理普通攻击、技能、范围攻击等检测类型）
- UI显示（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现基础命中率计算
  - Given: 攻击方和防御方的身法属性
  - When: 系统计算命中率
  - Then: 正确应用属性对抗公式
  - Edge cases: 身法属性极值、相同身法值、身法差值极大

- **AC-2**: 实现随机数判定机制
  - Given: 计算出的命中率
  - When: 系统进行随机判定
  - Then: 基于概率正确判定是否命中
  - Edge cases: 100%命中率、0%命中率、边界值测试

- **AC-3**: 实现强制命中检查机制
  - Given: 特定状态或技能标签
  - When: 系统检查强制命中条件
  - Then: 正确识别强制命中情况
  - Edge cases: 多个强制命中条件同时满足、条件冲突

- **AC-4**: 实现命中结果反馈
  - Given: 命中判定完成
  - When: 系统返回结果
  - Then: 提供准确的命中/未命中信息
  - Edge cases: 强制命中与普通命中的区分、Miss时的反馈

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/hit_mechanics_and_probability_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (影响因素与修正), Story 003 (检测类型与强制命中)