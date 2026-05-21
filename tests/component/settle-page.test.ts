/**
 * S3-3 SettlePage component tests.
 *
 * Covers display logic (rating / stats / win-vs-loss header) and button
 * routing (再来一局 / 换份工 → uni.reLaunch). The page reads from Pinia
 * stores; we mount with createPinia + seed runStore.lastRunResult before mount.
 */

import { describe, test, expect, beforeEach, afterEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import SettlePage from '@/pages/settle/index.vue'
import { useRunStore } from '@/stores/run-store'
import { useProgressionStore } from '@/stores/progression-store'
import type { RunResult } from '@/types/run-phase'
import type { JobConfig } from '@/types/job'

function makeResult(overrides: Partial<RunResult> = {}): RunResult {
  return {
    jobId: 'programmer',
    jobName: '程序员',
    won: true,
    survivalDays: 5,
    totalDays: 5,
    finalMoney: 65,
    totalChoices: 15,
    uniqueChoices: 12,
    rating: 'S',
    ratingLabel: '卷王',
    endedAt: 0,
    ...overrides
  }
}

let reLaunchSpy: ReturnType<typeof vi.fn>

beforeEach(() => {
  setActivePinia(createPinia())
  reLaunchSpy = vi.fn()
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  ;(globalThis as any).uni = {
    reLaunch: reLaunchSpy,
    navigateBack: vi.fn(),
    showToast: vi.fn()
  }
})

afterEach(() => {
  vi.restoreAllMocks()
})

describe('SettlePage — rendering', () => {
  test('AC-3: displays rating grade + label', () => {
    const runStore = useRunStore()
    runStore.lastRunResult = makeResult({ rating: 'S', ratingLabel: '卷王' })
    const wrapper = mount(SettlePage)
    expect(wrapper.find('.rating-grade').text()).toBe('S')
    expect(wrapper.find('.rating-label').text()).toBe('卷王')
  })

  test('AC-5: won=true → 🎉 emoji + 撑过了一周！title', () => {
    const runStore = useRunStore()
    runStore.lastRunResult = makeResult({ won: true })
    const wrapper = mount(SettlePage)
    expect(wrapper.find('.emoji').text()).toBe('🎉')
    expect(wrapper.find('.title').text()).toBe('撑过了一周！')
  })

  test('AC-5: won=false → 💔 emoji + 中途折戟 title', () => {
    const runStore = useRunStore()
    runStore.lastRunResult = makeResult({ won: false, survivalDays: 3 })
    const wrapper = mount(SettlePage)
    expect(wrapper.find('.emoji').text()).toBe('💔')
    expect(wrapper.find('.title').text()).toBe('中途折戟')
  })

  test('AC-4: stats grid shows survival / money / choices / unique', () => {
    const runStore = useRunStore()
    runStore.lastRunResult = makeResult({
      survivalDays: 5,
      totalDays: 5,
      finalMoney: 88,
      totalChoices: 17,
      uniqueChoices: 13
    })
    const wrapper = mount(SettlePage)
    const text = wrapper.text()
    expect(text).toContain('5 / 5 天')
    expect(text).toContain('88 元')
    expect(text).toContain('17 次')
    expect(text).toContain('13 个')
  })

  test('AC-4: header shows job name and survival fraction', () => {
    const runStore = useRunStore()
    runStore.lastRunResult = makeResult({
      jobName: '销售',
      survivalDays: 4,
      totalDays: 5
    })
    const wrapper = mount(SettlePage)
    expect(wrapper.find('.job-name').text()).toContain('销售')
    expect(wrapper.find('.job-name').text()).toContain('4 / 5')
  })

  test('AC-3: D-rating gets monochrome class (no glow)', () => {
    const runStore = useRunStore()
    runStore.lastRunResult = makeResult({ rating: 'D', ratingLabel: '第一天就寄了' })
    const wrapper = mount(SettlePage)
    expect(wrapper.find('.rating-grade').classes()).toContain('rating-d')
  })

  test('shows loading state when lastRunResult is null', () => {
    const wrapper = mount(SettlePage)
    expect(wrapper.find('.loading').exists()).toBe(true)
    expect(wrapper.text()).toContain('结算中')
  })
})

describe('SettlePage — unlock toast (AC-6)', () => {
  test('shows recentlyUnlocked job name when present at mount', async () => {
    const runStore = useRunStore()
    runStore.lastRunResult = makeResult()
    const progressionStore = useProgressionStore()
    const job: JobConfig = {
      id: 'sales',
      name: '销售',
      icon: '🤝',
      description: '...',
      salaryMul: 3,
      baseWeight: 1,
      eventPack: '/x'
    }
    progressionStore.recentlyUnlocked = job
    const wrapper = mount(SettlePage)
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.unlock-toast').exists()).toBe(true)
    expect(wrapper.find('.unlock-toast').text()).toContain('销售')
  })

  test('no unlock toast when recentlyUnlocked is null', async () => {
    const runStore = useRunStore()
    runStore.lastRunResult = makeResult()
    const progressionStore = useProgressionStore()
    progressionStore.recentlyUnlocked = null
    const wrapper = mount(SettlePage)
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.unlock-toast').exists()).toBe(false)
  })
})

describe('SettlePage — button routing', () => {
  test('AC-7: 再来一局 → selectJob(currentJob) + reLaunch /pages/index/index', async () => {
    const runStore = useRunStore()
    runStore.lastRunResult = makeResult({ jobId: 'sales' })
    const selectJobSpy = vi.spyOn(runStore, 'selectJob').mockImplementation(() => {})
    const wrapper = mount(SettlePage)
    await wrapper.find('.btn-replay').trigger('click')
    expect(selectJobSpy).toHaveBeenCalledWith('sales')
    expect(reLaunchSpy).toHaveBeenCalledWith({ url: '/pages/index/index' })
  })

  test('AC-8: 换份工 → reLaunch /pages/job-select/index (no selectJob)', async () => {
    const runStore = useRunStore()
    runStore.lastRunResult = makeResult()
    const selectJobSpy = vi.spyOn(runStore, 'selectJob').mockImplementation(() => {})
    const wrapper = mount(SettlePage)
    await wrapper.find('.btn-switch').trigger('click')
    expect(selectJobSpy).not.toHaveBeenCalled()
    expect(reLaunchSpy).toHaveBeenCalledWith({ url: '/pages/job-select/index' })
  })

  test('再来一局 falls back to job-select if no jobId on result', async () => {
    const runStore = useRunStore()
    runStore.lastRunResult = makeResult({ jobId: '' })
    const selectJobSpy = vi.spyOn(runStore, 'selectJob').mockImplementation(() => {})
    const wrapper = mount(SettlePage)
    await wrapper.find('.btn-replay').trigger('click')
    expect(selectJobSpy).not.toHaveBeenCalled()
    expect(reLaunchSpy).toHaveBeenCalledWith({ url: '/pages/job-select/index' })
  })
})
