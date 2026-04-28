# Story 001: 槽位类型与定义

> **Epic**: 装备槽位系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/equipment-slot-system.md`
**Requirement**: `TR-equip-slot-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数据结构定义槽位类型，利用枚举管理槽位标识

**Control Manifest Rules (this layer)**:
- Required: 槽位定义必须遵循GDD中规定的15个槽位类型
- Forbidden: 禁止在槽位定义中硬编码特殊逻辑
- Guardrail: 槽位数据结构不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/equipment-slot-system.md`, scoped to this story:*

- [x] 武器槽位类型正确实现（主手/副手）
- [x] 防具槽位类型正确实现（头、身体、手、腿、脚）
- [x] 饰品槽位类型正确实现（戒指、项链、腰带）
- [x] 特殊槽位类型正确实现（内功心法、轻功秘籍）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用EquipmentSlotManager节点管理槽位类型定义
- 实现define_slot_types()方法定义所有槽位类型
- 实现initialize_character_slots(character)方法初始化角色槽位
- 实现get_slot_by_type(slot_type)方法获取指定类型的槽位
- 实现is_valid_slot_type(slot_type)方法验证槽位类型有效性
- 实现slot_defined信号通知其他系统
- 与EquipmentSystem、CharacterProgressionSystem和ItemDatabase系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 境界解锁机制（处理境界相关的槽位解锁）
- Story 003: 装备规则与验证（处理装备品阶和职业限制）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 武器槽位类型正确实现
  - Given: 系统初始化角色装备槽位
  - When: 定义武器槽位类型
  - Then: 正确创建主手和副手武器槽位
  - Edge cases: 单手武器、双手武器、双持限制

- **AC-2**: 防具槽位类型正确实现
  - Given: 系统初始化角色装备槽位
  - When: 定义防具槽位类型
  - Then: 正确创建头、身体、手、腿、脚部槽位
  - Edge cases: 不同装备类型、装备兼容性、外观渲染

- **AC-3**: 饰品槽位类型正确实现
  - Given: 系统初始化角色装备槽位
  - When: 定义饰品槽位类型
  - Then: 正确创建2个戒指、1个项链、1个腰带槽位
  - Edge cases: 槽位数量限制、饰品特殊效果、属性叠加

- **AC-4**: 特殊槽位类型正确实现
  - Given: 系统初始化角色装备槽位
  - When: 定义特殊槽位类型
  - Then: 正确创建3个内功心法、1个轻功秘籍槽位
  - Edge cases: 内功冲突、轻功组合、特殊机制

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/equipment/slot_types_and_definitions_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (境界解锁机制), Story 003 (装备规则与验证)