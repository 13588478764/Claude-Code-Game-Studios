# Epic: 经济系统

> **Layer**: Feature
> **GDD**: design/gdd/economy-system.md
> **Architecture Module**: Economy
> **Status**: Ready
> **Stories**: 
> - [story-001-currency-management.md](story-001-currency-management.md)
> - [story-002-trade-system.md](story-002-trade-system.md)
> - [story-003-price-balancing.md](story-003-price-balancing.md)

## Overview

经济系统采用"单货币 + 核心资源"的极简模型，以银两作为通用流通货币，材料作为核心成长资源。银两通过战斗掉落、任务奖励、奇遇系统和物品出售获得，用于购买基础物资、装备强化、天赋重置等服务性消费；材料通过探索、拆解、奇遇获得，用于装备强化、境界突破、制造镶嵌等核心成长消耗。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-economy-001 | 货币管理系统 | ADR-001 ✅ |
| TR-economy-002 | 交易系统 | ADR-001 ✅ |
| TR-economy-003 | 价格平衡机制 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/economy-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-currency-management.md) | 货币管理系统 | Complete | Logic | Feature |
| [Story 002](story-002-trade-system.md) | 交易系统 | Complete | Integration | Feature |
| [Story 003](story-003-price-balancing.md) | 价格平衡机制 | Complete | Logic | Feature |

## Next Step

Run `/dev-story [story-path]` to begin implementation.