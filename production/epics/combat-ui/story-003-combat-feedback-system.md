# Story 003: 战斗反馈系统

> **Epic**: 战斗UI系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: UI
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/combat-ui.md`
**Requirement**: `TR-combat-ui-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的粒子系统和音频系统提供战斗反馈，利用信号系统同步特效播放

**Control Manifest Rules (this layer)**:
- Required: 战斗反馈必须与战斗事件同步，延迟不超过50ms
- Forbidden: 禁止播放过多特效导致性能下降
- Guardrail: 反馈系统不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/combat-ui.md`, scoped to this story:*

- [x] 伤害数字颜色正确（不同伤害类型对应不同颜色）
- [x] 战斗特效正常播放（命中、暴击、特殊技能）
- [x] 音频反馈正常（UI操作、战斗事件）
- [x] 状态效果视觉反馈（Buff/Debuff图标动画）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用CombatFeedbackManager节点管理战斗反馈效果
- 实现show_damage_number(damage_data)方法显示伤害数字
- 实现play_combat_effect(effect_type, position)方法播放特效
- 实现play_audio_feedback(audio_type)方法播放音效
- 实现animate_status_icons(status_data)方法处理状态图标动画
- 实现feedback_played信号通知其他系统
- 与CombatSystem、AudioSystem和ParticleSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 战斗HUD显示（处理HUD元素显示）
- Story 002: 战斗菜单交互（处理菜单交互和用户输入）
- 核心战斗逻辑（由战斗系统处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For UI stories — evidence specs]:**

- **AC-1**: 伤害数字颜色正确
  - Given: 角色受到外功伤害
  - When: 伤害计算完成
  - Then: 伤害数字显示为白色
  - Edge cases: 内功伤害（蓝色）、暴击（金色）、真实伤害（红色）

- **AC-2**: 战斗特效正常播放
  - Given: 角色发动强力技能
  - When: 技能命中目标
  - Then: 播放对应的特效和镜头震动
  - Edge cases: Miss效果、暴击特效、特殊技能特效

- **AC-3**: 音频反馈正常
  - Given: 玩家点击UI按钮
  - When: 按钮被激活
  - Then: 播放墨滴音效
  - Edge cases: 不同操作音效、战斗音效、背景音乐

- **AC-4**: 状态效果视觉反馈
  - Given: 角色获得中毒状态
  - When: 状态生效
  - Then: 状态图标显示旋转动画和持续时间
  - Edge cases: 多个状态、状态消失、状态叠加

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- Evidence: `production/qa/evidence/combat-feedback-system-evidence.md` — must exist and pass

**Status**: [x] Completed

---

## Dependencies

- Depends on: Story 001 (战斗HUD显示), Story 002 (战斗菜单交互)
- Unlocks: None