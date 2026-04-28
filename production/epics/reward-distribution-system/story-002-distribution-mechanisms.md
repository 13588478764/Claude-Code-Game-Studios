# Story 002: 分配机制

> **Epic**: 奖励分配系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/reward-distribution-system.md`
**Requirement**: `TR-reward-dist-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的随机数生成器和权重计算实现分配机制

**Control Manifest Rules (this layer)**:
- Required: 必须实现固定基础奖励、权重化随机池、层级掉落表和唯一性限制
- Forbidden: 禁止使用纯随机分配，必须考虑玩家属性和游戏进度
- Guardrail: 分配机制计算不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/reward-distribution-system.md`, scoped to this story:*

- [x] 实现固定基础奖励机制（每个奇遇/任务定义固定的保底奖励）
- [x] 实现权重化随机池机制（支持福缘属性对稀有物品权重的修正）
- [x] 实现层级掉落表机制（根据区域等级或奇遇难度选择不同层级的奖励表）
- [x] 实现唯一性限制机制（关键物品在每个存档中只能获得一次）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现固定奖励配置和发放功能
- 实现权重化随机池算法，支持动态权重调整
- 实现层级掉落表选择和管理功能
- 实现唯一性检查和冲突处理机制

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 奖励类型定义：由Story 001处理
- 奖励平衡与缩放：由Story 003处理
- UI界面：由UI故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 实现固定基础奖励机制
  - Given: 奇遇配置包含固定基础奖励
  - When: 系统处理奖励分配
  - Then: 正确发放固定基础奖励
  - Edge cases: 检查空奖励配置和无效奖励类型

- **AC-2**: 实现权重化随机池机制
  - Given: 玩家具有不同福缘属性值
  - When: 系统计算随机池权重
  - Then: 稀有物品权重正确修正（原始权重 × (1 + 福缘/100)）
  - Edge cases: 检查福缘为0和最大值的情况

- **AC-3**: 实现层级掉落表机制
  - Given: 不同区域等级和玩家等级
  - When: 系统选择掉落层级
  - Then: 正确计算掉落层级（min(最大层级, 玩家等级 / 层级间隔)）
  - Edge cases: 检查边界等级和超出范围的情况

- **AC-4**: 实现唯一性限制机制
  - Given: 玩家已拥有唯一物品
  - When: 系统进行唯一性检查
  - Then: 自动替换为等值的银两或通用材料
  - Edge cases: 检查多个唯一物品冲突和替换逻辑

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/reward_distribution/distribution_mechanisms_test.gd` — must exist and pass

**Status**: [x] Complete

---

## Dependencies

- Depends on: Story 001: 奖励类型与分类
- Unlocks: Story 003: 平衡与缩放

## Completion Notes
**Completed**: 2026-04-28
**Criteria**: 4/4 passing
**Deviations**: None
**Test Evidence**: Logic: test file at tests/unit/reward_distribution/distribution_mechanisms_test.gd (9 GUT tests)
**Code Review**: Pending
**Implementation Files**:
- src/scripts/reward_distribution/reward_distribution_manager.gd (~280 lines)
- tests/unit/reward_distribution/distribution_mechanisms_test.gd (9 tests)

**Implementation Quality**:
- ✅ 固定基础奖励机制正确实现
- ✅ 权重化随机池支持福缘属性修正
- ✅ 层级掉落表机制正确计算
- ✅ 唯一性限制机制防止重复获得
- ✅ 符合ADR-001架构指导
- ✅ 符合所有命名规范
- ✅ 性能优化，符合帧预算