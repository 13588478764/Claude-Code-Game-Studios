# Story 002: 弱点打击系统

> **Epic**: 战斗系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/combat-system.md`
**Requirement**: `TR-combat-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，战斗系统

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot节点系统实现弱点检测，利用信号系统处理弱点打击事件

**Control Manifest Rules (this layer)**:
- Required: 弱点检测必须基于属性克制关系
- Forbidden: 禁止在弱点系统中直接操作UI
- Guardrail: 弱点计算性能不应影响游戏帧率

---

## Acceptance Criteria

*From GDD `design/gdd/combat-system.md`, scoped to this story:*

- [x] 属性克制系统正确实现（金/木/水/火/土）
- [x] 弱点打击判定正常工作（使用克制属性攻击弱点）
- [x] 击倒机制正常（敌人跳过下回合，易伤）
- [x] 总攻击触发条件正确（全场敌人均Down时可发动）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 弱点系统使用WeaknessManager节点管理
- 实现ElementalWeakness类处理属性克制关系
- 弱点打击使用WeaknessHit类处理（伤害计算、状态变更）
- 击倒机制使用DownState类管理（跳过回合、易伤状态）
- 总攻击使用AllOutAttack类实现（触发条件、伤害计算）

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 战斗机制核心
- Story 003: 连携系统
- 战斗UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 属性克制系统正确实现
  - Given: 敌人弱点为火属性，角色使用金属性武学
  - When: 攻击命中
  - Then: 触发属性克制效果，伤害系数为1.5
  - Edge cases: 相同属性、无克制关系、多属性敌人

- **AC-2**: 弱点打击判定正常工作
  - Given: 敌人处于Normal状态，弱点部位暴露
  - When: 使用克制属性攻击弱点
  - Then: 触发弱点打击效果
  - Edge cases: 非克制属性、非弱点部位、敌人防御状态

- **AC-3**: 击倒机制正常
  - Given: 敌人被弱点打击命中
  - When: 触发击倒效果
  - Then: 敌人跳过下回合，进入易伤状态
  - Edge cases: 已处于其他状态、免疫击倒、多敌人

- **AC-4**: 总攻击触发条件正确
  - Given: 战场中所有敌人都处于Down状态
  - When: 检查总攻击触发条件
  - Then: 总攻击按钮可用，可发动终结技
  - Edge cases: 部分敌人Down、Boss免疫、特殊敌人

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/weakness_system_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (战斗机制核心)
- Unlocks: Story 003 (连携系统)