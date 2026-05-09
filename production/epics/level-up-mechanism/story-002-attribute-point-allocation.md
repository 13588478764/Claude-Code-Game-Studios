# Story 002: 属性点分配

> **Epic**: 等级提升机制
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/level-up-mechanism.md`
**Requirement**: `TR-level-up-mech-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号机制处理属性点分配事件

**Control Manifest Rules (this layer)**:
- Required: 属性点分配必须遵循GDD中定义的规则
- Forbidden: 禁止分配超出可用点数的属性点
- Guardrail: 属性点分配必须有验证和撤销机制

---

## Acceptance Criteria

*From GDD `design/gdd/level-up-mechanism.md`, scoped to this story:*

- [x] 实现自由属性点分配（每级5点）
- [x] 实现天赋点分配（每级1点）
- [x] 实现单属性限制（每级最多1点）
- [x] 实现重置机制（洗髓丹）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用LevelUpManager节点管理属性点分配逻辑
- 实现allocate_attribute_points()方法分配自由属性点
- 实现allocate_talent_points()方法分配天赋点
- 实现validate_allocation()方法验证分配有效性
- 实现reset_attributes()方法重置属性点
- 与CharacterProgressionSystem、UI系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 等级提升触发条件（处理等级提升逻辑）
- Story 003: 等级上限与突破（处理境界结构和上限）
- UI显示（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现自由属性点分配
  - Given: 玩家获得5个自由属性点
  - When: 分配属性点到不同属性
  - Then: 正确应用到力道(STR)、身法(AGI)、根骨(CON)、悟性(WIS)、定力(WIL)、福缘(LUK)
  - Edge cases: 分配超过可用点数、单属性分配超过限制、所有点数分配完毕

- **AC-2**: 实现天赋点分配
  - Given: 玩家获得1个天赋点
  - When: 分配天赋点
  - Then: 正确应用到天赋系统
  - Edge cases: 天赋点不足、天赋已满级、无效天赋选择

- **AC-3**: 实现单属性限制
  - Given: 玩家在当前级有属性点可分配
  - When: 尝试在单个属性上分配多点
  - Then: 限制每级最多分配1点到单个属性
  - Edge cases: 尝试分配2点或更多到单属性、不同级别的限制、跨级累计

- **AC-4**: 实现重置机制
  - Given: 玩家拥有洗髓丹道具
  - When: 使用洗髓丹重置属性点
  - Then: 重置已分配的自由属性点，返还给玩家
  - Edge cases: 没有洗髓丹道具、部分属性已使用、重置后重新分配

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/character/attribute_point_allocation_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (等级提升触发条件)
- Unlocks: Story 003 (等级上限与突破)