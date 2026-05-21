/**
 * Run phase types — full definition (S2-4 extension of S2-1's minimal stub).
 * StatusSystem subscribes to phase changes via subscribeToRunPhase to clear
 * statuses on ENDED.
 */

export type RunPhase =
  | 'JOB_SELECT'
  | 'INITIALIZING'
  | 'PLAYING'
  | 'DYING'
  | 'SETTLING'
  | 'ENDED'

export interface PhaseChangedPayload {
  from: RunPhase
  to: RunPhase
}

export type RunRating = 'S' | 'A' | 'B' | 'C' | 'D'

/** Inputs needed to compute rating — supplied by caller (e.g. RunStore wiring) */
export interface RatingContext {
  survivalDays: number    // days actually survived (1-N)
  totalDays: number        // expected total days (e.g. 5 for programmer)
  finalMoney: number       // resourceManager.money at end of run
  expectedMoney: number    // sum of expected daily salaries for the job
  totalChoices: number     // count of selectChoice calls during the run
  uniqueChoices: number    // distinct event ids the player encountered
}

export interface RunResult {
  jobId: string
  jobName: string
  won: boolean
  survivalDays: number
  totalDays: number
  finalMoney: number
  totalChoices: number
  uniqueChoices: number
  rating: RunRating
  ratingLabel: string  // "卷王" / "打工达人" / etc.
  endedAt: number
}

export type DepletionSource = 'energy' | 'mood' | 'health'

export interface JobInfo {
  jobId: string
  jobName: string
}
