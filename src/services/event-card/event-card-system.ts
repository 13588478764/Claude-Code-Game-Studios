/**
 * EventCardSystem — manages the per-day card queue, phase transitions, and
 * followUp chain. See `design/gdd/event-card.md` for the full design.
 *
 * Architecture (per ADR-001 + ADR-003):
 *  - Pure TS service, no Vue/Pinia imports
 *  - Communicates via TypedEventEmitter
 *  - Dependencies injected at construction (drawEvent, getEventById,
 *    notifyEventCompleted) so tests inject mocks and production wires real
 *    EventDataEngine + DayCycleSystem
 *  - Resolve handler set via setResolveHandler() — late-bound because
 *    ChoiceResolutionEngine (S2-3) is constructed after this system
 *
 * Two-phase resolve protocol:
 *  1. selectChoice(key) — marks RESOLVING, calls resolveHandler, stays in
 *     RESOLVING until commitResolve is called by UI (after animation)
 *  2. commitResolve() — advances to followUp or next queue card
 *
 * This guarantees AC-5: re-entrant selectChoice calls during the resolve
 * animation window are ignored.
 */

import { TypedEventEmitter } from '../common/event-emitter'
import type { Choice, EventCard, EventFilter } from '@/types/event'
import type {
  CardDisplayState,
  CardPhase,
  CardPhaseChangedPayload,
  ChoiceMadePayload,
  QueueStatus
} from '@/types/card-phase'

const MAX_FOLLOWUP_DEPTH = 3
const FALLBACK_TEXT = '今天平平无奇地过去了…'
const FALLBACK_CHOICE_TEXT = '继续'

export type ResolveHandler = (card: EventCard, key: 'A' | 'B') => void

export interface EventCardSystemDeps {
  drawEvent: (filter?: EventFilter) => EventCard
  getEventById: (id: string) => EventCard | null
  /** Optional: called when day events fully complete (wires DayCycleSystem) */
  notifyEventCompleted?: () => void
}

export class EventCardSystem {
  private queue: EventCard[] = []
  private currentCard: EventCard | null = null
  private currentPhase: CardPhase = 'READING'
  private completedToday = 0
  private totalToday = 0
  private followUpDepth = 0
  private isResolving = false
  private lastChoiceKey: 'A' | 'B' | null = null
  private resolveHandler: ResolveHandler | null = null

  readonly onCardShown = new TypedEventEmitter<EventCard>()
  readonly onChoiceMade = new TypedEventEmitter<ChoiceMadePayload>()
  readonly onDayEventsCompleted = new TypedEventEmitter<void>()
  readonly onPhaseChanged = new TypedEventEmitter<CardPhaseChangedPayload>()
  /**
   * Emitted whenever a queue card (NOT a followUp card) finishes resolving.
   * Production wiring: subscribers call DayCycleSystem.eventCompleted() to
   * drive the day-end / week-completed natural emit chain. (S2-5 addition)
   */
  readonly onQueueCardAdvanced = new TypedEventEmitter<void>()

  constructor(private deps: EventCardSystemDeps) {}

  /** Late-bind the resolve handler — ChoiceResolutionEngine is constructed after this. */
  setResolveHandler(handler: ResolveHandler): void {
    this.resolveHandler = handler
  }

  // ============== Day flow ==============

  /**
   * Prepare the queue for a new day. Draws `eventsCount` cards from EventDataEngine
   * via injected deps and shows the first card.
   * If eventsCount=0, immediately emits onDayEventsCompleted.
   */
  prepareDay(_day: number, eventsCount: number, filter?: EventFilter): void {
    this.queue = []
    this.completedToday = 0
    this.totalToday = eventsCount
    this.followUpDepth = 0
    this.isResolving = false
    this.lastChoiceKey = null
    this.currentCard = null

    if (eventsCount <= 0) {
      this.onDayEventsCompleted.emit()
      return
    }

    for (let i = 0; i < eventsCount; i++) {
      this.queue.push(this.deps.drawEvent(filter))
    }
    this.advanceToNextQueueCard()
  }

  /**
   * S4-3: replace the LAST queued card with a draw matching `tags`.
   * Used to force a weekend-review event at the end of week-5 days. Falls
   * back silently to the original draw if no matching tag is found in the
   * pool (drawEvent already handles empty matches via fallback events).
   *
   * Must be called BEFORE the first eventCompleted of the day, i.e. while
   * the queue is still queue.length === totalToday. Idempotent only on the
   * tail slot.
   */
  swapLastQueueCard(tags: string[]): void {
    if (this.queue.length === 0) return
    if (tags.length === 0) return
    const newCard = this.deps.drawEvent({ tags })
    // Replace the LAST queued card (or the current card if queue advanced).
    if (this.queue.length > 0) {
      this.queue[this.queue.length - 1] = newCard
    }
  }

