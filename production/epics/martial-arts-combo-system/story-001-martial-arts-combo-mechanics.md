# Story 001: 武功组合机制

> **Epic**: 武学组合/连招系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/martial-arts-combo-system.md`
**Requirement**: `TR-martial-arts-combo-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，战斗系统实现

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理连招事件，通过数据结构管理技能标签和协同效果

**Control Manifest Rules (this layer)**:
- Required: 武功组合必须与武学系统和战斗系统正确集成
- Forbidden: 禁止绕过标签协同规则直接触发连招效果
- Guardrail: 连招计算不应超过性能预算（<2ms处理时间）

---

## Acceptance Criteria

*From GDD `design/gdd/martial-arts-combo-system.md`, scoped to this story:*

- [ ] 标签协同机制正常工作，支持[破防]+[刚]、[湿]+[雷]、[浮空]+[坠击]等组合
- [ ] 系统正确识别技能标签并匹配协同效果
- [ ] 协同效果遵循公式：`协同伤害 = 基础伤害 × 协同倍率`
- [ ] 条件连招正常工作，基于敌人状态或环境触发额外效果

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 实现标签匹配算法，检测技能间的协同关系
- 通过信号系统通知战斗系统连招效果
- 实现协同伤害计算函数，遵循GDD中的公式
- 集成武学系统与连招系统的标签数据接口

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 连招系统：由Story 002处理
- 连招效果计算：由Story 003处理
- 连招UI界面：由UI故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 标签协同机制正常工作
  - Given: 玩家使用带有[破防]标签的技能攻击敌人
  - When: 敌人处于"架势破碎"状态，接着使用[刚]标签技能
  - Then: 触发"粉碎打击"协同效果，造成200%基础伤害
  - Edge cases: 检查不同标签组合的协同效果

- **AC-2**: 系统正确识别技能标签并匹配协同效果
  - Given: 玩家装备带有特定标签的武学
  - When: 释放技能时检查标签匹配
  - Then: 系统正确识别并准备协同效果
  - Edge cases: 检查标签缺失或不匹配的情况

- **AC-3**: 协同效果遵循公式
  - Given: 基础伤害为100，协同倍率为2.0
  - When: 触发协同连招
  - Then: 协同伤害为200（100×2.0）
  - Edge cases: 检查不同基础伤害和倍率的组合

- **AC-4**: 条件连招正常工作
  - Given: 敌人处于湿润状态
  - When: 玩家对湿润敌人使用雷系技能
  - Then: 触发"感电爆发"协同效果，造成范围麻痹
  - Edge cases: 检查不同敌人状态和环境条件

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/martial_arts_combo/martial_arts_combo_mechanics_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 武学系统相关故事
- Unlocks: Story 002: 连招系统, Story 003: 连招效果计算