# Story 002: 装备穿戴系统

> **Epic**: 装备系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/equipment-system.md`
**Requirement**: `TR-equipment-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: 使用Godot的3D模型系统实现装备可视化，利用场景树管理装备节点

**Control Manifest Rules (this layer)**:
- Required: 装备穿戴必须验证兼容性，确保类型匹配
- Forbidden: 禁止穿戴不兼容的装备类型
- Guardrail: 装备切换不应造成性能下降

---

## Acceptance Criteria

*From GDD `design/gdd/equipment-system.md`, scoped to this story:*

- [x] 装备槽位管理正常（6+3槽位结构）
- [x] 装备兼容性验证正确（武器流派匹配）
- [x] 装备穿戴/卸下功能正常（实时生效）
- [x] 装备外观渲染正确（3D模型挂载）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用EquipmentWearer节点管理装备穿戴逻辑
- 实现equip_item(equipment_id, slot_type)方法穿戴装备
- 实现unequip_item(slot_type)方法卸下装备
- 实现validate_compatibility(equipment_id, slot_type)方法验证兼容性
- 实现render_equipment_visuals()方法处理外观渲染
- 实现equipment_equipped信号通知其他系统
- 与CharacterModel、BattleManager和MartialArtsManager系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 装备管理功能（处理装备存储和筛选）
- Story 003: 装备属性计算（处理装备属性计算）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Integration stories — automated test specs]:**

- **AC-1**: 装备槽位管理正常
  - Given: 玩家拥有主手武器槽和头饰槽
  - When: 尝试将武器装备到头饰槽
  - Then: 操作被拒绝，显示错误提示
  - Edge cases: 槽位已占用、空装备、错误槽位类型

- **AC-2**: 装备兼容性验证正确
  - Given: 玩家当前武学为剑法，装备一把剑
  - When: 尝试装备到主手武器槽
  - Then: 允许装备并提供20%伤害加成
  - Edge cases: 武器类型不匹配、等级不足、流派限制

- **AC-3**: 装备穿戴/卸下功能正常
  - Given: 玩家已装备一把剑
  - When: 卸下当前武器
  - Then: 武器回到背包，属性立即更新
  - Edge cases: 穿戴绑定装备、卸下唯一装备、快速切换

- **AC-4**: 装备外观渲染正确
  - Given: 玩家装备了一把传说武器
  - When: 角色在3D场景中移动
  - Then: 武器模型正确挂载到角色手上，带有发光特效
  - Edge cases: 模型缺失、材质错误、特效异常

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/equipment/equipment_wearing_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (装备管理功能)
- Unlocks: Story 003 (装备属性计算)