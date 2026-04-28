# Story 002: 触发机制与事件

> **Epic**: 奇遇条件检查系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/encounter-condition-check-system.md`
**Requirement**: `TR-enc-cond-check-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的Area2D触发器和信号系统实现事件驱动机制

**Control Manifest Rules (this layer)**:
- Required: 触发机制必须使用区域触发器而非实时轮询
- Forbidden: 禁止每帧检查所有奇遇条件
- Guardrail: 触发机制不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/encounter-condition-check-system.md`, scoped to this story:*

- [x] 区域触发器正确实现（Area2D触发器）
- [x] 关键事件钩子正常工作（休息、战斗胜利、天气变化）
- [x] 触发时机准确（玩家进入区域时激活）
- [x] 事件监听机制正常（全局事件信号）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用TriggerMechanismManager节点管理触发机制
- 实现register_zone_triggers(encounter_zones)方法注册区域触发器
- 实现on_player_entered_zone(zone_id)方法处理区域进入事件
- 实现register_event_hooks()方法注册全局事件监听
- 实现handle_global_events(event_data)方法处理关键事件
- 实现trigger_activated信号通知其他系统
- 与EncounterSystem、OpenWorldExplorationSystem和BattleSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 条件类型与评估（处理条件评估逻辑）
- Story 003: 逻辑树与权重（处理嵌套逻辑和权重分配）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 区域触发器正确实现
  - Given: 玩家角色进入预设的奇遇区域
  - When: 触发器被激活
  - Then: 立即执行一次条件检查
  - Edge cases: 多个触发器重叠、快速进出区域、触发器大小边界

- **AC-2**: 关键事件钩子正常工作
  - Given: 玩家开始休息时
  - When: on_rest_started事件触发
  - Then: 检查是否有"梦中奇遇"或"夜间遭遇"奇遇
  - Edge cases: 战斗胜利、天气变化、其他全局事件

- **AC-3**: 触发时机准确
  - Given: 玩家接近潜在奇遇点
  - When: 进入区域触发器范围
  - Then: 在进入瞬间激活条件检查逻辑
  - Edge cases: 移动速度、帧率变化、瞬移技能

- **AC-4**: 事件监听机制正常
  - Given: 全局关键事件发生
  - When: 事件信号发出
  - Then: 监听器正确捕获并处理事件
  - Edge cases: 事件频率过高、事件丢失、多线程安全

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/encounter/trigger_mechanisms_and_events_test.gd` — must exist and pass

**Status**: [x] Completed

---

## Dependencies

- Depends on: Story 001 (条件类型与评估)
- Unlocks: Story 003 (逻辑树与权重)