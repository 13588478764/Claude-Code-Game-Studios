# Epic: 物品数据库

> **Layer**: Foundation
> **GDD**: design/gdd/item-database.md
> **Architecture Module**: Data Management
> **Status**: Complete
> **Stories**: 
> - [story-001-item-data-structures.md](story-001-item-data-structures.md)
> - [story-002-item-attribute-storage.md](story-002-item-attribute-storage.md)
> - [story-003-data-access-interface.md](story-003-data-access-interface.md)

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-item-data-structures.md) | 物品数据结构定义 | Complete | Logic | Foundation |
| [Story 002](story-002-item-attribute-storage.md) | 物品属性存储 | Complete | Logic | Foundation |
| [Story 003](story-003-data-access-interface.md) | 数据访问接口 | Complete | Logic | Foundation |

## Overview

物品数据库负责存储所有装备和物品的数据结构和属性，为游戏中的所有物品提供统一的数据存储和访问接口，支持不同类型的物品（装备、消耗品、材料）及其属性管理。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-item-db-001 | 物品数据结构定义 | ADR-001 ✅ |
| TR-item-db-002 | 物品属性存储 | ADR-001 ✅ |
| TR-item-db-003 | 数据访问接口 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/item-database.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

所有故事已完成实现。