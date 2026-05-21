/**
 * Choice resolution store — wires ChoiceResolutionEngine to the production
 * service singletons (statusSystem / resourceManager) and to EventCardSystem
 * via setResolveHandler.
 *
 * UI does not call resolveChoice directly. The engine is invoked through
 * EventCardSystem.selectChoice → resolveHandler chain set up here.
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { ChoiceResolutionEngine } from '@/services/choice-resolution/choice-resolution-engine'
import { statusSystem, useStatusStore } from './status-store'
import { resourceManager } from './resource-store'
import { eventCardSystem } from './event-card-store'
import { passiveSkillSystem } from './passive-skill-store'
import { itemSystem } from './item-store'
import { applyReviewBonus } from './career-store'
import type { EventCard } from '@/types/event'
import type { ResolveResult } from '@/types/resolve'

interface ChoiceHistoryEntry {
  eventId: string
  choiceKey: 'A' | 'B'
  timestamp: number
}

const choiceHistory: ChoiceHistoryEntry[] = []

const engine = new ChoiceResolutionEngine({
  statusApplyToEffect: (target, raw) => statusSystem.applyToEffect(target, raw),
  statusAddStatus: (status) => statusSystem.addStatus(status),
  resourceApplyEffects: (effects) => resourceManager.applyEffects(effects),
  recordChoice: (eventId, key) => {
    choiceHistory.push({ eventId, choiceKey: key, timestamp: Date.now() })
  },
  // S3-9: passive skills modifier — applied BEFORE status (raw → passive → status).
  passiveApplyToEffect: (target, raw) => passiveSkillSystem.applyToEffect(target, raw),
  // C-1: equipment modifier — applied AFTER passive, BEFORE status
  // (raw → passive → equipment → status → resource).
  equipmentApplyToEffect: (target, raw) => itemSystem.applyToEffect(target, raw)
})

// Wire EventCardSystem to use this engine for resolves
eventCardSystem.setResolveHandler((card, key) => {
  const result = engine.resolveChoice(card, key)
  // Stash the latest result for the store consumers (UI animations, etc.)
  lastResultRef.value = { card, key, result }

  // S4-3: route weekend-review careerScoreDelta to CareerProgressionSystem.
  const choice = key === 'A' ? card.choiceA : card.choiceB
  if (choice.careerScoreDelta != null && choice.careerScoreDelta !== 0) {
    applyReviewBonus(choice.careerScoreDelta)
  }

  // S3-7: attribute chip pulse to the status that caused the modification.
  // Per status-system invariant, only one of buff/debuff has a given Mul
  // (data lint S2-6 enforces this), so attribution is unambiguous.
  for (const delta of result.deltas) {
    if (!delta.wasStatusModified) continue
    if (delta.target !== 'energy' && delta.target !== 'mood') continue
    const field = delta.target === 'energy' ? 'energyMul' : 'moodMul'
    const buff = statusSystem.getBuff()
    const debuff = statusSystem.getDebuff()
    const causingId =
      buff && buff[field] != null
        ? buff.id
        : debuff && debuff[field] != null
          ? debuff.id
          : null
    if (causingId) {
      // Lazy-resolve store on first hit — defineStore returns the same
      // instance on subsequent calls.
      useStatusStore().markModifierTrigger(causingId)
    }
  }
})

const lastResultRef = ref<{ card: EventCard; key: 'A' | 'B'; result: ResolveResult } | null>(null)

export const useChoiceResolutionStore = defineStore('choice-resolution', () => {
  const lastResult = lastResultRef

  function getChoiceHistory(): ReadonlyArray<ChoiceHistoryEntry> {
    return choiceHistory
  }

  return { lastResult, getChoiceHistory }
})

export { engine as choiceResolutionEngine }
