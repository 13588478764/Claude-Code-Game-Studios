# Story 003: 升级与境界突破

> **Epic**: 经验值系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/experience-system.md`
**Requirement**: `TR-exp-sys-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理升级事件，利用数据结构管理境界突破逻辑

**Control Manifest Rules (this layer)**:
- Required: 升级与境界突破必须遵循GDD中定义的分段指数曲线和境界节点
- Forbidden: 禁止绕过升级检查直接提升等级或境界
- Guardrail: 升级过程不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/experience-system.md`, scoped to this story:*

- [x] 分段指数升级曲线正确实现（初期线性、中期温和指数、后期陡峭指数）
- [x] 境界突破机制正确实现（每10级大境界门槛、突破任务、奖励）
- [x] 属性点分配机制正确实现（每级5点属性点、1点天赋点）
- [x] 升级与境界突破特效正确触发（水墨风格、音效）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用LevelUpManager节点管理升级逻辑
- 实现check_level_up(exp_amount)方法检查是否升级
- 实现perform_level_up()方法执行升级逻辑
- 实现handle_realm_breakthrough()方法处理境界突破
- 实现grant_attribute_points()方法分配属性点
- 实现trigger_upgrade_effects()方法触发升级特效
- 与ExpCalculationManager、CharacterProgressionSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: EXP获取机制（处理EXP来源）
- Story 002: EXP计算与分配（处理EXP计算公式）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 分段指数升级曲线正确实现
  - Given: 玩家达到Lv 5（初期线性）
  - When: EXP达到升级要求时
  - Then: 成功升级并获得属性点
  - Edge cases: 初期、中期、后期不同曲线

- **AC-2**: 境界突破机制正确实现
  - Given: 玩家达到Lv 10（境界门槛）
  - When: 完成突破任务时
  - Then: 成功突破到筑基境界
  - Edge cases: 不同境界、突破任务、奖励发放

- **AC-3**: 属性点分配机制正确实现
  - Given: 玩家升级
  - When: 升级完成时
  - Then: 获得5个自由属性点和1个天赋点
  - Edge cases: 普通升级、境界突破、属性点使用

- **AC-4**: 升级与境界突破特效正确触发
  - Given: 玩家升级或突破境界
  - When: 升级/突破完成时
  - Then: 触发水墨风格特效和音效
  - Edge cases: 普通升级、境界突破、特殊成就

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/character/level_up_and_realm_breakthrough_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (EXP获取机制), Story 002 (EXP计算与分配)
- Unlocks: None