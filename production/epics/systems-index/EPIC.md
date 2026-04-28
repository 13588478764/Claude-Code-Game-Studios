# Epic: 系统索引

> **Layer**: Foundation
> **GDD**: design/gdd/systems-index.md
> **Architecture Module**: Core
> **Status**: Ready
> **Stories**: 
> - [story-001-system-identification-and-classification.md](story-001-system-identification-and-classification.md)
> - [story-002-dependency-mapping.md](story-002-dependency-mapping.md)
> - [story-003-implementation-ordering.md](story-003-implementation-ordering.md)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 系统识别与分类 | Config/Data | Ready | ADR-001 |
| 002 | 依赖关系映射 | Config/Data | Ready | ADR-001 |
| 003 | 实现顺序规划 | Config/Data | Ready | ADR-001 |

## Overview

系统索引为整个武侠奇遇录项目提供了一个全面的系统概览，包括系统枚举、依赖关系图和推荐设计顺序。该文档为项目架构提供了顶层设计指导，确保所有系统设计都围绕核心理念展开，并明确了各系统间的依赖关系。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，数据持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-sys-index-001 | 系统识别与分类 | ADR-001 ✅ |
| TR-sys-index-002 | 依赖关系映射 | ADR-001 ✅ |
| TR-sys-index-003 | 实现顺序规划 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/systems-index.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/dev-story [story-path]` to begin implementation.