  /**
   * Player choice. Synchronous: calls resolveHandler immediately.
   * UI must call commitResolve() after the resolve animation to advance.
   *
   * Re-entrant calls during RESOLVING are ignored (AC-5: 防连点).
   */
  selectChoice(key: 'A' | 'B'): void {
    if (this.isResolving) return
    if (!this.currentCard) return
    if (this.currentPhase === 'EXITING' || this.currentPhase === 'RESOLVING') return
    if (!this.resolveHandler) {
      console.warn('[EventCardSystem] selectChoice called but no resolveHandler set')
      return
    }

    this.isResolving = true
    this.lastChoiceKey = key
    this.setPhase('RESOLVING')
    this.onChoiceMade.emit({ card: this.currentCard, choiceKey: key })
    this.resolveHandler(this.currentCard, key)
  }

  /**
   * Called by UI after resolve animation completes. Advances to followUp
   * or next queue card; emits onDayEventsCompleted if day is done.
   */
  commitResolve(): void {
    if (!this.isResolving || !this.currentCard || !this.lastChoiceKey) return

    const choice =
      this.lastChoiceKey === 'A' ? this.currentCard.choiceA : this.currentCard.choiceB
    this.lastChoiceKey = null
    this.isResolving = false
    this.advanceAfterResolve(choice)
  }

  // ============== Query ==============

  getCurrentCard(): CardDisplayState | null {
    if (!this.currentCard) return null
    return { card: this.currentCard, phase: this.currentPhase }
  }

  getQueueStatus(): QueueStatus {
    return {
      total: this.totalToday,
      completed: this.completedToday,
      remaining: Math.max(0, this.totalToday - this.completedToday)
    }
  }

  reset(): void {
    this.queue = []
    this.currentCard = null
    this.currentPhase = 'READING'
    this.completedToday = 0
    this.totalToday = 0
    this.followUpDepth = 0
    this.isResolving = false
    this.lastChoiceKey = null
  }

  // ============== Internal ==============

  private advanceAfterResolve(choice: Choice): void {
    // followUp branch
    if (choice.followUpId) {
      if (this.followUpDepth < MAX_FOLLOWUP_DEPTH) {
        const followUp = this.deps.getEventById(choice.followUpId)
        if (followUp) {
          this.followUpDepth += 1
          this.showCard(followUp, 'FOLLOW_UP')
          return
        }
        console.warn(
          `[EventCardSystem] followUpId="${choice.followUpId}" not found, skipping`
        )
        // fall through to advance via queue
      }
      // depth exhausted — also fall through to queue
    }

    // No followUp (or skipped) — advance via queue
    // Emit BEFORE incrementing so listeners can observe the per-event signal.
    this.onQueueCardAdvanced.emit()
    this.completedToday += 1
    this.followUpDepth = 0

    if (this.completedToday >= this.totalToday) {
      this.currentCard = null
      this.onDayEventsCompleted.emit()
      this.deps.notifyEventCompleted?.()
      return
    }
    this.advanceToNextQueueCard()
  }

  private advanceToNextQueueCard(): void {
    // Invariant: only called when queue has at least one card.
    // Guarded by advanceAfterResolve's day-end check (completedToday >= totalToday)
    // and prepareDay's eventsCount > 0 path.
    const next = this.queue.shift()!
    this.showCard(next, 'ENTERING')
  }

  /**
   * Show a card. Normalizes empty text to fallback (AC-9), runs the
   * ENTERING → READING → CHOOSING transitions, and emits onCardShown.
   */
  private showCard(card: EventCard, entryPhase: 'ENTERING' | 'FOLLOW_UP'): void {
    this.currentCard = this.normalizeCard(card)
    this.setPhase(entryPhase)
    this.onCardShown.emit(this.currentCard)
    // For implementation simplicity, transition to interactive state.
    // UI animations are decorative; the data state machine snaps forward.
    this.setPhase('READING')
    this.setPhase('CHOOSING')
  }

  private normalizeCard(card: EventCard): EventCard {
    if (card.text && card.text.trim() !== '') return card
    return {
      ...card,
      text: FALLBACK_TEXT,
      choiceA: { ...card.choiceA, text: card.choiceA.text || FALLBACK_CHOICE_TEXT },
      choiceB: { ...card.choiceB, text: card.choiceB.text || FALLBACK_CHOICE_TEXT }
    }
  }

  private setPhase(phase: CardPhase): void {
    if (this.currentPhase === phase) return
    const from = this.currentPhase
    this.currentPhase = phase
    this.onPhaseChanged.emit({ from, to: phase })
  }
}
