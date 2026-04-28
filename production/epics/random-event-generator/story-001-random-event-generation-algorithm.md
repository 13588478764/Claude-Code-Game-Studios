# Story 001: 随机事件生成算法

> **Epic**: 随机事件生成器
> **Status**: Pending Test
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/random-event-generator.md`
**Requirement**: `TR-random-event-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，事件系统

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的伪随机数生成器实现基于区域的权重池算法

**Control Manifest Rules (this layer)**:
- Required: 随机事件生成必须基于区域权重池和玩家属性
- Forbidden: 禁止使用纯随机算法，必须考虑玩家属性和区域特性
- Guardrail: 生成算法不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/random-event-generator.md`, scoped to this story:*

- [x] 实现基于区域的权重池算法，支持4类事件（战斗遭遇、奇遇/叙事事件、资源/宝藏事件、环境/状态事件）
- [x] 实现伪随机数生成器，使用区域ID、日期和玩家ID作为种子
- [x] 实现权重调整机制，根据玩家福缘属性和区域特性调整事件权重
- [x] 实现事件冷却机制，防止相同类型事件连续触发

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现区域特定的事件池数据结构
- 实现基于种子的伪随机数生成器
- 实现权重计算函数，考虑福缘属性和区域倍数
- 实现事件冷却和防重复机制

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 事件触发条件：由Story 002处理
- 事件结果处理：由Story 003处理
- UI界面：由UI故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 实现基于区域的权重池算法
  - Given: 玩家位于特定区域
  - When: 系统需要生成随机事件
  - Then: 根据区域特性从事件池中选择事件
  - Edge cases: 检查边界区域和权重为0的事件

- **AC-2**: 实现伪随机数生成器
  - Given: 相同的区域ID、日期和玩家ID
  - When: 生成随机种子
  - Then: 产生相同的种子值确保可复现性
  - Edge cases: 检查种子溢出情况

- **AC-3**: 实现权重调整机制
  - Given: 玩家具有不同福缘属性
  - When: 计算事件权重
  - Then: 根据福缘属性调整事件权重
  - Edge cases: 检查福缘为0或最大值的情况

- **AC-4**: 实现事件冷却机制
  - Given: 某类型事件刚刚触发
  - When: 系统再次尝试生成事件
  - Then: 避免相同类型事件在短时间内重复触发
  - Edge cases: 检查多个事件同时冷却的情况

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/random_event/random_event_generation_algorithm_test.gd` — must exist and pass

**Status**: [x] Complete

---

## Dependencies

- Depends on: None
- Unlocks: Story 002: 事件触发条件, Story 003: 事件结果处理

## Completion Notes
**Completed**: 2026-04-27
**Criteria**: 4/4 passing
**Deviations**: None
**Test Evidence**: Logic: test file at tests/unit/random_event/random_event_generation_algorithm_test.gd
**Code Review**: Pending