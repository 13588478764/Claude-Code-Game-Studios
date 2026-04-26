# Story 002: 武学熟练度系统

> **Epic**: 武学系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/martial-arts-system.md`
**Requirement**: `TR-martial-arts-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化实现

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的Resource系统管理武学熟练度数据，利用信号系统处理熟练度更新事件

**Control Manifest Rules (this layer)**:
- Required: 熟练度数据必须正确保存和加载
- Forbidden: 禁止绕过熟练度系统直接提升武学等级
- Guardrail: 熟练度获取不应显著影响战斗性能

---

## Acceptance Criteria

*From GDD `design/gdd/martial-arts-system.md`, scoped to this story:*

- [ ] 玩家在战斗中使用武学可以获得熟练度
- [ ] 熟练度获取遵循公式：`熟练度获取 = 基础获取 × (1 + 幸运因子) × 连击倍率`
- [ ] 武学等级提升时提供相应效果（伤害提升、内力消耗降低、暴击伤害提升等）
- [ ] 熟练度数据正确保存和加载，不会丢失

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 熟练度数据存储在存档文件中，与角色数据一起保存
- 实现熟练度获取的计算函数，遵循GDD中的公式
- 通过信号系统通知UI更新武学等级显示
- 熟练度提升效果实时应用到武学属性

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 武学获取机制：由Story 001处理
- 武学装备和使用：由Story 003处理
- 武学组合系统：由Story 004处理
- 境界突破系统：由Story 005处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 玩家在战斗中使用武学可以获得熟练度
  - Given: 玩家在战斗中使用武学并命中敌人
  - When: 战斗结束时
  - Then: 武学熟练度按公式计算并增加
  - Edge cases: 检查不同品阶武学的基础获取值

- **AC-2**: 熟练度获取遵循公式
  - Given: 玩家使用地阶武学，幸运属性为20，处于连击状态
  - When: 武学命中敌人
  - Then: 获得39点熟练度（20×(1+0.2)×1.5）
  - Edge cases: 检查各种幸运值和连击状态下的熟练度计算

- **AC-3**: 武学等级提升时提供相应效果
  - Given: 武学达到升级条件
  - When: 熟练度增加触发等级提升
  - Then: 武学属性按GDD规定提升（伤害、内力消耗、暴击等）
  - Edge cases: 检查不同等级段的提升效果

- **AC-4**: 熟练度数据正确保存和加载
  - Given: 玩家获得武学熟练度
  - When: 游戏保存并重新加载
  - Then: 熟练度数据保持不变
  - Edge cases: 检查多次保存加载后的数据一致性

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/martial_arts/martial_arts_proficiency_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001: 武学获取机制
- Unlocks: Story 005: 境界突破系统