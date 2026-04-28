# Epic: 伤害计算系统

> **Layer**: Feature
> **GDD**: design/gdd/damage-calculation-system.md
> **Architecture Module**: Combat
> **Status**: Complete
> **Stories**: 
> - [story-001-damage-types-and-formulas.md](story-001-damage-types-and-formulas.md)
> - [story-002-damage-multipliers-and-corrections.md](story-002-damage-multipliers-and-corrections.md)
> - [story-003-damage-visualization-and-feedback.md](story-003-damage-visualization-and-feedback.md)

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-damage-types-and-formulas.md) | 伤害类型与公式 | Complete | Logic | Feature |
| [Story 002](story-002-damage-multipliers-and-corrections.md) | 伤害倍率与修正 | Complete | Logic | Feature |
| [Story 003](story-003-damage-visualization-and-feedback.md) | 伤害可视化与反馈 | Complete | UI | Feature |

## Overview

伤害计算系统采用"减法公式为主 + 乘法修正为辅"的混合机制，通过三种核心伤害类型（外功伤害、内功伤害、真实伤害）为玩家提供直观可控的数值体验。系统支持弱点克制、连击数、状态效果等多种影响因素，确保战斗既有策略深度又不会过于复杂。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-dmg-calc-001 | 伤害类型与公式 | ADR-001 ✅ |
| TR-dmg-calc-002 | 伤害倍率与修正 | ADR-001 ✅ |
| TR-dmg-calc-003 | 伤害可视化与反馈 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/damage-calculation-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/dev-story [story-path]` to begin implementation.