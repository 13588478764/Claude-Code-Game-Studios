# Story 002: 装备加成应用

> **Epic**: 装备属性计算
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/equipment-attribute-calculation.md`
**Requirement**: `TR-equip-attr-calc-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数据结构管理装备加成，利用数学计算实现叠加逻辑

**Control Manifest Rules (this layer)**:
- Required: 装备加成必须正确应用到角色属性上
- Forbidden: 禁止在加成应用中引入错误的叠加逻辑
- Guardrail: 加成应用不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/equipment-attribute-calculation.md`, scoped to this story:*

- [x] 装备特殊效果正确应用（武学技能增强、冷却缩减等）
- [x] 状态效果抗性正确计算（中毒、眩晕、冰冻等）
- [x] 同类属性线性叠加（多个装备的力道加成相加）
- [x] 百分比属性乘法叠加（暴击率等百分比属性）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用EquipmentBonusApplier节点管理装备加成应用逻辑
- 实现applySpecialEffects(equippedItems)方法应用装备特殊效果
- 实现calculateStatusResistances(equippedItems)方法计算状态抗性
- 实现applyLinearBonuses(equippedItems)方法处理线性叠加属性
- 实现applyMultiplicativeBonuses(equippedItems)方法处理乘法叠加属性
- 实现bonusApplied信号通知其他系统
- 与EquipmentSystem、StatusEffectSystem和MartialArtsSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 属性计算机制（处理基础属性和转换公式）
- Story 003: 元素属性计算（处理五行克制和元素伤害）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 装备特殊效果正确应用
  - Given: 玩家装备了增加武学技能效果的装备
  - When: 系统应用装备加成
  - Then: 武学技能效果正确增强
  - Edge cases: 多个同类效果、效果上限、负效果

- **AC-2**: 状态效果抗性正确计算
  - Given: 玩家装备了增加中毒抗性的装备
  - When: 系统计算状态抗性
  - Then: 中毒抗性正确增加
  - Edge cases: 多种抗性、抗性叠加、抗性上限

- **AC-3**: 同类属性线性叠加
  - Given: 玩家装备了多件增加力道的装备
  - When: 系统计算总力道
  - Then: 力道值正确线性相加
  - Edge cases: 大量装备、负值装备、属性溢出

- **AC-4**: 百分比属性乘法叠加
  - Given: 玩家装备了多件增加暴击率的装备
  - When: 系统计算总暴击率
  - Then: 暴击率正确乘法叠加
  - Edge cases: 多个百分比加成、暴击率上限、计算精度

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/equipment/equipment_bonuses_application_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (属性计算机制)
- Unlocks: Story 003 (元素属性计算)