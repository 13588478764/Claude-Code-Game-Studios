# Story 001: 物品数据结构定义

> **Epic**: 物品数据库
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/item-database.md`
**Requirement**: `TR-item-db-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的Resource系统定义物品数据结构

**Control Manifest Rules (this layer)**:
- Required: 物品数据结构必须遵循GDD中定义的属性
- Forbidden: 禁止在基础数据结构中添加业务逻辑
- Guardrail: 数据结构变更必须向后兼容

---

## Acceptance Criteria

*From GDD `design/gdd/item-database.md`, scoped to this story:*

- [x] 实现物品核心属性（ID、名称、描述、图标、稀有度等）
- [x] 实现装备特有属性（部位、基础属性、词缀等）
- [x] 实现消耗品特有属性（效果类型、数值、持续时间等）
- [x] 实现任务道具特有属性（任务ID、消耗性等）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用Godot的Resource系统定义ItemData基类
- 实现EquipmentData继承自ItemData
- 实现ConsumableData继承自ItemData
- 实现QuestItemData继承自ItemData
- 与UI系统、装备系统、武学系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 物品属性存储（处理数据持久化）
- Story 003: 数据访问接口（处理数据查询和检索）
- UI显示（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现物品核心属性
  - Given: 定义一个新的物品
  - When: 创建物品数据实例
  - Then: 正确包含ID、名称、描述、图标、稀有度等属性
  - Edge cases: 空字符串、无效图标、超出范围的稀有度值

- **AC-2**: 实现装备特有属性
  - Given: 定义一个新的装备
  - When: 创建装备数据实例
  - Then: 正确包含部位、基础属性、词缀等特有属性
  - Edge cases: 无效装备部位、负数属性值、空词缀数组

- **AC-3**: 实现消耗品特有属性
  - Given: 定义一个新的消耗品
  - When: 创建消耗品数据实例
  - Then: 正确包含效果类型、数值、持续时间等特有属性
  - Edge cases: 无效效果类型、负数效果值、负数持续时间

- **AC-4**: 实现任务道具特有属性
  - Given: 定义一个新的任务道具
  - When: 创建任务道具数据实例
  - Then: 正确包含任务ID、消耗性等特有属性
  - Edge cases: 空任务ID、无效布尔值

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/data/item_data_structures_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (物品属性存储), Story 003 (数据访问接口)