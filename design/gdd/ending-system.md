# 结局系统 (Ending System)

> **Status**: Designed (Retrofit 2026-05-25)
> **Author**: gameplay-programmer + user
> **Last Updated**: 2026-05-25
> **Implements Pillar**: 一局一笑 / 永远有新的
> **Sprint**: G-3

## Overview

结局系统在 run 结束时把"你这一局发生了什么"翻译成**一个有具体名字的结局**。它读取 RunContext（jobId / endMoney / weeksWorked / careerLevel / 死亡资源 / 完成原因等），按 ENDINGS catalog 顺序**first-match** 解析，得到一个 ending（如 tycoon-ending / overwork-death / just-another-week），调用 `recordEnding(ctx)` 持久化 + 通知 UI 弹"× × 结局解锁！"。

本系统是**纯数据驱动**——结局条件全在 `src/types/ending.ts` 的 ENDINGS catalog 里（priority 排列），加新结局只需 push entry，无需改代码。系统始终 emit `onRunEnded`（给 UI 用），但只在**首次解锁**时 emit `onEndingUnlocked`（带 isFirstTime: true）。

## Player Fantasy

**间接幻想**：玩家死后看到"暴富结局"或"过劳死结局"会笑出来——结局名字是给"这一局的人生剪影"加的标签。多周目动力：图鉴里 10 个结局还有 7 个没解锁 → "下次试试用销售拼一把暴富"。

结局命名走荒诞 + 自嘲：tycoon-ending（成为人生赢家）/ workaholic-king（卷王之王）/ overwork-death（过劳猝死）/ broke-but-survived（穷得活着）/ early-quit（早早躺平）/ just-another-week（又一个平凡的周）—— fallback 是最后这个，确保玩家**永远不会看到"无结局"**。

## Detailed Rules

### Ending 数据结构（src/types/ending.ts）

```typescript
interface Ending {
  id: string
  name: string
  description: string
  rarity: 'common' | 'rare' | 'legendary'   // UI 用，影响弹窗动效
  condition: EndingCondition                // 解析逻辑（10+ 种类型）
}

type EndingCondition =
  | { type: 'money-above'; threshold: number }
  | { type: 'died-of'; resource: 'energy' | 'mood' | 'health' }
  | { type: 'completed-weeks'; min: number }
  | { type: 'career-level'; min: number }
  | { type: 'fired'; weeks: number }   // 被炒（weeksWorked < expected）
  | { type: 'fallback' }
  | ...
```

### 解析流程：first-match

```
recordEnding(ctx):
  1. always emit onRunEnded({ ctx })
  2. resolved = resolveEnding(ctx)   ← 遍历 ENDINGS，找第一个 condition(ctx) === true
  3. isFirstTime = !this.unlocked.has(resolved.id)
  4. if (isFirstTime) this.unlocked.add(resolved.id)
  5. emit onEndingUnlocked({ ending: resolved, isFirstTime })
  6. return resolved
```

**resolveEnding** 在 `types/ending.ts` 实现——按 ENDINGS 数组顺序遍历，命中第一个 condition 满足的就返回。**catalog 顺序就是优先级**——把"暴富 + 卷王"放前面，"普通收尾"放后面，最后一个永远是 `{ type: 'fallback' }` 兜底。

### Catalog 当前 10 个结局

| ID | Name | Rarity | 主要条件 |
|----|------|--------|---------|
| tycoon-ending | 人生赢家 | legendary | money ≥ 10000 |
| workaholic-king | 卷王之王 | legendary | careerLevel ≥ 4 + weeksWorked ≥ 4 |
| overwork-death | 过劳猝死 | rare | died-of energy |
| mental-breakdown | 精神崩溃 | rare | died-of mood |
| burnt-out | 燃尽 | rare | died-of health |
| broke-but-survived | 穷得活着 | common | endMoney < 0 + 活到周末 |
| promoted-rookie | 升职新人 | common | careerLevel ≥ 2 |
| senior-veteran | 资深老兵 | common | careerLevel ≥ 3 |
| early-quit | 早早躺平 | common | fired/quit before week 2 |
| just-another-week | 又一个平凡的周 | common | **fallback** |

### Unlock 状态 + 持久化

`unlocked: Set<string>` —— 已解锁 ending id。**首次解锁**触发 `onEndingUnlocked({ isFirstTime: true })`，UI 弹"新结局解锁！"。重复触发同一 ending → 仍 emit `onEndingUnlocked` 但 `isFirstTime: false`（UI 显示"再次见到 XX 结局"）。

`init(unlockedIds: string[])`：从 SaveData.stats.endings 恢复。**默认 fallback**：若 SaveData 旧版本没有 endings 字段 → init([]) → 第一次解锁任何结局都是 firstTime（玩家体验：旧存档玩家"第一次"看到 ending 时全是首次解锁）。

### 与 ProgressionSystem 的协作

- ProgressionSystem.recordRun **不调用** ending；
- EndingSystem.recordEnding 被 RunManager 在 endRun 流程的另一条线调用；
- 持久化由 saveService 端整合：ending unlocked set 通过 `getUnlocked()` 写入下次 recordRun 的 stats.endings。**已知 SMELL**：当前 endings 持久化路径不在 ProgressionSystem.recordRun 的单一 save 内，是分两步写——可能在崩溃场景下短暂不一致。

