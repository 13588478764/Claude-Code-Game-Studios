# Story 001: 系统识别与分类

> **Epic**: 系统索引
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: 4 hours
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/systems-index.md`
**Requirement**: `TR-sys-index-001`
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

- [ ] 系统枚举：完整列出所有游戏系统，包括基础层、核心层和功能层系统
- [ ] 系统分类：按类别（技术、数据、游戏机制、UI、AI）对所有系统进行正确分类
- [ ] 系统描述：为每个系统提供清晰简洁的描述
- [ ] 系统状态：标记每个系统的当前状态（Approved/Not Started）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用JSON格式创建系统枚举数据文件，便于维护和扩展
- 按照Foundation层规则组织数据结构，确保与Godot 4.6架构兼容
- 系统分类应遵循GDD中定义的类别体系
- 数据文件应包含所有必要的元信息（名称、类别、描述、来源、状态）

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story 002]: 依赖关系映射
- [Story 003]: 实现顺序规划

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Config/Data stories — manual verification steps]:**

- **AC-1**: 系统枚举
  - Setup: 打开 `design/gdd/systems-index.md` 和创建的系统枚举数据文件
  - Verify: 数据文件包含GDD中列出的所有系统，无遗漏或多余项
  - Pass condition: 系统数量和名称完全匹配GDD

- **AC-2**: 系统分类
  - Setup: 检查系统枚举数据文件中的类别字段
  - Verify: 每个系统都被正确分配到技术、数据、游戏机制、UI或AI类别
  - Pass condition: 所有系统的类别与GDD中的分类一致

- **AC-3**: 系统描述
  - Setup: 比较数据文件中的描述与GDD
  - Verify: 描述内容准确反映系统功能和用途
  - Pass condition: 描述清晰、简洁、准确

- **AC-4**: 系统状态
  - Setup: 检查数据文件中的状态字段
  - Verify: 所有系统状态标记为"Approved"
  - Pass condition: 状态字段正确设置

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- Config/Data: smoke check pass (`production/qa/smoke-*.md`)

**Status**: [x] Completed - systems_index.json created and verified

---

## Dependencies

- Depends on: None
- Unlocks: [Story 002]