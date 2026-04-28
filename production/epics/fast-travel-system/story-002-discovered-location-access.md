# Story 002: 已发现地点访问

> **Epic**: 快速旅行系统
> **Status**: Pending Test
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/fast-travel-system.md`
**Requirement**: `TR-fast-travel-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，世界流式加载

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理地点解锁事件，利用数据结构管理解锁状态

**Control Manifest Rules (this layer)**:
- Required: 地点解锁必须持久化，确保跨会话一致性
- Forbidden: 禁止在内存中存储关键解锁状态
- Guardrail: 解锁状态查询不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/fast-travel-system.md`, scoped to this story:*

- [x] 传送点解锁机制正常（首次互动解锁）
- [x] 解锁状态持久化（存档/读档）
- [x] 地图标记更新正确（小地图/大地图）
- [x] 主线强制解锁功能（任务关联）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用LocationDiscoveryManager节点管理地点发现逻辑
- 实现discover_location(location_node_id)方法解锁地点
- 实现is_location_unlocked(location_node_id)方法检查解锁状态
- 实现save_discovered_locations()方法保存解锁状态
- 实现location_discovered信号通知地图系统
- 与MapSystem、QuestManager和SaveManager系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 快速旅行功能（处理旅行逻辑）
- Story 003: 旅行成本机制（处理经济系统集成）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 传送点解锁机制正常
  - Given: 玩家首次靠近土地庙传送点
  - When: 与传送点互动
  - Then: 传送点被解锁，播放解锁动画和音效
  - Edge cases: 不同类型传送点、距离判定、重复解锁

- **AC-2**: 解锁状态持久化
  - Given: 玩家解锁了多个传送点后退出游戏
  - When: 重新加载存档
  - Then: 已解锁的传送点保持解锁状态
  - Edge cases: 存档损坏、网络存储、版本迁移

- **AC-3**: 地图标记更新正确
  - Given: 玩家解锁了一个传送点
  - When: 查看小地图和大地图
  - Then: 该传送点在地图上显示为已解锁状态
  - Edge cases: 不同地图缩放级别、区域边界、图例更新

- **AC-4**: 主线强制解锁功能
  - Given: 玩家完成特定主线任务
  - When: 任务完成触发
  - Then: 相关的关键传送点自动解锁
  - Edge cases: 任务失败、条件变化、多任务依赖

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/fast-travel/discovered_location_access_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (快速旅行功能)
- Unlocks: Story 003 (旅行成本机制)