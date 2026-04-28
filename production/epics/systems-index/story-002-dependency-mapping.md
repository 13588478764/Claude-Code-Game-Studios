# Story 002: 依赖关系映射

> **Epic**: 系统索引
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: 6 hours
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/systems-index.md`
**Requirement**: `TR-sys-index-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: 使用Godot 4.6引擎，Scene-Node架构模式，JSON格式本地存储，组件化设计。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Godot原生的Scene-Node架构适合游戏对象管理，组件化设计通过脚本和节点组合实现功能复用。

**Control Manifest Rules (this layer)**:
- Required: Use Godot 4.6 Scene-Node architecture — organize game objects as scenes with node hierarchies — source: ADR-001
- Required: JSON format for local storage — human-readable, cross-platform compatible, supports version migration — source: ADR-001
- Forbidden: Never use string-based connect() — use typed signal connections for type safety and refactoring — source: Godot 4.6 best practices

---

## Acceptance Criteria

*From GDD `design/gdd/systems-index.md`, scoped to this story:*

- [ ] 基础层依赖：定义基础层系统（无依赖）的完整列表
- [ ] 核心层依赖：定义核心层系统对基础层系统的依赖关系
- [ ] 功能层依赖：定义功能层系统对核心层和基础层系统的依赖关系
- [ ] 依赖关系图：创建清晰的依赖关系图，显示各层系统间的依赖流向

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用JSON格式创建依赖关系数据文件，便于程序化处理和可视化
- 按照层级结构组织依赖关系（基础层 → 核心层 → 功能层）
- 依赖关系应明确指定被依赖的系统名称，避免模糊引用
- 数据文件应支持双向查询（给定系统查找依赖，给定系统查找被依赖）

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story 001]: 系统识别与分类
- [Story 003]: 实现顺序规划

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Config/Data stories — manual verification steps]:**

- **AC-1**: 基础层依赖
  - Setup: 打开 `design/gdd/systems-index.md` 和创建的依赖关系数据文件
  - Verify: 基础层系统列表与GDD完全一致，且标记为无依赖
  - Pass condition: 系统数量、名称和依赖状态完全匹配GDD

- **AC-2**: 核心层依赖
  - Setup: 检查依赖关系数据文件中的核心层系统依赖字段
  - Verify: 每个核心层系统的依赖关系与GDD中的依赖关系图一致
  - Pass condition: 依赖关系准确无误，无遗漏或错误依赖

- **AC-3**: 功能层依赖
  - Setup: 检查依赖关系数据文件中的功能层系统依赖字段
  - Verify: 每个功能层系统的依赖关系与GDD中的依赖关系图一致
  - Pass condition: 依赖关系准确无误，包含对核心层和基础层的正确依赖

- **AC-4**: 依赖关系图
  - Setup: 验证依赖关系数据文件的结构和可读性
  - Verify: 数据结构支持生成清晰的依赖关系图
  - Pass condition: 数据格式便于可视化工具处理，逻辑清晰

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- Config/Data: smoke check pass (`production/qa/smoke-*.md`)

**Status**: [x] Completed - systems_dependencies.json created and verified

---

## Dependencies

- Depends on: [Story 001]
- Unlocks: [Story 003]