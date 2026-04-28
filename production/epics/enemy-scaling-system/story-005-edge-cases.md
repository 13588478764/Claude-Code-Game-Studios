# Story 005: 边缘情况处理

> **Epic**: 敌人缩放系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/enemy-scaling-system.md`
**Requirement**: `TR-enemy-scaling-006`
*(边缘情况处理 - 等级差距保护、战斗中升级、数据异常)*

**ADR Governing Implementation**: ADR-001
**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-8: GIVEN 玩家等级60,区域推荐20-40, WHEN 遭遇敌人, THEN 区域倍率降至0.5x,显示UI提示
- [ ] AC-9: GIVEN 玩家等级20,区域推荐60-80, WHEN 遭遇敌人, THEN 敌人按Lv80缩放,显示UI警告
- [ ] AC-10: GIVEN 玩家战斗中从Lv49升到Lv50, WHEN 当前战斗继续, THEN 敌人属性不变
- [ ] AC-13: GIVEN 敌人基础HP=0, WHEN 计算缩放, THEN 使用默认值HP=100并记录日志
- [ ] AC-14: GIVEN 区域难度数据缺失, WHEN 读取倍率, THEN 使用默认1.0x并记录日志

---

## Implementation Notes

1. **等级差距阈值**: 20级
2. **过高保护**: 区域倍率降至0.5x
3. **过低保护**: 按区域上限缩放
4. **战斗中升级**: 锁定敌人属性
5. **数据异常**: 默认HP=100, 攻击=20

---

## QA Test Cases

**AC-8**: 等级过高保护
- Given: 玩家Lv60, 区域推荐20-40
- When: 遭遇敌人
- Then: 区域倍率=0.5x, UI显示"此区域对你来说过于简单"

**AC-10**: 战斗中升级
- Given: 战斗开始时Lv49
- When: 战斗中升到Lv50
- Then: 当前战斗敌人属性不变, 下一场战斗才更新

**AC-13**: 数据异常处理
- Given: 敌人基础HP=0
- When: 计算缩放属性
- Then: 使用HP=100, 记录错误日志

---

## Test Evidence

**Required**: `tests/unit/enemy_scaling/edge_cases_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001-004
- Unlocks: Story 007