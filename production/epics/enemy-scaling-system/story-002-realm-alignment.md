# Story 002: 境界对齐系统实现

> **Epic**: 敌人缩放系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/enemy-scaling-system.md`
**Requirement**: `TR-enemy-scaling-002`
*(境界对齐系统 - 实现9个境界等级,每个境界+10%全属性加成,与玩家境界一一对应)*

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: 使用Godot 4.6引擎和GDScript实现

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 无特殊API需求

**Control Manifest Rules (Feature layer)**:
- Required: 模块化设计
- Forbidden: (无)
- Guardrail: (无)

---

## Acceptance Criteria

- [ ] AC-2: GIVEN 玩家等级为50(金丹初期), WHEN 遭遇困难区精英敌人, THEN 敌人HP应约为18,000,攻击力应约为2,000(允许±10%误差)

---

## Implementation Notes

1. **境界系数公式**: `realm_coefficient = 1.0 + (realm_level × 0.1)`
2. **9个境界等级映射**:
   - 境界1 (Lv 1-11): 1.1
   - 境界2 (Lv 12-22): 1.2
   - ...
   - 境界9 (Lv 89-99): 1.9
3. **实现函数**: `calculate_realm_coefficient(player_level: int) -> float`

---

## Out of Scope

- Story 001: 等级系数
- Story 003: 区域和类型倍率

---

## QA Test Cases

**AC-2**: 金丹初期精英敌人验证
- Given: 玩家等级=50(境界5), 困难区(1.3x), 精英敌人(2.0x HP, 1.5x攻击)
- When: 计算最终属性
- Then: HP≈18,000±10%, 攻击≈2,000±10%
- Edge cases: 境界边界(Lv 44-45, Lv 55-56)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/enemy_scaling/realm_coefficient_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 007