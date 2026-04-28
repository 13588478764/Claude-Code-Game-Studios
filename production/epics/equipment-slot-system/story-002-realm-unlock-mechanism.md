# Story 002: 境界解锁机制

> **Epic**: 装备槽位系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/equipment-slot-system.md`
**Requirement**: `TR-equip-slot-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数据结构管理境界解锁，利用状态机处理境界变化

**Control Manifest Rules (this layer)**:
- Required: 境界解锁必须严格按照GDD中定义的境界等级要求
- Forbidden: 禁止绕过境界要求直接解锁槽位
- Guardrail: 解锁机制不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/equipment-slot-system.md`, scoped to this story:*

- [x] 境界解锁机制正确实现（炼气期到真仙境）
- [x] 槽位解锁时机正确（对应境界突破时）
- [x] 境界锁定状态正确显示（未达到境界的槽位）
- [x] 境界变化时槽位状态动态更新

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用RealmUnlockManager节点管理境界解锁逻辑
- 实现unlock_slots_for_realm(realm_level)方法根据境界解锁槽位
- 实现check_realm_requirements(slot_type, character_realm)方法检查境界要求
- 实现update_slot_lock_status()方法更新槽位锁定状态
- 实现on_realm_changed(new_realm)方法处理境界变化事件
- 实现realm_unlocked信号通知其他系统
- 与CharacterProgressionSystem、EquipmentSlotManager和UISystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 槽位类型与定义（处理基础槽位类型定义）
- Story 003: 装备规则与验证（处理装备品阶和职业限制）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 境界解锁机制正确实现
  - Given: 玩家角色达到筑基期（10级）
  - When: 系统检查槽位解锁状态
  - Then: 头部和手部槽位被解锁
  - Edge cases: 所有境界等级、境界回退、多角色

- **AC-2**: 槽位解锁时机正确
  - Given: 玩家即将突破到元婴期
  - When: 境界突破完成时
  - Then: 相应槽位立即解锁
  - Edge cases: 突破失败、突破延迟、网络同步

- **AC-3**: 境界锁定状态正确显示
  - Given: 玩家角色为炼气期
  - When: 查看未解锁槽位
  - Then: 槽位显示为锁定状态并提示所需境界
  - Edge cases: 不同锁定原因、提示信息准确性

- **AC-4**: 境界变化时槽位状态动态更新
  - Given: 玩家境界发生变化
  - When: 境界更新事件触发
  - Then: 所有相关槽位状态正确更新
  - Edge cases: 快速境界变化、批量更新、性能影响

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/equipment/realm_unlock_mechanism_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (槽位类型与定义)
- Unlocks: Story 003 (装备规则与验证)