# Story 004: 武学组合系统

> **Epic**: 武学系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/martial-arts-system.md`
**Requirement**: `TR-martial-arts-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，战斗系统实现

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的Resource系统管理武学数据，利用信号系统处理武学组合事件

**Control Manifest Rules (this layer)**:
- Required: 武学组合必须遵循GDD中定义的流派羁绊和心法回路规则
- Forbidden: 禁止绕过组合系统直接修改武学效果
- Guardrail: 组合计算不应影响战斗性能

---

## Acceptance Criteria

*From GDD `design/gdd/martial-arts-system.md`, scoped to this story:*

- [x] 武学组合系统正常工作（支持同流派和跨流派组合）
- [x] 流派羁绊效果正常（2件套、3件套、4件套效果）
- [x] 心法回路系统正常（主、副、辅心法槽位）
- [x] 组合效果对武学伤害和特性的影响正确实现

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现武学组合逻辑（同流派加成、跨流派特效）
- 实现流派羁绊系统（少林、武当、唐门、丐帮、逍遥等）
- 实现心法回路系统（3个槽位，五行相生等效果）
- 通过信号系统通知UI更新组合效果显示

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 武学获取机制：由Story 001处理
- 武学熟练度系统：由Story 002处理
- 武学装备和使用：由Story 003处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 武学组合系统正常工作
  - Given: 玩家装备多个武学
  - When: 满足组合条件
  - Then: 组合效果正确激活
  - Edge cases: 检查不同流派组合和数量限制

- **AC-2**: 流派羁绊效果正常
  - Given: 玩家装备同一流派多个武学
  - When: 满足羁绊条件
  - Then: 羁绊效果正确应用
  - Edge cases: 检查各流派2/3/4件套效果

- **AC-3**: 心法回路系统正常
  - Given: 玩家装备心法到不同槽位
  - When: 激活心法效果
  - Then: 回路效应正确触发
  - Edge cases: 检查心法冲突和优先级

- **AC-4**: 组合效果对武学的影响正确
  - Given: 武学处于不同组合状态
  - When: 计算武学属性
  - Then: 属性根据组合效果正确调整
  - Edge cases: 检查多重效果叠加和上限

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/martial_arts/martial_arts_combo_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001: 武学获取机制, Story 002: 武学熟练度系统, Story 003: 武学装备和使用
- Unlocks: None