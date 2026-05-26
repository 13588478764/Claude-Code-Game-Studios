# 永久进度系统 (Progression System)

> **Status**: Designed (Retrofit 2026-05-25)
> **Author**: gameplay-programmer + user
> **Last Updated**: 2026-05-25
> **Implements Pillar**: 局外成长 / 永远有新的
> **Sprint**: S3-1

## Overview

永久进度系统是**跨 run 的总调度器**。每局结束时由 RunManager 触发，它做四件事：(1) 累计 GlobalStats（局数 / 胜数 / 死数 / 总金 / 各职业游玩数）；(2) 调用 JobRotationSystem.checkUnlocks 检查解锁新职业；(3) 持久化更新后的 stats + jobUnlocks；(4) emit `onProgressRecorded` 让被动技能 / 成就系统等下游订阅者各自处理。

本系统是**纯协调者**——不持有业务逻辑，只编排"结算 → 累计 → 解锁检查 → 持久化"的流水线。被动技能解锁、成就解锁、Ending 记录都由各自系统订阅 `onProgressRecorded` 实现。

## Player Fantasy

**间接基础设施**——玩家直接感知的是被动技能 / 成就 / 图鉴进度，但这些都依赖本系统每局准确地累计 stats。

如果做得好：玩家关掉游戏再打开，所有数据都对得上，"再玩一局解锁 XXX" 的目标感持续存在。做得差：stats 丢失或重复累加，玩家失去成长反馈，弃游。

## Detailed Rules

### GlobalStats 结构（src/types/save.ts）

```typescript
interface GlobalStats {
  totalRuns: number          // 总局数（不论输赢）
  totalWins: number          // 通关数
  totalDeaths: number        // 资源归零次数
  totalMoneyEarned: number   // 累计获得金钱（不扣消费）
  jobsPlayed: Record<string, number>  // 每职业游玩次数 { programmer: 3, sales: 1 }
  achievements: string[]     // 已解锁 achievement id 列表
  endings?: string[]         // 已解锁 ending id 列表（G-3 新增，optional 兼容旧存档）
}
```

### recordRun 流程

```
RunManager.endRun(result: RunResult)
  → ProgressionSystem.recordRun(result)
    1. const currentSave = saveServiceLoad()
    2. const currentStats = currentSave?.stats ?? emptyStats()
    3. newStats = {
         ...currentStats,               // J-4 fix: 保留 optional 字段
         totalRuns: +1,
         totalWins: result.won ? +1 : +0,
         totalDeaths: result.won ? +0 : +1,
         totalMoneyEarned: + result.finalMoney,
         jobsPlayed: { ...prev, [result.jobId]: prev[id]+1 },
         achievements: [...prev]
       }
    4. newlyUnlocked = checkUnlocks(newStats)   ← JobRotationSystem
    5. newJobUnlocks = [...currentJobUnlocks, ...newlyUnlocked]
    6. saveServiceUpdate({ stats, jobUnlocks, currentRun: null })
    7. emit onProgressRecorded({ stats: newStats, newlyUnlocked })
```

### J-4 fix 不变量

第 3 步 **必须** 使用 `...currentStats` 展开作为基础，再 override 命名字段。否则未来添加 optional GlobalStats 字段（如 `endings`）会被静默吞掉。

### 不直接持有职业解锁列表

`jobUnlocks` 字段独立于 stats，由 ProgressionSystem 写入但**不由它派生**——派生逻辑在 `JobRotationSystem.checkUnlocks(stats)` 内。这种分离让两个系统的测试可以独立 mock。

### 不 re-emit 子系统的 onJobUnlocked

`jobRotationSystem.checkUnlocks` 内部已 emit `onJobUnlocked`（per S1-10）。ProgressionSystem **不重复 emit** —— UI 想监听新职业解锁，订阅 `jobSystem.onJobUnlocked`。这避免了双重弹窗。

### 唯一持久化点

整个 recordRun 仅一次 `saveServiceUpdate({ stats, jobUnlocks, currentRun: null })`——保证原子性，避免半途崩溃产生数据不一致（如 stats 已 +1 但 jobUnlocks 未写）。

## Formulas

本系统**无独立公式**——只做整数累加：

