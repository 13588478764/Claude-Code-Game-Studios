# Story 003: 连招效果计算

> **Epic**: 武学组合/连招系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/martial-arts-combo-system.md`
**Requirement**: `TR-martial-arts-combo-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，战斗系统实现

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理效果计算事件，通过计算函数实现连招效果

**Control Manifest Rules (this layer)**:
- Required: 连招效果计算必须与战斗系统和状态效果系统正确集成
- Forbidden: 禁止绕过效果计算公式直接修改战斗数值
- Guardrail: 效果计算不应超过性能预算（<2ms处理时间）

---

## Acceptance Criteria

*From GDD `design/gdd/martial-arts-combo-system.md`, scoped to this story:*

- [x] 连招效果计算遵循公式：`协同伤害 = 基础伤害 × 协同倍率`
- [x] 内力回流机制正常工作，遵循公式：`返还内力 = 消耗内力 × 回流比例`
- [x] 连携槽积累机制正常工作，遵循公式：`连携槽增加 = 基础增量 × 连招等级系数`
- [x] 状态升级持续时间计算正常工作，遵循公式：`升级持续时间 = 基础持续时间 × 升级倍率`

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现连招效果计算函数，遵循GDD中的公式
- 通过信号系统通知战斗系统效果变更
- 实现内力回流和连携槽管理计算
- 集成连招效果与战斗系统的伤害计算接口

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 武功组合机制：由Story 001处理
- 连招系统：由Story 002处理
- 连招UI界面：由UI故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 连招效果计算遵循公式
  - Given: 基础伤害为100，协同倍率为2.0
  - When: 触发协同连招
  - Then: 协同伤害为200（100×2.0）
  - Edge cases: 检查不同基础伤害和倍率的组合

- **AC-2**: 内力回流机制正常工作
  - Given: 消耗内力为30，回流比例为0.3
  - When: 成功触发连招
  - Then: 返还内力为9（30×0.3）
  - Edge cases: 检查不同消耗和比例的组合

- **AC-3**: 连携槽积累机制正常工作
  - Given: 基础增量为20，连招等级系数为1.5
  - When: 执行连招
  - Then: 连携槽增加30（20×1.5）
  - Edge cases: 检查不同增量和系数的组合

- **AC-4**: 状态升级持续时间计算正常工作
  - Given: 基础持续时间为2，升级倍率为1.5
  - When: 状态升级
  - Then: 升级持续时间为3（2×1.5）
  - Edge cases: 检查不同基础时间和倍率的组合

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/martial_arts_combo/combo_effect_calculation_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001: 武功组合机制, Story 002: 连招系统
- Unlocks: None