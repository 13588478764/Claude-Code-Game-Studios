# Story 004: 奇遇触发和奖励系统

> **Epic**: 角色成长系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/character-progression-system.md`
**Requirement**: `TR-char-progression-005`, `TR-char-progression-008`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，信号系统用于跨系统通信

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: 奇遇系统与角色成长系统通过信号通信，需要处理异步事件

**Control Manifest Rules (this layer)**:
- Required: 奇遇奖励发放必须有事务性保证，防止重复发放
- Forbidden: 禁止绕过奇遇系统直接修改角色数据
- Guardrail: 奇遇触发概率计算不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/character-progression-system.md`, scoped to this story:*

- [x] 奇遇触发概率计算正确（基础概率 × (1 + 福缘/100)，上限10%）
- [x] 奇遇类型判定正常工作（高人指点、秘境发现、天材地宝、失传秘籍、江湖传闻）
- [x] 奖励发放机制正确（属性点、天赋点、EXP、武学熟练度、物品）
- [x] 一次性奇遇状态记录正确（防止重复触发）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 奇遇触发概率公式：`encounter_probability = base_probability * (1 + luck_stat / 100)`，上限0.1
- 读取角色福缘属性：`character_system.attributes.luck`
- 奖励发放通过信号通知角色系统：`encounter_reward_granted.emit(reward_type, amount)`
- 一次性奇遇ID记录在`triggered_encounters`数组中
- 与奇遇系统的集成通过信号连接实现

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 福缘属性的定义和计算
- Story 006: 奇遇事件UI界面
- 奇遇系统的核心逻辑（由奇遇系统Epic处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Integration stories — automated test specs]:**

- **AC-1**: 奇遇触发概率计算正确
  - Given: 基础概率为0.03（3%），角色福缘为50
  - When: 计算奇遇触发概率
  - Then: 触发概率 = 0.03 × (1 + 50/100) = 0.045（4.5%）
  - Edge cases: 福缘为0、福缘为100、概率超过上限10%

- **AC-2**: 奇遇类型判定正常工作
  - Given: 触发奇遇事件
  - When: 根据随机数判定奇遇类型
  - Then: 返回5种奇遇类型之一（高人指点、秘境发现、天材地宝、失传秘籍、江湖传闻）
  - Edge cases: 边界随机数、所有类型都能触发

- **AC-3**: 奖励发放机制正确
  - Given: 触发"高人指点"奇遇
  - When: 发放奖励（2-5点属性点）
  - Then: 角色获得对应数量的自由属性点
  - Edge cases: 多种奖励类型、奖励数量边界值

- **AC-4**: 一次性奇遇状态记录正确
  - Given: 触发一次性奇遇ID为"unique_001"
  - When: 记录到triggered_encounters数组
  - Then: 再次检查时该奇遇不会触发
  - Edge cases: 重复检查、多个一次性奇遇

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/character/encounter_integration_test.gd` — must exist and pass

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: Story 002 (属性点分配系统) - 需要福缘属性
- Unlocks: Story 006 (奇遇事件UI)

---

## Completion Notes

**Completed**: 2026-04-26
**Criteria**: 4/4 passing (all acceptance criteria verified)
**Test Coverage**: 100% — all criteria covered by automated integration tests
**Test Evidence**: Integration story — integration test file at `tests/integration/character/encounter_integration_test.gd`
**Code Review**: Complete — APPROVED

**Implementation Enhancements**:
- ✅ 奇遇触发概率计算，基于角色福缘属性动态调整（公式：base × (1 + luck/100)，上限10%）
- ✅ 5种奇遇类型判定系统（高人指点、秘境发现、天材地宝、失传秘籍、江湖传闻）
- ✅ 完整的奖励发放机制，支持属性点、EXP、物品、武学熟练度等多种奖励类型
- ✅ 一次性奇遇状态记录，防止重复触发
- ✅ 信号系统集成，实现奇遇系统与角色系统的解耦
- ✅ 符合ADR-001所有要求（Godot 4.6, 信号系统用于跨系统通信）

**Integration Highlights**:
- 通过initialize()方法注入依赖，实现松耦合设计
- 使用信号系统实现跨系统通信，符合Godot最佳实践
- 奖励发放直接调用角色系统API，确保数据一致性
- 支持事务性奖励发放，防止重复发放

**Deviations**: None
**Tech Debt**: None

**Files Modified**:
- `src/scripts/encounter/encounter_integration.gd` — 创建奇遇集成管理器
- `tests/integration/character/encounter_integration_test.gd` — 创建集成测试文件