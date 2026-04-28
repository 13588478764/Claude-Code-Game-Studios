# Story 002: 属性点分配系统

> **Epic**: 角色成长系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26
> **Estimate**: 4-6 hours

## Context

**GDD**: `design/gdd/character-progression-system.md`
**Requirement**: `TR-char-progression-003`, `TR-char-progression-007`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，GDScript实现，信号系统用于UI通知

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统通知UI更新，数据验证在分配前执行

**Control Manifest Rules (this layer)**:
- Required: 属性点分配必须有验证机制，防止超出可用点数
- Forbidden: 禁止直接修改属性值绕过分配系统
- Guardrail: 属性计算不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/character-progression-system.md`, scoped to this story:*

- [x] 六维核心属性分配正常工作（力道、身法、根骨、悟性、定力、福缘）
- [x] 属性点分配验证正确（防止超出可用点数，拒绝无效分配）
- [x] 属性效果正确计算并影响战斗面板（物理攻击、闪避率、生命值等）
- [x] 属性重置功能正常工作（免费重置次数 + 洗髓丹消耗）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用`allocate_attribute_points(attribute_name, points)`方法进行属性分配
- 分配前验证：`allocated_attribute_points + points <= total_attribute_points`
- 分配成功后发射`attribute_points_allocated`信号通知UI
- 重置时检查`free_reset_count`，如果为0则消耗洗髓丹
- 属性效果通过`get_combat_stats()`方法计算并返回战斗面板数据

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 基础等级系统和境界突破（已完成）
- Story 003: 天赋网格系统
- Story 005: 属性分配UI界面

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 六维核心属性分配正常工作
  - Given: 角色有10点可用属性点
  - When: 分配5点到力道属性
  - Then: 力道属性增加5点，已分配属性点增加5点
  - Edge cases: 分配0点、分配负数点、分配到不存在的属性

- **AC-2**: 属性点分配验证正确
  - Given: 角色有10点可用属性点，已分配5点
  - When: 尝试分配6点到身法属性
  - Then: 分配失败，返回false，属性值不变
  - Edge cases: 恰好分配完所有点、超出1点、超出大量点

- **AC-3**: 属性效果正确计算
  - Given: 角色力道属性为20
  - When: 调用`get_combat_stats()`
  - Then: 物理攻击力 = 20 × 2 = 40
  - Edge cases: 属性为0、属性为最大值、境界加成影响

- **AC-4**: 属性重置功能正常工作
  - Given: 角色有1次免费重置机会
  - When: 调用`reset_attributes()`
  - Then: 所有属性恢复到基础值10，已分配点数归零，免费重置次数减1
  - Edge cases: 无免费重置次数时消耗洗髓丹、洗髓丹不足时重置失败

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/character/attribute_allocation_test.gd` — must exist and pass

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: Story 001 (角色等级和境界突破) ✅ Complete
- Unlocks: Story 004 (奇遇触发和奖励系统), Story 005 (角色成长UI)

---

## Completion Notes

**Completed**: 2026-04-26
**Criteria**: 4/4 passing (all acceptance criteria verified)
**Test Coverage**: 100% — all criteria covered by automated unit tests
**Test Evidence**: Logic story — unit test file at `tests/unit/character/attribute_allocation_test.gd`
**Code Review**: Complete — APPROVED

**Implementation Enhancements**:
- ✅ 完整的属性点分配验证机制（处理边界情况：0点、负数、无效属性名）
- ✅ 正确集成物品管理器处理洗髓丹消耗
- ✅ 符合ADR-001所有要求（Godot 4.6, GDScript, 信号系统, 数据持久化准备）

**Deviations**: None
**Tech Debt**: None

**Files Modified**:
- `src/scripts/character/character_system.gd` — 修改/完善
- `src/scripts/economy/item_manager.gd` — 创建
- `tests/unit/character/attribute_allocation_test.gd` — 创建