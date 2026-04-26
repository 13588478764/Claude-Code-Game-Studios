# Epic: 武学数据库

> **Layer**: Foundation
> **GDD**: design/gdd/martial-arts-database.md
> **Architecture Module**: Data Management
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories martial-arts-database`

## Overview

武学数据库负责存储所有武学技能的数据结构和属性，为游戏中的所有武功招式提供统一的数据存储和访问接口，支持不同类型的武学（剑法、掌法、内功、轻功）及其属性管理。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-martial-arts-db-001 | 武学数据结构定义 | ADR-001 ✅ |
| TR-martial-arts-db-002 | 武学属性存储 | ADR-001 ✅ |
| TR-martial-arts-db-003 | 数据访问接口 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/martial-arts-database.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories martial-arts-database` to break this epic into implementable stories.