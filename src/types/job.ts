/**
 * Job (career) types — Roguelike "class" system.
 */

export interface JobConfig {
  id: string
  name: string
  icon: string
  description: string
  salaryMul: number  // 0.5 (intern) ~ 3.0 (sales) — NOT YET WIRED, see S4-10
  baseWeight: number  // for recommendation algorithm
  unlockCondition?: UnlockCondition
  eventPack: string  // path to events JSON
  initialEnergy?: number
  initialMood?: number
  /**
   * S4-1: career duration in weeks. A run lasts weeksPerCareer × DAYS_PER_WEEK
   * days. Default DEFAULT_WEEKS_PER_CAREER (4). Different jobs can have
   * different pacing — e.g. intern 2 weeks (quick onboarding), banker 8 weeks
   * (long-term growth) — to be tuned post-playtest.
   */
  weeksPerCareer?: number
  /**
   * S4-2 follow-up: per-job promotion ladder (Lv1 → Lv4).
   * Index 0 = starting title (Lv1), index 3 = Lv4 max.
   * If omitted, falls back to generic LEVEL_TITLES from types/career.ts.
   */
  careerTitles?: [string, string, string, string]
}

export interface UnlockCondition {
  type: 'wins' | 'totalMoney' | 'deaths' | 'achievement'
  value: number | string
}

export interface JobUnlockState {
  unlocked: string[]
  recentlyPlayed: string[]  // last 3 jobs played
  neverPlayed: string[]     // unlocked but never played
}
