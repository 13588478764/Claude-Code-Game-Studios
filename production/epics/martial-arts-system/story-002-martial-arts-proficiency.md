# Story 002: 武学熟练度系统

> **Epic**: 武学系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/martial-arts-system.md`
**Requirement**: `TR-martial-arts-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，战斗系统实现

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的Resource系统管理武学数据，利用信号系统处理熟练度变化事件

**Control Manifest Rules (this layer)**:
- Required: 熟练度系统必须遵循GDD中定义的升级规则
- Forbidden: 禁止绕过熟练度系统直接修改武学威力
- Guardrail: 熟练度计算不应影响战斗性能

---

## Acceptance Criteria

*From GDD `design/gdd/martial-arts-system.md`, scoped to this story:*

- [x] 熟练度获取机制正常工作（基于基础获取、幸运因子、连击倍率）
- [x] 熟练度升级效果正常（伤害提升、内力消耗降低、暴击伤害提升）
- [x] 境界突破功能正常（消耗资源进行突破，解锁新效果）
- [x] 熟练度对武学伤害计算的影响正确实现

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现熟练度获取公式：`熟练度获取 = 基础获取 × (1 + 幸运因子) × 连击倍率`
- 实现熟练度升级效果（Lv.1-5、Lv.6-9、Lv.11-14、Lv.15）
- 实现境界突破机制（消耗银两、丹药等资源）
- 通过信号系统通知UI更新熟练度显示

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 武学获取机制：由Story 001处理
- 武学装备和使用：由Story 003处理
- 武学组合系统：由Story 004处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 熟练度获取机制正常工作
  - Given: 玩家使用武学命中敌人
  - When: 计算熟练度获取
  - Then: 根据基础获取、幸运因子、连击倍率正确计算
  - Edge cases: 检查不同品阶武学和连击状态的影响

- **AC-2**: 熟练度升级效果正常
  - Given: 武学熟练度达到升级条件
  - When: 熟练度提升
  - Then: 伤害、内力消耗、暴击伤害等属性按规则变化
  - Edge cases: 检查各等级段的升级效果

- **AC-3**: 境界突破功能正常
  - Given: 武学达到突破等级（Lv.5/Lv.10/Lv.15）
  - When: 消耗资源进行突破
  - Then: 解锁新效果，可能失败但不损失熟练度
  - Edge cases: 检查资源不足和失败情况

- **AC-4**: 熟练度对伤害计算的影响正确
  - Given: 武学具有不同熟练度等级
  - When: 计算武学伤害
  - Then: 伤害值根据熟练度正确调整
  - Edge cases: 检查熟练度上限和各种加成组合

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/martial_arts/martial_arts_proficiency_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001: 武学获取机制
- Unlocks: Story 003: 武学装备和使用, Story 004: 武学组合系统