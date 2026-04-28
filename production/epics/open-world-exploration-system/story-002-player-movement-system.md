# Story 002: 玩家移动系统

> **Epic**: 开放世界探索系统
> **Status**: Pending Test
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/open-world-exploration-system.md`
**Requirement**: `TR-open-world-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，世界流式加载

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的CharacterBody2D实现玩家移动系统

**Control Manifest Rules (this layer)**:
- Required: 玩家移动必须平滑流畅，响应迅速
- Forbidden: 禁止移动过程中出现卡顿或穿模
- Guardrail: 移动系统不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/open-world-exploration-system.md`, scoped to this story:*

- [x] 实现玩家基础移动（行走、奔跑、跳跃）
- [x] 实现垂直探索机制（轻功攀爬、滑翔）
- [x] 实现移动限制（体力/内力消耗）
- [x] 实现移动相关的探索奖励触发

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用Godot的CharacterBody2D实现玩家物理移动
- 实现轻功系统，包括攀爬和滑翔机制
- 实现体力/内力消耗机制
- 与探索系统集成，触发移动相关的探索奖励

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 无缝世界探索：由Story 001处理
- 探索反馈机制：由Story 003处理
- 战斗移动：由战斗系统处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现玩家基础移动
  - Given: 玩家在世界中
  - When: 玩家输入移动指令
  - Then: 玩家角色平滑移动
  - Edge cases: 检查斜向移动和边界碰撞

- **AC-2**: 实现垂直探索机制
  - Given: 玩家靠近可攀爬表面
  - When: 玩家使用轻功
  - Then: 玩家可以攀爬或滑翔
  - Edge cases: 检查体力不足时的限制

- **AC-3**: 实现移动限制
  - Given: 玩家移动中
  - When: 体力/内力消耗
  - Then: 移动能力受限制
  - Edge cases: 检查资源耗尽时的行为

- **AC-4**: 实现移动相关的探索奖励触发
  - Given: 玩家移动到特定位置
  - When: 满足触发条件
  - Then: 触发探索奖励
  - Edge cases: 检查重复触发的防止

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/open_world/player_movement_system_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001: 无缝世界探索
- Unlocks: Story 003: 探索反馈机制