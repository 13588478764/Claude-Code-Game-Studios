# ADR-007: Save Resume — Day-Boundary Checkpoint

## Status

Accepted

## Date

2026-05-20

## Last Verified

2026-05-21

## Context

ADR-004 把 1 run = 5 天 扩到 20 天，单次游玩 5-10 分钟。玩家手机随时被打断（小程序场景核心特征）— 必须能"中途关游戏，下次继续"。

约束：
- 不能丢失整个 career 的进度（重玩 20 天对玩家是 punishing）
- 必须 cover 多个独立 system 的 state：resources（4 个）/ status（buff/debuff）/ career（level/score/weeksWorked）/ item（inventory/equipped）/ day-cycle 位置
- 写存档不能太频繁 — 影响性能 + 小程序 storage 写次数有配额
- 必须 back-compat 旧 save（schema v1 已用，不想 v2 migration）
- 任何 service 不可知 save 系统 — 各自暴露 getSnapshot/loadSnapshot pure API

## Decision

**Day-boundary checkpoint：每天结束（onDayEnded）写 currentRun snapshot；玩家中断后 resume 时跳到下一天开始。Mid-day 进度（当天已选了几张卡）不持久化。**

```ts
// Checkpoint write — useGameSession 注册的最后一个 onDayEnded listener
dayCycleSystem.onDayEnded.on(() => {
  if (runManager.getPhase() !== 'PLAYING') return
  writeRunCheckpoint()  // 抓所有 sub-system snapshot 写入 SaveData.currentRun
})

// Resume on mount
if (snapshot && phase === 'INITIALIZING') {
  tryResume(snapshot)  // 恢复 4 个 system + dayCycleSystem.startWeek/startDay 到 next day
}
```

**Snapshot shape**（RunSnapshot 扩展）：
```ts
interface RunSnapshot {
  jobId: string
  weekIndex?: number  // optional for back-compat
  day: number         // day N — resume jumps to day N+1 (or week+1 day 1)
  resources: Resources             // {energy, mood, money, health}
  career?: CareerState             // {level, score, weeksWorked}
  statuses?: StatusEffect[]        // buff + debuff snapshots
  inventory?: InventoryEntry[]
  equipped?: Array<{slot, itemId}>
  totalChoices: number
  // ...
}
```

**Resume 流程**：
1. useGameSession mount → saveService.load() → 检查 currentRun
2. 如 currentRun 非 null：调 tryResume(snapshot)
3. resourceManager.init(snapshot.resources)（health 缺失 → 默认 100，back-compat 老存档）
4. statusSystem.loadSnapshot / careerProgressionSystem.loadSnapshot / itemSystem.loadInventory + loadEquipped
5. RunManager: selectJob(jobId) → startPlaying（短暂 INITIALIZING → PLAYING）
6. dayCycleSystem.configure(weeks) → startWeek(next) → startDay(next)
7. **不重启 RunManager 的 totalChoices/uniqueEventIds** — 已接受 rating 略偏差作为 MVP trade-off

**清理**：endRun 触发 progressionSystem.recordRun → progression-store 已在 patch 中设 `currentRun: null` — 自动 cleanup 已完成的 run。

**为什么 day-boundary 而不是每 event resolve**：
- Mid-event 状态太多 — 需序列化 EventCardSystem 队列 + currentCard + isResolving flag — 复杂度爆炸
- 写次数：1 run 写 ~20 次 vs 每 event 写 ~64 次 — 3x 差异，写 storage 是同步阻塞
- "丢失当天进度"是可接受 punishment — 一天 3 个事件 = 30s 重玩，不是 20 天重玩
- 玩家心智模型清晰 — "撑过这一天才算保存"

## Consequences

**正面：**
- 实现简洁 — 5 个 system 各 expose getSnapshot/loadSnapshot pure 方法 + useGameSession 一个 hook
- back-compat 安全 — RunSnapshot 所有新字段 optional，老存档（v1 pre-G-1）也能 resume（只丢失 career/status/inventory）
- 性能可控 — 20 次 storage write per run，远低于配额
- service 解耦保持 — 各 system 不知道 save 存在
- 测试简单 — 12 integration tests cover 各 system 的 round-trip

**负面：**
- 玩家中途关游戏会丢失当天进度（接受）
- totalChoices / uniqueEventIds 不持久化 → rating 略偏（仅影响"resume 后这一段的"，前面累积的丢失 — acceptable for MVP）
- 5 个 system 都要 maintain snapshot/load API — 加新 system 时记得 wire

**缓解：**
- "丢当天进度" 用户在 game-main 顶部可看见 weekIndex/day，知道存档位置 — 心智一致
- rating 偏差 → 玩家通常一次玩完 1 个 career，resume 是少数 case
- 加新 system 时 useGameSession.writeRunCheckpoint() 是单一改动点 — 评审 review 易 catch

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | uni-app + Vue 3 + TypeScript strict |
| **Domain** | Core (persistence) |
| **Knowledge Risk** | LOW |
| **References Consulted** | `composables/useGameSession.ts` / `services/save/save-service.ts` |
| **Post-Cutoff APIs Used** | None — 用 uni.setStorageSync via StorageAdapter |
| **Verification Required** | 小程序 storage 配额：单次 1MB / 总 10MB — 当前 save ~5KB，无风险 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-003 (Service/Store) / ADR-004 (multi-week career — Resume 跳到 next day 需要 weekIndex 概念) |
| **Enables** | 未来 cross-device sync（save 已经是 serializable） |
| **Blocks** | G-1 |

## GDD Requirements Addressed

- 用户场景：手机随时被打断（小程序核心特征）— resume 必要
- ADR-004 引入 20 天 career — 长 run 必须可中断
- 不引入新存档 schema 版本 — 保留 SAVE_SCHEMA_VERSION = 1
