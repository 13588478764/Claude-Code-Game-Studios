# Systems Index: 打工轮回

> **Status**: Approved
> **Created**: 2026-05-16
> **Last Updated**: 2026-05-25
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

《打工轮回》是一款Roguelike打工模拟器小程序，核心循环为"事件卡二选一→资源管理→撑过工作日"。
系统架构围绕四根支柱设计：三秒上手（极简交互）、一局一笑（荒诞内容）、随开随走（碎片化存档）、
永远有新的（数据驱动扩展）。全部系统为UI驱动的前端组件，无需游戏引擎，技术栈为uni-app + TypeScript。

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | 事件卡系统 | Gameplay | MVP | Designed | design/gdd/event-card.md | 事件数据引擎, 日周期系统, 职业轮回系统 |
| 2 | 资源管理系统 | Core | MVP | Designed | design/gdd/resource-management.md | 存档系统 |
| 3 | 职业轮回系统 | Gameplay | MVP | Designed | design/gdd/job-rotation.md | 存档系统 |
| 4 | 永久进度系统 | Progression | Alpha | Designed | design/gdd/progression-system.md | 局管理器, 存档系统 |
| 5 | 事件数据引擎 | Core | MVP | Designed | design/gdd/event-data-engine.md | — |
| 6 | 选择结算引擎 | Gameplay | MVP | Designed | design/gdd/choice-resolution.md | 资源管理系统, 事件卡系统 |
| 7 | 日周期系统 | Gameplay | MVP | Designed | design/gdd/day-cycle.md | 事件数据引擎 |
| 8 | 局管理器 | Gameplay | MVP | Designed | design/gdd/run-manager.md | 日周期系统, 资源管理系统, 职业轮回系统 |
| 9 | 存档系统 | Persistence | MVP | Designed | design/gdd/save-system.md | — |
| 10 | 成就系统 | Progression | Beta | Designed | design/gdd/achievement-system.md | 局管理器, 永久进度系统 |
| 11 | 被动技能系统 | Progression | Alpha | Designed | design/gdd/passive-skill-system.md | 资源管理系统, 存档系统 |
| 12 | 广告激励系统 | Economy | Alpha | Not Started | — | 局管理器, 资源管理系统 |
| 13 | 分享系统 | Meta | Beta | Not Started | — | 局管理器 |
| 14 | 游戏主界面 | UI | MVP | Designed | design/gdd/game-main-ui.md | 事件卡系统, 资源管理系统, 选择结算引擎, 状态效果系统 |
| 18 | 状态效果系统 | Gameplay | MVP | Designed | design/gdd/status-system.md | 选择结算引擎, 日周期系统, 资源管理系统, 存档系统 |
| 19 | 升职机制 (Career Progression) | Progression | Alpha | Designed | design/gdd/career-progression-system.md | 日周期系统, 局管理器 |
| 20 | 道具系统 (Item) | Economy | Alpha | Designed | design/gdd/item-system.md | 资源管理系统, 局管理器 |
| 21 | 结局系统 (Ending) | Progression | Alpha | Designed | design/gdd/ending-system.md | 局管理器, 升职机制, 资源管理系统 |
| 15 | 职业选择页 | UI | Alpha | Not Started | — | 职业轮回系统 |
| 16 | 结算页面 | UI | Alpha | Not Started | — | 局管理器, 广告激励系统 |
| 17 | 主菜单/图鉴 | UI | Beta | Not Started | — | 成就系统, 被动技能系统, 职业轮回系统 |

---

## Categories

| Category | Description |
|----------|-------------|
| **Core** | 基础系统，多个系统依赖它们 |
| **Gameplay** | 直接产生玩法体验的系统 |
| **Progression** | 跨局成长和收集系统 |
| **Economy** | 资源获取和变现系统 |
| **Persistence** | 数据存储和读写 |
| **UI** | 玩家直接交互的界面 |
| **Meta** | 核心循环之外的辅助系统 |

---

## Priority Tiers

