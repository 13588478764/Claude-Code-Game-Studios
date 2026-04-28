# Story 001: 数据结构与存储

> **Epic**: 成长数据保存
> **Status**: Pending Test
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/growth-data-persistence.md`
**Requirement**: `TR-grow-data-pers-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数据结构定义成长数据，利用文件系统实现存储功能

**Control Manifest Rules (this layer)**:
- Required: 数据结构必须遵循GDD中定义的格式规范
- Forbidden: 禁止在数据结构中使用硬编码的特殊值
- Guardrail: 存储操作不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/growth-data-persistence.md`, scoped to this story:*

- [x] 成长数据结构正确实现（等级、境界、经验值等）
- [x] 属性分配数据结构正确实现（六维属性、重置次数等）
- [x] 技能学习数据结构正确实现（武学列表、熟练度等）
- [x] 存储格式正确实现（JSON格式、版本管理）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用GrowthDataStructureManager节点管理成长数据结构
- 实现define_growth_data_structure()方法定义成长数据结构
- 实现define_attribute_data_structure()方法定义属性分配数据结构
- 实现define_skill_data_structure()方法定义技能学习数据结构
- 实现define_equipment_data_structure()方法定义装备数据结构
- 实现define_encounter_data_structure()方法定义奇遇历史数据结构
- 实现data_structure_defined信号通知其他系统
- 与CharacterProgressionSystem、MartialArtsSystem、EquipmentSystem和EncounterSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 保存加载机制（处理保存和加载逻辑）
- Story 003: 数据完整性与安全（处理数据验证和安全机制）
- 实际保存/加载操作（由保存加载机制处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 成长数据结构正确实现
  - Given: 系统需要存储角色成长数据
  - When: 定义成长数据结构时
  - Then: 正确包含等级、境界、经验值等字段
  - Edge cases: 最大等级、最小等级、经验值溢出

- **AC-2**: 属性分配数据结构正确实现
  - Given: 系统需要存储属性分配数据
  - When: 定义属性数据结构时
  - Then: 正确包含六维属性、重置次数等字段
  - Edge cases: 属性上限、负值属性、重置次数限制

- **AC-3**: 技能学习数据结构正确实现
  - Given: 系统需要存储武学学习数据
  - When: 定义技能数据结构时
  - Then: 正确包含武学列表、熟练度等字段
  - Edge cases: 最大武学数量、熟练度上限、内功心法配置

- **AC-4**: 存储格式正确实现
  - Given: 系统需要保存成长数据
  - When: 选择存储格式时
  - Then: 使用JSON格式并包含版本管理
  - Edge cases: 版本兼容性、数据迁移、格式验证

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/persistence/data_structures_and_storage_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (保存加载机制), Story 003 (数据完整性与安全)