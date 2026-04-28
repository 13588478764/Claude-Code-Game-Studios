# Epic: 技能树/学习路径系统

> **Layer**: Feature
> **GDD**: design/gdd/skill-tree-learning-path-system.md
> **Architecture Module**: MartialArts
> **Status**: Ready
> **Stories**: 
> - [story-001-learning-path-types.md](story-001-learning-path-types.md)
> - [story-002-unlock-mechanisms.md](story-002-unlock-mechanisms.md)
> - [story-003-visualization-and-interaction.md](story-003-visualization-and-interaction.md)

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-learning-path-types.md) | 学习路径类型 | Ready | Logic | Feature |
| [Story 002](story-002-unlock-mechanisms.md) | 解锁机制 | Ready | Logic | Feature |
| [Story 003](story-003-visualization-and-interaction.md) | 可视化与交互 | Ready | UI | Feature |

## Overview

技能树/学习路径系统采用"模块化武学图谱 + 熟练度解锁"的机制，通过为每个武学流派或角色境界设计独立的微型图谱，摒弃复杂的传统RPG天赋树，转而强调"武学招式"的收集与精进。系统实现线性主干、分支专精和网状关联的混合结构。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-skill-tree-001 | 学习路径类型 | ADR-001 ✅ |
| TR-skill-tree-002 | 解锁机制 | ADR-001 ✅ |
| TR-skill-tree-003 | 可视化与交互 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/skill-tree-learning-path-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/dev-story [story-path]` to begin implementation.