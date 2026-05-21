/**
 * Status effect types — runtime status state held by StatusSystem.
 * Distinct from event.ts BuffSpec which is the JSON config shape (uses `days` for
 * initial duration). StatusEffect uses `daysLeft` for current remaining duration.
 * ChoiceResolutionEngine converts BuffSpec → StatusEffect at the addStatus boundary.
 */

export type StatusType = 'buff' | 'debuff'
export type StatusModifierTarget = 'energy' | 'mood'
export type StatusSlot = 'buff' | 'debuff'

export interface StatusEffect {
  id: string
  name: string
  icon: string
  type: StatusType
  daysLeft: number
  energyMul?: number
  moodMul?: number
  /** source event id — for stats/achievements only, never affects logic */
  source?: string
}

export interface StatusReplacedEvent {
  slot: StatusSlot
  old: StatusEffect
  new: StatusEffect
}

export interface StatusRefreshedEvent {
  id: string
  oldDays: number
  newDays: number
}

export interface StatusLoadCorrectedEvent {
  dropped: StatusEffect[]
}
