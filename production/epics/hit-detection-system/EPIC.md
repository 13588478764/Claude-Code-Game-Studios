# Epic: 命中检测系统

> **Layer**: Feature
> **GDD**: design/gdd/hit-detection-system.md
> **Architecture Module**: Combat
> **Status**: Complete
> **Stories**: 
> - [story-001-hit-mechanics-and-probability.md](story-001-hit-mechanics-and-probability.md)
> - [story-002-influence-factors-and-modifiers.md](story-002-influence-factors-and-modifiers.md)
> - [story-003-detection-types-and-guaranteed-hits.md](story-003-detection-types-and-guaranteed-hits.md)

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-hit-mechanics-and-probability.md) | 命中机制与概率 | Complete | Logic | Feature |
| [Story 002](story-002-influence-factors-and-modifiers.md) | 影响因素与修正 | Complete | Logic | Feature |
| [Story 003](story-003-detection-types-and-guaranteed-hits.md) | 检测类型与强制命中 | Complete | Logic | Feature |

## Overview

命中检测系统采用"属性对抗 + 概率判定"的机制，通过"命中率 vs 闪避率"的对抗公式为玩家提供策略深度体验。系统支持普通攻击、技能、范围攻击等多种检测类型，并提供强制命中机制确保控制技能和爆发窗口期的收益稳定性。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-hit-det-001 | 命中机制与概率 | ADR-001 ✅ |
| TR-hit-det-002 | 影响因素与修正 | ADR-001 ✅ |
| TR-hit-det-003 | 检测类型与强制命中 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/hit-detection-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

所有故事已完成实现。