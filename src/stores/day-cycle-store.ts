/**
 * Day cycle store — bridges DayCycleSystem to Vue.
 * Per ADR-003.
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { DayCycleSystem } from '@/services/day-cycle/day-cycle-system'
import { DAY_NAMES, DEFAULT_WEEKS_PER_CAREER } from '@/types/day-cycle'

const dayCycleSystem = new DayCycleSystem()

export const useDayCycleStore = defineStore('day-cycle', () => {
  const currentDay = ref<number>(1)
  const currentWeekIndex = ref<number>(1)
  const weeksPerCareer = ref<number>(DEFAULT_WEEKS_PER_CAREER)
  const dayName = ref<string>(DAY_NAMES[0] ?? '')
  const eventsToday = ref<{ done: number; total: number }>({ done: 0, total: 0 })

  dayCycleSystem.onDayStarted.on((event) => {
    currentDay.value = event.day
    currentWeekIndex.value = event.weekIndex
    weeksPerCareer.value = dayCycleSystem.getWeeksPerCareer()
    dayName.value = DAY_NAMES[event.day - 1] ?? ''
    eventsToday.value = { done: 0, total: event.total }
  })

  dayCycleSystem.onEventCompleted.on((event) => {
    eventsToday.value = { done: event.done, total: event.total }
  })

  return {
    currentDay,
    currentWeekIndex,
    weeksPerCareer,
    dayName,
    eventsToday
  }
})

export { dayCycleSystem }
