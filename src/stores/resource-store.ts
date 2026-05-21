/**
 * Resource store — bridges ResourceManager (pure TS) to Vue reactivity.
 * See ADR-003: Service emit → Store subscribe.
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { ResourceManager } from '@/services/resource/resource-manager'
import type {
  Effect,
  Resources,
  ResourceState,
  ApplyResult,
  ResourceDelta
} from '@/types/resource'

// Singleton service instance
const resourceManager = new ResourceManager()

export const useResourceStore = defineStore('resource', () => {
  const resources = ref<Resources>({ ...resourceManager.getResources() })
  const state = ref<ResourceState>(resourceManager.getState())

  // S3-8: most recent change. UI watches this to spawn floating delta visuals.
  // Each emission carries timestamp so consumers can debounce / dedupe.
  const lastResourceChange = ref<{
    deltas: ResourceDelta[]
    timestamp: number
  } | null>(null)

  // Subscribe to service events
  resourceManager.onResourceChanged.on((event) => {
    resources.value = { ...event.after }
    lastResourceChange.value = {
      deltas: event.deltas,
      timestamp: Date.now()
    }
  })
  resourceManager.onStateChanged.on((event) => {
    state.value = event.to
  })

  function applyEffects(effects: Effect[]): ApplyResult {
    return resourceManager.applyEffects(effects)
  }

  function reset(): void {
    resourceManager.reset()
    resources.value = { ...resourceManager.getResources() }
    state.value = resourceManager.getState()
  }

  function init(initial?: Partial<Resources>): void {
    resourceManager.init(initial)
    resources.value = { ...resourceManager.getResources() }
    state.value = resourceManager.getState()
  }

  return { resources, state, lastResourceChange, applyEffects, reset, init }
})

export { resourceManager }
