# S3-1: 永久进度系统 service + store

> **Sprint**: 3 | **Status**: Done | **Layer**: Feature (Alpha) | **Type**: Logic | **Owner**: gameplay-programmer | **Estimate**: 1.5 days
> **TR-ID**: pending | **Manifest Version**: N/A

## Quick-Spec（lite design — Alpha GDD 待补，但本故事已含完整设计）

**意图**：在 endRun 时累计跨局 stats（已有 SaveData.stats 结构），并触发 jobRotationSystem.checkUnlocks 解锁新职业。

**架构**：
- 新建 `ProgressionSystem` service（pure TS）
- 订阅 `runManager.onRunEnded` → 处理 RunResult → 更新 stats + 触发 unlock
- 通过 store 持久化（用 saveStore.update）

**核心数据流**：
```
runManager.onRunEnded(RunResult) 
  → progressionSystem.recordRun(result)
    → stats.totalRuns++
    → if won: stats.totalWins++; else stats.totalDeaths++
    → stats.totalMoneyEarned += result.finalMoney
    → stats.jobsPlayed[result.jobId]++
    → saveStore.update({ stats })
    → jobRotationSystem.checkUnlocks(stats) → 新解锁列表
    → for each newly unlocked: emit onJobUnlocked
```

## Context

**ADRs**:
- **ADR-001**（事件通信）— emit onJobUnlocked / onProgressUpdated
- **ADR-003**（Service emit → Store subscribe）— progressionStore 订阅事件

**Engine**: TypeScript strict | **Risk**: LOW

## Acceptance Criteria

- [x] AC-1: `recordRun(result)` 累计 totalRuns += 1（不论输赢）
- [x] AC-2: result.won=true → totalWins += 1
- [x] AC-3: result.won=false → totalDeaths += 1
- [x] AC-4: stats.totalMoneyEarned += result.finalMoney（含负数）
- [x] AC-5: stats.jobsPlayed[result.jobId] += 1（首次游玩则初始化为 1）
- [x] AC-6: 调用 jobRotationSystem.checkUnlocks(stats) → 解锁新职业 → emit onProgressRecorded with newlyUnlocked
- [x] AC-7: saveStore.update 触发持久化
- [x] AC-8: 多次 recordRun 累计正确（idempotent 不要求，但单次调用不重入）
- [x] AC-9: profile/stats 跨局保留：load → recordRun → 重新 load 仍含累计值
- [x] AC-10: 100% 行覆盖

## Implementation Notes

### 文件
- `src/services/progression/progression-system.ts`
- `src/stores/progression-store.ts`
- `tests/unit/progression-system.test.ts`

### 接口
```typescript
class ProgressionSystem {
  constructor(deps: {
    saveServiceUpdate: (patch: Partial<SaveData>) => void
    saveServiceLoad: () => SaveData | null
    checkUnlocks: (stats: GlobalStats) => string[]  // 返回新解锁的 jobIds
  }) {}

  recordRun(result: RunResult): void
  getStats(): GlobalStats

  readonly onProgressUpdated: TypedEventEmitter<{ stats: GlobalStats }>
  readonly onJobUnlocked: TypedEventEmitter<{ jobId: string }>
}
```

### Store
```typescript
// progression-store.ts
const progressionSystem = new ProgressionSystem({
  saveServiceUpdate: (patch) => useSaveStore().update(patch),
  saveServiceLoad: () => saveService.load(),
  checkUnlocks: (stats) => jobSystem.checkUnlocks(stats)
})

// Wire to runManager
runManager.onRunEnded.on((result) => progressionSystem.recordRun(result))
```

## Out of Scope

- **S3-2** 职业选择页：消费 unlocked jobs 但不解锁
- **S3-3** 结算页面：触发 endRun（onRunEnded 后端）
- **S3-9** 被动技能：单独 stub，不在此故事
- **S3-10** 图鉴页：消费 stats 显示，不更新

## QA Test Cases

```
AC-1/2/3: recordRun 累计 totalRuns/Wins/Deaths
- Given: stats={ totalRuns:0, totalWins:0, totalDeaths:0 }
- When: recordRun({won:true, ...})
- Then: stats.totalRuns=1, totalWins=1, totalDeaths=0
- When: recordRun({won:false, ...})
- Then: stats.totalRuns=2, totalWins=1, totalDeaths=1
- Edge: result with finalMoney<0 → totalMoneyEarned 减少（允许）

AC-4: 累计 finalMoney
- Given: stats.totalMoneyEarned=50
- When: recordRun({finalMoney: 30, ...})
- Then: stats.totalMoneyEarned=80
- Edge: finalMoney=-10 → 40

AC-5: jobsPlayed 计数
- Given: stats.jobsPlayed={}
- When: recordRun({jobId: 'programmer', ...})
- Then: jobsPlayed.programmer=1
- When: recordRun({jobId: 'programmer', ...})  // 第二次
- Then: jobsPlayed.programmer=2

AC-6: 解锁触发
- Given: stats.totalWins=0；spy on checkUnlocks 返回 ['sales']（mock 满足条件）
- When: recordRun({won:true, ...}) - 之后 totalWins=1
- Then: checkUnlocks 被调用 1 次；返回的新解锁 jobs 各 emit 一次 onJobUnlocked
- Edge: checkUnlocks 返回空 → 无 emit

AC-7: 持久化
- Given: spy on saveStore.update
- When: recordRun
- Then: update 被调用，patch.stats 含正确 stats

AC-9: 跨局保留（集成）
- Given: storage 有旧 stats={ totalRuns:5 }
- When: progressionSystem 实例化 + load + recordRun
- Then: 重新 load → totalRuns=6
```

## Test Evidence

**Story Type**: Logic
**Required**: `tests/unit/progression-system.test.ts` — pass + 100% 行覆盖
**Status**: [x] Created — 23 tests, all passing

## Dependencies

- 前置: S1-3（SaveService）✓ + S1-10（JobRotationSystem.checkUnlocks）✓ + S2-4（runManager.onRunEnded）✓
- 阻塞: S3-2（职业选择页消费 unlocked）, S3-3（结算页面触发 endRun → 间接触发本故事）, S3-10

## Completion Notes (2026-05-19)

**Files created**:
- `src/services/progression/progression-system.ts` — 87 lines, pure TS service
- `src/stores/progression-store.ts` — defineStore + module-level wiring runManager → progression
- `tests/unit/progression-system.test.ts` — 23 tests across 7 describe blocks

**API delta from spec**:
- Spec showed `onProgressUpdated` + `onJobUnlocked` events. Final API consolidated to single
  `onProgressRecorded({stats, newlyUnlocked: string[]})` event — newly-unlocked jobs returned
  in payload rather than emitted separately. checkUnlocks itself is responsible for emitting
  onJobUnlocked from JobRotationSystem (existing Sprint 1 behavior).

**Architecture**:
- `ProgressionSystem` takes `ProgressionDeps { saveServiceLoad, saveServiceUpdate, checkUnlocks }`
  for full DI testability — no direct store/module imports inside the service.
- Store-level wiring lives in `progression-store.ts` (module load-time hook on
  `runManager.onRunEnded`).
- Empty-stats default applied when saveServiceLoad returns null (fresh install path).
- Default jobUnlocks `['intern', 'programmer']` applied when null save.

**Coverage**: 100% lines / 100% branches / 100% functions on
`src/services/progression/progression-system.ts` (verified via isolated vitest run).

**Type-check**: `npm run type-check` passes clean.

**Test counts**: 302/302 project total (23 new + 279 sprint 1+2 retained, all passing).
