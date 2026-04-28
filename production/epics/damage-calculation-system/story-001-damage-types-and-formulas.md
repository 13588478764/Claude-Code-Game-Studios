# Story 001: 伤害类型与公式

> **Epic**: 伤害计算系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/damage-calculation-system.md`
**Requirement**: `TR-dmg-calc-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数学计算功能实现伤害公式，利用数据结构管理伤害类型

**Control Manifest Rules (this layer)**:
- Required: 伤害计算必须遵循GDD中定义的公式和规则
- Forbidden: 禁止绕过基础减法公式直接修改伤害值
- Guardrail: 计算过程不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/damage-calculation-system.md`, scoped to this story:*

- [x] 三种伤害类型正确实现（外功、内功、真实伤害）
- [x] 基础伤害计算公式正确（减法公式）
- [x] 攻防属性正确应用（力道/悟性 vs 根骨/内力抗性）
- [x] 最小伤害限制正常（不低于1点）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用DamageCalculator节点管理伤害计算逻辑
- 实现calculate_base_damage(attacker, defender, damage_type)方法计算基础伤害
- 实现apply_damage_type_rules(damage_type, base_damage)方法应用伤害类型规则
- 实现enforce_minimum_damage(final_damage)方法确保最小伤害为1
- 实现damage_calculated信号通知其他系统
- 与CombatSystem、CharacterProgressionSystem和EquipmentSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 伤害倍率与修正（处理乘法修正系数）
- Story 003: 伤害可视化与反馈（处理UI显示和特效）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 三种伤害类型正确实现
  - Given: 玩家使用外功武学攻击敌人
  - When: 伤害计算系统执行计算
  - Then: 系统正确使用力道(STR)和武器攻击力作为攻击力
  - Edge cases: 内功伤害、真实伤害、混合伤害类型

- **AC-2**: 基础伤害计算公式正确
  - Given: 攻击力为150，防御力为80
  - When: 系统计算基础伤害
  - Then: 基础伤害 = 150 - 80 = 70
  - Edge cases: 高攻击力、高防御力、相等攻防值

- **AC-3**: 攻防属性正确应用
  - Given: 玩家力道为100，敌人根骨为50
  - When: 计算外功伤害
  - Then: 使用力道vs根骨的对抗关系
  - Edge cases: 悟性vs内力抗性、装备防御加成

- **AC-4**: 最小伤害限制正常
  - Given: 基础伤害计算结果为-10
  - When: 系统处理最终伤害
  - Then: 最终伤害强制为1
  - Edge cases: 0伤害、负数伤害、极低伤害

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/combat/damage_types_and_formulas_test.gd` — must exist and pass

**Status**: [x] Completed

---

## Dependencies

- Unlocks: Story 002 (伤害倍率与修正), Story 003 (伤害可视化与反馈)