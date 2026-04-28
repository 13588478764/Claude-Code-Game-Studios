# Story 002: 任务追踪系统

> **Epic**: 任务系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/quest-system.md`
**Requirement**: `TR-quest-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，UI系统实现

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理任务追踪事件，通过UI节点管理任务追踪显示

**Control Manifest Rules (this layer)**:
- Required: 任务追踪系统必须与地图系统和UI系统正确集成
- Forbidden: 禁止绕过追踪系统直接修改追踪状态
- Guardrail: 任务追踪更新不应超过性能预算（<2ms处理时间）

---

## Acceptance Criteria

*From GDD `design/gdd/quest-system.md`, scoped to this story:*

- [x] 任务追踪系统在小地图上正确显示任务目标位置
- [x] 任务追踪系统在UI上正确显示当前激活任务的目标和进度
- [x] 任务追踪系统支持不同类型的任务目标（对话、击杀、收集、到达位置）
- [x] 任务追踪系统正确更新目标进度（如击杀敌人数量、收集物品数量）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现任务追踪的UI组件，显示任务目标和进度
- 通过信号系统接收任务目标更新事件
- 实现小地图标记系统，显示任务目标位置
- 集成任务追踪与战斗系统和物品系统的接口

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 任务状态管理：由Story 001处理
- 任务奖励发放：由Story 003处理
- 任务UI界面：由UI故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 任务追踪系统在小地图上正确显示任务目标位置
  - Given: 玩家接取一个需要到达特定位置的任务
  - When: 任务状态变为ACTIVE
  - Then: 小地图上显示任务目标位置标记
  - Edge cases: 检查不同任务类型的标记显示

- **AC-2**: 任务追踪系统在UI上正确显示当前激活任务的目标和进度
  - Given: 玩家有激活的任务
  - When: 查看任务追踪UI
  - Then: 显示任务目标和当前进度
  - Edge cases: 检查多个激活任务的显示

- **AC-3**: 任务追踪系统支持不同类型的任务目标
  - Given: 玩家有不同类型目标的任务
  - When: 任务进行中
  - Then: 系统正确追踪TalkToNPC、KillEnemy、CollectItem、GoToLocation等目标
  - Edge cases: 检查每种目标类型的追踪准确性

- **AC-4**: 任务追踪系统正确更新目标进度
  - Given: 玩家进行任务相关活动
  - When: 完成部分任务目标（如击杀1/5个敌人）
  - Then: 进度正确更新并显示
  - Edge cases: 检查进度边界值和完成状态

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/quest/quest_tracking_system_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001: 任务状态管理
- Unlocks: None