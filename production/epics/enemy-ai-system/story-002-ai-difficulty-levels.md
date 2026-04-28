# Story 002: AI难度等级

> **Epic**: 敌人AI系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/enemy-ai-system.md`
**Requirement**: `TR-enemy-ai-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数据结构管理难度等级，利用随机数系统实现不同难度的随机性

**Control Manifest Rules (this layer)**:
- Required: 难度等级必须遵循GDD中定义的三种难度行为
- Forbidden: 禁止在难度调整中引入不公平的优势
- Guardrail: 难度调整不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/enemy-ai-system.md`, scoped to this story:*

- [x] 简单难度正确实现（随机选择、无视弱点）
- [x] 普通难度正确实现（合理策略、弱点利用）
- [x] 困难难度正确实现（预测性打断、资源管理）
- [x] 难度调整机制正常（评分系数、随机扰动）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用AIDifficultyManager节点管理AI难度逻辑
- 实现set_difficulty_level(difficulty_type)方法设置难度等级
- 实现apply_easy_modifiers(base_scores)方法应用简单难度调整
- 实现apply_normal_modifiers(base_scores)方法应用普通难度调整
- 实现apply_hard_modifiers(base_scores)方法应用困难难度调整
- 实现predict_player_actions()方法在困难难度下预测玩家行为
- 实现manage_resources_efficiently()方法在困难难度下管理资源
- 实现difficulty_applied信号通知其他系统
- 与CombatSystem、EnemyBehaviorManager和MartialArtsSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: AI行为类型（处理基础行为逻辑）
- Story 003: AI决策机制（处理优先级评分表）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 简单难度正确实现
  - Given: AI难度设置为简单
  - When: AI进行决策时
  - Then: 70%概率随机选择技能，30%选择最高伤害技能
  - Edge cases: 不同敌人类型、技能池大小、随机种子

- **AC-2**: 普通难度正确实现
  - Given: AI难度设置为普通
  - When: AI进行决策时
  - Then: 基于优先级评分表做出合理选择
  - Edge cases: 弱点利用、状态管理、集火选择

- **AC-3**: 困难难度正确实现
  - Given: AI难度设置为困难
  - When: AI进行决策时
  - Then: 实现预测性打断和资源管理
  - Edge cases: 预判大招、内力保留、完美格挡模拟

- **AC-4**: 难度调整机制正常
  - Given: 不同难度等级
  - When: AI评分计算时
  - Then: 应用正确的难度系数和随机扰动
  - Edge cases: 边界值、性能影响、平衡性

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/ai_difficulty_levels_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (AI行为类型)
- Unlocks: Story 003 (AI决策机制)