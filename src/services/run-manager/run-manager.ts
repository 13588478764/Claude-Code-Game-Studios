/**
 * RunManager — orchestrates the lifecycle of a single play session.
 *
 * State machine (6 phases):
 *   JOB_SELECT → INITIALIZING → PLAYING
 *                   ↓               ↓ (onResourceDepleted)
 *                   ↓             DYING
 *                   ↓               ↓
 *                   ↓        ┌──────┴───────┐
 *                   ↓        ↓               ↓
 *                   ↓     PLAYING        SETTLING
 *                   ↓     (revived)         ↓
 *                   ↓        ↑           ENDED
 *                   ↓        │              ↓
 *                   ↓        │       JOB_SELECT (next run)
 *                   ↓ (onWeekCompleted from PLAYING)
 *                SETTLING (won)
 *
 * Architecture (per ADR-001 + ADR-003):
 *  - Pure TS service, no Vue/Pinia imports
 *  - Communicates via TypedEventEmitter
 *  - Subscribes to upstream emitters (resourceManager, dayCycleSystem) via
 *    subscribeTo* methods — abstract emitter signatures keep RunManager
 *    decoupled from concrete services
 *  - StatusSystem subscribes to onPhaseChanged downstream to clear on ENDED
 *
 * Single-revive policy (per run-manager.md): revivedThisRun flag prevents
 * a second revive in the same run. Second resource depletion auto-declines.
 */

import { TypedEventEmitter } from '../common/event-emitter'
import type { Effect } from '@/types/resource'
import type {
  RunPhase,
  PhaseChangedPayload,
  RunRating,
  RatingContext,
  RunResult,
  DepletionSource,
  JobInfo
} from '@/types/run-phase'

const DEFAULT_REVIVE_AMOUNT = 50

export interface RunManagerDeps {
  /** Show revive ad. Returns true on success. */
  showReviveAd: () => Promise<boolean>
  /** Apply revive effect to resources (e.g. +50 energy). Optional for tests. */
  applyResourceEffects?: (effects: Effect[]) => void
  /** Clear runState in save (called on ENDED transition). Optional for tests. */
  clearRunState?: () => void
  /** Override the default 50 energy/mood revive restoration. */
  reviveAmount?: number
}

/** Resource-depleted payload shape that RunManager subscribes to. */
export interface ResourceDepletedPayload {
  which: DepletionSource
}

export class RunManager {
  private phase: RunPhase = 'JOB_SELECT'
  private currentJobId: string | null = null
  private revivedThisRun = false
  private depletionSource: DepletionSource | null = null
  private totalChoices = 0
  private uniqueEventIds = new Set<string>()

  readonly onPhaseChanged = new TypedEventEmitter<PhaseChangedPayload>()
  readonly onRunEnded = new TypedEventEmitter<RunResult>()
  readonly onJobSelected = new TypedEventEmitter<{ jobId: string }>()

  constructor(private deps: RunManagerDeps) {}

  // ============== Subscriptions ==============

  subscribeToResourceDepletion(
    emitter: TypedEventEmitter<ResourceDepletedPayload>
  ): void {
    emitter.on(({ which }) => {
      // Only react during PLAYING; ignore depletions during DYING/SETTLING
      // (e.g. revive flow shouldn't re-trigger DYING).
      if (this.phase !== 'PLAYING') return
      this.depletionSource = which
      // G-2: health depletion is fatal — skip DYING (no revive offered) and
      // go straight to SETTLING. Energy/mood depletion still routes through
      // DYING for the revive prompt.
      if (which === 'health') {
        this.transitionTo('SETTLING')
      } else {
        this.transitionTo('DYING')
      }
    })
  }

  /**
   * S4-1: Replaced subscribeToWeekCompleted with subscribeToCareerCompleted.
   * Pre-S4-1, "career = 1 week" so the SETTLING trigger fired at week-end.
   * Now a career spans multiple weeks (JobConfig.weeksPerCareer) and SETTLING
   * fires only at career-end. Weekly hooks (review events, status tick) stay
   * on onDayEnded / onWeekCompleted in useGameSession.
   */
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  subscribeToCareerCompleted(emitter: TypedEventEmitter<any>): void {
    emitter.on(() => {
      // Only react during PLAYING. Same-frame death + career completion case:
      // resourceDepleted fires first → phase becomes DYING → this listener
      // sees phase != PLAYING → ignores. Death wins.
      if (this.phase === 'PLAYING') {
        this.transitionTo('SETTLING')
      }
    })
  }

  // ============== Phase transitions ==============

  selectJob(jobId: string): void {
    if (this.phase !== 'JOB_SELECT') return
    this.currentJobId = jobId
    this.onJobSelected.emit({ jobId })
    this.transitionTo('INITIALIZING')
  }

