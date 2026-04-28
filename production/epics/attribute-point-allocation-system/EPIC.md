# Epic: 属性点分配系统

> **Layer**: Feature
> **GDD**: design/gdd/attribute-point-allocation-system.md
> **Architecture Module**: Character
> **Status**: Complete
> **Stories**: 
> - [story-001-attribute-point-mechanics.md](story-001-attribute-point-mechanics.md)
> - [story-002-attribute-point-assignment.md](story-002-attribute-point-assignment.md)
> - [story-003-attribute-point-verification.md](story-003-attribute-point-verification.md)

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-attribute-point-mechanics.md) | 属性点机制 | Complete | Logic | Feature |
| [Story 002](story-002-attribute-point-assignment.md) | 属性点分配 | Complete | Logic | Feature |
| [Story 003](story-003-attribute-point-verification.md) | 属性点验证 | Complete | Logic | Feature |

## Overview

属性点分配系统允许玩家在角色升级时获得属性点，并将其分配到不同的属性上，如力量、敏捷、智力等。该系统为玩家提供了自定义角色能力的机会，使角色发展更具个性化。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-attr-point-alloc-001 | 属性点获取机制 | ADR-001 ✅ |
| TR-attr-point-alloc-002 | 属性点分配界面 | ADR-001 ✅ |
| TR-attr-point-alloc-003 | 属性点验证规则 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/attribute-point-allocation-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/dev-story [story-path]` to begin implementation.