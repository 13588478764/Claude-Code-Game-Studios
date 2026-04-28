# Epic: 兴趣点追踪系统

> **Layer**: Core
> **GDD**: design/gdd/point-of-interest-tracking-system.md
> **Architecture Module**: World Management
> **Status**: Complete
> **Stories**: 
> - [story-001-poi-marking-system.md](story-001-poi-marking-system.md)
> - [story-002-poi-tracking-functionality.md](story-002-poi-tracking-functionality.md)
> - [story-003-poi-discovery-feedback.md](story-003-poi-discovery-feedback.md)

## Overview

兴趣点追踪系统跟踪和标记世界中的重要地点，为玩家提供目标指引和探索动机，帮助玩家发现游戏世界中的关键位置和隐藏内容。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，世界流式加载 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-poi-tracking-001 | 兴趣点标记系统 | ADR-001 ✅ |
| TR-poi-tracking-002 | 兴趣点追踪功能 | ADR-001 ✅ |
| TR-poi-tracking-003 | 兴趣点发现反馈 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/point-of-interest-tracking-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-poi-marking-system.md) | 兴趣点标记系统 | Complete | UI | Core |
| [Story 002](story-002-poi-tracking-functionality.md) | 兴趣点追踪功能 | Complete | Logic | Core |
| [Story 003](story-003-poi-discovery-feedback.md) | 兴趣点发现反馈 | Complete | Logic | Core |

## Next Step

所有故事已完成实现。