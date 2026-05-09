# Story 001: 属性计算机制

> **Epic**: 装备属性计算
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/equipment-attribute-calculation.md`
**Requirement**: `TR-equip-attr-calc-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数学计算功能实现属性计算，利用数据结构管理属性数据

**Control Manifest Rules (this layer)**:
- Required: 属性计算必须遵循GDD中定义的公式和转换规则
- Forbidden: 禁止绕过基础计算公式直接修改属性值
- Guardrail: 计算过程不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/equipment-attribute-calculation.md`, scoped to this story:*

- [x] 六维基础属性计算正确（力道、身法、根骨、悟性、定力、福缘）
- [x] 战斗属性计算正确（攻击力、防御力、生命值等）
- [x] 属性转换公式正确实施（力道→物理攻击力等）
- [x] 品阶属性差异正确体现（普通、稀有、史诗、传说）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用EquipmentAttributeCalculator节点管理装备属性计算逻辑
- 实现calculateTotalAttributes(character, equippedItems)方法计算角色总属性
- 实现applyAttributeConversion(baseAttributes)方法应用属性转换公式
- 实现calculateBaseAttributeBonuses(equippedItems)方法计算基础属性加成
- 实现calculateCombatAttributeBonuses(equippedItems)方法计算战斗属性加成
- 实现attributeCalculated信号通知其他系统
- 与EquipmentSystem、CharacterProgressionSystem和CombatSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 装备加成应用（处理装备特殊效果和状态抗性）
- Story 003: 元素属性计算（处理五行克制和元素伤害）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 六维基础属性计算正确
  - Given: 玩家装备了增加力道属性的装备
  - When: 系统计算总属性
  - Then: 力道属性值正确增加
  - Edge cases: 多件装备叠加、负属性值、属性上限

- **AC-2**: 战斗属性计算正确
  - Given: 玩家装备了增加攻击力的装备
  - When: 系统计算总属性
  - Then: 攻击力属性值正确增加
  - Edge cases: 百分比加成、固定数值加成、加成叠加

- **AC-3**: 属性转换公式正确实施
  - Given: 玩家力道属性为50点
  - When: 系统应用属性转换
  - Then: 物理攻击力增加100点（50×2）
  - Edge cases: 不同转换比例、小数处理、边界值

- **AC-4**: 品阶属性差异正确体现
  - Given: 玩家分别装备普通和史诗品阶装备
  - When: 系统计算属性加成
  - Then: 史诗装备提供更多的属性加成
  - Edge cases: 不同品阶对比、特殊效果、唯一特效

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/equipment/attribute_calculation_mechanics_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (装备加成应用), Story 003 (元素属性计算)