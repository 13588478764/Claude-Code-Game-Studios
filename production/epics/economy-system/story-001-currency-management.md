# Story 001: 货币管理系统

> **Epic**: 经济系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/economy-system.md`
**Requirement**: `TR-economy-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理货币变动事件，利用内置数据结构管理货币状态

**Control Manifest Rules (this layer)**:
- Required: 货币管理必须有验证机制，防止负数或超限值
- Forbidden: 禁止直接修改货币值绕过管理系统
- Guardrail: 货币计算不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/economy-system.md`, scoped to this story:*

- [x] 银两系统正常工作（获取、消耗、显示、存储）
- [x] 核心资源管理正确（材料获取、消耗、存储）
- [x] 货币验证机制正常（防止负数、超限值）
- [x] 货币变动事件处理正确（战斗掉落、任务奖励、奇遇奖励）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用CurrencyManager节点管理所有货币和资源
- 实现add_currency(currency_type, amount)方法增加货币
- 实现spend_currency(currency_type, amount)方法消耗货币，返回bool表示成功/失败
- 实现has_enough_currency(currency_type, amount)方法检查货币是否足够
- 实现currency_changed信号通知UI更新
- 实现save/load方法确保货币数据持久化

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 交易系统（商店购买、物品出售）
- Story 003: 价格平衡机制
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 银两系统正常工作
  - Given: 玩家当前持有1000银两
  - When: 获得战斗掉落500银两
  - Then: 玩家银两总数变为1500
  - Edge cases: 零值添加、负值添加、超限值添加

- **AC-2**: 核心资源管理正确
  - Given: 玩家背包中无初级强化石
  - When: 战斗掉落1个初级强化石
  - Then: 玩家背包中初级强化石数量为1
  - Edge cases: 资源堆叠上限、负值添加、资源类型不存在

- **AC-3**: 货币验证机制正常
  - Given: 玩家当前持有500银两
  - When: 尝试消耗800银两
  - Then: 操作失败，银两数量保持500
  - Edge cases: 恰好等于余额、零值消耗、负值消耗

- **AC-4**: 货币变动事件处理正确
  - Given: 玩家福缘为50
  - When: 战斗掉落基础100银两
  - Then: 实际获得150银两（100×(1+50/100)）
  - Edge cases: 福缘为0、福缘为100、福缘修正后超限

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/economy/currency_management_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (交易系统), Story 003 (价格平衡机制)