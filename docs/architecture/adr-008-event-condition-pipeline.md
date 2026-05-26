# ADR-008: EventCondition Pipeline — JSON-Driven Event Gating

## Status

Accepted

## Date

2026-05-24

## Last Verified

2026-05-25

## Context

随着 Sprint 4-7 内容扩张到 382 个事件 + 8 个职业 + 多周生涯 + 装备 / 状态 / 升职系统，
"哪些事件**何时**可以入池"的逻辑越来越复杂：

- 周末 review 事件只在 `day % 7 === 0` 出现
- 升职奖励事件需 `careerLevel >= 2`
- 道具触发事件需玩家 `inventory.coffee > 0`
- 状态联动事件需 `activeStatuses.includes('tired')`
- 教程后续事件需 `event-seen: 'tutorial-1'`

历史方案 (Sprint 3 前)：

1. **`prereqs`**：只支持"前置事件 id"，无法表达 "career level >= 2"
2. **`dayRange`**：只支持"第 X-Y 天"，无法表达 "weekday === 0"
3. **`cooldown`**：只是计时器，无谓词能力
4. **硬编码 in EventEngine**：每加一种条件就 patch 一次 buildPool，散落 if/else，无法 unit test

约束：
- 必须**数据驱动**（无代码改动加新事件 / 新条件 case）
- 必须**前向兼容**（旧 JSON 无 `conditions` 字段不报错）
- 必须**后向防御**（新 JSON 包含旧 build 不识别的 type → 保守失败，不抛错）
- 必须**纯函数**（evaluateCondition 可 unit test，无副作用）
- pipeline 位置必须明确（与 prereqs/dayRange/cooldown 配合）

## Decision

**引入 `EventCondition` 谓词数组 + 纯函数 evaluateCondition，作为 buildPool filter chain 的最后一道闸。**

```ts
// src/types/event.ts
interface EventCard {
  // ...
  conditions?: EventCondition[]  // 全 AND 满足才入池
}

type EventCondition =
  | { type: 'resource-below'; resource: 'energy'|'mood'|'money'|'health'; value: number }
  | { type: 'resource-above'; resource: ...; value: number }
  | { type: 'day-equals'; value: number }
  | { type: 'day-above'; value: number }
  | { type: 'day-below'; value: number }
  | { type: 'weekday'; value: number }   // day % 7
  | { type: 'career-level'; value: number }
  | { type: 'has-item'; itemId: string }
  | { type: 'has-equipment'; slot: ItemSlot; itemId: string }
  | { type: 'status-active'; statusId: string }
  | { type: 'event-seen'; eventId: string }
  | { type: 'event-not-seen'; eventId: string }
```

```ts
// src/services/event-data/event-data-engine.ts
buildPool(context):
  return rawEvents
    .filter(e => prereqsSatisfied(e, context))
    .filter(e => dayRangeMatches(e, context))
    .filter(e => cooldownClear(e, context))
    .filter(e => {
      if (!e.conditions || e.conditions.length === 0) return true
      for (const cond of e.conditions) {
        if (!evaluateCondition(cond, context)) return false
      }
      return true
    })

// Pure function — 100% unit-testable
export function evaluateCondition(cond: EventCondition, ctx: EventDrawContext): boolean {
  switch (cond.type) {
    case 'resource-below':   return (ctx.resources?.[cond.resource] ?? 0) < cond.value
    case 'resource-above':   return (ctx.resources?.[cond.resource] ?? 0) >= cond.value
    case 'day-equals':       return ctx.currentDay === cond.value
    case 'weekday':          return ctx.currentDay % 7 === cond.value
    case 'career-level':     return (ctx.careerLevel ?? 1) >= cond.value
    case 'has-item':         return (ctx.inventory?.[cond.itemId] ?? 0) > 0
    case 'has-equipment':    return ctx.equipped?.[cond.slot] === cond.itemId
    case 'status-active':    return ctx.activeStatuses?.includes(cond.statusId) ?? false
    case 'event-seen':       return ctx.shownEventIds.includes(cond.eventId)
    case 'event-not-seen':   return !ctx.shownEventIds.includes(cond.eventId)
    default:                 return false   // 前向兼容：未知 type 保守失败
  }
}
```

