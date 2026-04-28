# Epic: 状态效果系统

> **Layer**: Feature
> **GDD**: design/gdd/status-effect-system.md
> **Architecture Module**: Combat
> **Status**: Ready
> **Stories**: 
> - [story-001-status-effect-types.md](story-001-status-effect-types.md)
> - [story-002-status-mechanisms.md](story-002-status-mechanisms.md)
> - [story-003-status-sources-and-interactions.md](story-003-status-sources-and-interactions.md)
> - [story-004-status-ui-visual-feedback.md](story-004-status-ui-visual-feedback.md)

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-status-effect-types.md) | 状态效果类型实现 | Ready | Logic | Feature |
| [Story 002](story-002-status-mechanisms.md) | 状态机制实现 | Ready | Logic | Feature |
| [Story 003](story-003-status-sources-and-interactions.md) | 状态来源与系统交互 | Ready | Integration | Feature |
| [Story 004](story-004-status-ui-visual-feedback.md) | 状态UI与视觉反馈 | Ready | Visual/Feel | Feature |

## Overview

状态效果系统采用"回合计数 + 层数堆叠"的混合机制，通过四大类状态效果（持续伤害/恢复、属性修正、控制效果、特殊机制）为玩家提供丰富的战术博弈空间。系统支持回合制持续、时间制持续、叠加层数等多种机制。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-status-eff-001 | 状态效果类型实现 | ADR-001 ✅ |
| TR-status-eff-002 | 状态机制实现 | ADR-001 ✅ |
| TR-status-eff-003 | 状态来源与系统交互 | ADR-001 ✅ |
| TR-status-eff-004 | 状态UI与视觉反馈 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/status-effect-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/dev-story [story-path]` to begin implementation.