# Story 003: 奇遇记录管理

> **Epic**: 奇遇系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/encounter-system.md`
**Requirement**: `TR-encounter-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，事件系统

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数据序列化功能管理奇遇状态，利用内置数据结构存储记录

**Control Manifest Rules (this layer)**:
- Required: 奇遇记录必须持久化，确保跨会话一致性
- Forbidden: 禁止在内存中存储关键记录状态
- Guardrail: 记录查询不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/encounter-system.md`, scoped to this story:*

- [x] 奇遇完成状态记录正常（避免重复触发）
- [x] 连续失败计数器管理正确（保底机制）
- [x] 奇遇历史记录完整（类型、时间、奖励）
- [x] 存档/读档功能正常（状态持久化）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用EncounterRecordManager节点管理所有记录逻辑
- 实现mark_encounter_completed(encounter_id)方法标记完成
- 实现update_failure_counter(success: bool)方法更新失败计数器
- 实现get_encounter_history()方法获取历史记录
- 实现save_records()和load_records()方法处理存档
- 实现record_updated信号通知相关系统
- 与SaveManager系统集成确保数据持久化

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 奇遇触发系统（处理奇遇触发逻辑）
- Story 002: 奇遇奖励系统（处理奇遇奖励发放）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 奇遇完成状态记录正常
  - Given: 玩家完成江湖传闻奇遇
  - When: 系统记录完成状态
  - Then: 同一奇遇ID不再触发
  - Edge cases: 不同奇遇ID、存档读档后状态、周目重置

- **AC-2**: 连续失败计数器管理正确
  - Given: 玩家连续19次未触发奇遇
  - When: 系统更新计数器
  - Then: 计数器为19，下次触发概率正常
  - Edge cases: 第20次、第21次、成功触发后重置

- **AC-3**: 奇遇历史记录完整
  - Given: 玩家触发多个不同类型奇遇
  - When: 系统记录历史
  - Then: 包含类型、时间、奖励信息
  - Edge cases: 大量记录、记录排序、信息完整性

- **AC-4**: 存档/读档功能正常
  - Given: 玩家有多项奇遇记录
  - When: 保存并重新加载游戏
  - Then: 奇遇记录状态完全恢复
  - Edge cases: 存档损坏、部分数据丢失、版本兼容性

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/encounter/encounter_record_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (奇遇触发系统), Story 002 (奇遇奖励系统)
- Unlocks: None