# Story 008: 快捷栏系统

> **Epic**: HUD系统
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Manifest Version**: 2026-04-28
> **Estimate**: 18 hours

## Context

**GDD**: `design/ux/hud.md`
**Requirement**: `TR-HUD-008` (快捷栏系统 - P4级信息)

**ADR Governing Implementation**: ADR-002, ADR-003
**ADR Decision Summary**: 监听item_hotbar_changed信号,与物品系统集成。

**Engine**: Godot 4.6 | **Risk**: LOW

**Engine Notes**:
- 使用Godot 4.6的拖拽系统（Control.get_drag_data()、Control.can_drop_data()、Control.drop_data()）
- 使用Timer实现冷却时间显示
- 使用Tween实现冷却进度条动画
- 使用InputEvent处理数字键1-8快捷键
- 使用@onready缓存节点引用优化性能

**Out of Scope**:
- 快捷栏UI美术设计（由美术系统负责）
- 物品系统的具体实现（由物品系统负责）
- 拖拽动画的具体实现细节（由动画系统负责）
- 快捷栏配置文件的加密存储（由持久化系统负责）
- 快捷栏快捷键与其他系统的冲突管理（由输入系统负责）

**Performance Budget**:
- 快捷栏槽位点击响应时间: <16.67ms (60FPS)
- 拖拽操作响应时间: <16.67ms (60FPS)
- 冷却时间显示更新: <1ms
- UI节点总数: <30个（8个槽位 + 拖拽预览 + 冷却显示）
- 物品数量同步延迟: <100ms

---

## Acceptance Criteria

- [ ] AC-1: 8个槽位正确显示(64x64px)
- [ ] AC-2: 物品图标正确显示
- [ ] AC-3: 物品数量正确显示(右下角)
- [ ] AC-4: 数字键1-8正确绑定到对应槽位
- [ ] AC-5: 使用物品后数量正确减少
- [ ] AC-6: 物品用完后槽位清空
- [ ] AC-7: 支持从背包拖拽物品到快捷栏槽位
- [ ] AC-8: 支持在快捷栏内拖拽物品交换位置
- [ ] AC-9: 只有消耗品类型的物品可放入快捷栏
- [ ] AC-10: 物品使用后有冷却时间显示(圆形进度条)
- [ ] AC-11: 快捷栏配置在游戏退出后保存,重新进入时恢复
- [ ] AC-12: 物品数量与物品系统实时同步
- [ ] AC-13: 数字键1-8在其他UI打开时不触发快捷栏

---

## QA Test Cases

### TC-008-01: 快捷栏槽位显示验证
- **Given**: 游戏HUD已加载
- **When**: 观察HotbarController
- **Then**: 显示8个槽位,每个槽位尺寸为64x64px,槽位排列在底部中央

### TC-008-12: 物品数量同步验证
- **Given**: 快捷栏槽位1有5个生命药水,背包中同一物品有5个
- **When**: 在背包中使用1个生命药水
- **Then**: 快捷栏槽位1数量变为4,两处数量保持同步

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/ui/hotbar_system_test.gd`

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 009