# Story 009: 调试可视化工具

> **Epic**: 敌人缩放系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: UI
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/enemy-scaling-system.md`
**Requirement**: `TR-enemy-scaling-008`
*(调试可视化工具 - 实现开发模式下的缩放参数显示和难度曲线图表)*

**ADR Governing Implementation**: ADR-001
**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] 开发者UI-1: 缩放系数面板实时显示当前玩家的等级系数、境界系数、区域难度倍率、动态难度调整状态
- [ ] 开发者UI-2: 敌人属性对比显示基础属性vs缩放后属性、各个倍率的贡献百分比、公式计算过程可视化
- [ ] 开发者UI-3: 难度曲线图表显示横轴玩家等级(1-99)、纵轴敌人属性倍率、三段式曲线的衔接点

---

## Implementation Notes

1. **仅在开发模式启用**: 检查`OS.is_debug_build()`
2. **UI实现**: 使用Godot Control节点 + Theme资源
3. **实时更新**: 监听玩家等级/境界变化信号
4. **曲线图表**: 使用Line2D节点绘制

---

## QA Test Cases

**开发者UI-1**: 缩放系数面板
- Setup: 启动开发模式,打开调试面板
- Verify: 显示当前等级系数、境界系数、区域倍率、动态难度状态
- Pass condition: 所有数值实时更新,与计算结果一致

**开发者UI-2**: 属性对比面板
- Setup: 生成一个敌人,打开属性对比
- Verify: 显示基础HP/攻击 vs 最终HP/攻击,各倍率贡献
- Pass condition: 数值准确,公式可视化清晰

**开发者UI-3**: 难度曲线图表
- Setup: 打开曲线图表
- Verify: 显示1-99级的完整曲线,标记衔接点(33,66)
- Pass condition: 曲线平滑,衔接点清晰可见

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/debug-visualization-evidence.md`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 007, 008
- Unlocks: None (最后一个Story)