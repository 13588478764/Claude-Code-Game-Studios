# Story 002: 奇遇奖励系统

> **Epic**: 奇遇系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/encounter-system.md`
**Requirement**: `TR-encounter-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，事件系统

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理奖励发放事件，利用内置数据结构管理奖励配置

**Control Manifest Rules (this layer)**:
- Required: 奇遇奖励必须基于奇遇类型，确保可预测性
- Forbidden: 禁止硬编码奖励数值，必须使用配置或公式
- Guardrail: 奖励计算不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/encounter-system.md`, scoped to this story:*

- [x] 奇遇奖励类型正常（江湖传闻、天材地宝、高人指点、失传秘籍、秘境挑战）
- [x] 奖励发放机制正确（银两、材料、属性点、武学等）
- [x] 福缘影响奖励质量（高福缘获得更好奖励）
- [x] 奖励冲突处理正常（背包满、重复武学等）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用EncounterRewardManager节点管理所有奖励逻辑
- 实现distribute_reward(encounter_type, luck_stat)方法发放奖励
- 实现generate_reward_package(encounter_type, luck_stat)方法生成奖励包
- 实现handle_reward_conflicts(rewards_list)方法处理奖励冲突
- 实现reward_distributed信号通知UI显示奖励
- 与EconomyManager、CharacterStats、MartialArtsManager等系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 奇遇触发系统（处理奇遇触发逻辑）
- Story 003: 奇遇记录管理（处理奇遇状态记录）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 奇遇奖励类型正常
  - Given: 玩家触发江湖传闻奇遇
  - When: 系统生成奖励
  - Then: 奖励为银两(200-500)和普通材料(5-10)
  - Edge cases: 天材地宝、高人指点、失传秘籍、秘境挑战

- **AC-2**: 奖励发放机制正确
  - Given: 玩家触发高人指点奇遇
  - When: 系统发放奖励
  - Then: 获得自由属性点(2-5)、天赋点(1-2)、武学熟练度(50-100)
  - Edge cases: 奖励数量准确性、类型正确性

- **AC-3**: 福缘影响奖励质量
  - Given: 玩家福缘为100触发天材地宝
  - When: 系统生成奖励
  - Then: 可能触发双倍奖励
  - Edge cases: 福缘为0、福缘为50、福缘为100

- **AC-4**: 奖励冲突处理正常
  - Given: 玩家背包已满时触发天材地宝
  - When: 系统尝试发放不可堆叠物品
  - Then: 不可堆叠物品转换为等值银两或EXP
  - Edge cases: 已学会武学、重复物品、容量限制

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/encounter/encounter_reward_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (奇遇触发系统)
- Unlocks: Story 003 (奇遇记录管理)