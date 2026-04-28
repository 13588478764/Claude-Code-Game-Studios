# Story 006: 配置文件系统

> **Epic**: 敌人缩放系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Config/Data
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/enemy-scaling-system.md`
**Requirement**: `TR-enemy-scaling-007`
*(配置文件系统 - 通过JSON配置文件暴露所有缩放参数)*

**ADR Governing Implementation**: ADR-001
**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-15: GIVEN 设计师修改配置文件中的linear_coefficient从0.15改为0.12, WHEN 重新加载游戏, THEN 初期敌人属性应相应降低

---

## Implementation Notes

1. **配置文件路径**: `data/enemy_scaling_config.json`
2. **暴露参数**: 等级系数、境界系数、区域倍率、类型倍率、动态调整参数、边缘情况参数
3. **热重载**: 支持运行时重新加载配置
4. **验证**: 参数范围验证

---

## QA Test Cases

**AC-15**: 配置文件修改生效
- Given: linear_coefficient从0.15改为0.12
- When: 重新加载游戏
- Then: Lv10敌人属性降低(从2.35x降至2.08x)
- Edge cases: 无效值(负数、超出范围)

---

## Test Evidence

**Required**: `tests/unit/enemy_scaling/config_loader_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001-005
- Unlocks: Story 007