/**
 * CareerProgressionSystem (S4-2) — tracks per-run career level + score across
 * multi-week careers (S4-1). Score accumulates at each onWeekCompleted from
 * a weighted combo of (money / avg energy / avg mood / event variety) plus
 * any direct bonus from weekend review events (S4-3 wires this).
 *
 * Pure TS, no Vue/Pinia. RunManager-adjacent — same architectural tier as
 * PassiveSkillSystem (S3-9), wired in via a store at module load.
 */

import { TypedEventEmitter } from '../common/event-emitter'
import {
  PROMOTION_THRESHOLDS,
  SALARY_MULTIPLIER_PER_LEVEL,
  LEVEL_TITLES,
  type CareerLevel,
  type CareerState,
  type WeekScoreInputs
} from '@/types/career'

/**
 * Promotion event payload. Service stays jobId-agnostic — it does NOT include
 * a per-job title; consumers resolve via getJobLevelTitle(job.careerTitles, level)
 * if they need the job-specific copy.
 */
export interface PromotedEvent {
  fromLevel: CareerLevel
  toLevel: CareerLevel
  newSalaryMul: number
}

export interface ScoreChangedEvent {
  delta: number
  totalScore: number
  fromLevel: CareerLevel
}

const STARTING_LEVEL: CareerLevel = 1

export class CareerProgressionSystem {
  private level: CareerLevel = STARTING_LEVEL
  private score = 0
  private weeksWorked = 0

  readonly onPromoted = new TypedEventEmitter<PromotedEvent>()
  readonly onScoreChanged = new TypedEventEmitter<ScoreChangedEvent>()

  /** Reset to starting state. Called by RunManager when a fresh run begins. */
  reset(): void {
    this.level = STARTING_LEVEL
    this.score = 0
    this.weeksWorked = 0
  }

  /** Restore from a save snapshot (Sprint 5+ resume). Caps level to valid range. */
  loadSnapshot(snap: CareerState): void {
    const safeLevel = ([1, 2, 3, 4].includes(snap.level) ? snap.level : 1) as CareerLevel
    this.level = safeLevel
    this.score = Math.max(0, snap.score)
    this.weeksWorked = Math.max(0, snap.weeksWorked)
  }

  /** Tick — compute score for one completed week, accumulate, maybe promote. */
  recordWeek(inputs: WeekScoreInputs): void {
    this.weeksWorked += 1
    const delta = this.computeWeekScore(inputs)
    const before = this.level
    this.score += delta
    this.onScoreChanged.emit({
      delta,
      totalScore: this.score,
      fromLevel: before
    })
    this.checkPromotion(before)
  }

  /**
   * Direct score adjustment — used by weekend review events (S4-3) where the
   * player's choice maps directly to careerScore (e.g. "拼一把" = +30).
   */
  applyScoreDelta(delta: number): void {
    const before = this.level
    this.score = Math.max(0, this.score + delta)
    this.onScoreChanged.emit({
      delta,
      totalScore: this.score,
      fromLevel: before
    })
    this.checkPromotion(before)
  }

  // ============== Query ==============

  getLevel(): CareerLevel {
    return this.level
  }

  getScore(): number {
    return this.score
  }

  getWeeksWorked(): number {
    return this.weeksWorked
  }

  getSnapshot(): CareerState {
    return {
      level: this.level,
      score: this.score,
      weeksWorked: this.weeksWorked
    }
  }

  /** Salary multiplier for the CURRENT level. Used to scale daily salary. */
  getSalaryMultiplier(): number {
    return SALARY_MULTIPLIER_PER_LEVEL[this.level]
  }

  /**
   * Generic fallback title — DOES NOT reflect per-job ladders. UI should
   * use getJobLevelTitle(job.careerTitles, level) from types/career for
   * per-job display.
   */
  getTitle(): string {
    return LEVEL_TITLES[this.level]
  }

  /** How many score points until the NEXT promotion (Infinity at max level). */
  scoreToNextLevel(): number {
    const next = (this.level + 1) as CareerLevel
    const threshold = PROMOTION_THRESHOLDS[next]
    if (threshold == null) return Infinity
    return Math.max(0, threshold - this.score)
  }

  // ============== Internal ==============

  /**
   * Week-score formula. Weights are tuned to make reaching level 2 by week 2-3
   * achievable for an average player and level 3 by career end (week 4)
   * achievable for a strong player. Tuning will iterate post-playtest.
   *
   *   moneyComponent     = clamp(endMoney/100, -1, 2) × 25      [-25 .. +50]
   *   resourceComponent  = ((avgEnergy + avgMood) / 200) × 40   [0 .. +40]
   *   varietyComponent   = min(uniqueEvents / max(choices,1), 1) × 20  [0 .. +20]
   *   reviewBonus        = pass-through                          [-30 .. +30]
   *
   * Theoretical per-week range: ~ -55 .. +140
   * Sustainable average for "doing well": ~ 50-80/week
   * Hitting level 2 (100) takes 1-2 weeks; level 3 (250) takes ~ 3-4.
   */
  computeWeekScore(inputs: WeekScoreInputs): number {
    const moneyComp = clamp(inputs.endOfWeekMoney / 100, -1, 2) * 25
    const resourceComp = ((inputs.avgEnergy + inputs.avgMood) / 200) * 40
    const varietyRatio =
      inputs.choicesThisWeek > 0
        ? Math.min(inputs.uniqueEventsThisWeek / inputs.choicesThisWeek, 1)
        : 0
    const varietyComp = varietyRatio * 20
    const total = moneyComp + resourceComp + varietyComp + inputs.reviewBonus
    return Math.round(total)
  }

  private checkPromotion(before: CareerLevel): void {
    while (this.canPromote()) {
      const next = (this.level + 1) as CareerLevel
      this.level = next
    }
    if (this.level !== before) {
      this.onPromoted.emit({
        fromLevel: before,
        toLevel: this.level,
        newSalaryMul: SALARY_MULTIPLIER_PER_LEVEL[this.level]
      })
    }
  }

  private canPromote(): boolean {
    const next = (this.level + 1) as CareerLevel
    const threshold = PROMOTION_THRESHOLDS[next]
    if (threshold == null) return false
    return this.score >= threshold
  }
}

function clamp(v: number, lo: number, hi: number): number {
  if (v < lo) return lo
  if (v > hi) return hi
  return v
}
