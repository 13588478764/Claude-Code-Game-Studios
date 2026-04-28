# Story 001: EXP获取机制

> **Epic**: 经验值系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/experience-system.md`
**Requirement**: `TR-exp-sys-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数据结构管理EXP获取，利用事件系统处理不同来源的EXP奖励

**Control Manifest Rules (this layer)**:
- Required: EXP获取必须遵循GDD中定义的三大类来源机制
- Forbidden: 禁止绕过基础获取规则直接修改EXP值
- Guardrail: 获取机制不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/experience-system.md`, scoped to this story:*

- [x] 战斗收益正确实现（击败敌人、完美胜利、连携奖励）
- [x] 探索与奇遇收益正确实现（首次探索、完成奇遇、收集图鉴）
- [x] 任务进度收益正确实现（主线、支线、日常任务）
- [x] EXP获取来源清晰可追溯（战斗、探索、任务）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用ExpAcquisitionManager节点管理EXP获取逻辑
- 实现grant_combat_exp(enemy_data, battle_result)方法处理战斗收益
- 实现grant_exploration_exp(region_data, discovery_type)方法处理探索收益
- 实现grant_encounter_exp(encounter_data, completion_result)方法处理奇遇收益
- 实现grant_quest_exp(quest_data, completion_type)方法处理任务收益
- 实现exp_granted信号通知其他系统
- 与CombatSystem、EncounterSystem、QuestSystem和ExplorationSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: EXP计算与分配（处理EXP计算公式和队伍分配）
- Story 003: 升级与境界突破（处理升级逻辑和境界突破）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 战斗收益正确实现
  - Given: 玩家击败一个等级为10的敌人
  - When: 战斗结束时
  - Then: 获得基础EXP奖励
  - Edge cases: 完美胜利、连携奖励、不同敌人类型

- **AC-2**: 探索与奇遇收益正确实现
  - Given: 玩家首次探索新区域
  - When: 解锁传送点时
  - Then: 获得一次性EXP奖励
  - Edge cases: 不同区域、奇遇完成、图鉴收集

- **AC-3**: 任务进度收益正确实现
  - Given: 玩家完成主线任务
  - When: 任务提交时
  - Then: 获得大量EXP奖励
  - Edge cases: 支线任务、日常任务、任务类型差异

- **AC-4**: EXP获取来源清晰可追溯
  - Given: 玩家获得EXP
  - When: EXP到账时
  - Then: 系统记录EXP来源类型
  - Edge cases: 多来源同时获得、来源追踪准确性

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/character/exp_acquisition_mechanisms_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (EXP计算与分配), Story 003 (升级与境界突破)