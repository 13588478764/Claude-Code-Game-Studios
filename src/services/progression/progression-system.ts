/**
 * ProgressionSystem — orchestrates run-end side effects:
 *   1. Accumulates GlobalStats (totalRuns/Wins/Deaths/Money/jobsPlayed)
 *   2. Calls jobRotationSystem.checkUnlocks → discovers newly-unlocked jobs
 *   3. Persists new stats + appended jobUnlocks via saveService
 *   4. Emits onProgressRecorded for store consumers
 *
 * Architecture (per ADR-001 + ADR-003):
 *  - Pure TS service, no Vue/Pinia imports
 *  - Communicates via TypedEventEmitter
 *  - DI via deps so tests inject mocks; production wires real saveService + jobSystem
 *
 * Note: jobRotationSystem.checkUnlocks emits its own onJobUnlocked internally —
 * this system does NOT re-emit to avoid duplicates. Consumers wanting unlock
 * notifications subscribe to jobSystem.onJobUnlocked directly.
 */

import { TypedEventEmitter } from '../common/event-emitter'
import type { GlobalStats, SaveData } from '@/types/save'
import type { RunResult } from '@/types/run-phase'

export interface ProgressionDeps {
  /** Read current SaveData (may return null on fresh install) */
  saveServiceLoad: () => SaveData | null
  /** Persist a partial patch (merged with current save) */
  saveServiceUpdate: (patch: Partial<SaveData>) => void
  /** Check which jobs newly unlock given the new stats */
  checkUnlocks: (stats: GlobalStats) => string[]
}

export interface ProgressRecordedEvent {
  stats: GlobalStats
  newlyUnlocked: string[]
}

export class ProgressionSystem {
  readonly onProgressRecorded = new TypedEventEmitter<ProgressRecordedEvent>()

  constructor(private deps: ProgressionDeps) {}

  /**
   * Record the result of a completed run. Accumulates stats, checks for newly
   * unlocked jobs, and persists everything in one save call.
   */
  recordRun(result: RunResult): void {
    const currentSave = this.deps.saveServiceLoad()
    const currentStats = currentSave?.stats ?? emptyStats()

    // J-4 fix: spread currentStats FIRST so optional fields (endings, future
    // additions) carry through. The named overrides below win for the fields
    // this system manages.
    const newStats: GlobalStats = {
      ...currentStats,
      totalRuns: currentStats.totalRuns + 1,
      totalWins: currentStats.totalWins + (result.won ? 1 : 0),
      totalDeaths: currentStats.totalDeaths + (result.won ? 0 : 1),
      totalMoneyEarned: currentStats.totalMoneyEarned + result.finalMoney,
      jobsPlayed: {
        ...currentStats.jobsPlayed,
        [result.jobId]: (currentStats.jobsPlayed[result.jobId] ?? 0) + 1
      },
      achievements: [...currentStats.achievements]
    }

    // checkUnlocks may mutate jobRotationSystem.unlocked AND emit its own
    // onJobUnlocked (per S1-10). We collect the returned list to update jobUnlocks.
    const newlyUnlocked = this.deps.checkUnlocks(newStats)

    const currentJobUnlocks = currentSave?.jobUnlocks ?? ['intern', 'programmer']
    const newJobUnlocks = [...currentJobUnlocks, ...newlyUnlocked]

    this.deps.saveServiceUpdate({
      stats: newStats,
      jobUnlocks: newJobUnlocks,
      currentRun: null
    })

    this.onProgressRecorded.emit({ stats: newStats, newlyUnlocked })
  }

  getStats(): GlobalStats {
    return this.deps.saveServiceLoad()?.stats ?? emptyStats()
  }
}

function emptyStats(): GlobalStats {
  return {
    totalRuns: 0,
    totalWins: 0,
    totalDeaths: 0,
    totalMoneyEarned: 0,
    jobsPlayed: {},
    achievements: []
  }
}
