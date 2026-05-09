# Story 001: 玩家位置显示

> **Epic**: 地图/小地图系统
> **Status**: Complete
> **Layer**: Core
> **Type**: UI
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/minimap-system.md`
**Requirement**: `TR-minimap-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，UI系统

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的CanvasLayer和Control节点实现小地图UI，利用信号系统更新玩家位置

**Control Manifest Rules (this layer)**:
- Required: 小地图必须实时准确显示玩家位置和朝向
- Forbidden: 禁止在小地图上显示过多干扰信息
- Guardrail: 小地图更新不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/minimap-system.md`, scoped to this story:*

- [x] 小地图UI正确显示在屏幕右上角
- [x] 玩家位置箭头在小地图上正确显示并实时更新
- [x] 玩家朝向箭头正确指向当前面向方向
- [x] 小地图显示当前区域的简化地形轮廓

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用CanvasLayer创建小地图UI层
- 实现玩家位置跟踪和朝向显示
- 通过信号系统实时更新小地图显示
- 使用半透明背景和水墨风格视觉元素

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 已探索区域标记：由Story 002处理
- 导航标记系统：由Story 003处理
- 大地图功能：由UI故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For UI stories — automated test specs]:**

- **AC-1**: 小地图UI正确显示在屏幕右上角
  - Given: 游戏启动并加载场景
  - When: 小地图系统初始化
  - Then: 小地图UI显示在屏幕右上角
  - Edge cases: 检查不同分辨率下的位置

- **AC-2**: 玩家位置箭头在小地图上正确显示并实时更新
  - Given: 玩家在场景中移动
  - When: 小地图系统运行
  - Then: 玩家位置箭头跟随玩家移动
  - Edge cases: 检查边界情况和快速移动

- **AC-3**: 玩家朝向箭头正确指向当前面向方向
  - Given: 玩家改变朝向
  - When: 小地图系统运行
  - Then: 玩家箭头指向正确更新
  - Edge cases: 检查360度旋转

- **AC-4**: 小地图显示当前区域的简化地形轮廓
  - Given: 玩家在特定区域
  - When: 小地图系统运行
  - Then: 显示当前区域的简化地形轮廓
  - Edge cases: 检查区域切换时的更新

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/player_position_display_evidence.md` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002: 已探索区域标记, Story 003: 导航标记系统