# Epic: 快速旅行系统

> **Layer**: Core
> **GDD**: design/gdd/fast-travel-system.md
> **Architecture Module**: World Management
> **Status**: Ready
> **Stories**: 
> - [story-001-fast-travel-functionality.md](story-001-fast-travel-functionality.md)
> - [story-002-discovered-location-access.md](story-002-discovered-location-access.md)
> - [story-003-travel-cost-mechanism.md](story-003-travel-cost-mechanism.md)

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-fast-travel-functionality.md) | 快速旅行功能 | Ready | Logic | Core |
| [Story 002](story-002-discovered-location-access.md) | 已发现地点访问 | Ready | Logic | Core |
| [Story 003](story-003-travel-cost-mechanism.md) | 旅行成本机制 | Ready | Logic | Core |

## Overview

快速旅行系统允许玩家在已发现的地点间快速移动，为玩家提供便利的交通方式，节省重复行走的时间，让玩家能够专注于探索和冒险。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，世界流式加载 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-fast-travel-001 | 快速旅行功能 | ADR-001 ✅ |
| TR-fast-travel-002 | 已发现地点访问 | ADR-001 ✅ |
| TR-fast-travel-003 | 旅行成本机制 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/fast-travel-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/dev-story [story-path]` to begin implementation of individual stories.