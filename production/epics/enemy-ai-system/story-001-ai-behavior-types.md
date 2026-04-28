# Story 001: AI行为类型

> **Epic**: 敌人AI系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/enemy-ai-system.md`
**Requirement**: `TR-enemy-ai-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数据结构管理AI行为，利用评分系统实现战术决策

**Control Manifest Rules (this layer)**:
- Required: AI行为必须遵循GDD中定义的五种战术意识行为
- Forbidden: 禁止在行为选择中引入硬编码的特殊情况
- Guardrail: 行为评估不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/enemy-ai-system.md`, scoped to this story:*

- [x] 基础攻击行为正确实现（伤害期望值评估）
- [x] 弱点利用行为正确实现（破防优先、属性克制）
- [x] 状态管理行为正确实现（施加Debuff、解除Buff、控制链）
- [x] 生存本能行为正确实现（撤退/防御、集火威胁）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用EnemyBehaviorManager节点管理AI行为逻辑
- 实现evaluate_basic_attack(enemy_data, targets)方法评估基础攻击行为
- 实现evaluate_weakness_exploitation(enemy_data, targets)方法评估弱点利用行为
- 实现evaluate_status_management(enemy_data, targets)方法评估状态管理行为
- 实现evaluate_survival_instinct(enemy_data, targets)方法评估生存本能行为
- 实现evaluate_coordination(enemy_data, allies)方法评估连携配合行为
- 实现behavior_evaluated信号通知其他系统
- 与CombatSystem、StatusEffectSystem和MartialArtsSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: AI难度等级（处理难度调整和随机性）
- Story 003: AI决策机制（处理优先级评分表）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 基础攻击行为正确实现
  - Given: 敌人无特殊策略可用
  - When: AI评估基础攻击行为
  - Then: 选择伤害期望值最高的单体目标进行攻击
  - Edge cases: 多个目标伤害相近、技能冷却、内力不足

- **AC-2**: 弱点利用行为正确实现
  - Given: 玩家处于Break状态
  - When: AI评估弱点利用行为
  - Then: 优先使用高伤害技能进行终结
  - Edge cases: 属性克制、多个弱点目标、技能类型匹配

- **AC-3**: 状态管理行为正确实现
  - Given: 玩家血量健康且有增益状态
  - When: AI评估状态管理行为
  - Then: 优先施加Debuff或解除玩家Buff
  - Edge cases: 多种状态效果、控制链配合、状态抵抗

- **AC-4**: 生存本能行为正确实现
  - Given: 敌人HP < 30%且无治疗手段
  - When: AI评估生存本能行为
  - Then: 选择防御或撤退策略
  - Edge cases: 多个低血敌人、治疗手段可用、地形限制

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/ai_behavior_types_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (AI难度等级), Story 003 (AI决策机制)