**EventDrawContext 扩展**：原 DrawContext 加上 `careerLevel? / inventory? / equipped? / activeStatuses?`。callsite (EventCardSystem.drawEvent) 从 careerSys / itemSys / statusSys pull 当前快照填入。

**为什么 AND 而非 OR**：
- AND 让 JSON 更简单：每个 condition 是一个独立断言，作者读起来"全部满足"心智清晰
- OR 可由"拆成两个 event entry"在 catalog 层实现，避免 condition tree 复杂度
- 实际内容设计未出现"A OR B"刚需

**为什么 last filter（不是 first）**：
- prereqs / dayRange / cooldown 是 O(1) 廉价 — 先做
- conditions 可能读 inventory / careerSys（DI 调用） — 留到最后，被 prereqs 提前 short-circuit 掉的 event 不消耗 condition 计算
- 与 ADR-005 (Modifier Pipeline) 设计原则一致：cheap-first / expensive-last

## Consequences

**正面：**
- 加 condition type 单点改动：扩 union + 加 switch case + 写 unit test，不动 engine
- 加事件 zero 代码改动：JSON push entry + conditions 数组，dev:h5 / build 双路径 cover
- 纯函数 100% 可测：当前 32 个 evaluateCondition unit tests
- M-1 sprint 实现 12 个 type 后 catalog 立即支持复杂 gating（周末 review / 升职奖励 / 道具触发 / 状态联动 / 教程链）
- 与 prereqs/dayRange/cooldown **正交**——旧逻辑零修改

**负面：**
- DrawContext 需要 careerSys/itemSys/statusSys 当前快照 → EventCardSystem.drawEvent 调用前需 pull (~5 line 改动)
- 未知 type 保守失败可能让作者"明明写了 condition 为什么不生效" → 需在 CI 加 schema check 防御
- AND-only 限制可能催生"split entry"的丑陋 catalog（例如同事件文本 ×2 配不同 condition）—— 出现刚需时再加 OR

**缓解：**
- DrawContext 扩展是单一改动点（EventCardSystem.drawEvent）— 加新 system 时易 catch
- 未来加 JSON schema validator → CI 阶段 catch unknown type
- 文档明确：复杂逻辑优先 split entry，AND 是 90% case 足够

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | uni-app + Vue 3 + TypeScript strict |
| **Domain** | Core (data pipeline) |
| **Knowledge Risk** | LOW |
| **References Consulted** | `src/types/event.ts` / `src/services/event-data/event-data-engine.ts` |
| **Post-Cutoff APIs Used** | None — 纯 TypeScript union + switch |
| **Verification Required** | 无运行时风险；前向兼容由 default branch 保证 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-005 (Modifier Pipeline 设计原则：cheap-first) |
| **Enables** | M-1 / M-2 / M-续 (career-restricted events) / 周末 review / 教程链 |
| **Blocks** | 无 |

## GDD Requirements Addressed

- `design/gdd/event-data-engine.md` §EventCondition 谓词链（2026-05-25 retrofit）
- `design/gdd/career-progression-system.md` 周末 review 事件需 weekday=0 + careerLevel 条件
- `design/gdd/item-system.md` 道具触发事件需 has-item / has-equipment
- `design/gdd/status-system.md` 状态联动事件需 status-active

## Acceptance

- evaluateCondition 100% covered（unit tests 涵盖 12 type + default + 边界）
- 旧 JSON 无 conditions 字段：buildPool 正常工作（向后兼容）
- 新 build 加 type → 旧 build 加载：default branch 返回 false（保守失败）
- 加事件场景：dev:h5（middleware）+ build:mp-alipay（closeBundle） 双路径生效——见 ADR-009
