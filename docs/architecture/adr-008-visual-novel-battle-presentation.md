# ADR-008: 视觉小说 + 立绘站位表现层架构

**日期**: 2026-05-29
**状态**: 已采纳
**决策者**: 用户 + 技术总监

## 背景

项目原设计基于"2D 俯视角 + 角色 sprite + 场景地图"的传统 RPG 表现方式。评估后发现：
- 独立开发者缺乏制作大量 sprite 动画的资源
- AI 生成的立绘质量高，可直接用于视觉小说模式
- 已有 25 张角色立绘 + 16 张敌人立绘 + 15 张背景图
- 后端系统（战斗/对话/奇遇/经济）已完整实现，仅缺视觉表现层

## 决策

采用**视觉小说 + 立绘站位**作为游戏的表现层架构：

- **探索模式**: 全屏区域背景图 + NPC 列表 + 按钮驱动交互（非角色行走）
- **对话模式**: 全屏背景 + 左右立绘 + 底部对话框（经典视觉小说）
- **战斗模式**: 全屏战斗背景 + 左右立绘站位 + Tween 动画 + 顶部 HP 条 + 底部操作面板

## 关键约束

1. **后端不改**: GameLoopManager 状态机、CombatManager 战斗流程、DialogueManager 对话流程全部保持不变
2. **信号驱动**: 所有 UI 通过 GameEvents 信号订阅数据更新，与后端松耦合
3. **动画架构预留**: 当前用 Tween（前冲/闪烁/抖动），未来用 AnimatedSprite2D + SpriteFrames 实现每技能独立序列帧特效

## 文件清单

| 文件 | 职责 |
|------|------|
| `src/scenes/ui/exploration_panel.tscn` | 探索场景布局 |
| `src/scripts/ui/exploration_panel.gd` | 区域背景加载 + NPC 头像列表 |
| `src/scenes/ui/dialogue_box.tscn` | 对话全屏布局 (背景+立绘+对话框) |
| `src/scripts/ui/dialogue_box_script.gd` | 立绘切换 + 背景加载 |
| `src/scenes/ui/combat_action_panel.tscn` | 战斗全屏布局 (背景+立绘+HP+操作) |
| `src/scripts/ui/combat_action_panel.gd` | 战斗视觉 + Tween 动画 |
| `src/scenes/ui/battle_result_panel.tscn` | 战斗结算全屏 |

## 资源目录约定

```
assets/ui/
├── backgrounds/        # 区域/战斗/功能背景图 (1024×1024)
├── portraits/          # 主角+NPC 立绘 (512×512)
├── enemy_portraits/    # 敌人立绘 (512×512)
├── encounter_scenes/   # 奇遇事件插图 (512×512)
├── breakthrough_scenes/# 境界突破插图 (512×512, 未来)
└── party_portraits/    # 队伍头像 (60×60, 裁剪自 portraits/)
```

## 未来扩展路径

1. **序列帧技能特效**: `assets/vfx/skills/{skill_id}/frames.tres` → AnimatedSprite2D
2. **多敌人/多队友**: 左右 VBoxContainer 各放 2-3 个缩小立绘
3. **NPC 表情系统**: `portrait_{npc_id}_{emotion}.png` 按对话节点 emotion 字段切换
4. **时段系统**: 按游戏内时间切换 `bg_{region}_{time}.png`
5. **2D 场景行走 (远期)**: 在视觉小说基础上叠加可选的 TileMap 探索模式

## 被否决的方案

- **2D 俯视角 + sprite 行走**: 需要大量 sprite 动画资源，独立开发者不可行
- **NinePatch 纹理按钮**: AI 生成的 256×256 装饰画不适合九宫格拉伸，实测变形严重
- **完整战棋网格**: 需要寻路/移动/射程/地形系统，改动量巨大

## 影响

- 6 份设计文档加了架构变更通知 (combat-ui/dialogue-system/open-world/hud/encounter-ui/interaction-patterns)
- game-concept.md 电梯推销词改为"视觉小说风格"
- 测试通过率不受影响 (467/469, 99.6%)
