# Story 003: 任务奖励发放

> **Epic**: 任务系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/quest-system.md`
**Requirement**: `TR-quest-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化实现

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理奖励发放事件，通过数据结构管理不同类型的奖励

**Control Manifest Rules (this layer)**:
- Required: 任务奖励必须与角色成长系统、经济系统和装备系统正确集成
- Forbidden: 禁止绕过奖励系统直接发放任务奖励
- Guardrail: 奖励发放不应超过性能预算（<5ms处理时间）

---

## Acceptance Criteria

*From GDD `design/gdd/quest-system.md`, scoped to this story:*

- [x] 任务奖励系统支持不同类型的任务（主线、支线、悬赏、奇遇）和相应奖励
- [x] 奖励发放遵循公式（如主线任务：经验值=玩家等级×100，银两=玩家等级×50）
- [x] 奖励发放时检查玩家背包容量，背包满时使用临时储物箱
- [x] 奖励发放后正确更新玩家属性和资源

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现任务奖励的数据结构和类型定义
- 通过信号系统通知相关系统奖励发放
- 实现背包容量检查和临时储物箱逻辑
- 集成奖励与角色成长、经济、装备系统的接口

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 任务状态管理：由Story 001处理
- 任务追踪系统：由Story 002处理
- 任务UI界面：由UI故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 任务奖励系统支持不同类型的任务和相应奖励
  - Given: 玩家完成不同类型的任务
  - When: 任务状态变为FINISHED
  - Then: 系统根据任务类型发放相应奖励（主线-经验值+银两+关键道具等）
  - Edge cases: 检查每种任务类型奖励的准确性和数量

- **AC-2**: 奖励发放遵循公式
  - Given: 玩家等级为10，完成主线任务
  - When: 任务奖励发放
  - Then: 获得1000经验值（10×100）和500银两（10×50）
  - Edge cases: 检查不同等级和任务类型的奖励计算

- **AC-3**: 奖励发放时检查玩家背包容量
  - Given: 玩家背包已满
  - When: 系统尝试发放物品奖励
  - Then: 物品通过临时储物箱发放，玩家可在主城仓库领取
  - Edge cases: 检查不同物品类型的处理

- **AC-4**: 奖励发放后正确更新玩家属性和资源
  - Given: 玩家获得任务奖励
  - When: 奖励发放完成
  - Then: 玩家经验值、银两、装备等数据正确更新
  - Edge cases: 检查多种奖励同时发放的处理

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/quest/quest_reward_distribution_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001: 任务状态管理
- Unlocks: None