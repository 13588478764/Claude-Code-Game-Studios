/**
 * Run store — bridges RunManager to Vue components.
 * Wires production singletons:
 *  - resourceManager.onResourceDepleted → runManager (DYING transition)
 *  - dayCycleSystem.onWeekCompleted → runManager (SETTLING transition)
 *  - statusSystem.subscribeToRunPhase(runManager.onPhaseChanged) (ENDED clears statuses)
 *
 * S2-9 day-cycle wiring is deferred — DayCycleSystem singleton not yet
 * exported from a store; will be done in S2-5 game-main wiring or app init.
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { RunManager } from '@/services/run-manager/run-manager'
import { resourceManager } from './resource-store'
import { statusSystem } from './status-store'
import type { RunPhase, RunResult } from '@/types/run-phase'

const runManager = new RunManager({
  showReviveAd: async () => {
    // MVP: ad SDK not integrated; default to false (decline) until Alpha.
    // S2-5 / Alpha will replace this with real ad SDK call.
    return false
  },
  applyResourceEffects: (effects) => resourceManager.applyEffects(effects),
  clearRunState: () => {
    // MVP: SaveService.clearRunState is not implemented as a discrete method.
    // For Sprint 2 the runState clearing happens via saveStore.clear() in app init
    // when player returns to JOB_SELECT. Hook left here as no-op for now.
  }
})

// Wire upstream subscriptions
runManager.subscribeToResourceDepletion(resourceManager.onResourceDepleted)
// Status system subscribes to phase changes (ENDED triggers clearAll)
statusSystem.subscribeToRunPhase(runManager.onPhaseChanged)

export const useRunStore = defineStore('run', () => {
  const phase = ref<RunPhase>(runManager.getPhase())
  const currentJob = ref<string | null>(runManager.getCurrentJob())
  const lastRunResult = ref<RunResult | null>(null)
  const hasRevived = ref<boolean>(false)

  runManager.onPhaseChanged.on((event) => {
    phase.value = event.to
    hasRevived.value = runManager.hasRevived()
  })
  runManager.onJobSelected.on((event) => {
    currentJob.value = event.jobId
  })
  runManager.onRunEnded.on((result) => {
    lastRunResult.value = result
  })

  function selectJob(jobId: string): void {
    runManager.selectJob(jobId)
  }
  function startPlaying(): void {
    runManager.startPlaying()
  }
  async function requestRevive(): Promise<boolean> {
    return runManager.requestRevive()
  }
  function declineRevive(): void {
    runManager.declineRevive()
  }
  function trackChoice(eventId: string): void {
    runManager.trackChoice(eventId)
  }

  return {
    phase,
    currentJob,
    lastRunResult,
    hasRevived,
    selectJob,
    startPlaying,
    requestRevive,
    declineRevive,
    trackChoice
  }
})

export { runManager }
