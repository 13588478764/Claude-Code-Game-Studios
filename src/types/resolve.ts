/**
 * Choice resolution result types.
 *
 * Distinct from ResourceManager's internal ResourceDelta to add status-modifier
 * tracking — Sprint 1's `wasModified` means "was clamped at boundary"; we add
 * `wasStatusModified` for the separate concept of "status mul applied upstream".
 * (Per status-system.md v2.1 evaluator note #9 — disambiguate the two meanings.)
 */

import type { ResourceTarget, ResourceState } from './resource'

export interface ResolveDelta {
  target: ResourceTarget
  before: number
  after: number
  /** Final clamped change applied to the resource */
  delta: number
  /** Sum of original (pre-status) effect values for this target */
  rawDelta: number
  /** ResourceManager clamped the value at 0/MAX boundary */
  wasClamped: boolean
  /** statusSystem.applyToEffect modified at least one input effect for this target */
  wasStatusModified: boolean
}

export type RiskOutcome = 'success' | 'fail'

export interface ResolveResult {
  /** Text shown for the chosen option (for "you chose X" display) */
  choiceText: string
  /** One ResolveDelta per resource that changed */
  deltas: ResolveDelta[]
  /** New state if state machine transitioned, undefined if no transition */
  stateChange?: ResourceState
  /** Carried from choice — EventCardSystem advances to this card next */
  followUpId?: string
  /** Set when choice had a `risk` field — outcome of the dice roll */
  riskOutcome?: RiskOutcome
}
