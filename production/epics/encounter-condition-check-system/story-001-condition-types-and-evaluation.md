# Story 001: 条件类型与评估

> **Epic**: 奇遇条件检查系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/encounter-condition-check-system.md`
**Requirement**: `TR-enc-cond-check-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数据结构管理条件类型，利用数学计算实现条件评估

**Control Manifest Rules (this layer)**:
- Required: 条件评估必须遵循GDD中定义的四种条件类型
- Forbidden: 禁止在条件评估中引入外部随机性
- Guardrail: 评估过程不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/encounter-condition-check-system.md`, scoped to this story:*

- [x] 四大类条件类型正确实现（时空环境、角色状态、进度历史、随机概率）
- [x] 条件评估逻辑正确（AND/OR逻辑组合）
- [x] 福缘修正系数正确应用（影响触发概率）
- [x] 条件评估结果准确（true/false）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用ConditionEvaluator节点管理条件评估逻辑
- 实现evaluate_temporal_environment_conditions(player_data)方法评估时空环境条件
- 实现evaluate_character_state_conditions(player_data)方法评估角色状态条件
- 实现evaluate_progress_history_conditions(progress_data)方法评估进度历史条件
- 实现evaluate_random_probability_conditions(luck_value)方法评估随机概率条件
- 实现condition_evaluated信号通知其他系统
- 与EncounterSystem、CharacterProgressionSystem和OpenWorldExplorationSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 触发机制与事件（处理区域触发器和事件钩子）
- Story 003: 逻辑树与权重（处理嵌套逻辑和权重分配）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 四大类条件类型正确实现
  - Given: 玩家福缘为50，在雷雨夜进入破庙区域
  - When: 系统评估《避雨遇高僧》奇遇条件
  - Then: 时空环境条件（位置、时间、天气）正确评估
  - Edge cases: 不同天气、不同时间、不同位置

- **AC-2**: 条件评估逻辑正确
  - Given: 需要位置==破庙 AND 时间==深夜 AND 天气==雨
  - When: 系统评估复合条件
  - Then: 使用AND逻辑组合，全部满足才返回true
  - Edge cases: OR逻辑、嵌套逻辑、混合逻辑

- **AC-3**: 福缘修正系数正确应用
  - Given: 基础概率为0.05，福缘修正系数为0.5
  - When: 系统计算最终触发概率
  - Then: 最终概率 = 0.05 × (1 + 0.5) = 0.075
  - Edge cases: 不同福缘值、福缘上限、负值修正

- **AC-4**: 条件评估结果准确
  - Given: 玩家生命值低于20%
  - When: 评估角色状态条件
  - Then: 返回true表示条件满足
  - Edge cases: 边界值、浮点精度、状态变化

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/encounter/condition_types_and_evaluation_test.gd` — must exist and pass

**Status**: [x] Completed

---

## Dependencies

- Unlocks: Story 002 (触发机制与事件), Story 003 (逻辑树与权重)