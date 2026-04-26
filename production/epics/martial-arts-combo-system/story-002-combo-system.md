# Story 002: 连招系统

> **Epic**: 武学组合/连招系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/martial-arts-combo-system.md`
**Requirement**: `TR-martial-arts-combo-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，战斗系统实现

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理连招事件，通过状态机管理连招状态

**Control Manifest Rules (this layer)**:
- Required: 连招系统必须与战斗系统和UI系统正确集成
- Forbidden: 禁止绕过连招状态机直接执行连招
- Guardrail: 连招系统不应超过性能预算（<3ms处理时间）

---

## Acceptance Criteria

*From GDD `design/gdd/martial-arts-combo-system.md`, scoped to this story:*

- [ ] 连招系统支持菜单指令链，玩家可以在战术暂停模式下规划连招
- [ ] 连携指令系统正常工作，支持主角行动结束后的队友追加攻击
- [ ] 连招状态机正常工作（准备→协同→完成→中断）
- [ ] 连招系统正确管理连携槽，支持资源积累和消耗

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现连招状态机，管理连招的不同阶段
- 通过信号系统通知战斗系统连招执行
- 实现连携槽管理系统，跟踪连招资源
- 集成连招系统与战斗系统和UI系统的接口

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 武功组合机制：由Story 001处理
- 连招效果计算：由Story 003处理
- 连招UI界面：由UI故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 连招系统支持菜单指令链
  - Given: 玩家在战斗中
  - When: 进入战术暂停模式规划连招
  - Then: 可以在无时间压力下选择多个技能组成连招
  - Edge cases: 检查连招长度限制和技能选择有效性

- **AC-2**: 连携指令系统正常工作
  - Given: 主角行动结束，连携槽足够
  - When: 点击"连携"按钮
  - Then: 时间暂停，弹出队友技能选择面板
  - Edge cases: 检查连携槽不足时的处理

- **AC-3**: 连招状态机正常工作
  - Given: 玩家开始构建连招
  - When: 连招经历不同阶段
  - Then: 状态正确转换（准备→协同→完成→中断）
  - Edge cases: 检查状态转换的边界条件

- **AC-4**: 连招系统正确管理连携槽
  - Given: 玩家执行连招
  - When: 连招成功或失败
  - Then: 连携槽正确增加或保持
  - Edge cases: 检查连携槽溢出和最小值限制

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/martial_arts_combo/combo_system_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001: 武功组合机制
- Unlocks: Story 003: 连招效果计算