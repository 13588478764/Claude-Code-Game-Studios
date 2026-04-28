# Story 003: 旅行成本机制

> **Epic**: 快速旅行系统
> **Status**: Pending Test
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/fast-travel-system.md`
**Requirement**: `TR-fast-travel-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，世界流式加载

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理费用扣除事件，利用经济系统接口管理货币

**Control Manifest Rules (this layer)**:
- Required: 旅行成本必须实时计算并验证玩家余额
- Forbidden: 禁止在余额不足时执行旅行
- Guardrail: 成本计算不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/fast-travel-system.md`, scoped to this story:*

- [x] 旅行费用计算正确（银两消耗公式）
- [x] 旅行时间计算准确（时间跳跃公式）
- [x] 余额验证机制正常（支付确认）
- [x] 货币回收功能正常（经济平衡）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用TravelCostManager节点管理旅行成本逻辑
- 实现calculate_travel_cost(start_node, end_node)方法计算旅行费用
- 实现calculate_travel_time(distance)方法计算旅行时间
- 实现has_sufficient_funds(cost_amount)方法验证余额
- 实现process_payment(cost_amount)方法处理支付
- 实现travel_cost_processed信号通知其他系统
- 与EconomyManager、FastTravelManager和GameStateManager系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 快速旅行功能（处理旅行逻辑）
- Story 002: 已发现地点访问（处理地点解锁和标记）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 旅行费用计算正确
  - Given: 玩家从青云山到江南水乡（距离系数0.5）
  - When: 系统计算旅行费用
  - Then: 费用 = 10 + (0.5 × 100) = 60银两
  - Edge cases: 最近距离、最远距离、费用上限、基础费用变化

- **AC-2**: 旅行时间计算准确
  - Given: 玩家开始跨区域旅行（距离系数0.5）
  - When: 系统计算旅行时间
  - Then: 时间 = 1 + (0.5 × 6) = 4小时
  - Edge cases: 同区域旅行、最长旅行时间、基础时间变化

- **AC-3**: 余额验证机制正常
  - Given: 玩家账户有50银两
  - When: 尝试进行费用为60银两的旅行
  - Then: 系统拒绝旅行并提示余额不足
  - Edge cases: 精确余额、负余额、费用为0

- **AC-4**: 货币回收功能正常
  - Given: 玩家完成一次60银两的旅行
  - When: 支付成功后
  - Then: 玩家银两减少60，系统总收入增加60
  - Edge cases: 退款机制、交易记录、并发访问

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/fast-travel/travel_cost_mechanism_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (快速旅行功能), Story 002 (已发现地点访问)
- Unlocks: None