/**
 * Ending store (G-3) — bridges EndingSystem to Vue + auto-wires run-end resolution.
 *
 * Module-level wiring:
 *   - init from saveService.load()?.stats.endings
 *   - subscribe runManager.onRunEnded → resolve ending → write back to save
 *   - lastEnding ref exposed for settle page to display
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { EndingSystem } from '@/services/ending/ending-system'
import { runManager } from './run-store'
import { useCareerStore } from './career-store'
import { resourceManager } from './resource-store'
import { saveService } from './save-store'
import { getEndingById, type Ending } from '@/types/ending'
import type { DepletionSource } from '@/types/run-phase'

const endingSystem = new EndingSystem()
endingSystem.init(saveService.load()?.stats.endings ?? [])

// Track which resource was depleted during this run — set by listening to
// onResourceDepleted on the manager via the existing run-manager subscription.
let lastDepletionSource: DepletionSource | null = null

resourceManager.onResourceDepleted.on(({ which }) => {
  lastDepletionSource = which
})
runManager.onJobSelected.on(() => {
  lastDepletionSource = null  // reset at run start
})

// Wire run-end → resolve ending → persist
runManager.onRunEnded.on((result) => {
  // careerStore exposes current level — but careerProgressionSystem may have
  // reset by now. Use the careerStore reactive ref state at this instant.
  // Lazy-resolve store on first hit (Pinia singleton).
  const careerStore = useCareerStore()
  const level = careerStore.level
  const ending = endingSystem.recordEnding({
    result,
    finalCareerLevel: level,
    depletionSource: lastDepletionSource
  })
  // Persist unlocked endings list back to save.
  const cur = saveService.load()
  if (cur) {
    const merged = Array.from(
      new Set([...(cur.stats.endings ?? []), ending.id])
    )
    saveService.save({
      ...cur,
      stats: { ...cur.stats, endings: merged }
    })
  }
})

export const useEndingStore = defineStore('ending', () => {
  const unlockedIds = ref<string[]>(endingSystem.getUnlocked())
  const lastEnding = ref<Ending | null>(null)
  /** H-4: whether the most recent ending was first-time unlock (for "新结局" toast). */
  const lastIsFirstTime = ref<boolean>(false)

  endingSystem.onRunEnded.on(({ ending }) => {
    lastEnding.value = ending
  })
  endingSystem.onEndingUnlocked.on(({ endingId, isFirstTime }) => {
    unlockedIds.value = endingSystem.getUnlocked()
    lastIsFirstTime.value = isFirstTime
    void getEndingById(endingId)  // touch — keeps import meaningful
  })

  // Clear lastEnding + first-time flag on new job-select
  runManager.onJobSelected.on(() => {
    lastEnding.value = null
    lastIsFirstTime.value = false
  })

  return { unlockedIds, lastEnding, lastIsFirstTime }
})

export { endingSystem }
