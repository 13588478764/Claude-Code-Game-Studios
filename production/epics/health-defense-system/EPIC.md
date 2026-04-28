# Epic: 生命值/防御系统

> **Layer**: Feature
> **GDD**: design/gdd/health-defense-system.md
> **Architecture Module**: Combat
> **Status**: Complete
> **Stories**: 
> - [story-001-health-and-poise-mechanics.md](story-001-health-and-poise-mechanics.md)
> - [story-002-defense-types-and-mitigation.md](story-002-defense-types-and-mitigation.md)
> - [story-003-recovery-and-status-effects.md](story-003-recovery-and-status-effects.md)

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-health-and-poise-mechanics.md) | 生命值与架势机制 | Complete | Logic | Feature |
| [Story 002](story-002-defense-types-and-mitigation.md) | 防御类型与减伤 | Complete | Logic | Feature |
| [Story 003](story-003-recovery-and-status-effects.md) | 恢复与状态效果 | Complete | Logic | Feature |

## Overview

生命值/防御系统采用"传统血条 + 架势破防"的双层生存机制，通过生命值(HP)和架势值(Poise)两个核心数值为玩家提供深度策略体验。系统支持护甲减伤、抗性减免、闪避规避和格挡减伤四种防御类型，确保战斗既有策略深度又不会过于复杂。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-health-def-001 | 生命值与架势机制 | ADR-001 ✅ |
| TR-health-def-002 | 防御类型与减伤 | ADR-001 ✅ |
| TR-health-def-003 | 恢复与状态效果 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/health-defense-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

所有故事已完成实现。