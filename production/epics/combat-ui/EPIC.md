# Epic: 战斗UI系统

> **Layer**: Feature
> **GDD**: design/gdd/combat-ui.md
> **Architecture Module**: UI
> **Status**: Ready
> **Stories**: 
> - [story-001-combat-hud-display.md](story-001-combat-hud-display.md)
> - [story-002-combat-menu-interactions.md](story-002-combat-menu-interactions.md)
> - [story-003-combat-feedback-system.md](story-003-combat-feedback-system.md)

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-combat-hud-display.md) | 战斗HUD显示 | Complete | UI | Feature |
| [Story 002](story-002-combat-menu-interactions.md) | 战斗菜单交互 | Complete | UI | Feature |
| [Story 003](story-003-combat-feedback-system.md) | 战斗反馈系统 | Complete | UI | Feature |

## Overview

战斗UI系统采用"沉浸式HUD + 模块化面板"的设计，通过常驻HUD（角色状态栏、行动队列、连携/连击指示器、状态效果图标栏、伤害/状态飘字）和交互面板（武学指令菜单、目标选择光标、战斗日志、暂停/战术菜单）为玩家提供清晰的信息反馈和流畅的操作体验。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-combat-ui-001 | 战斗HUD显示 | ADR-001 ✅ |
| TR-combat-ui-002 | 战斗菜单交互 | ADR-001 ✅ |
| TR-combat-ui-003 | 战斗反馈系统 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/combat-ui.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/dev-story [story-path]` to begin implementation.