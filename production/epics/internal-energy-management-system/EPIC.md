# Epic: 内力/能量管理系统

> **Layer**: Feature
> **GDD**: design/gdd/internal-energy-management-system.md
> **Architecture Module**: Combat
> **Status**: Complete
> **Stories**: 
> - [story-001-qi-types-and-pools.md](story-001-qi-types-and-pools.md)
> - [story-002-recovery-mechanisms.md](story-002-recovery-mechanisms.md)
> - [story-003-consumption-mechanisms.md](story-003-consumption-mechanisms.md)

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-qi-types-and-pools.md) | 内力类型与池 | Complete | Logic | Feature |
| [Story 002](story-002-recovery-mechanisms.md) | 恢复机制 | Complete | Logic | Feature |
| [Story 003](story-003-consumption-mechanisms.md) | 消耗机制 | Complete | Logic | Feature |

## Overview

内力/能量管理系统采用"单一资源池 + 属性修正"的简化模型，通过统一内力池管理所有武学技能的资源消耗，避免复杂的五行生克计算带来的数值平衡噩梦，同时保留武侠"气"的核心概念。系统采用战斗内动态恢复和战斗外静态恢复的双轨制机制。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-int-energy-mgmt-001 | 内力类型与池 | ADR-001 ✅ |
| TR-int-energy-mgmt-002 | 恢复机制 | ADR-001 ✅ |
| TR-int-energy-mgmt-003 | 消耗机制 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/internal-energy-management-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

所有故事已完成实现。