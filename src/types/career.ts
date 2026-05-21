/**
 * Career progression types (S4-2).
 *
 * Per-run career level + accumulated score. Level rises automatically when
 * score crosses a threshold; persists into SaveData.currentRun so a partial
 * career can resume after app restart (Sprint 5+).
 */

export type CareerLevel = 1 | 2 | 3 | 4

/** Score thresholds for promotion to the NEXT level. Level 1 has no threshold. */
export const PROMOTION_THRESHOLDS: Readonly<Record<CareerLevel, number>> = {
  1: 0,    // starting level
  2: 100,  // promote from 1 → 2 at 100 score
  3: 250,  // promote from 2 → 3 at 250
  4: 500   // promote from 3 → 4 at 500 (cap)
}

/** Salary multiplier applied per career level. Level 1 = 1.0x, level 2 = 1.5x, etc. */
export const SALARY_MULTIPLIER_PER_LEVEL: Readonly<Record<CareerLevel, number>> = {
  1: 1.0,
  2: 1.5,
  3: 2.25,
  4: 3.5
}

/**
 * Generic title fallback shown when a job doesn't define careerTitles
 * (legacy code paths, tests, defensive fallback). Per-job ladders live on
 * JobConfig.careerTitles and are resolved via getJobLevelTitle().
 */
export const LEVEL_TITLES: Readonly<Record<CareerLevel, string>> = {
  1: '初出茅庐',
  2: '小有成就',
  3: '资深骨干',
  4: '行业翘楚'
}

/**
 * Resolve a level → title using the job's per-job careerTitles ladder when
 * available, falling back to the generic LEVEL_TITLES table.
 *
 * Decoupled here (not on CareerProgressionSystem) to keep the service
 * jobId-agnostic — system tracks numbers, presentation knows about jobs.
 */
export function getJobLevelTitle(
  jobLadder: ReadonlyArray<string> | undefined,
  level: CareerLevel
): string {
  if (jobLadder && jobLadder.length >= 4) {
    const idx = level - 1  // 1-based level → 0-based index
    return jobLadder[idx] ?? LEVEL_TITLES[level]
  }
  return LEVEL_TITLES[level]
}

/**
 * One week's worth of inputs to the scoring function. Captured by
 * CareerProgressionSystem at every onWeekCompleted hook.
 */
export interface WeekScoreInputs {
  /** Money remaining at week end. Negative penalized, positive rewarded. */
  endOfWeekMoney: number
  /** Average energy across the week (sampled at each day end). 0-100. */
  avgEnergy: number
  /** Average mood across the week (sampled at each day end). 0-100. */
  avgMood: number
  /** Distinct event ids resolved this week (variety). */
  uniqueEventsThisWeek: number
  /** Total choices made this week. */
  choicesThisWeek: number
  /** Direct careerScore delta from weekend-review events (S4-3). 0 if none yet. */
  reviewBonus: number
}

/** Snapshot of career state — what gets persisted in SaveData.currentRun. */
export interface CareerState {
  level: CareerLevel
  score: number
  weeksWorked: number
}
