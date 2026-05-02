# Story 006: 连击和连携系统显示

> **Epic**: HUD系统
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/ux/hud.md`
**Requirement**: `TR-HUD-006` (连击和连携系统显示 - P1级信息)

**GDD Requirement Text**: 
"连击和连携系统显示 - P1级信息 - 实现连击数字正确显示(48px字号)，连击倍率正确显示(20px字号,如×1.3)，连击数增加时颜色正确变化(白色→金色→橙色→红色)，连携槽正确显示当前值/最大值(300x40px水平条)，连携槽分段标记清晰可见(33%, 66%, 100%)，连携槽充满时有视觉提示(发光、闪烁等)，连击中断时连击数字有抖动动画(0.2秒)并快速归零，连击值归零时有淡出动画(0.3秒)，使用连携技能时连携槽有消耗动画(0.5秒)消耗量正确，连击值达到上限(如999)时不再增加显示MAX，连携槽充满时有脉冲动画提示可使用连携技能，连击颜色变化阈值1-10白色11-30金色31-50橙色51+红色"

**ADR Governing Implementation**: ADR-002, ADR-003
**ADR Decision Summary**: 监听combat_combo_changed, combat_link_gauge_changed信号。使用Tween实现平滑动画，使用@onready缓存节点引用避免_process()中的查找。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 
- 使用Tween.tween_property()实现颜色变化和动画效果
- 使用ProgressBar节点实现连携槽进度条
- 使用Label节点的add_theme_font_size_override()设置字号
- 抖动动画使用Tween.set_trans(Tween.TRANS_ELASTIC)

**Out of Scope**:
- 连击系统的游戏逻辑（由战斗系统负责）
- 连携技能的实际效果实现（由技能系统负责）
- 连击音效和粒子特效（由音频和特效系统负责）
- 连击数据的持久化存储（由存档系统负责）

**Performance Budget**:
- 连击数字更新响应时间: <16.67ms (60FPS)
- 颜色变化动画更新: <1ms
- 连携槽进度更新: <2ms
- 单个Tween动画内存占用: <100KB
- UI节点总数: <15个

---

## Acceptance Criteria

- [ ] AC-1: 连击数字正确显示(48px字号)
- [ ] AC-2: 连击倍率正确显示(20px字号,如×1.3)
- [ ] AC-3: 连击数增加时颜色正确变化(白色→金色→橙色→红色)
- [ ] AC-4: 连携槽正确显示当前值/最大值(300x40px水平条)
- [ ] AC-5: 连携槽分段标记清晰可见(33%, 66%, 100%)
- [ ] AC-6: 连携槽充满时有视觉提示(发光、闪烁等)
- [ ] AC-7: 连击中断时连击数字有抖动动画(0.2秒)并快速归零
- [ ] AC-8: 连击值归零时有淡出动画(0.3秒)
- [ ] AC-9: 使用连携技能时连携槽有消耗动画(0.5秒),消耗量正确
- [ ] AC-10: 连击值达到上限(如999)时不再增加,显示"MAX"
- [ ] AC-11: 连携槽充满时有脉冲动画提示可使用连携技能
- [ ] AC-12: 连击颜色变化阈值:1-10白色,11-30金色,31-50橙色,51+红色

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/combo-link-display-evidence.md`

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 007