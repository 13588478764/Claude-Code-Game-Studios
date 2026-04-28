# Story 001: 快速旅行功能

> **Epic**: 快速旅行系统
> **Status**: Pending Test
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/fast-travel-system.md`
**Requirement**: `TR-fast-travel-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，世界流式加载

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的场景管理功能实现异步加载，利用信号系统处理状态转换

**Control Manifest Rules (this layer)**:
- Required: 快速旅行必须验证前置条件，确保玩家不在战斗状态
- Forbidden: 禁止在战斗状态下启动快速旅行
- Guardrail: 旅行过程不应造成性能下降

---

## Acceptance Criteria

*From GDD `design/gdd/fast-travel-system.md`, scoped to this story:*

- [x] 快速旅行基础功能正常（传送点交互）
- [x] 旅行成本计算正确（银两消耗公式）
- [x] 旅行时间消耗合理（时间跳跃机制）
- [x] 旅行状态管理正确（异步加载）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用FastTravelManager节点管理快速旅行逻辑
- 实现travel_to_location(destination_node_id)方法执行旅行
- 实现calculate_travel_cost(start_node, end_node)方法计算旅行费用
- 实现calculate_travel_time(distance)方法计算旅行时间
- 实现travel_started信号通知其他系统
- 与WorldStreamingSystem、EconomyManager和GameStateManager系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 已发现地点访问（处理地点解锁和标记）
- Story 003: 旅行成本机制（处理经济系统集成）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 快速旅行基础功能正常
  - Given: 玩家靠近已解锁的土地庙传送点
  - When: 与传送点交互并选择目标地点
  - Then: 开始快速旅行过程，显示过场动画
  - Edge cases: 战斗状态、距离过远、目标未解锁

- **AC-2**: 旅行成本计算正确
  - Given: 玩家选择从青云山到江南水乡（距离系数0.5）
  - When: 系统计算旅行费用
  - Then: 费用 = 10 + (0.5 × 100) = 60银两
  - Edge cases: 最近距离、最远距离、费用上限

- **AC-3**: 旅行时间消耗合理
  - Given: 玩家开始跨区域旅行
  - When: 快速旅行过程完成
  - Then: 游戏内时间前进4小时（根据公式计算）
  - Edge cases: 同区域旅行、最长旅行时间、时间暂停

- **AC-4**: 旅行状态管理正确
  - Given: 玩家在旅行过程中
  - When: 系统异步加载目标区域
  - Then: 玩家无法进行其他操作，直到加载完成
  - Edge cases: 加载失败、中途取消、网络异常

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/fast-travel/fast_travel_functionality_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (已发现地点访问), Story 003 (旅行成本机制)