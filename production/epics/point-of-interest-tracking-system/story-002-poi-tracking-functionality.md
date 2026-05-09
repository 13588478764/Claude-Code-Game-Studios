# Story 002: 兴趣点追踪功能

> **Epic**: 兴趣点追踪系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/point-of-interest-tracking-system.md`
**Requirement**: `TR-poi-tracking-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，世界流式加载

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统和数据管理实现兴趣点追踪功能

**Control Manifest Rules (this layer)**:
- Required: 兴趣点追踪必须实时准确，响应迅速
- Forbidden: 禁止追踪功能导致游戏性能下降
- Guardrail: 追踪功能不应影响游戏核心玩法

---

## Acceptance Criteria

*From GDD `design/gdd/point-of-interest-tracking-system.md`, scoped to this story:*

- [x] 实现兴趣点自动发现机制（进入半径3-5格子时发现）
- [x] 实现主动感知功能（天眼通技能探测隐藏POI）
- [x] 实现任务强制指引（远距离目标方向指示）
- [x] 实现兴趣点距离和方向计算

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现兴趣点发现半径的计算逻辑
- 实现天眼通技能的探测机制
- 实现任务目标的强制指引系统
- 实现距离和方向的实时计算

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 兴趣点标记系统：由Story 001处理
- 兴趣点发现反馈：由Story 003处理
- UI显示：由UI系统处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现兴趣点自动发现机制
  - Given: 玩家接近兴趣点
  - When: 进入发现半径（3-5格子）
  - Then: 兴趣点从"未发现"变为"已发现"
  - Edge cases: 检查不同感知属性的影响

- **AC-2**: 实现主动感知功能
  - Given: 玩家激活天眼通技能
  - When: 技能生效期间
  - Then: 隐藏POI被探测并高亮显示
  - Edge cases: 检查冷却时间和感知属性影响

- **AC-3**: 实现任务强制指引
  - Given: 当前有激活任务目标
  - When: 目标在远距离外
  - Then: 显示方向指示器指引玩家
  - Edge cases: 检查多个任务目标的情况

- **AC-4**: 实现兴趣点距离和方向计算
  - Given: 玩家和兴趣点位置
  - When: 需要计算距离和方向
  - Then: 返回准确的距离和方向信息
  - Edge cases: 检查边界情况和精度

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/poi_tracking/poi_tracking_functionality_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001: 兴趣点标记系统
- Unlocks: Story 003: 兴趣点发现反馈