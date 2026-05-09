# Story 002: 装备交互功能

> **Epic**: 装备UI
> **Status**: Complete
> **Layer**: Feature
> **Type**: UI
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/equipment-ui.md`
**Requirement**: `TR-equip-ui-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理UI交互事件，利用InputEvent处理鼠标和键盘输入

**Control Manifest Rules (this layer)**:
- Required: UI交互必须响应迅速，无明显延迟
- Forbidden: 禁止在UI线程中执行耗时操作
- Guardrail: 交互响应不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/equipment-ui.md`, scoped to this story:*

- [x] 装备操作功能正常（点击、拖拽、右键菜单）
- [x] 属性查看功能正常（悬停提示、详细信息面板）
- [x] 筛选和排序功能正常（按品阶、类型、属性）
- [x] 一键装备和推荐功能有效

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用EquipmentUIInteraction节点处理所有交互逻辑
- 实现handle_slot_click()方法处理槽位点击事件
- 实现handle_drag_and_drop()方法处理拖拽操作
- 实现handle_right_click()方法处理右键菜单
- 实现show_tooltip()方法显示悬停提示
- 实现apply_filters()方法处理筛选功能
- 实现apply_sorting()方法处理排序功能
- 与EquipmentManager、EquipmentSlotManager系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 装备界面布局（处理UI布局结构）
- Story 003: 视觉反馈与特效（处理视觉效果）
- 装备数据逻辑（由装备系统处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For UI stories — manual evidence specs]:**

- **AC-1**: 装备操作功能正常
  - Given: 玩家在装备界面
  - When: 执行点击、拖拽、右键操作
  - Then: 装备操作按预期执行
  - Edge cases: 快速连续点击、拖拽到无效位置、右键菜单异常

- **AC-2**: 属性查看功能正常
  - Given: 玩家将鼠标悬停在装备上
  - When: 悬停时间超过阈值
  - Then: 属性提示正确显示
  - Edge cases: 无属性装备、属性过多、界面边界

- **AC-3**: 筛选和排序功能正常
  - Given: 背包中有多种装备
  - When: 应用筛选和排序条件
  - Then: 装备列表按条件正确显示
  - Edge cases: 无匹配装备、多重筛选、排序异常

- **AC-4**: 一键装备和推荐功能有效
  - Given: 玩家点击一键装备按钮
  - When: 系统计算最佳装备组合
  - Then: 最佳装备自动装备
  - Edge cases: 无可用装备、装备冲突、计算超时

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- Evidence: `production/qa/evidence/equipment-interactions-evidence.md` — must exist and pass manual verification

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (装备界面布局)
- Unlocks: Story 003 (视觉反馈与特效)