# Story 003: 区域难度和敌人类型倍率

> **Epic**: 敌人缩放系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/enemy-scaling-system.md`
**Requirement**: `TR-enemy-scaling-003, TR-enemy-scaling-004`
*(区域难度分级 + 敌人类型系数)*

**ADR Governing Implementation**: ADR-001
**ADR Decision Summary**: Godot 4.6 + GDScript

**Engine**: Godot 4.6 | **Risk**: LOW

**Control Manifest Rules**: 模块化设计

---

## Acceptance Criteria

- [ ] AC-2: 困难区精英敌人数值正确
- [ ] AC-3: GIVEN 玩家等级99, WHEN 遭遇终局区Boss, THEN HP≈450,000, 攻击≈15,000(±10%)

---

## Implementation Notes

1. **5个区域难度**: 新手0.8x, 普通1.0x, 困难1.3x, 精英1.6x, 终局2.0x
2. **3种敌人类型**: 普通(1.0x HP/攻击), 精英(2.0x HP/1.5x攻击), Boss(4.0x HP/2.0x攻击)
3. **函数**: `get_region_multiplier(region_id)`, `get_enemy_type_multipliers(enemy_type)`

---

## QA Test Cases

**AC-3**: 终局区Boss验证
- Given: Lv 99, 境界9, 终局区2.0x, Boss 4.0x HP/2.0x攻击
- When: 计算最终属性
- Then: HP≈450,000±10%, 攻击≈15,000±10%

---

## Test Evidence

**Required**: `tests/unit/enemy_scaling/multipliers_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 002
- Unlocks: Story 007