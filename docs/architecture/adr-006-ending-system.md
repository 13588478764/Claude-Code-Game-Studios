# ADR-006: 多结局 First-Match Catalog 架构

## Status

Accepted

## Date

2026-05-20

## Last Verified

2026-05-21

## Context

G-3 引入多结局系统：一个 run 结束时，根据玩家最终状态（won/lost、最终钱数、健康/能量/心情归零情况、career level）触发一个结局（如"过劳死" / "财富自由" / "勉强活着"）。这给玩家"收集" + "重玩驱动"。

约束：
- 10+ 结局且会持续增加 — 必须 catalog-driven，加 entry 不改代码
- 每 run 必须 resolve 到 exactly one ending — 不能 0 个不能多个
- 触发条件之间有优先级（health 归零 = 过劳死 > 一般失败）— 需要明确顺序规则
- 部分 ending 隐藏（rare/legendary）— 玩家解锁前在图鉴显示 "???"
- RunManager 不可知 ending 系统 — 保持纯（只 emit onRunEnded）
- Ending 解锁要持久化到 SaveData

## Decision

**First-Match Catalog：ENDINGS 按声明顺序匹配，第一个 `matches(ctx)` 返回 true 的 entry 即为结局。最后一个 entry 必须是无条件 fallback。**

```ts
export const ENDINGS: ReadonlyArray<Ending> = [
  // 优先级最高 — 特殊高分条件
  { id: 'tycoon-ending', rarity: 'legendary', matches: (ctx) =>
    ctx.result.won && ctx.result.finalMoney >= 3000 && ctx.finalCareerLevel === 4 },
  // ... 更多具体条件 ...
  // 优先级最低 — 兜底
  { id: 'just-another-week', rarity: 'common', matches: () => true }
] as const

export function resolveEnding(ctx): Ending {
  return ENDINGS.find((e) => e.matches(ctx)) ?? ENDINGS[ENDINGS.length - 1]!
}
```

**关键 invariant**：
1. **声明顺序 = 优先级**（高优先在前 — legendary → rare → common → fallback）
2. **最后一个必须无条件 match**（被 unit test "last entry is unconditional fallback" enforce）
3. **EndingSystem 不参与 ResolveEnding 自身** — 只持久化 + emit；resolveEnding 是 pure function on types/ending.ts
4. **持久化路径**：SaveData.stats.endings (string[]) — 复用 stats 区域，schema v1 back-compat（optional 字段）
5. **EndingContext 三字段足够**：RunResult + finalCareerLevel + depletionSource（已 cover 所有 ending 触发需要的输入）

**为什么 first-match 而不是 score-based / weighted**：
- 直觉 — 玩家看到的"为什么我得这个结局"答案应清晰
- 容易扩展 — 加新 ending 只需 push 到合适位置
- 避免歧义 — 不需要决"两个 ending 都 match 时 score 怎么比"
- Unit test 友好 — 每个 ending 独立测，无组合爆炸

## Consequences

**正面：**
- 数据驱动 — 加 1 个 ending = push 1 个 entry + 0 行代码改动
- 测试简单 — 每个 ending 独立 case + first-match 优先级测一遍
- UI 解耦 — 图鉴 page 直接 iterate ENDINGS catalog 渲染（lock/unlock 状态）
- depletionSource 字段 reuse — RunManager 已记录，ending-store 监听 onResourceDepleted 缓存
- "隐藏直到解锁" 简单实现 — 图鉴渲染时 `unlocked ? e.name : '???'`

**负面：**
- catalog 顺序 = 隐式优先级 — 加新 ending 时必须想清楚 insert 在哪
- 多个 ending 都满足时只 fire 一个 — 玩家可能错过"次优"结局（可由"先解锁高优先 → 再追低优先"策略弥补）
- `matches()` 是 closure — 不可序列化（但 ending catalog 是 build-time 常量，无需序列化）

**缓解：**
- ADR 锁定"声明顺序 = 优先级" — 未来 PR review 看见 insert 中间会自动想"是否破坏现有 ending 触发"
- catalog integrity test："所有 id 唯一" + "最后一个无条件 match" + "rarity 限定 3 值"
- 必要时可加 score-based ordering — 把 `priority: number` 字段加到 Ending 接口，sort 后再 find — 是加法改动

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | TypeScript strict |
| **Domain** | Core (game-end state resolution) |
| **Knowledge Risk** | LOW |
| **References Consulted** | `types/ending.ts` / `services/ending/ending-system.ts` / `stores/ending-store.ts` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (TypedEventEmitter) / ADR-003 (Service/Store) |
| **Enables** | 未来 ending-driven achievements / share image 含 ending |
| **Blocks** | G-3 + G-4（结局图鉴） |

## GDD Requirements Addressed

- 用户 2026-05-20 设计："多周目驱动 - 触发过特定随机事件才能解锁特殊结局" — first-match catalog 直接支撑
- 用户 2026-05-20 设计："死法/离职原因图鉴" — ENDINGS 的 rare 分组对应"奇葩离职"概念
- 用户 2026-05-20 设计："收集欲会驱动玩家尝试各种作死操作" — "???" 隐藏 + isFirstTime toast 双重激励
