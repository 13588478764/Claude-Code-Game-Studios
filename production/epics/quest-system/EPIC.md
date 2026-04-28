# Epic: 任务系统

> **Layer**: Feature
> **GDD**: design/gdd/quest-system.md
> **Architecture Module**: Quest
> **Status**: Complete
> **Stories**: 
| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 任务状态管理 | Logic | Ready | ADR-001 |
| 002 | 任务追踪系统 | Integration | Ready | ADR-001 |
| 003 | 任务奖励发放 | Integration | Ready | ADR-001 |

## Overview

任务系统采用"数据驱动 + 状态机"的轻量级架构，通过4种核心任务类型（主线任务、支线任务、悬赏任务、奇遇任务）为玩家提供叙事引导和目标感。主线任务推动核心剧情，解锁新地图和功能；支线任务丰富世界观，提供额外资源；悬赏任务提供重复性玩法和稳定收入；奇遇任务作为隐藏惊喜增强探索乐趣。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-quest-001 | 任务状态管理 | ADR-001 ✅ |
| TR-quest-002 | 任务追踪系统 | ADR-001 ✅ |
| TR-quest-003 | 任务奖励发放 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/quest-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories quest-system` to break this epic into implementable stories.