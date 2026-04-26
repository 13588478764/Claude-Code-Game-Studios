# Story 001: 战斗机制核心

> **Epic**: 战斗系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/combat-system.md`
**Requirement**: `TR-combat-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，战斗系统

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot节点系统实现战斗流程，利用信号系统处理战斗事件

**Control Manifest Rules (this layer)**:
- Required: 战斗逻辑必须可预测且可重现
- Forbidden: 禁止在战斗逻辑中直接操作UI
- Guardrail: 战斗计算性能不应影响游戏帧率

---

## Acceptance Criteria

*From GDD `design/gdd/combat-system.md`, scoped to this story:*

- [x] 回合制战斗机制正常工作（行动顺序、指令输入、执行演出）
- [x] 战斗资源系统正确实现（内力、架势、连击值、连携槽）
- [x] 战斗状态管理正常（Normal、Down、Break、Stun等）
- [x] 战斗流程阶段划分正确（遭遇、指令输入、执行演出、敌方回合、回合结束）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 战斗系统使用CombatManager节点作为主控制器
- 实现TurnOrderManager管理行动顺序
- 战斗资源使用CombatResource类管理（内力、架势、连击值、连携槽）
- 战斗状态使用枚举定义（Normal、Down、Break、Stun）
- 战斗流程使用状态机实现（Encounter、Input、Execution、Enemy、End）

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 弱点打击系统
- Story 003: 连携系统
- 战斗UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 回合制战斗机制正常工作
  - Given: 战斗开始，玩家角色身法为50，敌人身法为40
  - When: 生成行动队列
  - Then: 玩家角色在队列中位置优先于敌人
  - Edge cases: 相同身法值、多个敌人、队友加入

- **AC-2**: 战斗资源系统正确实现
  - Given: 战斗中角色内力上限为100，架势上限为80
  - When: 角色使用消耗50内力的技能，受到架势消耗30的攻击
  - Then: 内力减少50，架势减少30
  - Edge cases: 资源不足、资源回复、资源上限

- **AC-3**: 战斗状态管理正常
  - Given: 敌人处于Normal状态
  - When: 敌人架势归零
  - Then: 敌人进入Break状态
  - Edge cases: 状态转换、状态持续、状态解除

- **AC-4**: 战斗流程阶段划分正确
  - Given: 战斗开始
  - When: 进入指令输入阶段
  - Then: 时间暂停，玩家可选择指令
  - Edge cases: 阶段转换、阶段持续、阶段异常

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/combat_mechanics_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (弱点打击系统), Story 003 (连携系统)