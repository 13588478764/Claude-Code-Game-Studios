# Story 003: 逻辑树与权重

> **Epic**: 奇遇条件检查系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/encounter-condition-check-system.md`
**Requirement**: `TR-enc-cond-check-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数据结构实现逻辑树，利用数学计算处理权重分配

**Control Manifest Rules (this layer)**:
- Required: 逻辑树必须支持嵌套AND/OR结构
- Forbidden: 禁止在逻辑树评估中产生无限递归
- Guardrail: 权重计算不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/encounter-condition-check-system.md`, scoped to this story:*

- [x] 逻辑树结构正确实现（嵌套AND/OR结构）
- [x] 权重分配机制正常（基础权重×修正系数）
- [x] 互斥组处理正确（同组奇遇互斥）
- [x] 权重重分配算法准确（加权随机选择）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用LogicTreeManager节点管理逻辑树和权重
- 实现build_logic_tree(condition_data)方法构建逻辑树结构
- 实现evaluate_logic_tree(tree_root)方法评估嵌套逻辑
- 实现calculate_adjusted_weights(encounters)方法计算调整后权重
- 实现handle_mutex_groups(mutex_data)方法处理互斥组
- 实现weighted_random_selection(weighted_encounters)方法执行加权随机选择
- 实现logic_tree_processed信号通知其他系统
- 与EncounterSystem、ConditionEvaluator和TriggerMechanismManager系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 条件类型与评估（处理条件评估逻辑）
- Story 002: 触发机制与事件（处理区域触发器和事件钩子）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 逻辑树结构正确实现
  - Given: 需要(A AND B) OR (C AND D)的嵌套结构
  - When: 系统构建逻辑树
  - Then: 正确解析嵌套AND/OR逻辑
  - Edge cases: 深度嵌套、复杂结构、单节点

- **AC-2**: 权重分配机制正常
  - Given: 基础权重为10，修正系数为1.5
  - When: 系统计算调整后权重
  - Then: 调整后权重 = 10 × 1.5 = 15
  - Edge cases: 不同基础权重、修正系数边界值、负权重

- **AC-3**: 互斥组处理正确
  - Given: 多个奇遇属于同一互斥组
  - When: 第一个奇遇被触发
  - Then: 同组其他奇遇永久锁定
  - Edge cases: 多个互斥组、组间依赖、组内权重

- **AC-4**: 权重重分配算法准确
  - Given: 多个奇遇同时满足条件
  - When: 系统执行加权随机选择
  - Then: 根据权重值进行加权随机选择
  - Edge cases: 相同权重、零权重、权重总和

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/encounter/logic_tree_and_weighting_test.gd` — must exist and pass

**Status**: [x] Completed

---

## Dependencies

- Depends on: Story 001 (条件类型与评估), Story 002 (触发机制与事件)
- Unlocks: None