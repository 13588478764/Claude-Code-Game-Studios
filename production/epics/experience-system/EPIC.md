# Epic: 经验值系统

> **Layer**: Feature
> **GDD**: design/gdd/experience-system.md
> **Architecture Module**: Character
> **Status**: Complete
> **Stories**: 
> - [story-001-exp-acquisition-mechanisms.md](story-001-exp-acquisition-mechanisms.md)
> - [story-002-exp-calculation-and-distribution.md](story-002-exp-calculation-and-distribution.md)
> - [story-003-level-up-and-realm-breakthrough.md](story-003-level-up-and-realm-breakthrough.md)

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-exp-acquisition-mechanisms.md) | EXP获取机制 | Complete | Logic | Feature |
| [Story 002](story-002-exp-calculation-and-distribution.md) | EXP计算与分配 | Complete | Logic | Feature |
| [Story 003](story-003-level-up-and-realm-breakthrough.md) | 升级与境界突破 | Complete | Logic | Feature |

## Overview

经验值系统采用"多维获取 + 平滑指数曲线"的机制，通过战斗收益（击败敌人、完美胜利、连携奖励）、探索与奇遇（首次探索、完成奇遇、收集图鉴）和任务进度（主线、支线、日常任务）三大类来源为玩家提供稳定的成长反馈。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-exp-sys-001 | EXP获取机制 | ADR-001 ✅ |
| TR-exp-sys-002 | EXP计算与分配 | ADR-001 ✅ |
| TR-exp-sys-003 | 升级与境界突破 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/experience-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

所有故事已完成实现。