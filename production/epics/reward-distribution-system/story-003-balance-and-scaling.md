# Story 003: 平衡与缩放

> **Epic**: 奖励分配系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/reward-distribution-system.md`
**Requirement**: `TR-reward-dist-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数学函数和配置系统实现平衡与缩放机制

**Control Manifest Rules (this layer)**:
- Required: 必须实现等级/境界挂钩的数值缩放、通胀控制和背包容量管理
- Forbidden: 禁止硬编码平衡参数，必须使用可配置的公式
- Guardrail: 缩放计算不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/reward-distribution-system.md`, scoped to this story:*

- [x] 实现等级/境界挂钩的数值缩放（银两和经验值奖励随玩家当前等级线性增长）
- [x] 实现通胀控制机制（游戏后期低级材料奖励大幅减少，转而提供高级强化石或稀有宝石）
- [x] 实现背包容量管理（处理背包已满时的奖励发放，支持自动转换为等值银两或EXP）
- [x] 实现物品层级锁定（高等级区域不会掉落低级垃圾，低等级区域无法掉落神级装备）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现奖励数量缩放公式（最终奖励数量 = 基础奖励数量 × (1 + 玩家等级 × 等级缩放系数)）
- 实现通胀控制逻辑，根据游戏进度调整奖励类型
- 实现背包容量检查和溢出处理机制
- 实现物品层级锁定功能，确保奖励质量与区域等级匹配

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 奖励类型定义：由Story 001处理
- 奖励分配机制：由Story 002处理
- UI界面：由UI故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 实现等级/境界挂钩的数值缩放
  - Given: 不同玩家等级和基础奖励数量
  - When: 系统计算最终奖励数量
  - Then: 正确应用缩放公式（基础奖励数量 × (1 + 玩家等级 × 等级缩放系数)）
  - Edge cases: 检查等级为1和99的边界情况

- **AC-2**: 实现通胀控制机制
  - Given: 游戏后期阶段（高等级）
  - When: 系统选择奖励类型
  - Then: 低级材料奖励大幅减少，高级强化石或稀有宝石奖励增加
  - Edge cases: 检查中期过渡阶段的奖励平滑过渡

- **AC-3**: 实现背包容量管理
  - Given: 背包已满状态
  - When: 系统尝试发放不可堆叠物品
  - Then: 自动转换为等值的银两或EXP
  - Edge cases: 检查部分背包空间可用的情况

- **AC-4**: 实现物品层级锁定
  - Given: 不同区域等级和玩家等级
  - When: 系统选择物品奖励
  - Then: 高等级区域不掉落低级垃圾，低等级区域不掉落神级装备
  - Edge cases: 检查跨等级区域边界的物品选择

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/reward_distribution/balance_and_scaling_test.gd` — must exist and pass

**Status**: [x] Complete

---

## Dependencies

- Depends on: Story 001: 奖励类型与分类, Story 002: 分配机制
- Unlocks: None

## Completion Notes
**Completed**: 2026-04-28
**Criteria**: 4/4 passing
**Deviations**: None
**Test Evidence**: Logic: test file at tests/unit/reward_distribution/balance_and_scaling_test.gd (10 GUT tests)
**Code Review**: Pending
**Implementation Files**:
- src/scripts/reward_distribution/reward_balance_manager.gd (~250 lines)
- tests/unit/reward_distribution/balance_and_scaling_test.gd (10 tests)

**Implementation Quality**:
- ✅ 等级/境界挂钩数值缩放正确实现
- ✅ 通胀控制机制有效减少低级材料
- ✅ 背包容量管理处理溢出情况
- ✅ 物品层级锁定防止不匹配掉落
- ✅ 符合ADR-001架构指导
- ✅ 符合所有命名规范
- ✅ 性能优化，符合帧预算