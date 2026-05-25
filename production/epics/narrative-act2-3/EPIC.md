# Epic: 第二三幕剧情大纲 + 数据填充

> **Layer**: Polish (Content)
> **GDD**: design/narrative/act-2-outline.md + design/narrative/act-3-outline.md
> **Architecture Module**: Narrative / Dialogue Data
> **Status**: IN PROGRESS (大纲 DONE, 数据填充 PENDING)
> **Created**: 2026-05-20 (Sprint 7 Polish 阶段)
> **Stories**:
> - story-001-act2-outline.md (DONE — 第二幕剧情结构定稿)
> - story-002-act3-outline.md (DONE — 第三幕大结局定稿)
> - story-003-act2-dialogue-data.md (PENDING — Act 2 对话数据填充)
> - story-004-act3-dialogue-data.md (PENDING — Act 3 对话数据填充)
> - story-005-act2-act3-quests.md (PENDING — 主支线任务数据)

## Overview

补齐 Alpha 阶段缺失的第二三幕剧情内容。Alpha 仅实现 Act 1 + 系统骨架, 三幕完整剧情是 Beta 的硬性内容要求。本 epic 涵盖: 剧情大纲撰写 (已 DONE) → 对话数据填充 → 主支线任务挂接 → 关键 NPC 对话扩写。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| (无) | 后续可补 ADR-010 (剧情数据组织规范) | LOW |

## 三幕结构 (已定稿)

| 幕 | 主题 | 玩家境界段 | 主要场景 | 关键 NPC |
|----|------|------------|----------|----------|
| Act 1 | 入门修真界 (已实现) | 炼气 → 筑基 | 云中鹤山门 + 周边 | 师父云中鹤 + 同门 |
| Act 2 | 江湖纷争 (大纲 DONE) | 金丹 → 元婴 | 三大宗门 + 凡间 | 各宗门掌门 + 反派 |
| Act 3 | 飞升大结局 (大纲 DONE) | 化神 → 渡劫 | 仙界入口 + 渡劫之地 | 仙人 + 最终 Boss |

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| s001 | Act 2 剧情大纲 | DONE | Narrative | Polish |
| s002 | Act 3 剧情大纲 | DONE | Narrative | Polish |
| s003 | Act 2 对话数据填充 (≥15 段对话) | PENDING | Data | Polish |
| s004 | Act 3 对话数据填充 (≥10 段对话, 含大结局分支) | PENDING | Data | Polish |
| s005 | Act 2/3 主支线任务数据 (≥8 主线 + ≥5 支线) | PENDING | Data | Polish |
| s006 | (PLANNED) Act 2/3 NPC 关系初始值 | PENDING | Data | Polish |
| s007 | (PLANNED) Act 2/3 奇遇挂接 (encounter-system 数据) | PENDING | Data | Polish |

## 数据填充工作量估算

| 类别 | 数量 | 单位估算 | 总工时 |
|------|------|----------|--------|
| Act 2 对话 | ≥15 段 | 0.5 天/段 | 7.5 天 |
| Act 3 对话 | ≥10 段 | 0.5 天/段 | 5 天 |
| 主支线任务 | ≥13 个 | 0.3 天/个 | 4 天 |
| NPC 关系初始值 | ≥20 NPC | 0.1 天/NPC | 2 天 |
| 奇遇挂接 | ≥10 条 (Act 2/3 专属) | 0.4 天/条 | 4 天 |
| **总计** | — | — | **≈22.5 天** |

## Definition of Done

This epic is complete when:
- design/narrative/act-2-outline.md + act-3-outline.md 状态 = Approved
- 所有对话数据在 `assets/data/dialogues/` 或 `design/narrative/dialogues/` 落档
- 主支线任务全部可在 quest-system 中触发
- 至少 1 场 Act 3 通关 Playtest 验证大结局可达
- dialogue_data.gd 中 3 处 `return true` stub 全部用真实条件替换 (与 polish-fixlist #7 联动)
- NPC 关系数据接入 character-relationship-system

## Dependencies

- **dialogue-system** epic (基础对话系统已 DONE)
- **quest-system** epic (任务系统已 DONE)
- **encounter-system** epic (奇遇内容补齐, 与 polish-fixlist Concern #1 联动)
- **character-relationship-system** epic (关系初始值数据)

## Maintenance

- **Writer + Narrative Director** 双签: 对话数据需要双角色审稿
- **Cross-check**: 与 character-relationship-system 联动验证关系阈值
- **Playtest**: 每 5 段对话填充后跑 1 场 Playtest 验证流程
