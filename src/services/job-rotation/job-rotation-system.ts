/**
 * JobRotationSystem — Roguelike "class" system.
 * Manages job unlocks, recently-played state, and weighted recommendations.
 */

import { TypedEventEmitter } from '../common/event-emitter'
import { JOBS, getJobById } from '@/config/jobs'
import type { JobConfig } from '@/types/job'
import type { GlobalStats, SaveData } from '@/types/save'

const RECENTLY_PLAYED_BUFFER = 3
const WEIGHT_RECENT = 0.1
const WEIGHT_NEVER = 5.0

export class JobRotationSystem {
  private unlocked: Set<string> = new Set()
  private recentlyPlayed: string[] = []  // most recent first
  private played: Set<string> = new Set()  // all jobs ever played

  readonly onJobUnlocked = new TypedEventEmitter<{ jobId: string }>()
  readonly onJobSelected = new TypedEventEmitter<{ jobId: string }>()

  init(saveData: SaveData | null): void {
    this.unlocked = new Set(saveData?.jobUnlocks ?? ['intern', 'programmer'])
    if (saveData) {
      this.played = new Set(Object.keys(saveData.stats.jobsPlayed))
    }
    // recentlyPlayed is session-state; not persisted
    this.recentlyPlayed = []
  }

  getAllJobs(): JobConfig[] {
    return [...JOBS]
  }

  getAvailableJobs(): JobConfig[] {
    return JOBS.filter((j) => this.unlocked.has(j.id))
  }

  getUnlocked(): string[] {
    return Array.from(this.unlocked)
  }

  /**
   * Recommend top-N jobs by weight.
   * Weight rules:
   *   - locked → excluded
   *   - never played → ×5.0 boost
   *   - recently played (within last 3) → ×0.1 nerf
   */
  getRecommendedJobs(count: number): JobConfig[] {
    const candidates = this.getAvailableJobs()
    const scored = candidates.map((j) => ({
      job: j,
      weight: this.computeWeight(j)
    }))
    scored.sort((a, b) => {
      if (b.weight !== a.weight) return b.weight - a.weight
      return Math.random() - 0.5  // tie-break random
    })
    return scored.slice(0, count).map((s) => s.job)
  }

  selectJob(jobId: string): void {
    const job = getJobById(jobId)
    if (!job) throw new Error(`unknown job: ${jobId}`)
    if (!this.unlocked.has(jobId)) throw new Error(`job not unlocked: ${jobId}`)

    this.recentlyPlayed = [
      jobId,
      ...this.recentlyPlayed.filter((id) => id !== jobId)
    ].slice(0, RECENTLY_PLAYED_BUFFER)
    this.played.add(jobId)
    this.onJobSelected.emit({ jobId })
  }

  /**
   * Check if any locked job's unlock condition is now satisfied.
   * Returns the list of newly-unlocked job IDs.
   */
  checkUnlocks(stats: GlobalStats): string[] {
    const newly: string[] = []
    for (const job of JOBS) {
      if (this.unlocked.has(job.id)) continue
      if (!job.unlockCondition) continue
      if (this.satisfies(job.unlockCondition, stats)) {
        this.unlocked.add(job.id)
        newly.push(job.id)
        this.onJobUnlocked.emit({ jobId: job.id })
      }
    }
    return newly
  }

  private computeWeight(job: JobConfig): number {
    let w = job.baseWeight
    if (this.recentlyPlayed.includes(job.id)) w *= WEIGHT_RECENT
    if (!this.played.has(job.id)) w *= WEIGHT_NEVER
    return w
  }

  private satisfies(cond: { type: string; value: number | string }, stats: GlobalStats): boolean {
    switch (cond.type) {
      case 'wins': return stats.totalWins >= (cond.value as number)
      case 'totalMoney': return stats.totalMoneyEarned >= (cond.value as number)
      case 'deaths': return stats.totalDeaths >= (cond.value as number)
      case 'achievement': return stats.achievements.includes(cond.value as string)
      default: return false
    }
  }
}
