# Story 002: 交易系统

> **Epic**: 经济系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/economy-system.md`
**Requirement**: `TR-economy-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: 交易系统涉及多个子系统交互，需确保数据一致性

**Control Manifest Rules (this layer)**:
- Required: 交易必须有事务性保证，防止部分完成
- Forbidden: 禁止绕过交易系统直接修改玩家资产
- Guardrail: 交易计算不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/economy-system.md`, scoped to this story:*

- [x] 商店购买功能正常（基础商品、黑市商品）
- [x] 物品出售功能正常（直接出售、拆解回收）
- [x] 交易验证机制正确（余额不足、库存检查）
- [x] 交易历史记录完整（购买、出售、拆解记录）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用TradeManager节点管理所有交易操作
- 实现purchase_item(item_id, quantity, price)方法处理购买
- 实现sell_item(item_id, quantity)方法处理出售，返回获得货币
- 实现disassemble_item(item_id)方法处理拆解，返回材料
- 实现validate_transaction()方法验证交易可行性
- 实现transaction_completed信号通知UI更新
- 与CurrencyManager和InventoryManager集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 货币管理系统（已实现基础货币功能）
- Story 003: 价格平衡机制
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Integration stories — automated test specs]:**

- **AC-1**: 商店购买功能正常
  - Given: 商店有生命药水库存(价格50银两，库存10个)
  - When: 玩家购买3个生命药水
  - Then: 玩家银两减少150，背包中生命药水增加3个
  - Edge cases: 余额不足、库存不足、购买数量为0

- **AC-2**: 物品出售功能正常
  - Given: 玩家背包中有价值1000银两的装备
  - When: 玩家出售该装备
  - Then: 装备从背包移除，玩家银两增加500(50%出售价)
  - Edge cases: 装备绑定、出售数量、拆解功能

- **AC-3**: 交易验证机制正确
  - Given: 玩家只有200银两
  - When: 尝试购买价格500银两的商品
  - Then: 交易失败，银两和背包内容不变
  - Edge cases: 背包空间不足、负数金额、无效物品ID

- **AC-4**: 交易历史记录完整
  - Given: 玩家完成多次交易
  - When: 查看交易历史
  - Then: 显示所有交易记录，包括时间、类型、物品、金额
  - Edge cases: 大量交易记录、存档加载后记录保留

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/economy/trade_system_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (货币管理系统)
- Unlocks: Story 003 (价格平衡机制)