  /** Called after job-specific initialization (resource init, event load) completes. */
  startPlaying(): void {
    if (this.phase !== 'INITIALIZING') return
    this.revivedThisRun = false
    this.depletionSource = null
    this.totalChoices = 0
    this.uniqueEventIds.clear()
    this.transitionTo('PLAYING')
  }

  async requestRevive(): Promise<boolean> {
    if (this.phase !== 'DYING') return false
    if (this.revivedThisRun) {
      // No second revive — auto-decline (AC-10)
      this.transitionTo('SETTLING')
      return false
    }

    const adSuccess = await this.deps.showReviveAd()
    if (!adSuccess) {
      this.transitionTo('SETTLING')
      return false
    }

    // Restore the depleted resource (default 50)
    if (this.deps.applyResourceEffects && this.depletionSource) {
      const amount = this.deps.reviveAmount ?? DEFAULT_REVIVE_AMOUNT
      this.deps.applyResourceEffects([
        { target: this.depletionSource, value: amount }
      ])
    }
    this.revivedThisRun = true
    this.depletionSource = null
    this.transitionTo('PLAYING')
    return true
  }

  declineRevive(): void {
    if (this.phase !== 'DYING') return
    this.transitionTo('SETTLING')
  }

  /**
   * Settle the run and produce a RunResult. Transitions SETTLING → ENDED → JOB_SELECT.
   * Emits onRunEnded with the result, then triggers downstream cleanup
   * (statusSystem.clearAll via onPhaseChanged subscription, clearRunState via deps).
   */
  endRun(ctx: RatingContext, jobInfo: JobInfo): RunResult {
    if (this.phase !== 'SETTLING') {
      throw new Error(`endRun called in invalid phase: ${this.phase}`)
    }
    const won = ctx.survivalDays >= ctx.totalDays
    const rating = this.computeRating(ctx)
    const result: RunResult = {
      jobId: jobInfo.jobId,
      jobName: jobInfo.jobName,
      won,
      survivalDays: ctx.survivalDays,
      totalDays: ctx.totalDays,
      finalMoney: ctx.finalMoney,
      totalChoices: ctx.totalChoices,
      uniqueChoices: ctx.uniqueChoices,
      rating,
      ratingLabel: ratingLabel(rating),
      endedAt: Date.now()
    }
    // ENDED phase first — statusSystem clears via onPhaseChanged subscription
    this.transitionTo('ENDED')
    this.onRunEnded.emit(result)
    // Persist cleanup
    this.deps.clearRunState?.()
    // Auto-transition back to JOB_SELECT for next run
    this.transitionTo('JOB_SELECT')
    return result
  }

  computeRating(ctx: RatingContext): RunRating {
    // Per run-manager.md formula:
    //   rating = (survivalDays / totalDays) × 0.4
    //          + (money / expectedMoney) × 0.3
    //          + (variety / totalChoices) × 0.3
    const survivalRatio = ctx.totalDays > 0 ? ctx.survivalDays / ctx.totalDays : 0
    const moneyRatio = ctx.expectedMoney > 0 ? ctx.finalMoney / ctx.expectedMoney : 0
    const varietyRatio = ctx.totalChoices > 0 ? ctx.uniqueChoices / ctx.totalChoices : 0
    const score =
      clamp01(survivalRatio) * 0.4 +
      clamp01(moneyRatio) * 0.3 +
      clamp01(varietyRatio) * 0.3
    if (score >= 0.9) return 'S'
    if (score >= 0.7) return 'A'
    if (score >= 0.5) return 'B'
    if (score >= 0.3) return 'C'
    return 'D'
  }

  // ============== Choice tracking ==============

  /** Called externally (typically from ChoiceResolutionEngine wiring) per choice. */
  trackChoice(eventId: string): void {
    if (this.phase !== 'PLAYING') return
    this.totalChoices += 1
    this.uniqueEventIds.add(eventId)
  }

  // ============== Query ==============

  getPhase(): RunPhase {
    return this.phase
  }

  getCurrentJob(): string | null {
    return this.currentJobId
  }

  getRunStats(): { totalChoices: number; uniqueChoices: number } {
    return {
      totalChoices: this.totalChoices,
      uniqueChoices: this.uniqueEventIds.size
    }
  }

  hasRevived(): boolean {
    return this.revivedThisRun
  }

  // ============== Internal ==============

  private transitionTo(to: RunPhase): void {
    if (this.phase === to) return
    const from = this.phase
    this.phase = to
    this.onPhaseChanged.emit({ from, to })
  }
}

function clamp01(x: number): number {
  if (x < 0) return 0
  if (x > 1) return 1
  return x
}

function ratingLabel(rating: RunRating): string {
  // Map keyed lookup — 100% branch coverage friendly + exhaustive over RunRating.
  const labels: Record<RunRating, string> = {
    S: '卷王',
    A: '打工达人',
    B: '勉强混过',
    C: '摸鱼被抓',
    D: '第一天就寄了'
  }
  return labels[rating]
}
