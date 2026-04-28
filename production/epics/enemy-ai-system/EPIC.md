# Epic: 敌人AI系统

> **Layer**: Feature
> **GDD**: design/gdd/enemy-ai-system.md
> **Architecture Module**: Combat
> **Status**: Complete
> **Stories**: 
> - [story-001-ai-behavior-types.md](story-001-ai-behavior-types.md)
> - [story-002-ai-difficulty-levels.md](story-002-ai-difficulty-levels.md)
> - [story-003-ai-decision-mechanism.md](story-003-ai-decision-mechanism.md)

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-ai-behavior-types.md) | AI行为类型 | Complete | Logic | Feature |
| [Story 002](story-002-ai-difficulty-levels.md) | AI难度等级 | Complete | Logic | Feature |
| [Story 003](story-003-ai-decision-mechanism.md) | AI决策机制 | Complete | Logic | Feature |

## Overview

敌人AI系统采用"优先级评分表(Priority Scoring/Utility AI Lite)"机制，通过战术意识行为（基础攻击、弱点利用、状态管理、生存本能、连携配合）为玩家提供智能且具有挑战性的对手。系统支持简单（随机选择）、普通（基本策略）、困难（高级策略、预测玩家行为）三种难度等级，确保不同水平的玩家都能获得合适的挑战。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-enemy-ai-001 | AI行为类型 | ADR-001 ✅ |
| TR-enemy-ai-002 | AI难度等级 | ADR-001 ✅ |
| TR-enemy-ai-003 | AI决策机制 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/enemy-ai-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/dev-story [story-path]` to begin implementation.