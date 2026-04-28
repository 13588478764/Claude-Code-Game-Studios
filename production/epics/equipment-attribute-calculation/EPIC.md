# Epic: 装备属性计算

> **Layer**: Feature
> **GDD**: design/gdd/equipment-attribute-calculation.md
> **Architecture Module**: Equipment
> **Status**: Complete
> **Stories**: 
> - [story-001-attribute-calculation-mechanics.md](story-001-attribute-calculation-mechanics.md)
> - [story-002-equipment-bonuses-application.md](story-002-equipment-bonuses-application.md)
> - [story-003-elemental-property-calculation.md](story-003-elemental-property-calculation.md)

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-attribute-calculation-mechanics.md) | 属性计算机制 | Complete | Logic | Feature |
| [Story 002](story-002-equipment-bonuses-application.md) | 装备加成应用 | Complete | Logic | Feature |
| [Story 003](story-003-elemental-property-calculation.md) | 元素属性计算 | Complete | Logic | Feature |

## Overview

装备属性计算系统负责计算装备对角色六维属性（力道、身法、根骨、悟性、定力、福缘）和战斗属性的影响。该系统与装备槽位系统、武学系统和伤害计算系统集成，确保装备效果正确应用到角色能力上。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-equip-attr-calc-001 | 属性计算机制 | ADR-001 ✅ |
| TR-equip-attr-calc-002 | 装备加成应用 | ADR-001 ✅ |
| TR-equip-attr-calc-003 | 元素属性计算 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/equipment-attribute-calculation.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/dev-story [story-path]` to begin implementation.