## Formulas

本系统**无独立数值公式**——only first-match 谓词链。

```
resolved = ENDINGS.find(e => evaluateCondition(e.condition, ctx))
        ?? { id:'just-another-week', name:'又一个平凡的周', ... }   // fallback
```

不变量：ENDINGS 末位必须是 `{ type:'fallback' }`，保证 resolved 永远非 null。

## Edge Cases

- **多个条件同时满足**（如暴富 + 卷王 + 升职）→ first-match：catalog 顺序决定优先级。**故意如此**——legendary > rare > common 的体验由 catalog 排序保证。
- **catalog 末位不是 fallback**（开发期疏忽）→ resolveEnding 可能返回 null → recordEnding 行为未定义。**约定式防御**：types/ending.ts 在 catalog 末追加 `just-another-week` 作为 fallback。**没有 runtime 校验**——靠 code review。
- **save 中含未知 ending id**（旧版本删除的 ending）→ `init(['removed-ending', 'tycoon-ending'])` 时 **不 filter**——这些 id 仍在 unlocked set 里，下次玩家看图鉴会看到"已解锁但找不到 entry 的灰块"。**SMELL**：应 filter 但当前没做。
- **同一 run 触发 recordEnding 两次**（理论上 RunManager 不会）→ 两次 emit onRunEnded、两次 emit onEndingUnlocked、第二次 isFirstTime=false。调用方责任保证幂等。
- **ctx 字段缺失**（如 endMoney 为 undefined）→ 条件谓词读到 undefined 时多半返回 false → fall-through 到 fallback。不抛错。

## Dependencies

### 上游
| 系统 | 用途 |
|------|------|
| RunManager | 在 endRun 流程末调用 `recordEnding(ctx)` |
| RunContext (构造) | 由 RunManager 收集：jobId / endMoney / weeksWorked / careerLevel / 死亡资源 / weeksExpected ... |
| CareerProgressionSystem | `getLevel()` 进入 ctx.careerLevel |
| ResourceManager | 死亡资源信息进入 ctx.diedOf |

### 下游
| 系统 | 接口 |
|------|------|
| SaveService | 通过 ProgressionSystem.recordRun 或独立写入持久化 ending unlocked set |
| Vue Store (endingStore) | 订阅 onRunEnded / onEndingUnlocked 推 UI 弹窗 + 图鉴 |
| 图鉴 / Codex UI | 读 `getUnlocked()` 显示进度 |

### 公共接口

```typescript
class EndingSystem {
  init(unlockedIds: string[]): void
  hasEnding(id: string): boolean
  getUnlocked(): string[]
  recordEnding(ctx: RunContext): Ending           // 始终返回 resolved
  readonly onRunEnded: TypedEventEmitter<{ ctx: RunContext }>
  readonly onEndingUnlocked: TypedEventEmitter<{ ending: Ending, isFirstTime: boolean }>
}
```

## Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 说明 |
|--------|--------|---------|------|
| ENDINGS catalog | 10 entries | — | 加 ending 只需 push entry（注意保留 fallback 在末尾） |
| ending.condition.threshold | 视类型 | — | money-above:10000；career-level:2/3/4；died-of：无 threshold |
| ending.rarity | common/rare/legendary | — | 影响 UI 弹窗特效（金光 / 紫光 / 蓝光） |
| catalog 顺序 | legendary → rare → common → fallback | — | first-match 决定优先级；插入新 ending 要谨慎选位置 |

## Acceptance Criteria

- **GIVEN** 全新 save (unlocked=[]), **WHEN** `init([])`, **THEN** `getUnlocked() === []`。
- **GIVEN** ctx {endMoney:15000, weeksWorked:4}, **WHEN** `recordEnding(ctx)`, **THEN** 返回 tycoon-ending, emit onEndingUnlocked({isFirstTime:true})。
- **GIVEN** 同 ctx 第二次 recordEnding, **WHEN** 触发, **THEN** 仍返回 tycoon-ending, emit onEndingUnlocked({isFirstTime:**false**})。
- **GIVEN** ctx {diedOf:'energy'}, **WHEN** recordEnding, **THEN** 返回 overwork-death（rare）。
- **GIVEN** ctx 不满足任何 ending, **WHEN** recordEnding, **THEN** 返回 just-another-week（fallback）—— 永远非 null。
- **GIVEN** ctx {endMoney:15000, careerLevel:4, weeksWorked:4} (满足 tycoon + workaholic-king), **WHEN** recordEnding, **THEN** 返回 catalog 中靠前的那个（first-match）。
- **GIVEN** save endings=['tycoon-ending'], **WHEN** init, **THEN** hasEnding('tycoon-ending')=true, 后续解锁同 id emit isFirstTime:false。
- **GIVEN** recordEnding 调用一次, **WHEN** 检查 emit, **THEN** onRunEnded emit 1 次, onEndingUnlocked emit 1 次（无论是否首次）。
