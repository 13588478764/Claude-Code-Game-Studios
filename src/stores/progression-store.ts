/**
 * Progression store — bridges ProgressionSystem to Vue.
 *
 * Module-level wiring: ProgressionSystem subscribes to runManager.onRunEnded
 * for the run-finalization chain. saveService is used directly (not via store)
 * to avoid Pinia activation-order issues at module load.
 *
 * Components access via useProgressionStore — exposes stats + recentlyUnlocked
 * (toast for newly unlocked job, 1.5s).
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { ProgressionSystem } from '@/services/progression/progression-system'
import { saveService } from './save-store'
import { jobSystem } from './job-store'
import { runManager } from './run-store'
import { getJobById } from '@/config/jobs'
import type { GlobalStats, SaveData } from '@/types/save'
import type { JobConfig } from '@/types/job'

const TOAST_DURATION_MS = 1500

const progressionSystem = new ProgressionSystem({
  saveServiceLoad: () => saveService.load(),
  saveServiceUpdate: (patch) => {
    const current = saveService.load() ?? createEmptySave()
    saveService.save({ ...current, ...patch })
  },
  checkUnlocks: (stats) => jobSystem.checkUnlocks(stats)
})

// Wire run-end chain — fires whenever runManager.onRunEnded
runManager.onRunEnded.on((result) => {
  progressionSystem.recordRun(result)
})

export const useProgressionStore = defineStore('progression', () => {
  const stats = ref<GlobalStats>(loadInitialStats())
  const recentlyUnlocked = ref<JobConfig | null>(null)

  progressionSystem.onProgressRecorded.on((event) => {
    stats.value = event.stats
  })

  // Toast for newly unlocked jobs (subscribes to jobSystem directly)
  jobSystem.onJobUnlocked.on(({ jobId }) => {
    const job = getJobById(jobId)
    if (job) {
      recentlyUnlocked.value = job
      setTimeout(() => {
        recentlyUnlocked.value = null
      }, TOAST_DURATION_MS)
    }
  })

  return { stats, recentlyUnlocked }
})

function loadInitialStats(): GlobalStats {
  return (
    saveService.load()?.stats ?? {
      totalRuns: 0,
      totalWins: 0,
      totalDeaths: 0,
      totalMoneyEarned: 0,
      jobsPlayed: {},
      achievements: []
    }
  )
}

function createEmptySave(): SaveData {
  return {
    version: 1,
    jobUnlocks: ['intern', 'programmer'],
    currentRun: null,
    stats: {
      totalRuns: 0,
      totalWins: 0,
      totalDeaths: 0,
      totalMoneyEarned: 0,
      jobsPlayed: {},
      achievements: []
    },
    updatedAt: 0
  }
}

export { progressionSystem }
