# Story 003: 装备规则与验证

> **Epic**: 装备槽位系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/equipment-slot-system.md`
**Requirement**: `TR-equip-slot-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数据结构管理装备规则，利用验证函数实现装备限制检查

**Control Manifest Rules (this layer)**:
- Required: 装备规则验证必须严格执行GDD中定义的限制
- Forbidden: 禁止绕过装备品阶和职业限制
- Guardrail: 验证过程不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/equipment-slot-system.md`, scoped to this story:*

- [x] 装备品阶限制正确实施（白色到金色）
- [x] 职业限制正确应用（特定武学流派）
- [x] 性别限制正确应用（外观装备）
- [x] 装备验证功能正常（装备/卸下操作）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用EquipmentRuleValidator节点管理装备规则验证逻辑
- 实现validate_equipment_tier(item_id, character_realm)方法验证装备品阶
- 实现validate_profession_requirement(item_id, character_class)方法验证职业限制
- 实现validate_gender_requirement(item_id, character_gender)方法验证性别限制
- 实现can_equip_item(item_id, slot_type)方法综合验证装备可行性
- 实现validate_equipment_change(old_item_id, new_item_id, slot_type)方法验证装备更换
- 实现validation_performed信号通知其他系统
- 与EquipmentSystem、CharacterProgressionSystem和ItemDatabase系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 槽位类型与定义（处理基础槽位类型定义）
- Story 002: 境界解锁机制（处理境界相关的槽位解锁）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 装备品阶限制正确实施
  - Given: 玩家角色为筑基期
  - When: 尝试装备史诗品阶装备
  - Then: 系统拒绝装备并提示境界不足
  - Edge cases: 所有品阶限制、临界境界、品阶提升

- **AC-2**: 职业限制正确应用
  - Given: 玩家专精剑法流派
  - When: 尝试装备仅限刀法的装备
  - Then: 系统拒绝装备并提示职业不符
  - Edge cases: 多流派、无限制装备、职业转换

- **AC-3**: 性别限制正确应用
  - Given: 玩家角色为男性
  - When: 尝试装备女性专用外观装备
  - Then: 系统拒绝装备并提示性别限制
  - Edge cases: 无性别限制、性别中立装备、外观与属性分离

- **AC-4**: 装备验证功能正常
  - Given: 玩家尝试装备物品
  - When: 执行装备操作时
  - Then: 系统验证所有相关限制后决定是否允许
  - Edge cases: 多重限制、验证性能、错误提示

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/equipment/equipment_rules_and_validation_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (槽位类型与定义), Story 002 (境界解锁机制)
- Unlocks: None