# Story 002: EXP计算与分配

> **Epic**: 经验值系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/experience-system.md`
**Requirement**: `TR-exp-sys-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数学函数实现EXP计算公式，利用数据结构管理队伍分配逻辑

**Control Manifest Rules (this layer)**:
- Required: EXP计算必须遵循GDD中定义的公式和修正系数
- Forbidden: 禁止绕过基础计算公式直接修改EXP值
- Guardrail: 计算过程不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/experience-system.md`, scoped to this story:*

- [x] 基础经验值公式正确实现（敌人基础值、等级缩放）
- [x] 等级缩放修正公式正确实现（等级差异、悟性修正、全局倍率）
- [x] 队伍EXP分配公式正确实现（参与系数、队伍人数）
- [x] 分段指数升级曲线正确实现（初期、中期、后期）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用ExpCalculationManager节点管理EXP计算逻辑
- 实现calculate_base_exp(enemy_data, player_level)方法计算基础EXP
- 实现apply_level_scaling(exp, enemy_level, player_level)方法应用等级缩放
- 实现apply_wisdom_bonus(exp, wisdom_attribute)方法应用悟性修正
- 实现distribute_party_exp(total_exp, party_members)方法处理队伍分配
- 实现calculate_level_curve(current_level)方法计算升级曲线
- 与ExpAcquisitionManager、CharacterProgressionSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: EXP获取机制（处理EXP来源）
- Story 003: 升级与境界突破（处理升级逻辑和境界突破）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 基础经验值公式正确实现
  - Given: 玩家击败等级为10的敌人（基础值50）
  - When: EXP计算时
  - Then: 按照基础公式计算EXP
  - Edge cases: 不同敌人类型、不同等级差

- **AC-2**: 等级缩放修正公式正确实现
  - Given: 玩家悟性为50，击败高等级敌人
  - When: EXP计算时
  - Then: 应用悟性修正和等级差异修正
  - Edge cases: 最高+50%加成，最低-80%惩罚

- **AC-3**: 队伍EXP分配公式正确实现
  - Given: 队伍中有2名角色（1参战1后备）
  - When: 获得200EXP时
  - Then: 参战角色获得100EXP，后备角色获得50EXP
  - Edge cases: 不同队伍规模、不同参与系数

- **AC-4**: 分段指数升级曲线正确实现
  - Given: 玩家达到升级所需EXP
  - When: 升级检查时
  - Then: 按照分段指数曲线计算升级
  - Edge cases: 初期线性、中期温和指数、后期陡峭指数

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/character/exp_calculation_and_distribution_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (EXP获取机制)
- Unlocks: Story 003 (升级与境界突破)