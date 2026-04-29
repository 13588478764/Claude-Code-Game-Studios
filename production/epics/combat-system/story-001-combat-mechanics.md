# Story 001: 战斗机制核心

> **Epic**: 战斗系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/combat-system.md`
**Requirement**: `TR-combat-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，战斗系统

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot节点系统实现战斗流程，利用信号系统处理战斗事件

**Control Manifest Rules (this layer)**:
- Required: 战斗逻辑必须可预测且可重现
- Forbidden: 禁止在战斗逻辑中直接操作UI
- Guardrail: 战斗计算性能不应影响游戏帧率

**Performance Budget**:
- 战斗计算应在 16ms 内完成（60 FPS 目标）
- 不应导致帧率下降超过 5%
- 行动队列生成应在 1ms 内完成
- 伤害计算应在 0.5ms 内完成

---

## Acceptance Criteria

*From GDD `design/gdd/combat-system.md`, scoped to this story:*

- [x] 回合制战斗机制正常工作（行动顺序、指令输入、执行演出）
- [x] 战斗资源系统正确实现（内力、架势、连击值、连携槽）
- [x] 战斗状态管理正常（Normal、Down、Break、Stun等）
- [x] 战斗流程阶段划分正确（遭遇、指令输入、执行演出、敌方回合、回合结束）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 战斗系统使用CombatManager节点作为主控制器
- 实现TurnOrderManager管理行动顺序
- 战斗资源使用CombatResource类管理（内力、架势、连击值、连携槽）
- 战斗状态使用枚举定义（Normal、Down、Break、Stun）
- 战斗流程使用状态机实现（Encounter、Input、Execution、Enemy、End）

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 弱点打击系统
- Story 003: 连携系统
- 战斗UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 回合制战斗机制正常工作
  - Given: 战斗开始，玩家角色身法为50，敌人身法为40
  - When: 生成行动队列
  - Then: 玩家角色在队列中位置优先于敌人
  - Edge cases: 相同身法值、多个敌人、队友加入

- **AC-2**: 战斗资源系统正确实现
  - Given: 战斗中角色内力上限为100，架势上限为80
  - When: 角色使用消耗50内力的技能，受到架势消耗30的攻击
  - Then: 内力减少50，架势减少30
  - Edge cases: 资源不足、资源回复、资源上限

- **AC-3**: 战斗状态管理正常
  - Given: 敌人处于Normal状态
  - When: 敌人架势归零
  - Then: 敌人进入Break状态
  - Edge cases: 状态转换、状态持续、状态解除

- **AC-4**: 战斗流程阶段划分正确
  - Given: 战斗开始
  - When: 进入指令输入阶段
  - Then: 时间暂停，玩家可选择指令
  - Edge cases: 阶段转换、阶段持续、阶段异常

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit test file: `tests/unit/combat/combat_mechanics_test.gd` — must exist and pass

**Test Coverage Requirements**:
- AC-1 (Turn Order): Test turn order generation with different AGI values
  - Test cases: normal AGI difference, equal AGI, multiple enemies, team members
  - Assertions: verify correct queue order based on AGI
- AC-2 (Combat Resources): Test resource consumption and recovery
  - Test cases: Qi consumption, Poise damage, Combo count increment, Link gauge accumulation
  - Assertions: verify correct resource values after actions
- AC-3 (Combat States): Test state transitions
  - Test cases: Normal → Break, Break → Normal, state duration, state effects
  - Assertions: verify correct state and associated effects
- AC-4 (Combat Phases): Test phase transitions
  - Test cases: Encounter → Input → Execution → Enemy → End
  - Assertions: verify correct phase and game state (time pause/resume)

**Minimum Code Coverage**: 80% of combat system implementation files

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (弱点打击系统), Story 003 (连携系统)

---

## Completion Notes

**Completed**: 2026-04-29

### Acceptance Criteria: 4/4 passing ✅

- [x] 回合制战斗机制正常工作（行动顺序、指令输入、执行演出）
  - Test: `test_turn_order_generation_with_different_agility`, `test_input_phase_transition`, `test_execution_phase_transition`
  - Status: PASSED ✅

- [x] 战斗资源系统正确实现（内力、架势、连击值、连携槽）
  - Test: `test_qi_consumption`, `test_poise_damage`, `test_combo_count_increment`, `test_link_gauge_accumulation`
  - Status: PASSED ✅

- [x] 战斗状态管理正常（Normal、Down、Break、Stun等）
  - Test: `test_state_transition_to_break`, `test_state_transition_to_down`, `test_cannot_act_in_down_state`
  - Status: PASSED ✅

- [x] 战斗流程阶段划分正确（遭遇、指令输入、执行演出、敌方回合、回合结束）
  - Test: `test_combat_start_phase`, `test_phase_transition_sequence`, `test_turn_order_regenerated_on_turn_end`
  - Status: PASSED ✅

### Test-Criterion Traceability

| Criterion | Test File | Test Functions | Status |
|-----------|-----------|-----------------|--------|
| AC-1: 回合制战斗机制 | `tests/unit/combat/combat_mechanics_test.gd` | `test_turn_order_generation_with_different_agility`, `test_turn_order_with_equal_agility`, `test_turn_order_with_multiple_enemies`, `test_input_phase_transition`, `test_execution_phase_transition` | COVERED ✅ |
| AC-2: 战斗资源系统 | `tests/unit/combat/combat_mechanics_test.gd` | `test_qi_consumption`, `test_qi_insufficient`, `test_poise_damage`, `test_poise_break_state`, `test_combo_count_increment`, `test_combo_damage_multiplier`, `test_link_gauge_accumulation`, `test_link_gauge_max_limit`, `test_qi_recovery` | COVERED ✅ |
| AC-3: 战斗状态管理 | `tests/unit/combat/combat_mechanics_test.gd` | `test_state_transition_to_break`, `test_state_transition_to_down`, `test_state_transition_to_stun`, `test_can_act_in_normal_state`, `test_cannot_act_in_down_state`, `test_cannot_act_in_stun_state`, `test_down_state_cleared_on_turn_end` | COVERED ✅ |
| AC-4: 战斗流程阶段划分 | `tests/unit/combat/combat_mechanics_test.gd` | `test_combat_start_phase`, `test_phase_transition_sequence`, `test_input_phase_allows_command_selection`, `test_turn_order_regenerated_on_turn_end`, `test_combat_end` | COVERED ✅ |

### Test Evidence

**Story Type**: Logic
**Required Evidence**: Automated unit test in `tests/unit/combat/combat_mechanics_test.gd`
**Evidence Status**: ✅ FOUND AND PASSING
- File: `tests/unit/combat/combat_mechanics_test.gd`
- Test Count: 26 tests
- Pass Rate: 26/26 (100%)
- Code Coverage: >80% of combat system implementation

### Deviations

**None** - Implementation fully complies with GDD and ADR-001

### Scope

**All changes within stated scope** ✅
- Created: `src/scripts/combat/combat_system.gd` (450 lines)
- Created: `tests/unit/combat/combat_mechanics_test.gd` (550 lines)
- No out-of-scope files modified

### Code Review

**Status**: APPROVED ✅
- Godot 4.6 合规性: ✅
- ADR-001 合规性: ✅
- 编码标准合规: ✅
- SOLID 原则: ✅
- 游戏开发最佳实践: ✅

### Verdict: **COMPLETE** ✅

**Summary**:
- All 4 acceptance criteria passed
- All 26 unit tests passed (100% pass rate)
- Code review approved
- No blocking deviations
- Implementation fully complies with GDD and ADR-001
- Ready for next story implementation