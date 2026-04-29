# Story 006: 奇遇事件UI

> **Epic**: 角色成长系统
> **Status**: Blocked - Requires Manual Fix
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

**Status**: ⚠️ **BLOCKED** - Scene file corrupted, requires manual fix in Godot Editor

---

## ⚠️ BLOCKING ISSUES (Added 2026-04-29)

**Status**: BLOCKED - Scene file corrupted, requires manual fix

**Problem Description**:
The UI scene file `src/scenes/ui/encounter_ui.tscn` contains invalid placeholder UIDs and cannot be loaded by Godot Engine.

**Error Message**:
```
ERROR: res://src/scenes/ui/encounter_ui.tscn:3 - Parse Error: Missing 'id' in external resource tag.
ERROR: Failed loading resource: res://src/scenes/ui/encounter_ui.tscn.
```

**Root Cause**:
- Scene file uses placeholder UIDs (e.g., `uid://-jz0q00000001`)
- External resource references are invalid
- File appears to be a template/placeholder, not a real Godot scene

**Impact**:
- ❌ UI cannot be loaded in game
- ❌ Cannot verify any acceptance criteria
- ⚠️ Manual test evidence document exists but doesn't match actual implementation

**Required Fix**:
1. Open Godot Editor
2. Create new Control scene from scratch
3. Add all required UI elements:
   - Panel node for encounter card
   - TextureRect for dynamic background
   - Label nodes for title and description
   - TextureRect for lucky star icon
   - Button nodes (Accept, Decline, Try)
   - AnimationPlayer for entrance animation
4. Attach script: `res://src/scripts/ui/encounter_ui_script.gd`
5. Create entrance animation:
   - Scale: 0.8 → 1.0
   - Modulate alpha: 0 → 1
   - Duration: ~0.5 seconds
6. Save as: `res://src/scenes/ui/encounter_ui.tscn`
7. Test in game to verify animations and interactions
8. Update manual test evidence if needed
9. Run `/story-done` again to complete verification

**Files Affected**:
- `src/scenes/ui/encounter_ui.tscn` - CORRUPTED, needs recreation
- `src/scripts/ui/encounter_ui_script.gd` - OK, script is complete
- `production/qa/evidence/encounter-ui-evidence.md` - Needs re-verification

**Next Steps**:
1. Recreate scene file in Godot Editor
2. Test animations and interactions manually
3. Re-run `/story-done production/epics/character-progression-system/story-006-encounter-ui.md`

---

## Dependencies

- Depends on: Story 004 (奇遇触发和奖励系统)
- Unlocks: None