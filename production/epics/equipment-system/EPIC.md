# Epic: 装备系统

> **Layer**: Feature
> **GDD**: design/gdd/equipment-system.md
> **Architecture Module**: Character
> **Status**: Complete
> **Stories**: 
> - [story-001-equipment-management.md](story-001-equipment-management.md)
> - [story-002-equipment-wearing.md](story-002-equipment-wearing.md)
> - [story-003-equipment-attribute-calculation.md](story-003-equipment-attribute-calculation.md)

## Overview

装备系统管理玩家的装备和物品，为玩家提供装备穿戴、属性加成和装备管理功能，是角色战斗力的重要组成部分。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-equipment-001 | 装备穿戴系统 | ADR-001 ✅ |
| TR-equipment-002 | 装备属性计算 | ADR-001 ✅ |
| TR-equipment-003 | 装备管理功能 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/equipment-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-equipment-management.md) | 装备管理功能 | Complete | Logic | Feature |
| [Story 002](story-002-equipment-wearing.md) | 装备穿戴系统 | Complete | Integration | Feature |
| [Story 003](story-003-equipment-attribute-calculation.md) | 装备属性计算 | Complete | Logic | Feature |

## Next Step

Run `/dev-story [story-path]` to begin implementation.