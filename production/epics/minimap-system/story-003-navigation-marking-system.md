# Story 003: 导航标记系统

> **Epic**: 地图/小地图系统
> **Status**: Complete
> **Layer**: Core
> **Type**: UI
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/minimap-system.md`
**Requirement**: `TR-minimap-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，UI系统

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的CanvasLayer和Control节点实现导航标记，利用信号系统更新标记状态

**Control Manifest Rules (this layer)**:
- Required: 导航标记必须清晰易识别且不影响游戏性能
- Forbidden: 禁止在小地图上显示过多标记导致界面混乱
- Guardrail: 标记系统不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/minimap-system.md`, scoped to this story:*

- [x] 任务目标标记在小地图上正确显示
- [x] 兴趣点标记（敌人、宝箱、传送点等）在小地图上正确显示
- [x] 罗盘环显示方向指示（东、南、西、北）
- [x] 支持自定义标记功能（玩家可标记重要地点）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现任务目标标记系统
- 实现兴趣点标记（敌人、宝箱、传送点等）
- 添加罗盘环显示方向指示
- 实现自定义标记功能
- 使用传统纹样图标设计标记

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 玩家位置显示：由Story 001处理
- 已探索区域标记：由Story 002处理
- 大地图功能：由UI故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For UI stories — automated test specs]:**

- **AC-1**: 任务目标标记在小地图上正确显示
  - Given: 玩家接受任务
  - When: 任务目标在当前区域
  - Then: 小地图上显示任务目标标记
  - Edge cases: 检查多个任务目标和远距离目标

- **AC-2**: 兴趣点标记在小地图上正确显示
  - Given: 场景中有兴趣点（敌人、宝箱、传送点等）
  - When: 兴趣点在小地图范围内
  - Then: 显示相应的兴趣点标记
  - Edge cases: 检查标记重叠和密集区域

- **AC-3**: 罗盘环显示方向指示
  - Given: 小地图激活
  - When: 查看小地图
  - Then: 显示罗盘环和方向指示
  - Edge cases: 检查不同朝向下的显示

- **AC-4**: 支持自定义标记功能
  - Given: 玩家在小地图上操作
  - When: 执行自定义标记操作
  - Then: 在指定位置添加自定义标记
  - Edge cases: 检查标记数量限制和删除功能

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/navigation_marking_system_evidence.md` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001: 玩家位置显示, Story 002: 已探索区域标记
- Unlocks: None