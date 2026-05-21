# ADR-005: 选择 effect 的 4 层 Modifier Pipeline

## Status

Accepted

## Date

2026-05-20

## Last Verified

2026-05-21

## Context

游戏选择会产生 effects（如 energy -20, mood +10, money -50）。最初 Sprint 1 设计是简单：effect 直接 apply 到 ResourceManager。

逐 Sprint 加了新机制：
- **Sprint 2 (S2-1/S2-3)**: 状态系统 — buff/debuff 有 `energyMul/moodMul`，应该在 resource apply 之前 modify effect
- **Sprint 3 (S3-9)**: 被动技能（永久跨 run） — 同样需要 modify effect
- **Sprint 4 (C-1)**: 装备道具（per-run，slot-based） — 也需要 modify effect

四层都对 effect 有 "倍率" 类型的 modifier，需要确定调用顺序、责任边界、互斥规则。

约束：
- ResourceManager 不可知 buff/skill/item — 保持纯（只接收最终 effects）
- ChoiceResolutionEngine 是 effect 流转的中枢 — 在它内部组装 pipeline
- 不同 modifier 类型有不同生命周期（永久 vs per-run vs 临时 buff）— 顺序不能颠倒
- 必须可分别 unit test — 每个 modifier system 独立

## Decision

**4 层 modifier pipeline：raw → passive → equipment → status → resource，按生命周期长 → 短排序**

```
choice.effect.value
  → PassiveSkillSystem.applyToEffect   (永久跨 run modifier)
  → ItemSystem.applyToEffect           (per-run 装备 modifier)
  → StatusSystem.applyToEffect         (per-run 临时 buff/debuff modifier)
  → ResourceManager.applyEffects       (最终落盘 + clamp + state machine)
```

实现：`ChoiceResolutionEngine.applyStatusModifiers()` 内部链式调用注入的 deps：

```ts
const afterPassive = deps.passiveApplyToEffect(target, raw)   // 永久
const afterEquipment = deps.equipmentApplyToEffect(target, afterPassive)  // 装备
const afterStatus = deps.statusApplyToEffect(target, afterEquipment)     // 临时
deps.resourceApplyEffects([{ target, value: afterStatus }])
```

**关键 invariant**：
1. 所有 4 层都 multiplicative 累乘 — `signFloor` 在每层 round-toward-zero
2. `money` target 是 pass-through — 不被任何 modifier 影响
3. `wasStatusModified` 标记仅追 status 层 — passive/equipment 永久不需要 UI pulse
4. 所有 deps 是 optional — 单独测试 ResourceManager 时可跳过整链
5. ChoiceResolutionEngine 内部加锁顺序 — `addStatus` 在 `applyEffects` 之后（避免本次 effect 受新加 buff 影响 — preserves "选项 A 的 buff 不影响选项 A 的 effect" invariant from S2-3）

**排序原因**（生命周期长 → 短）：
- Passive 跨多 run 持久 — 最稳定，最早 apply（base 基础属性）
- Equipment per-run 但跨多天 — 中等
- Status per-run + 几天 daysLeft — 最易变化，最后 apply（覆盖前面的中间结果）

## Consequences

**正面：**
- 4 个系统完全解耦 — 各自 100% 覆盖单测 + 各自可单独 disable
- 配置可选 — 不传 deps 等同于 identity 透传 — Sprint 1 测试 0 退化
- 顺序明确可推理 — 不会出现 "为什么这个 buff 被吞了" 的混乱
- 加第 5 层（如未来 buff stacking / 公会光环）只需 push 一层 dep

**负面：**
- 4 次 function call per effect — 小开销但每秒只调几次，无 perf 问题
- ChoiceResolutionDeps 接口字段多（4 个 optional applyToEffect 同模式 — 看着像重复但 OO 重构会破坏 service 解耦）
- 测试时 mock 4 个 dep 略 verbose

**缓解：**
- pipeline 顺序在 ADR 锁定，未来加层有"应该 insert 到哪"的决策框架
- 4 个 dep 字段都有 JSDoc 说明 — IDE 自动提示
- Test fixture 提供 `noOpDeps` 默认 — 测试只覆盖关心的层

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | uni-app + Vue 3 + TypeScript strict |
| **Domain** | Core (game state mutation) |
| **Knowledge Risk** | LOW |
| **References Consulted** | `services/choice-resolution/choice-resolution-engine.ts` + 4 sub-systems |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — pure logic |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (TypedEventEmitter) / ADR-003 (Service emit → Store subscribe) |
| **Enables** | S3-9 passive skills / C-1 equipment / 未来 buff stacking |
| **Blocks** | None |

## GDD Requirements Addressed

- 用户 2026-05-20 设计：「道具可以购买，增加属性，增加buff」— equipment modifier 层支撑
- 用户 2026-05-20 设计：「不同的房屋有不同的属性或者buff加成」— equipment housing slot 复用同层
- 用户希望"加新道具/buff 零代码"— 4 层独立 + 数据驱动 catalog 设计支撑
