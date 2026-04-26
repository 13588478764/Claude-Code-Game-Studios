# Epic: 武学组合/连招系统

> **Layer**: Feature
> **GDD**: design/gdd/martial-arts-combo-system.md
> **Architecture Module**: Combat
> **Status**: Ready
> **Stories**: 
| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 武功组合机制 | Logic | Ready | ADR-001 |
| 002 | 连招系统 | Integration | Ready | ADR-001 |
| 003 | 连招效果计算 | Logic | Ready | ADR-001 |

## Overview

武学组合/连招系统实现多个武学技能的组合和连招，为玩家提供高级战斗技巧和策略深度，允许玩家通过连贯的动作组合打出更高伤害。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，战斗系统 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-martial-arts-combo-001 | 武功组合机制 | ADR-001 ✅ |
| TR-martial-arts-combo-002 | 连招系统 | ADR-001 ✅ |
| TR-martial-arts-combo-003 | 连招效果计算 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/martial-arts-combo-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories martial-arts-combo-system` to break this epic into implementable stories.