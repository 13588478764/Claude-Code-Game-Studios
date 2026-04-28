# Story 003: 元素属性计算

> **Epic**: 装备属性计算
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/equipment-attribute-calculation.md`
**Requirement**: `TR-equip-attr-calc-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数据结构管理元素属性，利用数学计算实现五行克制逻辑

**Control Manifest Rules (this layer)**:
- Required: 元素属性计算必须遵循五行克制体系
- Forbidden: 禁止在元素计算中引入不符合五行理论的逻辑
- Guardrail: 元素计算不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/equipment-attribute-calculation.md`, scoped to this story:*

- [x] 五行克制计算正确（金克木、木克土等）
- [x] 克制伤害倍数正确（1.5倍和0.5倍）
- [x] 装备元素属性正确应用（火、水、土、金、木）
- [x] 元素属性与武学属性正确叠加

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用ElementalPropertyCalculator节点管理元素属性计算逻辑
- 实现calculateElementalDamage(sourceElement, targetElement, baseDamage)方法计算元素克制伤害
- 实现applyEquipmentElementalBonuses(equippedItems)方法应用装备元素属性
- 实现combineElementalProperties(martialArtElements, equipmentElements)方法合并武学和装备元素属性
- 实现getElementalAdvantageMultiplier(attackerElement, defenderElement)方法获取克制倍数
- 实现elementalCalculated信号通知其他系统
- 与EquipmentSystem、MartialArtsSystem和DamageCalculationSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 属性计算机制（处理基础属性和转换公式）
- Story 002: 装备加成应用（处理装备特殊效果和状态抗性）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 五行克制计算正确
  - Given: 攻击方使用金系武学，防守方使用木系护具
  - When: 系统计算元素克制
  - Then: 金克木，造成1.5倍伤害
  - Edge cases: 所有克制关系、相同元素、循环克制

- **AC-2**: 克制伤害倍数正确
  - Given: 攻击方使用火系武学，防守方使用水系护具
  - When: 系统计算克制伤害
  - Then: 火被水克，造成0.5倍伤害
  - Edge cases: 1.5倍伤害、0.5倍伤害、边界值

- **AC-3**: 装备元素属性正确应用
  - Given: 玩家装备了火系属性的武器
  - When: 系统计算元素属性
  - Then: 火系属性正确加成到角色
  - Edge cases: 多件同系装备、多件异系装备、元素叠加

- **AC-4**: 元素属性与武学属性正确叠加
  - Given: 武学具有火系属性，装备也提供火系加成
  - When: 系统合并元素属性
  - Then: 武学和装备的火系属性正确叠加
  - Edge cases: 多种元素叠加、属性冲突、效果增强

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/equipment/elemental_property_calculation_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (属性计算机制), Story 002 (装备加成应用)
- Unlocks: None