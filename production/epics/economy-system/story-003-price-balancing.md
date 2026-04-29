# Story 003: 价格平衡机制

> **Epic**: 经济系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26
> **Test Status**: All 4 unit tests PASSED ✓

## Context

**GDD**: `design/gdd/economy-system.md`
**Requirement**: `TR-economy-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 价格平衡机制使用配置文件管理，支持运行时调整

**Control Manifest Rules (this layer)**:
- Required: 价格平衡必须基于数学公式，确保可预测性
- Forbidden: 禁止硬编码价格值，必须使用配置或公式
- Guardrail: 价格计算不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/economy-system.md`, scoped to this story:*

- [x] 强化费用计算正确（指数级消耗公式）
- [x] 掉落修正机制正常（福缘影响公式）
- [x] 出售价格计算准确（50%基础价值）
- [x] 黑市价格机制正常（境界等级关联定价）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用PriceBalancingManager节点管理所有价格计算
- 实现calculate_upgrade_cost(level, base_cost)方法计算强化费用
- 实现calculate_drop_amount(base_amount, luck_stat)方法计算掉落修正
- 实现calculate_sell_price(item_base_value)方法计算出售价格
- 实现calculate_blackmarket_price(realm_level)方法计算黑市价格
- 实现公式验证和边界检查机制
- 与CurrencyManager和TradeManager集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 货币管理系统（已处理基础货币功能）
- Story 002: 交易系统（已处理交易流程）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 强化费用计算正确
  - Given: 装备强化到+5，基础费用为200
  - When: 计算强化到+6的费用
  - Then: 费用为200×1.5^6=2,278银两（约）
  - Edge cases: Level 1强化、极高Level、基础费用为0

- **AC-2**: 掉落修正机制正常
  - Given: 基础掉落100银两，玩家福缘为30
  - When: 计算最终掉落
  - Then: 最终掉落为100×(1+30/100)=130银两
  - Edge cases: 福缘为0、福缘为100、负福缘值

- **AC-3**: 出售价格计算准确
  - Given: 物品基础价值为1000银两
  - When: 计算出售价格
  - Then: 出售价格为1000×0.5=500银两
  - Edge cases: 基础价值为0、极高价值物品、小数处理

- **AC-4**: 黑市价格机制正常
  - Given: 筑基丹（境界等级2）
  - When: 计算黑市价格
  - Then: 价格为5000×2=10,000银两
  - Edge cases: 境界等级1、极高境界等级、价格上限

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/economy/price_balancing_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (货币管理系统), Story 002 (交易系统)
- Unlocks: None