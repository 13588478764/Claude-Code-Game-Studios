# Story 003: 武学装备和使用

> **Epic**: 武学系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/martial-arts-system.md`
**Requirement**: `TR-martial-arts-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，战斗系统实现

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理武学使用事件，通过场景切换和动画系统展示武学效果

**Control Manifest Rules (this layer)**:
- Required: 武学使用必须与战斗系统正确集成
- Forbidden: 禁止在战斗外使用未装备的武学
- Guardrail: 武学使用不应超过性能预算（<2ms处理时间）

---

## Acceptance Criteria

*From GDD `design/gdd/martial-arts-system.md`, scoped to this story:*

- [ ] 玩家可以在配招界面装备武学到技能槽
- [ ] 武学在战斗中可以正常使用，消耗相应内力
- [ ] 武学伤害计算遵循GDD中的公式
- [ ] 武器适配系统正常工作，影响武学伤害

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 武学装备数据存储在角色数据结构中
- 通过信号系统通知战斗系统武学使用请求
- 实现武学伤害计算函数，遵循GDD中的复杂公式
- 集成武学与战斗系统的交互接口

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 武学获取机制：由Story 001处理
- 武学熟练度系统：由Story 002处理
- 武学组合系统：由Story 004处理
- 境界突破系统：由Story 005处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 玩家可以在配招界面装备武学到技能槽
  - Given: 玩家拥有已获取的武学
  - When: 玩家在配招界面拖拽武学到技能槽
  - Then: 武学成功装备到对应槽位
  - Edge cases: 检查装备数量限制和武器适配提示

- **AC-2**: 武学在战斗中可以正常使用
  - Given: 玩家在战斗中，武学已装备到技能槽
  - When: 玩家选择并使用武学
  - Then: 武学成功释放，消耗相应内力
  - Edge cases: 检查内力不足时的错误处理

- **AC-3**: 武学伤害计算遵循GDD中的公式
  - Given: 玩家使用武学攻击敌人
  - When: 武学命中目标
  - Then: 伤害值按GDD公式计算（基础伤害×暴击系数×连击系数等）
  - Edge cases: 检查各种系数组合下的伤害计算

- **AC-4**: 武器适配系统正常工作
  - Given: 玩家装备特定武器和武学
  - When: 使用武学进行攻击
  - Then: 根据武器与武学匹配度应用相应系数（完美适配1.2倍，勉强适配0.7倍）
  - Edge cases: 检查完全不适配时的禁用状态

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/martial_arts/martial_arts_usage_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001: 武学获取机制, Story 002: 武学熟练度系统
- Unlocks: Story 004: 武学组合系统