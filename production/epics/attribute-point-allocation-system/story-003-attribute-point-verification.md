# Story 003: 属性点验证

> **Epic**: 属性点分配系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/attribute-point-allocation-system.md`
**Requirement**: `TR-char-progression-007`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的验证系统确保属性点分配合规，利用数据结构管理重置机制

**Control Manifest Rules (this layer)**:
- Required: 属性点验证必须实时进行，防止非法分配
- Forbidden: 禁止绕过验证机制直接修改属性点
- Guardrail: 验证过程不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/attribute-point-allocation-system.md`, scoped to this story:*

- [x] 属性点分配验证正常（验证可用点数）
- [x] 重置机制正常（境界突破重置、洗髓丹重置）
- [x] 属性点上限验证（单个属性99点限制）
- [x] 数据完整性验证（保存/加载验证）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用AttributeValidationManager节点管理属性点验证逻辑
- 实现validate_allocation(attribute_type, points)方法验证分配
- 实现reset_attributes(reset_type)方法重置属性点
- 实现verify_data_integrity()方法验证数据完整性
- 实现validation_passed信号通知其他系统
- 与AttributePointManager、SaveManager和CharacterProgressionSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 属性点机制（处理核心逻辑）
- Story 002: 属性点分配（处理UI界面和用户交互）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 属性点分配验证正常
  - Given: 玩家拥有0点可用属性点
  - When: 尝试分配1点到力道属性
  - Then: 系统拒绝分配并显示错误消息
  - Edge cases: 负数分配、超出可用点数、浮点数分配

- **AC-2**: 重置机制正常
  - Given: 玩家分配了部分属性点
  - When: 使用洗髓丹重置属性
  - Then: 所有属性点返回可分配状态
  - Edge cases: 无洗髓丹、境界突破重置、多次重置

- **AC-3**: 属性点上限验证
  - Given: 玩家力道属性已达99点上限
  - When: 尝试再分配1点到力道
  - Then: 系统拒绝分配并显示错误消息
  - Edge cases: 等于上限、超过上限、不同属性上限

- **AC-4**: 数据完整性验证
  - Given: 玩家属性点数据
  - When: 保存后重新加载
  - Then: 数据验证通过，属性点状态正确
  - Edge cases: 数据损坏、版本不匹配、存档迁移

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/character/attribute_point_verification_test.gd` — must exist and pass

**Status**: [x] Completed

---

## Dependencies

- Depends on: Story 001 (属性点机制), Story 002 (属性点分配)
- Unlocks: None