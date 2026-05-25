# Epics Index

Last Updated: 2026-05-25
Engine: Godot 4.6
Total Epics: 44 (41 实施 + 3 polish 阶段新增)

## Foundation Layer

| Epic | System | GDD | Stories | Status |
|------|--------|-----|---------|--------|
| world-streaming-system | 世界流式加载系统 | design/gdd/world-streaming-system.md | Done | DONE |
| lod-system | LOD（细节层次）系统 | design/gdd/lod-system.md | Done | DONE |
| martial-arts-database | 武学数据库 | design/gdd/martial-arts-database.md | Done | DONE |
| item-database | 物品数据库 | design/gdd/item-database.md | Done | DONE |
| random-event-generator | 随机事件生成器 | design/gdd/random-event-generator.md | Done | DONE |
| consistency-check-report | 一致性检查报告 (元工具) | — | Infra | DONE |
| systems-index | 系统索引 (元目录) | — | Infra | DONE |
| game-concept | 游戏概念 (顶层定义) | design/game-concept.md | Foundation | DONE |

## Core Layer

| Epic | System | GDD | Stories | Status |
|------|--------|-----|---------|--------|
| open-world-exploration-system | 开放世界探索系统 | design/gdd/open-world-exploration-system.md | Done | DONE |
| minimap-system | 地图/小地图系统 | design/gdd/minimap-system.md | Done | DONE |
| point-of-interest-tracking-system | 兴趣点追踪系统 | design/gdd/point-of-interest-tracking-system.md | Done | DONE |
| fast-travel-system | 快速旅行系统 | design/gdd/fast-travel-system.md | Done (5 stub) | DONE |
| world-state-persistence-system | 世界状态持久化 | design/gdd/world-state-persistence-system.md | Done | DONE |
| growth-data-persistence | 成长数据持久化 | design/gdd/growth-data-persistence.md | Done | DONE |

## Feature Layer — Combat

| Epic | System | GDD | Stories | Status |
|------|--------|-----|---------|--------|
| combat-system | 战斗系统 | design/gdd/combat-system.md | Done | DONE |
| martial-arts-system | 武学系统 | design/gdd/martial-arts-system.md | Done | DONE |
| martial-arts-combo-system | 武学组合/连招系统 | design/gdd/martial-arts-combo-system.md | Done | DONE |
| damage-calculation-system | 伤害计算系统 | design/gdd/damage-calculation-system.md | Done (乘数 PENDING) | POLISH |
| hit-detection-system | 命中检测系统 | design/gdd/hit-detection-system.md | Done | DONE |
| status-effect-system | 状态效果系统 | design/gdd/status-effect-system.md | Done | DONE |
| enemy-ai-system | 敌人 AI 系统 | design/gdd/enemy-ai-system.md | Done | DONE |
| enemy-scaling-system | 敌人缩放系统 | design/gdd/enemy-scaling-system.md | Done | DONE |
| health-defense-system | 生命/防御系统 | design/gdd/health-defense-system.md | Done | DONE |
| internal-energy-management-system | 内力管理系统 | design/gdd/internal-energy-management-system.md | Done | DONE |

## Feature Layer — Character & Equipment

| Epic | System | GDD | Stories | Status |
|------|--------|-----|---------|--------|
| character-progression-system | 角色成长系统 | design/gdd/character-progression-system.md | Done | DONE |
| level-up-mechanism | 升级机制 | design/gdd/level-up-mechanism.md | Done | DONE |
| experience-system | 经验值系统 | design/gdd/experience-system.md | Done | DONE |
| attribute-point-allocation-system | 属性点分配系统 | design/gdd/attribute-point-allocation-system.md | Done | DONE |
| skill-tree-learning-path-system | 技能树/学习路径系统 | design/gdd/skill-tree-learning-path-system.md | Done | DONE |
| equipment-system | 装备系统 | design/gdd/equipment-system.md | Done (9/15 槽决策 PENDING) | POLISH |
| equipment-slot-system | 装备槽位系统 | design/gdd/equipment-slot-system.md | Done | POLISH |
| equipment-attribute-calculation | 装备属性计算 | design/gdd/equipment-attribute-calculation.md | Done | DONE |

## Feature Layer — Content & Reward

| Epic | System | GDD | Stories | Status |
|------|--------|-----|---------|--------|
| encounter-system | 奇遇系统 | design/gdd/encounter-system.md | Done (内容待补齐) | POLISH |
| encounter-condition-check-system | 奇遇条件检查 | design/gdd/encounter-condition-check-system.md | Done | DONE |
| encounter-history-record-system | 奇遇历史记录 | design/gdd/encounter-history-record-system.md | Done | DONE |
| quest-system | 任务系统 | design/gdd/quest-system.md | Done | DONE |
| reward-distribution-system | 奖励分发系统 | design/gdd/reward-distribution-system.md | Done | DONE |
| economy-system | 经济系统 | design/gdd/economy-system.md | Done | DONE |

## Presentation Layer

| Epic | System | GDD | Stories | Status |
|------|--------|-----|---------|--------|
| hud-system | HUD 系统 | design/ux/hud.md | Done (10 信号 PENDING) | POLISH |
| dialogue-system | 对话系统 | design/gdd/dialogue-system.md | Done (3 stub) | POLISH |
| character-relationship-system | 角色关系系统 | design/gdd/character-relationship-system.md | Done | DONE |
| combat-ui | 战斗 UI | design/ux/combat-ui.md | Done | DONE |
| equipment-ui | 装备 UI | design/ux/equipment-ui.md | Done (1 stub) | POLISH |

## Polish Phase Epics (2026-05-15+ 新增)

| Epic | System | GDD | Stories | Status |
|------|--------|-----|---------|--------|
| ai-asset-pipeline | AI 美术批量出图管线 (ComfyUI + FLUX) | production/epics/ai-asset-pipeline/EPIC.md | 第一批 41 张 DONE; 第二批 54 张挂机中 | IN PROGRESS |
| theme-system | Godot 主题系统 (main_theme.tres + 生成器) | production/epics/theme-system/EPIC.md | Theme 已就位; 全 UI 普及中 | IN PROGRESS |
| narrative-act2-3 | 第二三幕剧情大纲 + 数据填充 | design/narrative/act-2-outline.md + act-3-outline.md | 大纲 DONE; 数据填充 PENDING | IN PROGRESS |

---

## 维护说明

- **DONE**: 系统实现 + GDD + 测试三齐, Alpha 阶段已签收
- **POLISH**: 系统骨架已搭, 但 polish-fixlist-2026-05-25.md 中含改进项
- **IN PROGRESS**: Polish 阶段新增, 持续推进中
- **Infra**: 元工具/元目录类 epic, 不对应单一 GDD

更新此索引时, 请同时验证 `production/epics/` 实际目录数量与本文件一致 (当前 41 + 3 新 polish = 44)。
