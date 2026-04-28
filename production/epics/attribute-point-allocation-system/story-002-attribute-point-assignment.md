# Story 002: 属性点分配

> **Epic**: 属性点分配系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/attribute-point-allocation-system.md`
**Requirement**: `TR-char-progression-007`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的UI系统实现属性点分配界面，利用信号系统处理用户交互

**Control Manifest Rules (this layer)**:
- Required: 属性点分配界面必须实时显示属性变化效果
- Forbidden: 禁止在战斗中进行属性点分配
- Guardrail: 界面响应不应超过100ms

---

## Acceptance Criteria

*From GDD `design/gdd/attribute-point-allocation-system.md`, scoped to this story:*

- [x] 属性点分配界面正常（UI展示和交互）
- [x] 属性点分配实时生效（即时应用效果）
- [x] 智能推荐分配方案（基于武学配置）
- [x] 分配历史记录（撤销/重做功能）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用AttributeAssignmentUI节点管理属性点分配界面
- 实现show_assignment_interface()方法显示分配界面
- 实现apply_allocation_changes()方法应用分配变更
- 实现recommend_allocation_scheme()方法提供智能推荐
- 实现allocation_applied信号通知其他系统
- 与AttributePointManager、UIManager和MartialArtsSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 属性点机制（处理核心逻辑）
- Story 003: 属性点验证（处理分配验证和重置机制）
- 核心算法（由逻辑层处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Integration stories — automated test specs]:**

- **AC-1**: 属性点分配界面正常
  - Given: 玩家打开属性点分配界面
  - When: 界面加载完成
  - Then: 显示六维属性条和可用属性点数
  - Edge cases: 不同分辨率、不同主题、无障碍访问

- **AC-2**: 属性点分配实时生效
  - Given: 玩家在界面中分配属性点
  - When: 点击分配按钮
  - Then: 属性变化立即反映在角色面板
  - Edge cases: 大量属性点分配、连续分配、网络延迟

- **AC-3**: 智能推荐分配方案
  - Given: 玩家当前学习了剑法武学
  - When: 请求智能推荐
  - Then: 推荐优先分配力道和悟性属性
  - Edge cases: 多种武学、无武学、推荐冲突

- **AC-4**: 分配历史记录
  - Given: 玩家进行了多次属性点分配
  - When: 使用撤销功能
  - Then: 可以撤销到之前的状态
  - Edge cases: 超出历史记录限制、存档加载、多角色

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/character/attribute_point_assignment_test.gd` — must exist and pass

**Status**: [x] Completed

---

## Dependencies

- Depends on: Story 001 (属性点机制)
- Unlocks: Story 003 (属性点验证)