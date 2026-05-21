/**
 * Career store (S4-2) — bridges CareerProgressionSystem to Vue + auto-wires
 * weekly score accumulation from DayCycleSystem.
 *
 * Module-level wiring:
 *   - Subscribes to dayCycleSystem.onDayEnded to sample energy/mood for
 *     end-of-week averaging.
 *   - Subscribes to dayCycleSystem.onWeekCompleted to call recordWeek().
 *   - Subscribes to runManager.onRunEnded / onJobSelected to reset career
 *     state at run boundaries.
 *
 * Resets are EAGER (at job-select / run-end) so a fresh career always starts
 * at level 1. Persistence of partial career (RunSnapshot.career) is wired in
 * Sprint 5+ resume work.
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { CareerProgressionSystem } from '@/services/career/career-progression-system'
import { dayCycleSystem } from './day-cycle-store'
import { runManager } from './run-store'
import { resourceManager } from './resource-store'
import { getJobById } from '@/config/jobs'
import {
  SALARY_MULTIPLIER_PER_LEVEL,
  getJobLevelTitle,
  type CareerLevel
} from '@/types/career'

const careerProgressionSystem = new CareerProgressionSystem()

// ============== Per-week sampling state (module-private) ==============
// We sample energy + mood at each day end to compute weekly averages, and
// track distinct event ids resolved this week for variety. State is reset
// at week boundary and run boundary.

let energySamples: number[] = []
let moodSamples: number[] = []
let weekEventIds = new Set<string>()
/** J-3 fix: actual choice count per week (separate from unique-id Set). */
let weekChoiceCount = 0

function resetWeekSampling(): void {
  energySamples = []
  moodSamples = []
  weekEventIds = new Set()
  weekChoiceCount = 0
}

function avg(arr: number[]): number {
  if (arr.length === 0) return 0
  let sum = 0
  for (const v of arr) sum += v
  return sum / arr.length
}

// ============== Module-level wiring ==============

dayCycleSystem.onDayEnded.on(() => {
  const r = resourceManager.getResources()
  energySamples.push(r.energy)
  moodSamples.push(r.mood)
})

dayCycleSystem.onWeekCompleted.on(() => {
  const r = resourceManager.getResources()
  careerProgressionSystem.recordWeek({
    endOfWeekMoney: r.money,
    avgEnergy: avg(energySamples),
    avgMood: avg(moodSamples),
    uniqueEventsThisWeek: weekEventIds.size,
    choicesThisWeek: weekChoiceCount,
    // J-3 fix: reviewBonus is applied immediately via applyScoreDelta (so the
    // player sees the score tick right after choosing) — pass 0 here so we
    // don't double-count in the weekly formula.
    reviewBonus: 0
  })
  resetWeekSampling()
})

// Reset at run boundaries
runManager.onJobSelected.on(() => {
  careerProgressionSystem.reset()
  resetWeekSampling()
})
runManager.onRunEnded.on(() => {
  // Don't reset here — settle page may read final level via getSnapshot
  // until next onJobSelected triggers reset.
  resetWeekSampling()
})

/**
 * Public API for S4-3 weekend-review events to push score directly.
 * Wired through choice-resolution-store. J-3 simplified: apply immediately,
 * don't double-count in recordWeek (which now passes 0 for reviewBonus).
 */
export function applyReviewBonus(delta: number): void {
  careerProgressionSystem.applyScoreDelta(delta)
}

/**
 * Test seam — external hook for choice-resolution-store to record event id +
 * increment choice count.
 */
export function recordWeekEvent(eventId: string): void {
  weekEventIds.add(eventId)
  weekChoiceCount += 1  // J-3 fix: count every choice for varietyRatio
}

// ============== Vue store ==============

/**
 * Resolve current title using current job's careerTitles ladder + level.
 * Falls back to generic LEVEL_TITLES via getJobLevelTitle when:
 *   - no current job set
 *   - job has no careerTitles defined
 */
function resolveTitle(level: CareerLevel): string {
  const jobId = runManager.getCurrentJob()
  const job = jobId != null ? getJobById(jobId) : undefined
  return getJobLevelTitle(job?.careerTitles, level)
}

export const useCareerStore = defineStore('career', () => {
  const level = ref<CareerLevel>(careerProgressionSystem.getLevel())
  const score = ref<number>(careerProgressionSystem.getScore())
  const title = ref<string>(resolveTitle(careerProgressionSystem.getLevel()))
  const salaryMul = ref<number>(careerProgressionSystem.getSalaryMultiplier())
  const scoreToNext = ref<number>(careerProgressionSystem.scoreToNextLevel())
  const lastPromotion = ref<{
    toLevel: CareerLevel
    title: string
    fromLevel: CareerLevel
  } | null>(null)

  function refreshFromSystem(): void {
    const lv = careerProgressionSystem.getLevel()
    level.value = lv
    score.value = careerProgressionSystem.getScore()
    title.value = resolveTitle(lv)
    salaryMul.value = careerProgressionSystem.getSalaryMultiplier()
    scoreToNext.value = careerProgressionSystem.scoreToNextLevel()
  }

  careerProgressionSystem.onScoreChanged.on(() => {
    refreshFromSystem()
  })

  careerProgressionSystem.onPromoted.on((event) => {
    refreshFromSystem()
    lastPromotion.value = {
      toLevel: event.toLevel,
      title: resolveTitle(event.toLevel),
      fromLevel: event.fromLevel
    }
  })

  // Reset reactive refs when system resets (job-selected). Also re-resolve
  // title because currentJob just changed.
  runManager.onJobSelected.on(() => {
    refreshFromSystem()
    lastPromotion.value = null
  })

  return {
    level,
    score,
    title,
    salaryMul,
    scoreToNext,
    lastPromotion
  }
})

export { careerProgressionSystem, SALARY_MULTIPLIER_PER_LEVEL }
