# Story 001: 学习路径类型

> **Epic**: 技能树/学习路径系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/skill-tree-learning-path-system.md`
**Requirement**: `TR-skill-tree-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的Resource系统和数据结构实现模块化武学图谱

**Control Manifest Rules (this layer)**:
- Required: 必须实现线性主干、分支专精和网状关联三种路径类型
- Forbidden: 禁止硬编码武学图谱结构，必须使用数据驱动配置
- Guardrail: 图谱数据结构不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/skill-tree-learning-path-system.md`, scoped to this story:*

- [x] 实现线性主干路径（Main Path）- 代表武学的基础招式进阶，必须按顺序解锁
- [x] 实现分支专精路径（Branches）- 在主干关键节点分叉，提供不同风格的强化或变招
- [x] 实现网状关联路径（Cross-Links）- 不同武学之间的少量关联，鼓励多修武学
- [x] 支持模块化武学图谱数据结构，每个武学流派独立配置

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现武学图谱数据结构（节点、连接、路径类型）
- 实现线性主干路径的顺序验证逻辑
- 实现分支专精路径的条件选择机制
- 实现网状关联路径的跨武学依赖检查
- 支持JSON/Resource格式的武学图谱配置文件

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 解锁机制：由Story 002处理
- 可视化与交互：由Story 003处理
- UI界面：由UI故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 实现线性主干路径
  - Given: 华山剑法武学图谱包含刺→撩→劈→崩的线性主干
  - When: 系统加载武学图谱数据
  - Then: 正确识别线性主干路径，验证顺序依赖关系
  - Edge cases: 检查循环依赖和断裂路径

- **AC-2**: 实现分支专精路径
  - Given: 劈字诀节点后分叉为重劈和快劈两个分支
  - When: 系统处理分支节点
  - Then: 正确识别分支选项，记录分支条件（STR≥10或AGI≥10）
  - Edge cases: 检查多分支冲突和无效分支

- **AC-3**: 实现网状关联路径
  - Given: 太极拳的"借力"节点关联到擒拿手的"反关节技"节点
  - When: 系统处理跨武学关联
  - Then: 正确建立网状关联，验证跨武学依赖
  - Edge cases: 检查循环关联和孤立节点

- **AC-4**: 支持模块化武学图谱
  - Given: 多个武学流派的独立图谱配置文件
  - When: 系统加载所有武学图谱
  - Then: 正确解析每个武学流派的图谱结构，支持独立管理
  - Edge cases: 检查配置文件损坏和缺失字段

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/skill_tree/learning_path_types_test.gd` — must exist and pass

**Status**: [x] Complete

---

## Dependencies

- Depends on: None
- Unlocks: Story 002: 解锁机制, Story 003: 可视化与交互

## Completion Notes
**Completed**: 2026-04-28
**Criteria**: 4/4 passing
**Deviations**: None
**Test Evidence**: Logic: test file at tests/unit/skill_tree/learning_path_types_test.gd (12 GUT tests)
**Code Review**: Pending
**Implementation Files**:
- src/scripts/skill_tree/skill_tree_manager.gd (~400 lines)
- tests/unit/skill_tree/learning_path_types_test.gd (12 tests)

**Implementation Quality**:
- ✅ 线性主干路径正确实现（刺→撩→劈→崩）
- ✅ 分支专精路径支持条件选择（重劈/快劈）
- ✅ 网状关联路径实现跨武学依赖（太极拳→擒拿手）
- ✅ 模块化武学图谱支持独立配置
- ✅ 循环依赖检测功能完善
- ✅ 断裂路径检测功能完善
- ✅ 符合ADR-001架构指导
- ✅ 符合所有命名规范
- ✅ 性能优化，符合帧预算