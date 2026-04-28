# Epic: 武学组合/连招系统

> **Layer**: Feature
> **GDD**: design/gdd/martial-arts-combo-system.md
> **Architecture Module**: Combat
> **Status**: Complete
> **Stories**: 
> - [story-001-martial-arts-combo-mechanics.md](story-001-martial-arts-combo-mechanics.md)
> - [story-002-combo-system.md](story-002-combo-system.md)
> - [story-003-combo-effect-calculation.md](story-003-combo-effect-calculation.md)

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| [Story 001](story-001-martial-arts-combo-mechanics.md) | 武功组合机制 | Complete | Logic | Feature |
| [Story 002](story-002-combo-system.md) | 连招系统 | Complete | Integration | Feature |
| [Story 003](story-003-combo-effect-calculation.md) | 连招效果计算 | Complete | Logic | Feature |

## Overview

武学组合/连招系统采用"标签协同 + 状态连锁"的策略性连招机制，摒弃动作游戏中复杂的"按键序列"输入，转而强调战前规划与战中决策。系统利用2D俯视角和回合制战斗的优势，通过菜单指令链实现流畅的技能组合体验。

玩家通过标签协同（如[破防]+[刚]、[湿]+[雷]、[浮空]+[坠击]）和状态连锁触发强大的协同效果，在战术暂停模式下无时间压力地构建连招策略。系统提供数值增强、状态施加/转化、资源反馈和丰富的视听表现，让玩家体验到武侠"招式变化"和"见招拆招"的精髓。

如果没有这个系统，游戏将失去战斗深度与流派特色，每个技能都成为独立的孤岛，玩家只会选择单体伤害最高的技能，其他辅助或控制技能沦为摆设。战斗变成简单的"选最高伤害技能 -> 结束"，缺乏"铺垫 -> 爆发"的节奏感，武侠感薄弱如同两个机器人互相扔数字。该系统是实现"深度武学系统"游戏支柱的重要支撑，利用Steam平台的PC硬件优势提供高精度视觉表现、即时反馈与缓存、复杂数据计算和音频沉浸感。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: 核心架构决策 | Godot 4.6引擎选择，战斗系统 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-martial-arts-combo-001 | 武功组合机制 | ADR-001 ✅ |
| TR-martial-arts-combo-002 | 连招系统 | ADR-001 ✅ |
| TR-martial-arts-combo-003 | 连招效果计算 | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/martial-arts-combo-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

所有故事已完成实现。