# Story 004: 武学组合系统

> **Epic**: 武学系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/martial-arts-system.md`
**Requirement**: `TR-martial-arts-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，战斗系统实现

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理武学组合事件，通过状态机管理连击状态

**Control Manifest Rules (this layer)**:
- Required: 武学组合必须与战斗系统正确集成
- Forbidden: 禁止绕过组合规则直接激活组合效果
- Guardrail: 武学组合计算不应超过性能预算（<1ms处理时间）

---

## Acceptance Criteria

*From GDD `design/gdd/martial-arts-system.md`, scoped to this story:*

- [ ] 流派羁绊系统正常工作，同流派或跨流派武学提供加成效果
- [ ] 心法回路系统正常工作，装备的心法产生相应效果
- [ ] 武学连击系统正常工作，连续使用武学可获得连击加成
- [ ] 武器适配与流派羁绊正确叠加，共同影响武学效果

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现流派羁绊效果计算函数，检测同流派武学数量并应用加成
- 实现心法回路效果系统，处理3个心法槽位的组合效果
- 实现连击状态管理，跟踪连续攻击次数并应用连击系数
- 通过信号系统通知战斗系统组合效果变更

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 武学获取机制：由Story 001处理
- 武学熟练度系统：由Story 002处理
- 武学装备和使用：由Story 003处理
- 境界突破系统：由Story 005处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 流派羁绊系统正常工作
  - Given: 玩家装备多个同流派武学
  - When: 在战斗中使用这些武学
  - Then: 激活相应的流派羁绊效果（2件套、3件套、4件套）
  - Edge cases: 检查跨流派组合效果（如少林+武当）

- **AC-2**: 心法回路系统正常工作
  - Given: 玩家装备3个心法到不同槽位
  - When: 在战斗中使用武学
  - Then: 激活心法回路效应（五行相生、阴阳调和等）
  - Edge cases: 检查心法冲突时的优先级处理

- **AC-3**: 武学连击系统正常工作
  - Given: 玩家在战斗中连续使用武学
  - When: 连击状态持续
  - Then: 连击系数逐步提升，最高达到1.3倍
  - Edge cases: 检查连击中断后的重置机制

- **AC-4**: 武器适配与流派羁绊正确叠加
  - Given: 玩家装备适配武器和同流派武学
  - When: 使用武学进行攻击
  - Then: 武器适配系数和流派羁绊系数正确叠加
  - Edge cases: 检查系数叠加的上限和合理性

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/martial_arts/martial_arts_combo_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001: 武学获取机制, Story 002: 武学熟练度系统, Story 003: 武学装备和使用
- Unlocks: None