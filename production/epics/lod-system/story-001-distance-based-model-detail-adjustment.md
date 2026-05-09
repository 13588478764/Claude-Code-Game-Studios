# Story 001: 基于距离的模型细节调整

> **Epic**: LOD（细节层次）系统
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/lod-system.md`
**Requirement**: `TR-lod-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，渲染系统

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的LOD功能和场景切换机制

**Control Manifest Rules (this layer)**:
- Required: 模型细节调整必须遵循GDD中定义的3个LOD级别
- Forbidden: 禁止在切换时造成明显的视觉跳跃
- Guardrail: 必须实施防抖机制避免频繁切换

---

## Acceptance Criteria

*From GDD `design/gdd/lod-system.md`, scoped to this story:*

- [x] 实现3个LOD级别（高、中、低）
- [x] 实现基于距离的模型切换
- [x] 实现切换距离机制（1.5倍、3.0倍屏幕宽度）
- [x] 实现防抖机制

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用LODManager节点管理LOD逻辑
- 实现switch_model_lod()方法处理模型切换
- 实现calculate_distance_thresholds()方法计算切换距离
- 实现debounce_mechanism()方法防止频繁切换
- 与WorldStreamingSystem、OpenWorldExplorationSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 纹理细节随距离变化（处理纹理LOD）
- Story 003: 性能优化和帧率保障（处理整体性能监控）
- UI显示（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现3个LOD级别
  - Given: 游戏中有需要LOD的模型
  - When: 根据距离判断LOD级别
  - Then: 正确识别高、中、低三个细节级别
  - Edge cases: 边界距离、快速移动、内存限制

- **AC-2**: 实现基于距离的模型切换
  - Given: 玩家在世界中移动
  - When: 距离达到切换阈值
  - Then: 模型正确切换到对应LOD级别
  - Edge cases: 快速来回移动、多个物体同时切换

- **AC-3**: 实现切换距离机制
  - Given: 屏幕宽度为基准
  - When: 计算切换距离
  - Then: 高→中切换为1.5倍屏幕宽度，中→低切换为3.0倍屏幕宽度
  - Edge cases: 不同分辨率、窗口大小改变

- **AC-4**: 实现防抖机制
  - Given: 玩家在切换边界附近移动
  - When: 频繁跨越切换阈值
  - Then: 在500毫秒内避免重复切换
  - Edge cases: 极端快速移动、网络延迟

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/rendering/distance_based_model_detail_adjustment_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (纹理细节随距离变化), Story 003 (性能优化和帧率保障)