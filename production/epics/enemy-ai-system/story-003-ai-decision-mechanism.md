# Story 003: AI决策机制

> **Epic**: 敌人AI系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/enemy-ai-system.md`
**Requirement**: `TR-enemy-ai-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数据结构实现优先级评分表，利用数学计算进行决策评分

**Control Manifest Rules (this layer)**:
- Required: 决策机制必须使用优先级评分表方法
- Forbidden: 禁止使用复杂的神经网络或机器学习算法
- Guardrail: 评分计算不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/enemy-ai-system.md`, scoped to this story:*

- [x] 优先级评分表正确实现（基础评分+修正项）
- [x] 候选动作生成正确（可用技能遍历）
- [x] 评分计算机制准确（权重系数应用）
- [x] 最佳动作选择正确（最高分选择）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用AIDecisionManager节点管理AI决策逻辑
- 实现generate_candidate_actions(enemy_data)方法生成候选动作列表
- 实现calculate_action_score(action, target, modifiers)方法计算动作评分
- 实现apply_score_modifiers(base_score, battlefield_context)方法应用评分修正
- 实现select_best_action(scored_actions)方法选择最佳动作
- 实现execute_selected_action(best_action)方法执行选定动作
- 实现decision_made信号通知其他系统
- 与CombatSystem、EnemyBehaviorManager和AIDifficultyManager系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: AI行为类型（处理基础行为逻辑）
- Story 002: AI难度等级（处理难度调整和随机性）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 优先级评分表正确实现
  - Given: 敌人需要选择行动
  - When: 系统计算动作评分时
  - Then: 使用基础评分+修正项的公式计算最终评分
  - Edge cases: 高分动作、负分动作、边界值

- **AC-2**: 候选动作生成正确
  - Given: 敌人拥有多个可用技能
  - When: 系统生成候选动作时
  - Then: 遍历所有可用技能生成候选列表
  - Edge cases: 技能冷却、内力不足、目标限制

- **AC-3**: 评分计算机制准确
  - Given: 战场存在多个目标和状态
  - When: 系统计算动作评分时
  - Then: 正确应用权重系数进行评分
  - Edge cases: 多重修正、状态叠加、距离因素

- **AC-4**: 最佳动作选择正确
  - Given: 系统计算出多个动作评分
  - When: 选择最佳动作时
  - Then: 选择总分最高的动作和目标组合
  - Edge cases: 平分情况、性能影响、实时性

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/ai_decision_mechanism_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (AI行为类型), Story 002 (AI难度等级)
- Unlocks: None