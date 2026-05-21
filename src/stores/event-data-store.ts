/**
 * EventData store — bridges EventDataEngine to Vue components.
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { EventDataEngine } from '@/services/event-data/event-data-engine'
import { UniEventLoader } from '@/services/event-data/uni-event-loader'
import type { EventCard, EventFilter } from '@/types/event'

const engine = new EventDataEngine(new UniEventLoader())

export const useEventDataStore = defineStore('event-data', () => {
  const commonLoaded = ref(false)
  const currentJobId = ref<string | null>(null)
  const loadFailed = ref(false)

  engine.onLoadComplete.on((event) => {
    if (event.jobId === 'common') {
      commonLoaded.value = true
    } else {
      currentJobId.value = event.jobId
    }
  })
  engine.onLoadFailed.on(() => {
    loadFailed.value = true
  })

  async function loadCommon() {
    await engine.loadCommon()
  }

  async function loadJob(jobId: string) {
    await engine.loadJobEvents(jobId)
  }

  function unload() {
    engine.unload()
    currentJobId.value = null
  }

  function drawEvent(filter?: EventFilter): EventCard {
    return engine.drawEvent(filter)
  }

  function getEventById(id: string): EventCard | null {
    return engine.getEventById(id)
  }

  return {
    commonLoaded,
    currentJobId,
    loadFailed,
    loadCommon,
    loadJob,
    unload,
    drawEvent,
    getEventById
  }
})

export { engine as eventDataEngine }
