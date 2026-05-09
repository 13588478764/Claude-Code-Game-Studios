# Story 001: 武学获取机制

> **Epic**: 武学系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/martial-arts-system.md`
**Requirement**: `TR-martial-arts-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，战斗系统实现

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的Resource系统管理武学数据，利用信号系统处理武学获取事件

**Control Manifest Rules (this layer)**:
- Required: 武学数据结构必须遵循统一格式
- Forbidden: 禁止硬编码武学数值，必须通过数据文件配置
- Guardrail: 武学获取逻辑不应影响战斗性能

---

## Acceptance Criteria

*From GDD `design/gdd/martial-arts-system.md`, scoped to this story:*

- [x] 玩家可以通过多种方式获取武学（残页合成、奇遇奖励、黑市购买等）
- [x] 武学残页系统正常工作，玩家可以收集同名残页
- [x] 残页合成机制正常工作（3张同名残页 + 1本空白秘籍 = 完整武学）
- [x] 合成后的武学正确添加到玩家武学图鉴中

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用JSON格式存储武学数据，便于扩展和修改
- 实现武学数据的CRUD操作接口
- 通过信号系统通知UI更新武学图鉴
- 残页和武学使用不同的数据结构，但共享基础属性

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 武学熟练度系统：由Story 002处理
- 武学装备和使用：由Story 003处理
- 武学组合系统：由Story 004处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 玩家可以通过多种方式获取武学
  - Given: 玩家进入游戏
  - When: 玩家完成奇遇事件或击败敌人
  - Then: 玩家获得武学残页或完整武学
  - Edge cases: 检查不同获取方式的概率和条件

- **AC-2**: 武学残页系统正常工作
  - Given: 玩家拥有某武学的部分残页
  - When: 玩家获得该武学的其他残页
  - Then: 残页数量正确累加
  - Edge cases: 检查残页数量上限和溢出处理

- **AC-3**: 残页合成机制正常工作
  - Given: 玩家拥有3张同名残页和1本空白秘籍
  - When: 玩家在合成界面执行合成操作
  - Then: 获得完整武学，残页和秘籍被消耗
  - Edge cases: 检查材料不足时的错误提示

- **AC-4**: 合成后的武学正确添加到玩家武学图鉴
  - Given: 玩家成功合成武学
  - When: 合成操作完成
  - Then: 武学出现在图鉴中，状态为"已获取"
  - Edge cases: 检查重复合成的处理

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/martial_arts/martial_arts_acquisition_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: None
- Unlocks: Story 002: 武学熟练度系统, Story 003: 武学装备和使用