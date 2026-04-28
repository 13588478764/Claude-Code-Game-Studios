# Epic: 奖励分配系统

> **Layer**: Feature
> **GDD**: design/gdd/reward-distribution-system.md
> **Architecture Module**: Economy
> **Status**: Complete
> **Stories**: 
| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 奖励类型与分类 | Logic | Complete | ADR-001 |
| 002 | 分配机制 | Logic | Complete | ADR-001 |
| 003 | 平衡与缩放 | Logic | Complete | ADR-001 |

## Overview

奖励分配系统采用"固定基础 + 随机浮动 + 动态修正"的混合机制，通过四大类奖励类型（物质资源、成长资源、装备物品、叙事状态）为玩家提供正向反馈循环。系统支持权重化随机池、层级掉落表和唯一性限制，确保奖励既有期待感又不会破坏游戏平衡。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-reward-dist-001 | 奖励类型与分类 | ADR-001 ✅ |
| TR-reward-dist-002 | 分配机制 | ADR-001 ✅ |
| TR-reward-dist-003 | 平衡与缩放 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/reward-distribution-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

All stories completed. Epic is ready for QA validation and integration testing.