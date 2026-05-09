# Story 002: 已探索区域标记

> **Epic**: 地图/小地图系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/minimap-system.md`
**Requirement**: `TR-minimap-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，UI系统

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的Resource系统管理探索数据，利用信号系统更新探索状态

**Control Manifest Rules (this layer)**:
- Required: 探索标记必须准确记录玩家探索进度
- Forbidden: 禁止丢失探索进度数据
- Guardrail: 探索标记更新不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/minimap-system.md`, scoped to this story:*

- [x] 实现迷雾系统，未探索区域显示为灰色迷雾
- [x] 玩家探索过的区域在小地图上永久点亮
- [x] 探索进度百分比正确计算和显示
- [x] 探索数据正确保存和加载

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现探索区域的数据结构和存储
- 通过Shader实现迷雾效果
- 计算并显示区域探索进度百分比
- 与存档系统集成以保存探索状态

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 玩家位置显示：由Story 001处理
- 导航标记系统：由Story 003处理
- 大地图功能：由UI故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现迷雾系统，未探索区域显示为灰色迷雾
  - Given: 玩家未探索某区域
  - When: 查看小地图
  - Then: 未探索区域显示为灰色迷雾
  - Edge cases: 检查边界区域和复杂地形

- **AC-2**: 玩家探索过的区域在小地图上永久点亮
  - Given: 玩家探索过某区域
  - When: 查看小地图
  - Then: 已探索区域永久点亮
  - Edge cases: 检查重新进入已探索区域

- **AC-3**: 探索进度百分比正确计算和显示
  - Given: 玩家在区域内移动
  - When: 探索更多区域
  - Then: 探索进度百分比正确更新
  - Edge cases: 检查100%探索完成情况

- **AC-4**: 探索数据正确保存和加载
  - Given: 玩家探索了部分区域
  - When: 游戏存档并重新加载
  - Then: 探索状态正确恢复
  - Edge cases: 检查存档损坏情况

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/minimap/explored_area_marking_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001: 玩家位置显示
- Unlocks: Story 003: 导航标记系统