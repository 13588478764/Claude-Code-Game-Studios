/**
 * Job store — bridges JobRotationSystem to Vue.
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { JobRotationSystem } from '@/services/job-rotation/job-rotation-system'
import { getJobById } from '@/config/jobs'
import type { JobConfig } from '@/types/job'
import type { GlobalStats, SaveData } from '@/types/save'

const jobSystem = new JobRotationSystem()

export const useJobStore = defineStore('job', () => {
  const currentJob = ref<JobConfig | null>(null)
  const unlockedIds = ref<string[]>([])
  const lastUnlocked = ref<string | null>(null)

  jobSystem.onJobSelected.on((event) => {
    currentJob.value = getJobById(event.jobId) ?? null
  })
  jobSystem.onJobUnlocked.on((event) => {
    lastUnlocked.value = event.jobId
    unlockedIds.value = jobSystem.getUnlocked()
  })

  function init(saveData: SaveData | null) {
    jobSystem.init(saveData)
    unlockedIds.value = jobSystem.getUnlocked()
  }

  function selectJob(jobId: string) {
    jobSystem.selectJob(jobId)
  }

  function getRecommendations(count: number) {
    return jobSystem.getRecommendedJobs(count)
  }

  function checkUnlocks(stats: GlobalStats) {
    return jobSystem.checkUnlocks(stats)
  }

  return {
    currentJob,
    unlockedIds,
    lastUnlocked,
    init,
    selectJob,
    getRecommendations,
    checkUnlocks
  }
})

export { jobSystem }
