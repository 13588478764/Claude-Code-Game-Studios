# Story 002: 防御类型与减伤

> **Epic**: 生命值/防御系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/health-defense-system.md`
**Requirement**: `TR-health-def-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数值计算系统实现各种防御类型的减伤计算

**Control Manifest Rules (this layer)**:
- Required: 所有防御类型必须遵循GDD中定义的计算公式
- Forbidden: 禁止护甲值超过原始伤害时完全免疫伤害（最终伤害至少为1）
- Guardrail: 内力抗性必须限制在0.0-0.8范围内

---

## Acceptance Criteria

*From GDD `design/gdd/health-defense-system.md`, scoped to this story:*

- [x] 实现护甲减伤机制（固定减伤）
- [x] 实现内力抗性机制（百分比减伤）
- [x] 实现闪避规避机制（完全免伤）
- [x] 实现格挡减伤机制（主动减伤）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用DefenseMitigationManager节点管理各种防御类型
- 实现calculate_armor_reduction()方法计算护甲减伤
- 实现calculate_resistance_reduction()方法计算内力抗性减伤
- 实现calculate_dodge_chance()方法计算闪避概率
- 实现calculate_block_mitigation()方法计算格挡减伤
- 实现apply_defense_to_damage()方法应用所有防御效果
- 与CombatSystem、DamageCalculationSystem、EquipmentSystem、CharacterProgressionSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 生命值与架势机制（处理HP和Poise机制）
- Story 003: 恢复与状态效果（处理恢复机制）
- UI显示（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现护甲减伤机制
  - Given: 玩家角色具有护甲值
  - When: 系统计算护甲减伤
  - Then: 正确应用固定减伤公式
  - Edge cases: 护甲值超过原始伤害、护甲值为0、负护甲值

- **AC-2**: 实现内力抗性机制
  - Given: 玩家角色具有内力抗性
  - When: 系统计算内力抗性减伤
  - Then: 正确应用百分比减伤公式
  - Edge cases: 抗性超过80%、抗性为0、负抗性

- **AC-3**: 实现闪避规避机制
  - Given: 玩家角色具有闪避率
  - When: 系统判定闪避
  - Then: 基于概率决定是否完全免伤
  - Edge cases: 闪避率为0、闪避率接近100%、随机数边界值

- **AC-4**: 实现格挡减伤机制
  - Given: 玩家选择格挡指令
  - When: 系统计算格挡减伤
  - Then: 正确应用格挡减伤效果
  - Edge cases: 完美格挡、格挡失败、格挡后反击

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/defense_types_and_mitigation_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (生命值与架势机制)
- Unlocks: Story 003 (恢复与状态效果)