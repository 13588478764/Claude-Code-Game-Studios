# Epic: HUD系统

> **层级**: Presentation
> **UX设计文档**: design/ux/hud.md
> **架构模块**: UI/HUD (基于Godot 4.6 CanvasLayer)
> **状态**: Ready
> **Stories**: 9 stories created

## 概述

HUD（Head-Up Display）系统是游戏的核心用户界面，负责在游戏过程中向玩家实时显示关键信息。本系统实现水墨风格的武侠RPG HUD，包括角色状态、战斗信息、探索导航和系统功能入口。

**核心功能**：
1. **角色状态显示** — HP、Qi、Poise、等级、经验、Buff/Debuff
2. **战斗信息显示** — 行动队列、敌人信息、连击值、连携槽
3. **探索导航** — 小地图、任务追踪、兴趣点标记
4. **系统功能** — 菜单入口、快捷栏、通知系统

**设计原则**（来自design/ux/hud.md第1节）：
- **意境优先，留白为美** — 继承水墨画的留白美学，避免信息过载
- **信息分层，按需显示** — P0-P4优先级系统，核心信息始终可见
- **功能至上，形式服务** — 可读性 > 美观性，性能优化优先
- **武侠美学，文化融合** — 传统纹样、书法、卷轴元素

## 管理ADRs

由于项目尚未创建HUD相关的专门ADR，本Epic基于以下架构约束：

| 约束来源 | 决策摘要 | 引擎风险 |
|---------|---------|---------|
| control-manifest.md | 使用Godot 4.6 Scene-Node架构 | LOW |
| control-manifest.md | 使用信号系统进行松耦合 | LOW |
| control-manifest.md | 组件化设计，避免深度继承 | LOW |
| design/ux/hud.md | 性能预算：<2000 draw calls，<2GB内存，60FPS | MEDIUM |
| design/ux/hud.md | Web/Browser平台优化 | MEDIUM |

**建议在实现前创建的ADRs**：
- ADR-HUD-001: HUD架构模式（信号驱动 vs 轮询更新）
- ADR-HUD-002: 性能优化策略（对象池、脏标记、批量更新）
- ADR-HUD-003: 数据绑定机制（GameEvents信号总线设计）

## UX设计要求

本Epic需满足design/ux/hud.md定义的UX规范：

### MVP阶段要求（第11.1节）

**阶段1.1：核心生存信息（P0级）** — 预计2-3天
- 主角状态显示（左下角）：HP、Qi、Poise条（280x24px）
- 队友状态显示：简化的HP条和头像（60x60px）
- 临界状态警告（HP<30%变红，Poise<20%闪烁）
- 基础数值显示（当前值/最大值）

**阶段1.2：核心战斗信息（P1级）** — 预计3-4天
- 行动顺序队列（顶部中央）：当前+接下来3个单位
- 敌人信息显示（右下角）：HP条、五行弱点图标
- 连击值显示（中央偏上）：连击数（48px）、倍率（20px）
- 连携槽显示：水平条形图（300x40px），分段标记

**阶段1.3：基础系统功能（P4级）** — 预计2天
- 菜单入口（右上角）：主菜单、设置、帮助按钮（48x48px）
- 快捷栏（底部中央）：8个物品槽位（64x64px）
- 快捷键支持：ESC、F1、数字键1-8

### 技术实现要求（第9节）

**场景结构**（第9.1.1节）：
```
res://src/scenes/ui/hud/
├── HUD.tscn (主场景，CanvasLayer)
│   ├── PlayerStatusPanel (角色状态)
│   ├── PartyPanel (队友状态)
│   ├── CombatInfoPanel (战斗信息)
│   ├── NavigationPanel (导航)
│   ├── HotbarController (快捷栏)
│   └── NotificationManager (通知)
```

**脚本架构**（第9.1.2节）：
- `HUDManager.gd` — 总控制器，模式切换（探索/战斗/菜单）
- `PlayerStatusPanel.gd` — 角色状态显示和更新
- `CombatInfoPanel.gd` — 战斗信息显示
- `NavigationPanel.gd` — 小地图和任务追踪
- `HotbarController.gd` — 快捷栏管理
- `NotificationManager.gd` — 通知显示和队列管理

**数据绑定**（第9.3节）：
- 使用GameEvents全局信号总线
- 信号驱动更新（推荐方式）
- 脏标记避免重复更新
- 数据缓存优化性能

