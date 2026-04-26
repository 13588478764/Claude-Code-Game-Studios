# Epic: 战斗系统

> **Layer**: Feature
> **GDD**: design/gdd/combat-system.md
> **Architecture Module**: Combat
> **Status**: Ready
> **Stories**: 
> - [story-001-combat-mechanics.md](story-001-combat-mechanics.md)
> - [story-002-weakness-system.md](story-002-weakness-system.md)
> - [story-003-combat-link-system.md](story-003-combat-link-system.md)

## Overview

战斗系统实现玩家与敌人的战斗交互，采用策略指令回合制模式，通过弱点打击、连携系统、架势破防和内力资源四大核心机制为玩家提供深度策略体验。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，战斗系统 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-combat-001 | 回合制战斗机制 | ADR-001 ✅ |
| TR-combat-002 | 弱点打击系统 | ADR-001 ✅ |
| TR-combat-003 | 连携系统 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/combat-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-combat-mechanics.md) | 战斗机制核心 | Complete | Logic | Feature |
| [Story 002](story-002-weakness-system.md) | 弱点打击系统 | Complete | Logic | Feature |
| [Story 003](story-003-combat-link-system.md) | 连携系统 | Complete | Logic | Feature |