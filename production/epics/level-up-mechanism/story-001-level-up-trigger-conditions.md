# Story 001: 等级提升触发条件

> **Epic**: 等级提升机制
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/level-up-mechanism.md`
**Requirement**: `TR-level-up-mech-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号机制处理等级提升事件

**Control Manifest Rules (this layer)**:
- Required: 等级提升触发必须遵循GDD中定义的双阶段机制
- Forbidden: 禁止在小境界提升时要求玩家手动确认
- Guardrail: 大境界突破必须验证所有条件后才允许执行

---

## Acceptance Criteria

*From GDD `design/gdd/level-up-mechanism.md`, scoped to this story:*

- [x] 实现小境界提升（自动触发）
- [x] 实现大境界突破（手动确认+条件验证）
- [x] 实现EXP阈值计算
- [x] 实现圆满状态检测

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用LevelUpManager节点管理等级提升逻辑
- 实现trigger_minor_realm_up()方法处理小境界提升
- 实现trigger_major_realm_breakthrough()方法处理大境界突破
- 实现calculate_exp_threshold()方法计算升级所需EXP
- 实现check_perfect_state()方法检测圆满状态
- 与ExperienceSystem、CharacterProgressionSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 属性点分配（处理属性点分配逻辑）
- Story 003: 等级上限与突破（处理境界结构和上限）
- UI显示（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现小境界提升
  - Given: 玩家累积EXP达到当前层级阈值
  - When: EXP条填满时
  - Then: 角色立即提升1级，恢复满血/满内力
  - Edge cases: EXP刚好达到阈值、EXP超过阈值很多、EXP计算溢出

- **AC-2**: 实现大境界突破
  - Given: 玩家达到当前大境界最高级且EXP已满
  - When: 玩家点击"闭关突破"按钮
  - Then: 验证突破条件并执行突破逻辑
  - Edge cases: 缺少突破道具、未完成前置任务、突破失败

- **AC-3**: 实现EXP阈值计算
  - Given: 当前小境界等级和境界难度系数
  - When: 计算升级所需EXP
  - Then: 正确应用公式计算所需EXP
  - Edge cases: 最低等级、最高等级、极高难度系数

- **AC-4**: 实现圆满状态检测
  - Given: 玩家达到当前大境界最高级
  - When: 检查角色状态
  - Then: 正确识别圆满状态并阻止自动升级
  - Edge cases: 刚达到圆满、即将突破、EXP继续获得

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/character/level_up_trigger_conditions_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (属性点分配), Story 003 (等级上限与突破)