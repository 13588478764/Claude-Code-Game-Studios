# Story 002: 恢复机制

> **Epic**: 内力/能量管理系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/internal-energy-management-system.md`
**Requirement**: `TR-int-energy-mgmt-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的计时器系统实现战斗内外恢复机制

**Control Manifest Rules (this layer)**:
- Required: 恢复机制必须遵循GDD中定义的公式
- Forbidden: 禁止恢复速度超过最大内力的200%
- Guardrail: 恢复过程必须有明确的视觉反馈

---

## Acceptance Criteria

*From GDD `design/gdd/internal-energy-management-system.md`, scoped to this story:*

- [x] 实现战斗内恢复（自然回复、行动回收、道具/技能）
- [x] 实现战斗外恢复（自动满额、休息点、环境加成）
- [x] 实现恢复速度计算
- [x] 实现恢复效果反馈

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用QiManager节点管理内力系统
- 实现recover_qi_in_combat()方法处理战斗内恢复
- 实现recover_qi_out_of_combat()方法处理战斗外恢复
- 实现calculate_recovery_amount()方法计算恢复量
- 实现apply_recovery_bonus()方法应用恢复加成
- 与CombatSystem、ItemDatabase、MartialArtsSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 内力类型与池（处理内力池定义）
- Story 003: 消耗机制（处理技能消耗和连招递增）
- UI显示（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现战斗内恢复
  - Given: 玩家角色在战斗中
  - When: 回合结束或执行特定行动
  - Then: 正确应用自然回复和行动回收机制
  - Edge cases: 悟性属性极值、回合结束恢复、行动回收量边界

- **AC-2**: 实现战斗外恢复
  - Given: 玩家角色脱离战斗状态
  - When: 等待3秒后或到达休息点
  - Then: 正确应用自动恢复和休息点恢复机制
  - Edge cases: 战斗状态重新激活、休息点恢复速度、环境加成叠加

- **AC-3**: 实现恢复速度计算
  - Given: 玩家角色具有特定属性
  - When: 系统计算恢复速度
  - Then: 正确应用属性修正和环境加成
  - Edge cases: 恢复速度上限、属性修正边界、环境加成极值

- **AC-4**: 实现恢复效果反馈
  - Given: 内力恢复发生
  - When: 系统处理恢复效果
  - Then: 提供准确的恢复反馈信息
  - Edge cases: 恢复量为0、恢复量达到最大值、恢复过程中的状态变化

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/recovery_mechanisms_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (内力类型与池)
- Unlocks: Story 003 (消耗机制)