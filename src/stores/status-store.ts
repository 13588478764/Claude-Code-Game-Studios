/**
 * Status store — bridges StatusSystem to Vue components.
 * See ADR-003 (Service emit → Store subscribe).
 *
 * UI components MUST NOT import StatusSystem directly — only via this store.
 * Mutations happen through ChoiceResolutionEngine (S2-3), not here.
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { StatusSystem } from '@/services/status/status-system'
import type { StatusEffect } from '@/types/status'

const statusSystem = new StatusSystem()

export const useStatusStore = defineStore('status', () => {
  const buff = ref<StatusEffect | null>(null)
  const debuff = ref<StatusEffect | null>(null)

  // S3-7: chip pulse trigger. ChoiceResolutionStore writes here whenever a
  // status-modifier was applied to an effect. StatusChip watches this ref
  // and runs a 350ms pulse when its status.id matches.
  const lastModifierTrigger = ref<{ statusId: string; timestamp: number } | null>(null)

  function markModifierTrigger(statusId: string): void {
    lastModifierTrigger.value = { statusId, timestamp: Date.now() }
  }

  statusSystem.onStatusChanged.on(() => {
    buff.value = statusSystem.getBuff()
    debuff.value = statusSystem.getDebuff()
  })

  return { buff, debuff, lastModifierTrigger, markModifierTrigger }
})

export { statusSystem }
