# Story 003: 装备属性计算

> **Epic**: 装备系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/equipment-system.md`
**Requirement**: `TR-equipment-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理属性变更事件，利用内置数学函数实现属性计算

**Control Manifest Rules (this layer)**:
- Required: 装备属性计算必须基于公式，确保可预测性
- Forbidden: 禁止硬编码属性值，必须使用配置或公式
- Guardrail: 属性计算不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/equipment-system.md`, scoped to this story:*

- [x] 装备基础属性计算正确（装备属性计算公式）
- [x] 强化属性加成正常（强化成功率公式）
- [x] 宝石套装效果计算正确（套装共鸣激活公式）
- [x] 装备流派加成正常（武学兼容性）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用EquipmentAttributeCalculator节点管理所有属性计算
- 实现calculate_base_attributes(equipment_data)方法计算基础属性
- 实现calculate_enhancement_bonus(equipment_data, enhancement_level)方法计算强化加成
- 实现calculate_gem_effects(equipment_data)方法计算宝石效果
- 实现calculate_school_bonus(equipment_data, martial_art_school)方法计算流派加成
- 实现attributes_calculated信号通知其他系统属性变更
- 与BattleManager、MartialArtsManager和CharacterStats系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 装备管理功能（处理装备存储和筛选）
- Story 002: 装备穿戴系统（处理装备穿戴逻辑）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 装备基础属性计算正确
  - Given: 一件上品剑（基础攻击力50-70），强化等级+10
  - When: 计算最终攻击力
  - Then: 最终攻击力 = 60 × (1 + 0.03 × 10) = 78（假设强化倍率为0.03）
  - Edge cases: 不同品阶、不同强化等级、附加词条

- **AC-2**: 强化属性加成正常
  - Given: 装备强化等级为+15
  - When: 计算强化成功率
  - Then: 强化成功率为60%（衰减系数0.04）
  - Edge cases: 不同强化等级、不同衰减系数、保护符使用

- **AC-3**: 宝石套装效果计算正确
  - Given: 全身装备嵌入6颗红色宝石
  - When: 检查套装效果
  - Then: 激活"6红套装效果"：所有攻击附带小火球
  - Edge cases: 不同颜色宝石、不同数量、混合套装

- **AC-4**: 装备流派加成正常
  - Given: 玩家装备武当派专用装备，使用武当武学
  - When: 计算最终属性
  - Then: 装备属性额外+20%
  - Edge cases: 不匹配流派、多重加成、装备特效

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/equipment/equipment_attribute_calculation_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (装备管理功能), Story 002 (装备穿戴系统)
- Unlocks: None