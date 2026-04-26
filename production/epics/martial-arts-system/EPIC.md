# Epic: 武学系统

> **Layer**: Feature
> **GDD**: design/gdd/martial-arts-system.md
> **Architecture Module**: Combat
> **Status**: Ready
> **Stories**: 
| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 武学获取机制 | Logic | Ready | ADR-001 |
| 002 | 武学熟练度系统 | Logic | Ready | ADR-001 |
| 003 | 武学装备和使用 | Integration | Ready | ADR-001 |
| 004 | 武学组合系统 | Logic | Ready | ADR-001 |

## Overview

武学系统实现武功技能的学习、使用和组合，为玩家提供丰富的战斗手段和策略选择，是武侠游戏中核心的战斗机制之一。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，战斗系统 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-martial-arts-001 | 武功学习机制 | ADR-001 ✅ |
| TR-martial-arts-002 | 武功使用系统 | ADR-001 ✅ |
| TR-martial-arts-003 | 武功组合功能 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/martial-arts-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories martial-arts-system` to break this epic into implementable stories.