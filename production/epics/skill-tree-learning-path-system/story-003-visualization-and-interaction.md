# Story 003: 可视化与交互

> **Epic**: 技能树/学习路径系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: UI
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/skill-tree-learning-path-system.md`
**Requirement**: `TR-skill-tree-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的Control节点、GPUParticles2D和动画系统实现水墨卷轴风格界面

**Control Manifest Rules (this layer)**:
- Required: 必须实现水墨卷轴风格的技能树界面，支持节点悬停、点击解锁和分支选择交互
- Forbidden: 禁止使用不符合艺术圣经的视觉风格，必须遵循青绿山水主色调
- Guardrail: UI渲染不应影响游戏性能，保持60FPS

---

## Acceptance Criteria

*From GDD `design/gdd/skill-tree-learning-path-system.md`, scoped to this story:*

- [ ] 实现水墨卷轴风格的技能树背景（展开的古旧卷轴或宣纸纹理）
- [ ] 实现武学节点设计（毛笔书写的汉字或简化的兵器图标，品阶颜色区分）
- [ ] 实现节点悬停交互（显示招式详细信息、伤害系数、消耗内力、前置条件）
- [ ] 实现点击解锁交互（满足条件时播放墨水晕染动画，节点变为金色/亮色）
- [ ] 实现分支选择对话框（提供2-3个分支选项，显示属性要求和效果差异）
- [ ] 支持鼠标滚轮缩放、拖拽平移和快捷键操作

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现水墨卷轴风格的UI背景和纹理
- 实现武学节点的视觉设计和品阶颜色编码
- 实现节点悬停时的详细信息面板
- 实现点击解锁时的墨水晕染特效（使用GPUParticles2D）
- 实现分支选择对话框的UI布局和交互逻辑
- 实现鼠标滚轮缩放和拖拽平移功能
- 实现快捷键操作（WASD移动视图，鼠标滚轮缩放，空格居中）
- 支持不同分辨率的UI适配（16:9、16:10、21:9）

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 学习路径类型：由Story 001处理
- 解锁机制：由Story 002处理
- 音频系统：由音频故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For UI stories — manual test specs with evidence docs]:**

- **AC-1**: 实现水墨卷轴风格背景
  - Given: 玩家打开技能树界面
  - When: 界面加载完成
  - Then: 显示展开的古旧卷轴或宣纸纹理背景，符合艺术圣经的青绿山水主色调
  - Evidence: 截图显示水墨卷轴风格背景

- **AC-2**: 实现武学节点设计
  - Given: 技能树界面显示华山剑法图谱
  - When: 查看不同品阶的武学节点
  - Then: 节点使用毛笔书写的汉字或兵器图标，品阶通过颜色区分（黄阶-黄色、玄阶-蓝色、地阶-紫色、天阶-金色）
  - Evidence: 截图显示不同品阶节点的视觉差异

- **AC-3**: 实现节点悬停交互
  - Given: 鼠标悬停在崩字诀节点上
  - When: 悬停超过0.5秒
  - Then: 显示详细信息面板，包含招式名称、描述、伤害系数、消耗内力、前置条件
  - Evidence: 截图显示悬停时的详细信息面板

- **AC-4**: 实现点击解锁交互
  - Given: 玩家满足崩字诀的所有解锁条件
  - When: 点击崩字诀节点
  - Then: 播放墨水晕染动画，节点变为金色/亮色，显示"领悟成功"提示
  - Evidence: 视频录制显示解锁动画和视觉反馈

- **AC-5**: 实现分支选择对话框
  - Given: 玩家在劈字诀节点满足多个分支条件
  - When: 点击分支节点
  - Then: 弹出分支选择对话框，显示重劈和快劈两个选项，包含属性要求、效果差异和不可逆提示
  - Evidence: 截图显示分支选择对话框

- **AC-6**: 支持缩放和平移
  - Given: 玩家在技能树界面
  - When: 使用鼠标滚轮缩放或拖拽平移
  - Then: 技能树视图正确缩放和平移，保持流畅性
  - Evidence: 视频录制显示缩放和平移操作

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/skill-tree-visualization-evidence.md` — must exist with screenshots/videos and sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001: 学习路径类型, Story 002: 解锁机制
- Unlocks: None