/**
 * Achievement store (C-2) — bridges AchievementSystem to Vue + auto-wires
 * progression-driven unlock checks.
 *
 * Mirror of passive-skill-store wiring:
 *   - init from saveService.load()?.stats.achievements
 *   - subscribe progressionSystem.onProgressRecorded → checkUnlocks(newStats)
 *   - write newly-unlocked back into save via direct saveService access
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { AchievementSystem } from '@/services/achievement/achievement-system'
import { progressionSystem } from './progression-store'
import { saveService } from './save-store'
import { getAchievementById, type Achievement } from '@/types/achievement'

const achievementSystem = new AchievementSystem()
achievementSystem.init(saveService.load()?.stats.achievements ?? [])

// Module-level wiring — run-end → progression updates stats → check unlocks
progressionSystem.onProgressRecorded.on((event) => {
  const newly = achievementSystem.checkUnlocks(event.stats)
  if (newly.length === 0) return
  const cur = saveService.load()
  if (!cur) return
  const merged = Array.from(
    new Set([...(cur.stats.achievements ?? []), ...newly])
  )
  saveService.save({
    ...cur,
    stats: { ...cur.stats, achievements: merged }
  })
})

export const useAchievementStore = defineStore('achievement', () => {
  const unlockedIds = ref<string[]>(achievementSystem.getUnlocked())
  const recentlyUnlocked = ref<Achievement | null>(null)

  achievementSystem.onAchievementUnlocked.on(({ achievementId }) => {
    unlockedIds.value = achievementSystem.getUnlocked()
    const a = getAchievementById(achievementId)
    if (a) recentlyUnlocked.value = a
  })

  return { unlockedIds, recentlyUnlocked }
})

export { achievementSystem }
