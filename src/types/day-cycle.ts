/**
 * Day cycle types — manages 5-day work week rhythm.
 */

export const DAYS_PER_WEEK = 5
export const EVENTS_PER_DAY: readonly number[] = [2, 3, 3, 4, 4]
// Salaries scale up over the week so finishing matters. Total = 175 (was 70).
// Bumped after first playtest revealed common-pool money events averaging -30
// per choice would tank the player into deep negatives before week-end.
// S4-10: useGameSession scales these by JobConfig.salaryMul × careerLevel
// multiplier. So sales Lv2 effective per-week salary = 175 × 3.0 × 1.5 = 787.5,
// intern Lv1 = 175 × 0.5 × 1.0 = 87.5.
export const DAY_SALARIES: readonly number[] = [20, 25, 30, 40, 60]
export const DAY_NAMES: readonly string[] = ['周一', '周二', '周三', '周四', '周五']

/** Sum of base daily salaries over the week (175 with current values). */
export const TOTAL_WEEK_SALARY: number = DAY_SALARIES.reduce((a, b) => a + b, 0)

/**
 * S4-1: default career length in weeks. A "career" = one full run, was 1 week
 * pre-Sprint 4. Overridable per JobConfig.weeksPerCareer for jobs with
 * different pacing (e.g. intern shorter, banker longer in Sprint 5+).
 */
export const DEFAULT_WEEKS_PER_CAREER = 4

export interface DayProgress {
  day: number       // 1-5 within current week
  weekIndex: number // 1-N
  done: number
  total: number
}
