# Story 001: 三段式等级缩放曲线实现

> **Epic**: 敌人缩放系统
> **Status**: Complete
> **Estimate**: 2-4 hours
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/enemy-scaling-system.md`
**Requirement**: `TR-enemy-scaling-001`
*(三段式缩放曲线 - 实现初期线性(Lv 1-33)、中期温和指数(Lv 34-66)、后期陡峭指数(Lv 67-99)的敌人属性缩放)*

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: 使用Godot 4.6引擎和GDScript实现,采用Scene-Node架构模式

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Godot 4.6原生支持所需的数学计算,无需特殊API

**Control Manifest Rules (Feature layer)**:
- Required: 模块化设计 - 功能应自包含且可独立测试
- Forbidden: (无特定禁止)
- Guardrail: (无特定性能限制)

---

## Acceptance Criteria

*From GDD `design/gdd/enemy-scaling-system.md`:*

- [ ] AC-1: GIVEN 玩家等级为1, WHEN 遭遇新手区普通敌人, THEN 敌人HP应在100-200范围内,攻击力应在15-30范围内
- [ ] AC-4: GIVEN 玩家在Lv 33和Lv 34之间升级, WHEN 计算等级系数, THEN 两个等级的系数应相等(5.8),确保曲线平滑衔接
- [ ] AC-5: GIVEN 玩家在Lv 66和Lv 67之间升级, WHEN 计算等级系数, THEN 两个等级的系数应相等(13.5),确保曲线平滑衔接

---

## Implementation Notes

*Derived from ADR-001 and GDD:*

1. **三段式公式实现**:
   - 初期线性段(Lv 1-33): `level_coefficient = 1.0 + (level - 1) × 0.15`
   - 中期温和指数段(Lv 34-66): `level_coefficient = 5.8 × (level / 34)^1.5`
   - 后期陡峭指数段(Lv 67-99): `level_coefficient = 13.5 × (level / 67)^2.0`

2. **关键节点值验证**:
   - Lv 1 = 1.0
   - Lv 33 = 5.8 (段落衔接点)
   - Lv 34 = 5.8 (段落衔接点)
   - Lv 66 = 13.5 (段落衔接点)
   - Lv 67 = 13.5 (段落衔接点)
   - Lv 99 = 29.8

3. **实现为独立函数**: `calculate_level_coefficient(player_level: int) -> float`

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 002: 境界系数计算
- Story 003: 区域难度和敌人类型倍率
- Story 007: 完整的敌人实例生成

---

## QA Test Cases

**AC-1**: 等级1敌人数值验证
- Given: 玩家等级=1, 敌人基础HP=100, 基础攻击=20, 新手区倍率=0.8, 普通敌人
- When: 调用 `calculate_level_coefficient(1)` 和完整缩放公式
- Then: 等级系数=1.0, 最终HP在100-200范围, 最终攻击在15-30范围
- Edge cases: 等级0(无效), 等级100(超出范围)

**AC-4**: Lv 33-34衔接点验证
- Given: 玩家等级=33和34
- When: 分别调用 `calculate_level_coefficient(33)` 和 `calculate_level_coefficient(34)`
- Then: 两个返回值都应等于5.8(允许±0.01误差)
- Edge cases: Lv 32, Lv 35(验证衔接点附近的平滑性)

**AC-5**: Lv 66-67衔接点验证
- Given: 玩家等级=66和67
- When: 分别调用 `calculate_level_coefficient(66)` 和 `calculate_level_coefficient(67)`
- Then: 两个返回值都应等于13.5(允许±0.01误差)
- Edge cases: Lv 65, Lv 68(验证衔接点附近的平滑性)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/enemy_scaling/level_coefficient_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (基础功能)
- Unlocks: Story 007 (敌人实例生成集成)