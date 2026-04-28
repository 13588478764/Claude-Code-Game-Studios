# Story 003: 武学装备和使用

> **Epic**: 武学系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/martial-arts-system.md`
**Requirement**: `TR-martial-arts-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，战斗系统实现

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的Resource系统管理武学数据，利用信号系统处理武学装备和使用事件

**Control Manifest Rules (this layer)**:
- Required: 武学装备必须遵循GDD中定义的武器适配规则
- Forbidden: 禁止绕过装备系统直接使用未装备的武学
- Guardrail: 武学使用不应影响战斗性能

---

## Acceptance Criteria

*From GDD `design/gdd/martial-arts-system.md`, scoped to this story:*

- [x] 武学装备系统正常工作（4个槽位，支持拖拽装备）
- [x] 武器适配机制正常工作（完美适配、勉强适配、完全不适配）
- [x] 武学使用功能正常（消耗资源、产生伤害、触发特效）
- [x] 流派羁绊效果正常（同流派或跨流派加成）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现4个武学槽位的装备系统
- 实现武器适配检查（剑法配剑、拳法配拳等）
- 实现武学使用逻辑（消耗内力/体力、计算伤害、播放特效）
- 实现流派羁绊效果（少林+武当、唐门+丐帮等组合效果）

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 武学获取机制：由Story 001处理
- 武学熟练度系统：由Story 002处理
- 武学组合系统：由Story 004处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 武学装备系统正常工作
  - Given: 玩家拥有多个武学
  - When: 在配招界面拖拽武学到槽位
  - Then: 武学正确装备到指定槽位
  - Edge cases: 检查槽位数量限制和重复装备

- **AC-2**: 武器适配机制正常工作
  - Given: 玩家装备特定武器
  - When: 使用适配/不适配的武学
  - Then: 伤害根据适配度正确调整
  - Edge cases: 检查各种武器与武学的适配情况

- **AC-3**: 武学使用功能正常
  - Given: 玩家装备武学并有足够资源
  - When: 在战斗中使用武学
  - Then: 消耗资源、产生伤害、播放特效
  - Edge cases: 检查资源不足和冷却时间

- **AC-4**: 流派羁绊效果正常
  - Given: 玩家装备多个同流派或相关流派武学
  - When: 激活武学
  - Then: 羁绊效果正确应用
  - Edge cases: 检查不同流派组合的效果

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/martial_arts/martial_arts_usage_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001: 武学获取机制, Story 002: 武学熟练度系统
- Unlocks: Story 004: 武学组合系统