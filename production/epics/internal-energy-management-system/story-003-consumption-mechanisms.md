# Story 003: 消耗机制

> **Epic**: 内力/能量管理系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/internal-energy-management-system.md`
**Requirement**: `TR-int-energy-mgmt-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数值计算系统实现技能消耗和连招递增机制

**Control Manifest Rules (this layer)**:
- Required: 消耗机制必须遵循GDD中定义的公式
- Forbidden: 禁止消耗值导致内力值为负数
- Guardrail: 消耗过程必须有明确的验证和反馈

---

## Acceptance Criteria

*From GDD `design/gdd/internal-energy-management-system.md`, scoped to this story:*

- [x] 实现固定基础消耗
- [x] 实现连招递增消耗
- [x] 实现属性修正
- [x] 实现过载机制

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用QiManager节点管理内力系统
- 实现consume_qi()方法处理内力消耗
- 实现calculate_combo_scaling()方法计算连招递增消耗
- 实现apply_stat_modifiers()方法应用属性修正
- 实现overload_mechanism()方法处理过载机制
- 与MartialArtsSystem、CombatSystem、CharacterProgressionSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 内力类型与池（处理内力池定义）
- Story 002: 恢复机制（处理战斗内外恢复机制）
- UI显示（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现固定基础消耗
  - Given: 玩家角色尝试使用武学技能
  - When: 系统计算技能消耗
  - Then: 正确应用技能的基础内力消耗
  - Edge cases: 基础消耗为0、基础消耗为最大值、消耗值边界测试

- **AC-2**: 实现连招递增消耗
  - Given: 玩家角色在同回合内连续使用技能
  - When: 系统计算连招消耗
  - Then: 正确应用连招递增消耗公式
  - Edge cases: 连招次数为0、连招次数极大值、递增系数边界

- **AC-3**: 实现属性修正
  - Given: 玩家角色具有特定属性
  - When: 系统计算消耗修正
  - Then: 正确应用属性对消耗的影响
  - Edge cases: 属性修正系数为0、修正系数为极值、境界压制效果

- **AC-4**: 实现过载机制
  - Given: 玩家角色内力不足但尝试使用技能
  - When: 系统处理过载请求
  - Then: 正确应用过载机制消耗生命值
  - Edge cases: 生命值不足、过载转换率边界、过载后虚弱状态

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/consumption_mechanisms_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (内力类型与池), Story 002 (恢复机制)
- Unlocks: None