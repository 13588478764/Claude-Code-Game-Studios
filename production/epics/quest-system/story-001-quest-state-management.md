# Story 001: 任务状态管理

> **Epic**: 任务系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/quest-system.md`
**Requirement**: `TR-quest-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化实现

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的Resource系统管理任务数据，利用信号系统处理任务状态变更事件

**Control Manifest Rules (this layer)**:
- Required: 任务状态数据必须正确保存和加载
- Forbidden: 禁止绕过任务系统直接修改任务状态
- Guardrail: 任务状态管理不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/quest-system.md`, scoped to this story:*

- [x] 任务状态机正常工作，支持LOCKED、AVAILABLE、ACTIVE、COMPLETED、FINISHED五种状态
- [x] 系统正确处理任务状态转换（接取、激活、完成、结束）
- [x] 任务状态数据正确保存和加载，不会丢失
- [x] 前置条件检查正常工作，确保任务按顺序解锁

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 任务状态数据存储在存档文件中，与游戏进度一起保存
- 实现任务状态转换的逻辑函数
- 通过信号系统通知UI更新任务状态显示
- 实现前置条件检查函数

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 任务追踪系统：由Story 002处理
- 任务奖励发放：由Story 003处理
- 任务UI界面：由UI故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 任务状态机正常工作
  - Given: 玩家游戏中的任务
  - When: 任务经历不同阶段
  - Then: 任务状态正确转换（LOCKED→AVAILABLE→ACTIVE→COMPLETED→FINISHED）
  - Edge cases: 检查状态转换的边界条件和异常路径

- **AC-2**: 系统正确处理任务状态转换
  - Given: 玩家与任务NPC交互
  - When: 接取、完成或提交任务
  - Then: 任务状态按预期转换
  - Edge cases: 检查无效操作的处理

- **AC-3**: 任务状态数据正确保存和加载
  - Given: 玩家进行任务状态变更
  - When: 游戏保存并重新加载
  - Then: 任务状态保持不变
  - Edge cases: 检查多次保存加载后的数据一致性

- **AC-4**: 前置条件检查正常工作
  - Given: 玩家尝试接取需要前置条件的任务
  - When: 检查前置条件
  - Then: 任务正确锁定或解锁
  - Edge cases: 检查等级、境界和其他前置条件

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/quest/quest_state_management_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: None
- Unlocks: Story 002: 任务追踪系统, Story 003: 任务奖励发放