| Tier | Definition | Target | Systems Count |
|------|------------|--------|---------------|
| **MVP** | 核心循环运转的最小系统集，验证"二选一事件+资源管理有没有趣" | 1-2周 | 9 |
| **Alpha** | 完整的可运营版本（多职业+广告+进度） | 3-4周 | 5 |
| **Beta** | 完整体验（成就+分享+图鉴） | 5-6周 | 3 |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **[9] 存档系统** — 所有持久化数据的读写基础，6个系统依赖它
2. **[5] 事件数据引擎** — JSON事件配置的加载和管理，数据驱动架构的根基

### Core Layer (depends on foundation)

1. **[2] 资源管理系统** — depends on: 存档系统
2. **[7] 日周期系统** — depends on: 事件数据引擎
3. **[3] 职业轮回系统** — depends on: 存档系统

### Feature Layer (depends on core)

1. **[1] 事件卡系统** — depends on: 事件数据引擎, 日周期系统, 职业轮回系统
2. **[6] 选择结算引擎** — depends on: 资源管理系统, 事件卡系统, 状态效果系统
3. **[18] 状态效果系统** — depends on: 选择结算引擎, 日周期系统, 资源管理系统, 存档系统
4. **[11] 被动技能系统** — depends on: 资源管理系统, 存档系统
5. **[8] 局管理器** — depends on: 日周期系统, 资源管理系统, 职业轮回系统, 状态效果系统

### Meta Layer (depends on features)

1. **[4] 永久进度系统** — depends on: 局管理器, 存档系统
2. **[10] 成就系统** — depends on: 局管理器, 永久进度系统
3. **[12] 广告激励系统** — depends on: 局管理器, 资源管理系统
4. **[13] 分享系统** — depends on: 局管理器

### Presentation Layer (depends on gameplay)

1. **[14] 游戏主界面** — depends on: 事件卡系统, 资源管理系统, 选择结算引擎
2. **[15] 职业选择页** — depends on: 职业轮回系统
3. **[16] 结算页面** — depends on: 局管理器, 广告激励系统
4. **[17] 主菜单/图鉴** — depends on: 成就系统, 被动技能系统, 职业轮回系统

---

## Recommended Design Order

| Order | System | Priority | Layer | Est. Effort |
|-------|--------|----------|-------|-------------|
| 1 | 存档系统 | MVP | Foundation | S |
| 2 | 事件数据引擎 | MVP | Foundation | S |
| 3 | 资源管理系统 | MVP | Core | S |
| 4 | 日周期系统 | MVP | Core | S |
| 5 | 职业轮回系统 | MVP | Core | S |
| 6 | 事件卡系统 | MVP | Feature | M |
| 7 | 选择结算引擎 | MVP | Feature | S |
| 8 | 局管理器 | MVP | Feature | M |
| 9 | 游戏主界面 | MVP | Presentation | M |
| 10 | 被动技能系统 | Alpha | Feature | S |
| 11 | 永久进度系统 | Alpha | Meta | S |
| 12 | 广告激励系统 | Alpha | Meta | S |
| 13 | 职业选择页 | Alpha | Presentation | S |
| 14 | 结算页面 | Alpha | Presentation | S |
| 15 | 成就系统 | Beta | Meta | S |
| 16 | 分享系统 | Beta | Meta | S |
| 17 | 主菜单/图鉴 | Beta | Presentation | S |

Effort: S = 1 session, M = 2-3 sessions

---

## Circular Dependencies

None found. 依赖图为有向无环图(DAG)，可以严格按层级实现。

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| 事件卡系统 | Design | 事件内容（文案）不够好笑→核心体验崩塌 | 先写20个事件原型，找5个朋友测试笑点 |
| 事件数据引擎 | Technical | 事件权重/去重算法影响重复感 | MVP阶段用简单随机，观察重复率再优化 |
| 广告激励系统 | Technical | 多平台广告SDK差异大，适配工作量不确定 | Alpha阶段先只做微信一个平台验证 |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 21 |
| Design docs started | 16 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 10/10 ✓ |
| Alpha systems designed (incl. retrofit) | 5/8 |
| Beta systems designed (incl. retrofit) | 1/3 |

---

## Next Steps

- [ ] Design MVP-tier systems first: `/design-system 存档系统`
- [ ] Or auto-pick next: `/map-systems next`
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check pre-production` when MVP systems are designed
- [ ] Prototype the event card system early: `/prototype event-card`
