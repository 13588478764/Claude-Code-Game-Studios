/**
 * Passive skill store — bridges PassiveSkillSystem to Vue.
 *
 * Module-level wiring:
 *   - On runManager.onRunEnded → progressionSystem records stats →
 *     progressionStore subscribes to onProgressRecorded which already updates
 *     stats; here we mirror that and run passiveSkillSystem.checkUnlocks
 *     against the new stats so newly-unlocked skills emit onSkillUnlocked
 *     and persist via saveServiceUpdate.
 *
 * UI does not call PassiveSkillSystem directly — only via this store.
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { PassiveSkillSystem } from '@/services/passive-skill/passive-skill-system'
import { progressionSystem } from './progression-store'
import { saveService } from './save-store'
import {
  getPassiveSkillById,
  type PassiveSkill
} from '@/types/passive-skill'

const passiveSkillSystem = new PassiveSkillSystem()
passiveSkillSystem.init(saveService.load()?.passiveSkills ?? [])

// Module-level wiring — fires whenever progression records a run. Run-end
// chain order is run-store → progression-store → here. Newly-unlocked
// passives are written back to save via direct saveService access (mirrors
// progression-store's pattern to avoid Pinia activation order issues).
progressionSystem.onProgressRecorded.on((event) => {
  const newly = passiveSkillSystem.checkUnlocks(event.stats)
  if (newly.length === 0) return
  const cur = saveService.load()
  if (!cur) return
  const merged = Array.from(
    new Set([...(cur.passiveSkills ?? []), ...newly])
  )
  saveService.save({ ...cur, passiveSkills: merged })
})

export const usePassiveSkillStore = defineStore('passive-skill', () => {
  const unlockedIds = ref<string[]>(passiveSkillSystem.getUnlocked())
  const recentlyUnlocked = ref<PassiveSkill | null>(null)

  passiveSkillSystem.onSkillUnlocked.on(({ skillId }) => {
    unlockedIds.value = passiveSkillSystem.getUnlocked()
    const skill = getPassiveSkillById(skillId)
    if (skill) {
      recentlyUnlocked.value = skill
    }
  })

  return { unlockedIds, recentlyUnlocked }
})

export { passiveSkillSystem }
