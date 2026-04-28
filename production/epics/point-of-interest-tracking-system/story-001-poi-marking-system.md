# Story 001: 兴趣点标记系统

> **Epic**: 兴趣点追踪系统
> **Status**: Pending Test
> **Layer**: Core
> **Type**: UI
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/point-of-interest-tracking-system.md`
**Requirement**: `TR-poi-tracking-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，世界流式加载

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的CanvasLayer和Control节点实现兴趣点标记，利用信号系统更新标记状态

**Control Manifest Rules (this layer)**:
- Required: 兴趣点标记必须清晰易识别且不影响游戏性能
- Forbidden: 禁止在小地图上显示过多标记导致界面混乱
- Guardrail: 标记系统不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/point-of-interest-tracking-system.md`, scoped to this story:*

- [x] 实现兴趣点类型标记（资源采集点、任务目标、奇遇/隐藏点、功能设施）
- [x] 实现小地图兴趣点标记（像素风图标，颜色区分类型）
- [x] 实现世界内高亮效果（POI下方发光光晕）
- [x] 实现屏幕边缘指示器（远距离目标方向指引）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现兴趣点类型的数据结构和枚举
- 实现小地图兴趣点标记系统
- 实现世界内高亮效果
- 实现屏幕边缘指示器系统
- 使用水墨风格图标设计标记

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 兴趣点追踪功能：由Story 002处理
- 兴趣点发现反馈：由Story 003处理
- 天眼通技能：由专门的技能系统处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For UI stories — automated test specs]:**

- **AC-1**: 实现兴趣点类型标记
  - Given: 游戏世界中存在不同类型兴趣点
  - When: 玩家进入游戏世界
  - Then: 不同类型兴趣点使用不同图标标记
  - Edge cases: 检查图标清晰度和颜色区分度

- **AC-2**: 实现小地图兴趣点标记
  - Given: 玩家在游戏中
  - When: 小地图系统运行
  - Then: 兴趣点在小地图上正确显示
  - Edge cases: 检查不同分辨率下的显示

- **AC-3**: 实现世界内高亮效果
  - Given: 玩家接近兴趣点
  - When: 兴趣点在可视范围内
  - Then: 兴趣点显示高亮效果
  - Edge cases: 检查多个兴趣点同时高亮

- **AC-4**: 实现屏幕边缘指示器
  - Given: 远距离兴趣点在屏幕外
  - When: 兴趣点为当前任务目标
  - Then: 屏幕边缘显示方向指示器
  - Edge cases: 检查多个目标指示器

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/poi_marking_system_evidence.md` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002: 兴趣点追踪功能, Story 003: 兴趣点发现反馈