**性能优化**（第9.2节）：
- 对象池模式（Buff图标、伤害数字、通知面板）
- 批量更新（收集多个更新，一次性应用）
- LOD（根据分辨率调整细节）
- Draw Calls < 100（HUD部分）

### 视觉设计要求（第4节）

**颜色规范**：
- 主色调：青绿(#2E8B57)、墨黑(#000000)
- 强调色：深红(#DC143C)、金色(#FFD700)
- 背景：半透明黑色(rgba(0,0,0,0.7))

**字体规范**：
- 标题：方正清刻本悦宋（18-24px）
- 正文：思源宋体（14-16px）
- 最小字号：14px（确保可读性）

**布局规范**（第3节）：
- 安全区域：距离屏幕边缘至少40px
- 响应式设计：支持1280x720到2560x1440
- 屏幕分区：左下（角色）、右下（敌人）、顶部（队列）、底部（快捷栏）

## 完成定义

本Epic完成的标准：

1. **所有Stories实现并关闭**
   - 通过 `/story-done` 验证每个story
   - 所有接受标准通过

2. **UX规范符合性**
   - MVP阶段所有必需元素实现（阶段1.1-1.3）
   - 符合design/ux/hud.md的设计规范
   - 通过 `/ux-review` 验证

3. **测试覆盖**
   - Logic stories有单元测试（tests/unit/ui/hud/）
   - Integration stories有集成测试（tests/integration/ui/）
   - UI stories有手动测试证据（production/qa/evidence/hud/）

4. **性能达标**（第9.2.1节）
   - HUD draw calls < 100
   - 战斗中更新 < 1ms/帧
   - 探索中更新 < 0.5ms/帧
   - 60FPS稳定
   - 内存占用 < 50MB（所有HUD纹理）

5. **可访问性**（第1.1节）
   - 最小字号14px
   - 对比度≥4.5:1（WCAG AA标准）
   - 键盘导航支持
   - 色盲友好设计（不仅依赖颜色传达信息）

6. **跨分辨率测试**
   - 1280x720（最低）
   - 1920x1080（主流）
   - 2560x1440（高分辨率）

## 依赖系统

本Epic依赖以下系统提供数据：

**必需依赖**：
- **战斗系统** — 提供HP、Qi、Poise、行动队列数据
- **角色成长系统** — 提供等级、经验、境界数据
- **装备系统** — 提供装备状态和属性加成
- **物品系统** — 提供快捷栏物品数据

**可选依赖**（第二阶段）：
- **任务系统** — 提供任务追踪数据
- **地图系统** — 提供小地图数据
- **奇遇系统** — 提供奇遇触发通知

## 实现路线图

基于design/ux/hud.md第11节的实现优先级：

**MVP阶段**（7-9天）：
1. 阶段1.1：核心生存信息（2-3天）
2. 阶段1.2：核心战斗信息（3-4天）
3. 阶段1.3：基础系统功能（2天）

**第二阶段**（8-12天，可选）：
- 探索与导航（小地图、任务追踪）
- 角色成长反馈（等级、经验、境界）
- 战斗信息完善（Buff/Debuff、Down/Break状态）

**第三阶段**（6-10天，可选）：
- 视觉效果增强（高级动画、粒子效果）
- 音效集成
- 可访问性优化

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | HUD场景结构和管理器 | Integration | Ready | ADR-002, ADR-003 |
| 002 | 角色状态显示面板 | UI | Ready | ADR-002, ADR-003 |
| 003 | 队友状态显示 | UI | Ready | ADR-002, ADR-003 |
| 004 | 行动顺序队列显示 | UI | Ready | ADR-002, ADR-003 |
| 005 | 敌人信息显示 | UI | Ready | ADR-002, ADR-003 |
| 006 | 连击和连携系统显示 | UI | Ready | ADR-002, ADR-003 |
| 007 | 菜单入口和系统功能 | UI | Ready | ADR-002, ADR-003 |
| 008 | 快捷栏系统 | Integration | Ready | ADR-002, ADR-003 |
| 009 | HUD性能优化和集成测试 | Integration | Ready | ADR-002, ADR-003, ADR-004 |

**总计**: 9 stories (3 Integration, 6 UI)

## 下一步

运行 `/story-readiness production/epics/hud-system/story-001-hud-scene-structure-and-manager.md` 开始实现第一个story。

**实现顺序建议**:
1. Story 001 (基础架构) → 必须首先完成
2. Story 002-008 (UI组件) → 可并行实现
3. Story 009 (性能优化) → 最后完成,依赖所有其他stories