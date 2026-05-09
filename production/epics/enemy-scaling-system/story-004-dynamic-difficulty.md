# Story 004: 动态难度调整系统

> **Epic**: 敌人缩放系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/enemy-scaling-system.md`
**Requirement**: `TR-enemy-scaling-005`
*(动态难度平衡 - 实现基于玩家表现的动态难度调整)*

**ADR Governing Implementation**: ADR-001
**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-6: GIVEN 玩家连续失败同一战斗3次, WHEN 第4次遭遇, THEN 敌人属性降低30%(系数=0.7)
- [ ] AC-7: GIVEN 玩家连续10场无伤胜利, WHEN 第11场战斗, THEN 敌人属性提升5%(系数=1.05)

---

## Implementation Notes

1. **失败惩罚**: `dynamic_coefficient = 1.0 - (min(failure_count, 3) × 0.1)`
2. **碾压奖励**: `dynamic_coefficient = 1.0 + (min(perfect_win_count, 3) × 0.05)`
3. **范围限制**: 0.7-1.15
4. **重置条件**: 切换区域或升级

---

## QA Test Cases

**AC-6**: 连续失败惩罚
- Given: 同一战斗失败3次
- When: 第4次遭遇
- Then: dynamic_coefficient = 0.7
- Edge cases: 失败4次(仍为0.7), 失败后胜利(重置)

**AC-7**: 连续碾压奖励
- Given: 连续10场无伤胜利
- When: 第11场战斗
- Then: dynamic_coefficient = 1.05
- Edge cases: 30场无伤(上限1.15)

---

## Test Evidence

**Required**: `tests/unit/enemy_scaling/dynamic_difficulty_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001-003
- Unlocks: Story 007