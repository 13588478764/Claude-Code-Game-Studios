# Epic: 地图/小地图系统

> **Layer**: Core
> **GDD**: design/gdd/minimap-system.md
> **Architecture Module**: UI
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories minimap-system`

## Overview

地图/小地图系统显示玩家当前位置和已探索区域，为玩家提供导航和空间感知功能，帮助玩家在开放世界中定位和规划探索路线。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，UI系统 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-minimap-001 | 玩家位置显示 | ADR-001 ✅ |
| TR-minimap-002 | 已探索区域标记 | ADR-001 ✅ |
| TR-minimap-003 | 导航标记系统 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/minimap-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories minimap-system` to break this epic into implementable stories.