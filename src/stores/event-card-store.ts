/**
 * Event card store — bridges EventCardSystem to Vue components.
 * See ADR-003.
 *
 * Wires EventDataEngine (S1-4) into EventCardSystem deps. ResolveHandler is
 * late-bound by app initialization (will be set when ChoiceResolutionEngine
 * is constructed in S2-3 setup).
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { EventCardSystem } from '@/services/event-card/event-card-system'
import { eventDataEngine } from './event-data-store'
import type { EventCard } from '@/types/event'
import type { CardDisplayState, QueueStatus } from '@/types/card-phase'

const eventCardSystem = new EventCardSystem({
  drawEvent: (filter) => eventDataEngine.drawEvent(filter),
  getEventById: (id) => eventDataEngine.getEventById(id)
})

export const useEventCardStore = defineStore('event-card', () => {
  const currentCard = ref<CardDisplayState | null>(null)
  const queueStatus = ref<QueueStatus>({ total: 0, completed: 0, remaining: 0 })
  const lastChoiceMade = ref<{ card: EventCard; choiceKey: 'A' | 'B' } | null>(null)

  eventCardSystem.onCardShown.on(() => {
    currentCard.value = eventCardSystem.getCurrentCard()
    queueStatus.value = eventCardSystem.getQueueStatus()
  })
  eventCardSystem.onPhaseChanged.on(() => {
    currentCard.value = eventCardSystem.getCurrentCard()
  })
  eventCardSystem.onChoiceMade.on((event) => {
    lastChoiceMade.value = event
  })
  eventCardSystem.onDayEventsCompleted.on(() => {
    currentCard.value = null
    queueStatus.value = eventCardSystem.getQueueStatus()
  })

  // Actions exposed to UI
  function selectChoice(key: 'A' | 'B'): void {
    eventCardSystem.selectChoice(key)
  }
  function commitResolve(): void {
    eventCardSystem.commitResolve()
  }

  return { currentCard, queueStatus, lastChoiceMade, selectChoice, commitResolve }
})

export { eventCardSystem }
