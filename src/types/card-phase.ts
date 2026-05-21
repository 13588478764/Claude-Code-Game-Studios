/**
 * Card phase types — fine-grained per-card state for the event card system.
 * Distinct from system-level state (handled internally by EventCardSystem).
 */

import type { EventCard } from './event'

export type CardPhase =
  | 'ENTERING'   // entry animation
  | 'READING'    // text visible, awaiting player attention
  | 'CHOOSING'   // accepting input
  | 'RESOLVING'  // choice made, animating result (await commitResolve)
  | 'FOLLOW_UP'  // transitioning to followUp card
  | 'EXITING'    // exit animation

export interface CardDisplayState {
  card: EventCard
  phase: CardPhase
}

export interface ChoiceMadePayload {
  card: EventCard
  choiceKey: 'A' | 'B'
}

export interface CardPhaseChangedPayload {
  from: CardPhase
  to: CardPhase
}

export interface QueueStatus {
  total: number
  completed: number
  remaining: number
}
