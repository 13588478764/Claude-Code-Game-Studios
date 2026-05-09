# Story 001: 奇遇触发系统

> **Epic**: 奇遇系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/encounter-system.md`
**Requirement**: `TR-encounter-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，事件系统

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理奇遇触发事件，利用内置随机数生成器实现概率判定

**Control Manifest Rules (this layer)**:
- Required: 奇遇触发必须基于福缘属性，确保可预测性
- Forbidden: 禁止硬编码触发概率，必须使用配置或公式
- Guardrail: 概率计算不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/encounter-system.md`, scoped to this story:*

- [x] 奇遇触发时机正常（地图移动、战斗胜利、休息存档）
- [x] 福缘影响概率计算正确（概率修正公式）
- [x] 权重重分配机制正常（福缘影响奇遇类型）
- [x] 保底机制正常（连续未触发后强制触发）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用EncounterTriggerManager节点管理所有触发逻辑
- 实现trigger_encounter_check(trigger_type)方法检查是否触发奇遇
- 实现calculate_trigger_probability(base_chance, luck_stat)方法计算触发概率
- 实现adjust_weights_by_luck(base_weights, luck_stat)方法根据福缘调整权重
- 实现enforce_guarantee_mechanism()方法实现保底机制
- 实现encounter_triggered信号通知UI显示奇遇事件
- 与CharacterStats系统集成获取福缘属性

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 奇遇奖励系统（处理奇遇奖励发放）
- Story 003: 奇遇记录管理（处理奇遇状态记录）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 奇遇触发时机正常
  - Given: 玩家在大地图移动
  - When: 触发时机到达（基础概率5%）
  - Then: 系统进行触发判定
  - Edge cases: 战斗胜利后、休息存档、特定地点触发

- **AC-2**: 福缘影响概率计算正确
  - Given: 玩家福缘属性为50，基础触发概率为5%
  - When: 计算最终触发概率
  - Then: 最终概率为7.5%（5%×(1+50/100)）
  - Edge cases: 福缘为0、福缘为100、概率上限20%

- **AC-3**: 权重重分配机制正常
  - Given: 玩家福缘为100，基础权重为秘境挑战5、江湖传闻40
  - When: 计算调整后权重
  - Then: 秘境挑战权重升至15，江湖传闻权重降至13
  - Edge cases: 福缘为0、极高福缘、权重下限

- **AC-4**: 保底机制正常
  - Given: 玩家连续20次未触发奇遇
  - When: 进行第21次触发判定
  - Then: 系统强制触发奇遇并重置计数器
  - Edge cases: 第19次、第20次、第21次触发

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/encounter/encounter_trigger_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (奇遇奖励系统), Story 003 (奇遇记录管理)