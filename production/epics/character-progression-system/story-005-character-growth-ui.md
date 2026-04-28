# Story 005: 角色成长UI

> **Epic**: 角色成长系统
> **Status**: Pending Test
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/character-progression-system.md`
**Requirement**: `TR-char-progression-003`, `TR-char-progression-004`, `TR-char-progression-006`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot Control节点系统 + Theme资源，水墨武侠风格

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot Control节点构建UI，通过信号连接数据更新

**Control Manifest Rules (this layer)**:
- Required: UI必须响应式适配不同分辨率
- Forbidden: 禁止UI直接修改角色数据，必须通过角色系统接口
- Guardrail: UI更新不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/character-progression-system.md`, scoped to this story:*

- [x] 角色面板界面正常显示（属性、等级、境界、3D模型预览）
- [x] 属性分配界面正常工作（六维属性滑块、可用点数、效果预览）
- [x] 天赋网格界面正常显示（4x4网格、已点亮/未点亮状态）
- [x] UI交互和数据绑定正确（实时更新、动画效果）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用Godot Control节点构建UI层级结构
- 连接角色系统信号：`character_system.level_up.connect(_on_level_up)`
- 属性滑块使用HSlider节点，范围0到可用点数
- 天赋网格使用GridContainer + TextureButton节点
- 水墨风格UI使用Theme资源定义

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002-003: 属性和天赋的逻辑实现
- Story 006: 奇遇事件UI

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For UI stories — manual verification steps]:**

- **AC-1**: 角色面板界面正常显示
  - Setup: 打开角色面板
  - Verify: 显示角色等级、境界、六维属性、EXP进度条
  - Pass condition: 所有信息清晰可读，布局合理

- **AC-2**: 属性分配界面正常工作
  - Setup: 角色有10点可用属性点，打开属性分配界面
  - Verify: 拖动力道滑块分配5点，显示剩余5点，预览物理攻击增加
  - Pass condition: 滑块响应流畅，数字实时更新

- **AC-3**: 天赋网格界面正常显示
  - Setup: 打开天赋网格界面
  - Verify: 显示4x4网格，已点亮节点显示金色，未点亮显示灰色
  - Pass condition: 网格清晰，鼠标悬停显示天赋描述

- **AC-4**: UI交互和数据绑定正确
  - Setup: 升级角色，打开角色面板
  - Verify: 等级数字滚动动画，属性点数量更新
  - Pass condition: 动画流畅，数据同步无延迟

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/character-growth-ui-evidence.md` — manual walkthrough doc

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 002 (属性点分配系统), Story 003 (天赋网格系统)
- Unlocks: None