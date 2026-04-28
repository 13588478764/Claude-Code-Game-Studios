# Story 003: 连携系统

> **Epic**: 战斗系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/combat-system.md`
**Requirement**: `TR-combat-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，战斗系统

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot节点系统实现连携机制，利用信号系统处理连携事件

**Control Manifest Rules (this layer)**:
- Required: 连携系统必须支持队友间协作
- Forbidden: 禁止在连携系统中直接操作UI
- Guardrail: 连携计算性能不应影响游戏帧率

---

## Acceptance Criteria

*From GDD `design/gdd/combat-system.md`, scoped to this story:*

- [x] 连携槽系统正常工作（队友间共享积累）
- [x] 连击系统正常（同一角色连续命中敌人）
- [x] 连携攻击实现（追击和合体技）
- [x] 连携条件判定正确（消耗连携槽，满足触发条件）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 连携系统使用LinkSystemManager节点管理
- 实现LinkGauge类处理连携槽（队友间共享积累）
- 连击系统使用ComboTracker类管理（连续命中、伤害系数）
- 连携攻击使用LinkAttack类实现（追击Follow-up、合体技Dual Tech）
- 连携条件使用LinkCondition类判定（消耗条件、触发条件）

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 战斗机制核心
- Story 002: 弱点打击系统
- 战斗UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 连携槽系统正常工作
  - Given: 战斗开始，玩家和队友连携槽为空
  - When: 玩家使用普攻、完美格挡、击中弱点
  - Then: 连携槽积累，队友间共享
  - Edge cases: 槽满、队友离场、多回合积累

- **AC-2**: 连击系统正常
  - Given: 角色连续攻击同一敌人
  - When: 攻击命中
  - Then: 连击数递增，伤害系数提升
  - Edge cases: 被闪避重置、切换目标重置、最高连击数

- **AC-3**: 连携攻击实现
  - Given: 连携槽满，满足合体技条件
  - When: 选择合体技选项
  - Then: 发动合体技，消耗连携槽
  - Edge cases: 槽不足、条件不符、队友死亡

- **AC-4**: 连携条件判定正确
  - Given: 战斗中角色尝试发动连携
  - When: 检查连携条件
  - Then: 满足条件则可发动，不满足则禁用
  - Edge cases: 多种条件组合、条件动态变化、特殊状态

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/combat_link_system_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (战斗机制核心), Story 002 (弱点打击系统)
- Unlocks: None