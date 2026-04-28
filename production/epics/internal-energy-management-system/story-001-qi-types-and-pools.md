# Story 001: 内力类型与池

> **Epic**: 内力/能量管理系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/internal-energy-management-system.md`
**Requirement**: `TR-int-energy-mgmt-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的Resource系统实现内力数据管理，利用信号机制处理状态变化

**Control Manifest Rules (this layer)**:
- Required: 内力池必须遵循GDD中定义的计算公式
- Forbidden: 禁止内力值超出0到最大内力的范围
- Guardrail: 内力池变化必须触发UI更新

---

## Acceptance Criteria

*From GDD `design/gdd/internal-energy-management-system.md`, scoped to this story:*

- [x] 实现统一内力池（Qi）
- [x] 实现先天真气（Passive Qi）
- [x] 实现后天精气（Active Qi）
- [x] 实现属性差异体现

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用QiManager节点管理内力系统
- 实现initialize_qi_pool()方法初始化内力池
- 实现get_current_qi()方法获取当前内力值
- 实现get_max_qi()方法获取最大内力值
- 实现set_qi_value()方法设置内力值
- 与MartialArtsSystem、CombatSystem、CharacterProgressionSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 恢复机制（处理战斗内外恢复机制）
- Story 003: 消耗机制（处理技能消耗和连招递增）
- UI显示（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现统一内力池
  - Given: 玩家角色具有内力属性
  - When: 系统初始化或查询内力值
  - Then: 正确返回当前内力值和最大内力值
  - Edge cases: 内力值为0、内力值为最大值、内力值超出范围

- **AC-2**: 实现先天真气
  - Given: 玩家角色存在
  - When: 系统计算基础内力值
  - Then: 正确应用角色属性对基础内力的影响
  - Edge cases: 属性极值、属性为0、属性修正系数边界

- **AC-3**: 实现后天精气
  - Given: 玩家角色存在
  - When: 系统计算额外内力值
  - Then: 正确应用装备和技能对额外内力的影响
  - Edge cases: 装备加成为0、装备加成极值、技能效果叠加

- **AC-4**: 实现属性差异体现
  - Given: 不同属性的角色
  - When: 系统计算内力相关数值
  - Then: 正确体现不同属性对内力系统的影响
  - Edge cases: 不同武学标签、属性修正边界值、境界差异

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/qi_types_and_pools_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (恢复机制), Story 003 (消耗机制)