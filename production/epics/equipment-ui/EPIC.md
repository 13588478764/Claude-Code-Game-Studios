# Epic: 装备UI

> **Layer**: Feature
> **GDD**: design/gdd/equipment-ui.md
> **Architecture Module**: UI
> **Status**: Complete
> **Stories**: 
> - [story-001-equipment-interface-layout.md](story-001-equipment-interface-layout.md)
> - [story-002-equipment-interactions.md](story-002-equipment-interactions.md)
> - [story-003-visual-feedback-and-effects.md](story-003-visual-feedback-and-effects.md)

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-equipment-interface-layout.md) | 装备界面布局 | Complete | UI | Feature |
| [Story 002](story-002-equipment-interactions.md) | 装备交互功能 | Complete | UI | Feature |
| [Story 003](story-003-visual-feedback-and-effects.md) | 视觉反馈与特效 | Complete | UI | Feature |

## Overview

装备UI系统为玩家提供直观的装备管理和查看界面。该系统与装备槽位系统、装备属性计算系统和战斗UI集成，支持装备的装备/卸下、属性对比、品阶显示等功能，并遵循统一的4级品阶颜色编码（普通-白色、稀有-蓝色、史诗-紫色、传说-金色）。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-equip-ui-001 | 装备界面布局 | ADR-001 ✅ |
| TR-equip-ui-002 | 装备交互功能 | ADR-001 ✅ |
| TR-equip-ui-003 | 视觉反馈与特效 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/equipment-ui.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/dev-story [story-path]` to begin implementation.