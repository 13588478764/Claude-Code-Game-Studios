# Story 001: 动态加载和卸载世界区域

> **Epic**: 世界流式加载系统
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 12 hours
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/world-streaming-system.md`
**Requirement**: `TR-world-streaming-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: 使用Godot 4.6引擎，Scene-Node架构模式，组件化设计，利用PC平台硬件优势。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Godot原生的场景管理系统和异步加载功能适合实现动态世界加载，PC平台可充分利用内存和存储性能。

**Control Manifest Rules (this layer)**:
- Required: Use Godot 4.6 Scene-Node architecture — organize game objects as scenes with node hierarchies — source: ADR-001
- Required: Component-based design — implement functionality through script and node composition, not deep inheritance — source: ADR-001
- Forbidden: Never use string-based connect() — use typed signal connections for type safety and refactoring — source: Godot 4.6 best practices

---

## Acceptance Criteria

*From GDD `design/gdd/world-streaming-system.md`, scoped to this story:*

- [ ] 区块划分：实现2048x2048像素的正方形区块作为独立加载单元
- [ ] 预加载机制：当玩家距离区块边界1.5个屏幕宽度（约2700像素）时，开始异步预加载该区块的资源
- [ ] 卸载机制：当玩家距离已加载区块超过3个屏幕宽度（约5400像素）时，卸载该区块的资源以释放内存
- [ ] 同时加载限制：支持最多16个同时加载的区块（4x4网格），根据可用内存动态调整
- [ ] 异步加载：使用后台线程或异步加载功能，避免主线程卡顿

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 创建WorldStreamingManager类，负责管理所有区块的加载和卸载状态
- 实现BlockData结构体，包含区块坐标、加载状态、资源引用等信息
- 使用Godot的ResourceLoader.load_interactive()或PackedScene.instantiate()进行异步加载
- 实现距离计算函数，根据玩家位置和屏幕宽度动态计算加载/卸载距离
- 设计内存管理策略，监控可用内存并动态调整最大加载区块数
- 使用信号系统通知其他系统（如小地图系统）区块状态变化

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story 002]: 基于玩家位置的区域加载
- [Story 003]: 内存优化和性能预算

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated unit/integration tests]:**

- **AC-1**: 区块划分
  - Setup: 创建测试世界，设置区块大小为2048x2048像素
  - Verify: WorldStreamingManager正确将世界划分为独立的区块单元
  - Pass condition: 区块边界计算准确，每个区块大小一致

- **AC-2**: 预加载机制
  - Setup: 玩家移动到距离区块边界1.5个屏幕宽度的位置
  - Verify: 系统开始异步预加载目标区块的资源
  - Pass condition: 加载在正确距离触发，不影响游戏帧率

- **AC-3**: 卸载机制
  - Setup: 玩家移动到距离已加载区块超过3个屏幕宽度的位置
  - Verify: 系统卸载该区块的资源并释放内存
  - Pass condition: 卸载在正确距离触发，内存使用量下降

- **AC-4**: 同时加载限制
  - Setup: 在内存充足的PC平台上探索大型地图
  - Verify: 系统可同时加载最多16个区块，提供流畅体验
  - Pass condition: 加载区块数量不超过限制，性能保持稳定

- **AC-5**: 异步加载
  - Setup: 在主线程繁忙时触发区块加载
  - Verify: 游戏帧率不受影响，加载操作在后台完成
  - Pass condition: 主线程FPS保持稳定，加载完成后触发完成信号

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: Unit test file with 100% coverage (`tests/unit/world_streaming_manager_test.gd`)
- Integration: Integration test verifying dynamic loading/unloading cycle (`tests/integration/world_streaming_integration_test.gd`)

**Status**: [x] Completed - world_streaming_manager.gd implemented and verified

---

## Dependencies

- Depends on: None
- Unlocks: [Story 002]