```
totalRuns'        = totalRuns + 1
totalWins'        = totalWins + (won ? 1 : 0)
totalDeaths'      = totalDeaths + (won ? 0 : 1)
totalMoneyEarned' = totalMoneyEarned + result.finalMoney
jobsPlayed[jobId]' = jobsPlayed[jobId] + 1
```

不变量：`totalRuns === totalWins + totalDeaths`（任何一局必属其一）。

## Edge Cases

- **首次启动**（save 为 null）→ `currentStats = emptyStats()`，第一局 recordRun 后 `totalRuns=1`。
- **save 损坏**（saveServiceLoad 抛错）→ 由 saveService 内部处理（fallback 到 emptyStats）；ProgressionSystem 不做防御。
- **result.finalMoney 为负数**（玩家欠债结束）→ 累计金钱会减少——**设计允许**，反映玩家真实经济史。
- **result.jobId 不在已知 job 列表中**（未来添加的 job 在旧 save 上 resume）→ jobsPlayed 仍然 +1，下次启动旧 build 会显示该 jobId 计数（看起来奇怪但不破坏数据）。
- **同一 result 重复调用 recordRun**（理论 RunManager 不会）→ 会重复 +1，破坏数据。**调用方责任**保证幂等。
- **持久化失败**（storage 满 / 权限被拒）→ stats 已在内存中 +1 但未落盘——下次启动会回退。当前不做事务回滚（小程序场景，storage 失败属罕见 edge）。

## Dependencies

### 上游
| 系统 | 用途 |
|------|------|
| RunManager | 每局结束调用 `recordRun(result)` |
| SaveService | `load()` / `update(patch)` |
| JobRotationSystem | `checkUnlocks(stats): string[]` |

### 下游（订阅 onProgressRecorded）
| 系统 | 用途 |
|------|------|
| PassiveSkillSystem | `checkUnlocks(stats)` 解锁新被动技能 |
| AchievementSystem | `checkUnlocks(stats)` 解锁新成就 |
| Vue Store (progressionStore) | UI 显示局数 / 胜率等统计 |

### 公共接口

```typescript
class ProgressionSystem {
  constructor(deps: {
    saveServiceLoad: () => SaveData | null
    saveServiceUpdate: (patch: Partial<SaveData>) => void
    checkUnlocks: (stats: GlobalStats) => string[]
  })
  recordRun(result: RunResult): void
  getStats(): GlobalStats
  readonly onProgressRecorded: TypedEventEmitter<{
    stats: GlobalStats
    newlyUnlocked: string[]   // 新解锁的 jobId
  }>
}
```

依赖注入 (DI) 设计：production 注入真实 saveService + jobSystem；test 注入 mock，使本系统 100% 可单测。

## Tuning Knobs

本系统**无 tuning knob** ——它是纯协调流水线。所有可调内容（解锁阈值 / mul 值 / 成就条件）由下游系统的 catalog 控制。

## Acceptance Criteria

- **GIVEN** 全新 save, **WHEN** `recordRun({jobId:'programmer', won:true, finalMoney:500})`, **THEN** `getStats()` 返回 `{ totalRuns:1, totalWins:1, totalDeaths:0, totalMoneyEarned:500, jobsPlayed:{programmer:1}, achievements:[] }`。
- **GIVEN** 已有 stats (runs:5, wins:3), **WHEN** `recordRun({won:false})`, **THEN** stats 变 (runs:6, wins:3, deaths:+1)，不变量 runs === wins + deaths 成立。
- **GIVEN** `checkUnlocks` mock 返回 `['sales']`, **WHEN** `recordRun(...)`, **THEN** `onProgressRecorded` payload `newlyUnlocked === ['sales']`，且 `jobUnlocks` 持久化含 `'sales'`。
- **GIVEN** save 中 stats 含 `endings: ['tycoon-ending']`（未来字段）, **WHEN** `recordRun`, **THEN** 新 stats **仍然保留** `endings` 字段（J-4 fix 验证）。
- **GIVEN** `saveServiceUpdate` 被调用, **WHEN** 检查参数, **THEN** `currentRun: null` 必含（确保 run 结束时清除 in-progress save）。
- **GIVEN** `recordRun` 调用一次, **WHEN** 检查 `saveServiceUpdate` mock, **THEN** **仅调用 1 次**（不变量：一局一次持久化）。
