/**
 * Event card types — JSON-driven configuration for the event card system.
 */

import type { Effect } from './resource'

export interface BuffSpec {
  id: string
  name: string
  icon: string
  type: 'buff' | 'debuff'
  days: number
  energyMul?: number
  moodMul?: number
}

export interface RiskOutcome {
  text: string
  effects: Effect[]
  buff?: BuffSpec
}

export interface RiskSpec {
  chance: number  // 0-1
  success: RiskOutcome
  fail: RiskOutcome
}

export interface Choice {
  text: string
  icon?: string
  effects: Effect[]
  buff?: BuffSpec
  risk?: RiskSpec
  followUpId?: string
  /**
   * S4-3: weekend-review events can push careerScore directly via this delta.
   * Routed to careerProgressionSystem.applyScoreDelta by choice-resolution-store
   * when present. Omit for non-review events.
   */
  careerScoreDelta?: number
}

export interface EventCard {
  id: string
  text: string
  tags?: string[]
  weight?: number
  conditions?: EventCondition[]
  choiceA: Choice
  choiceB: Choice
}

/**
 * M-1: conditions are evaluated against EventDrawContext at draw time.
 * If ANY condition fails, the card is filtered out of the candidate pool.
 *
 * Supported condition types:
 *   minDay/maxDay         — current day-of-week (1..5)
 *   minWeek/maxWeek       — current week index (1..weeksPerCareer)
 *   minMoney/maxMoney     — money threshold (max for "broke" triggers)
 *   minHealth/maxHealth   — health threshold (max for "frail" triggers)
 *   minCareerLevel/maxCareerLevel — current career level (1..4)
 *   job                   — restrict to a specific job (string value)
 *   hasBuff               — buff/debuff id must be active (string value)
 */
export interface EventCondition {
  type:
    | 'minDay' | 'maxDay'
    | 'minWeek' | 'maxWeek'
    | 'minMoney' | 'maxMoney'
    | 'minHealth' | 'maxHealth'
    | 'minCareerLevel' | 'maxCareerLevel'
    | 'job' | 'hasBuff'
  value: number | string
}

export interface EventDrawContext {
  day?: number
  weekIndex?: number
  money?: number
  health?: number
  careerLevel?: number
  jobId?: string
  activeBuffIds?: string[]
}

export interface EventFilter {
  jobId?: string
  day?: number
  excludeIds?: string[]
  tags?: string[]
  /** M-1: context for evaluating EventCondition entries during pool build. */
  context?: EventDrawContext
}

export interface EventPack {
  jobId: string
  events: EventCard[]
}
