# Story 006: 奇遇事件UI

> **Epic**: 角色成长系统
> **Status**: Pending Test
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/character-progression-system.md`
**Requirement**: `TR-char-progression-005`, `TR-char-progression-008`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot AnimationPlayer + Control节点，水墨武侠风格

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用AnimationPlayer制作入场动画，TextureRect显示动态背景

**Control Manifest Rules (this layer)**:
- Required: UI动画必须流畅，不影响游戏性能
- Forbidden: 禁止UI直接修改奇遇数据
- Guardrail: 动画播放时间不超过1秒

---

## Acceptance Criteria

*From GDD `design/gdd/character-progression-system.md`, scoped to this story:*

- [x] 动态事件卡片正常显示（背景根据奇遇类型变化）
- [x] 入场动画流畅（AnimationPlayer缩放淡入效果）
- [x] 福缘状态可视化正确（"吉星高照"图标显示）
- [x] 选项按钮和交互反馈正常（接受、拒绝、尝试等选项）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用Panel + TextureRect构建事件卡片
- AnimationPlayer制作缩放淡入动画：scale 0.8→1.0, modulate alpha 0→1
- 背景纹理根据奇遇类型切换：山洞、竹林、集市
- 福缘图标在角色福缘>60时显示
- 选项按钮使用Button节点，连接pressed信号

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: 奇遇触发和奖励逻辑
- Story 005: 角色成长UI

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Visual/Feel stories — manual verification steps]:**

- **AC-1**: 动态事件卡片正常显示
  - Setup: 触发"高人指点"奇遇
  - Verify: 卡片背景显示竹林场景，文字清晰可读
  - Pass condition: 背景与奇遇类型匹配，视觉风格统一

- **AC-2**: 入场动画流畅
  - Setup: 触发任意奇遇
  - Verify: 卡片从0.8倍缩放淡入到1.0倍，动画时长约0.5秒
  - Pass condition: 动画流畅无卡顿，视觉效果舒适

- **AC-3**: 福缘状态可视化正确
  - Setup: 角色福缘为70，触发奇遇
  - Verify: 卡片右上角显示"吉星高照"金色图标
  - Pass condition: 图标清晰，位置合理

- **AC-4**: 选项按钮和交互反馈正常
  - Setup: 触发奇遇，显示"接受"和"拒绝"按钮
  - Verify: 鼠标悬停按钮高亮，点击后卡片关闭
  - Pass condition: 按钮响应灵敏，反馈清晰

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**:
- Visual/Feel: `production/qa/evidence/encounter-ui-evidence.md` + sign-off

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 004 (奇遇触发和奖励系统)
- Unlocks: None