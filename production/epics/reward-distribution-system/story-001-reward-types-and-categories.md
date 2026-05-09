# Story 001: 奖励类型与分类

> **Epic**: 奖励分配系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/reward-distribution-system.md`
**Requirement**: `TR-reward-dist-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数据结构和JSON序列化实现奖励类型定义

**Control Manifest Rules (this layer)**:
- Required: 奖励类型必须支持四大类分类（物质资源、成长资源、装备物品、叙事状态）
- Forbidden: 禁止硬编码奖励类型，必须使用数据驱动配置
- Guardrail: 奖励类型定义不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/reward-distribution-system.md`, scoped to this story:*

- [x] 实现物质资源奖励类型（银两、基础材料、稀有材料）
- [x] 实现成长资源奖励类型（经验值、武学熟练度/残页、属性点/天赋点）
- [x] 实现装备与物品奖励类型（成品装备、消耗品、特殊道具）
- [x] 实现叙事与状态奖励类型（声望/善恶值、临时Buff、奇遇专属称号）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现奖励类型枚举和数据结构
- 实现奖励配置数据加载和解析
- 实现奖励类型验证和分类功能
- 支持JSON配置文件定义奖励类型

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 奖励分配机制：由Story 002处理
- 奖励平衡与缩放：由Story 003处理
- UI界面：由UI故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 实现物质资源奖励类型
  - Given: 奖励配置包含银两、基础材料、稀有材料
  - When: 系统加载奖励类型定义
  - Then: 正确识别和分类物质资源奖励
  - Edge cases: 检查无效材料类型和边界值

- **AC-2**: 实现成长资源奖励类型
  - Given: 奖励配置包含EXP、武学熟练度、属性点
  - When: 系统处理成长资源奖励
  - Then: 正确识别和分类成长资源奖励
  - Edge cases: 检查负值和超大数值

- **AC-3**: 实现装备与物品奖励类型
  - Given: 奖励配置包含装备、消耗品、特殊道具
  - When: 系统处理装备物品奖励
  - Then: 正确识别和分类装备物品奖励
  - Edge cases: 检查未定义的物品ID和重复物品

- **AC-4**: 实现叙事与状态奖励类型
  - Given: 奖励配置包含声望、Buff、称号
  - When: 系统处理叙事状态奖励
  - Then: 正确识别和分类叙事状态奖励
  - Edge cases: 检查无效状态效果和冲突状态

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/reward_distribution/reward_types_and_categories_test.gd` — must exist and pass

**Status**: [x] Complete

---

## Dependencies

- Depends on: None
- Unlocks: Story 002: 分配机制, Story 003: 平衡与缩放

## Completion Notes
**Completed**: 2026-04-28
**Criteria**: 4/4 passing
**Deviations**: None
**Test Evidence**: Logic: test file at tests/unit/reward_distribution/reward_types_and_categories_test.gd (8 GUT tests)
**Code Review**: Pending
**Implementation Files**:
- src/scripts/reward_distribution/reward_type_manager.gd (~250 lines)
- tests/unit/reward_distribution/reward_types_and_categories_test.gd (8 tests)

**Implementation Quality**:
- ✅ 完整的奖励类型枚举和数据结构
- ✅ 四大类奖励类型正确实现
- ✅ 数据驱动配置支持
- ✅ 符合ADR-001架构指导
- ✅ 符合所有命名规范
- ✅ 性能优化，符合帧预算