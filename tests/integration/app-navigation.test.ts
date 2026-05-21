/**
 * S3-4 integration tests — verify the cross-page navigation chain, store
 * persistence across pages, and the full run lifecycle end-to-end.
 *
 * Approach: avoid real Vue page mount (uni-app's onUnload doesn't fire in
 * vitest) and instead drive the navigation primitives + Pinia stores
 * directly. Pages are exercised individually in their own component tests.
 */

import { describe, test, expect, beforeEach, afterEach, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { mount } from '@vue/test-utils'
import { SaveService, type StorageAdapter } from '@/services/save/save-service'
import { JobRotationSystem } from '@/services/job-rotation/job-rotation-system'
import { ProgressionSystem } from '@/services/progression/progression-system'
import { RunManager } from '@/services/run-manager/run-manager'
import { TypedEventEmitter } from '@/services/common/event-emitter'
import JobSelectPage from '@/pages/job-select/index.vue'
import SettlePage from '@/pages/settle/index.vue'
import { useRunStore } from '@/stores/run-store'
import { useResourceStore } from '@/stores/resource-store'
import { useJobStore } from '@/stores/job-store'
import { useSaveStore } from '@/stores/save-store'
import type { RunResult } from '@/types/run-phase'
import type { SaveData } from '@/types/save'

let navigateToSpy: ReturnType<typeof vi.fn>
let reLaunchSpy: ReturnType<typeof vi.fn>

function makeMemoryAdapter(): StorageAdapter & { snapshot: () => string | null } {
  let value: string | null = null
  return {
    setSync(_key, v) {
      value = v
    },
    getSync() {
      return value
    },
    removeSync() {
      value = null
    },
    snapshot() {
      return value
    }
  }
}

beforeEach(() => {
  setActivePinia(createPinia())
  navigateToSpy = vi.fn()
  reLaunchSpy = vi.fn()
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  ;(globalThis as any).uni = {
    navigateTo: navigateToSpy,
    reLaunch: reLaunchSpy,
    navigateBack: vi.fn(),
    showToast: vi.fn()
  }
})

afterEach(() => {
  vi.useRealTimers()
  vi.restoreAllMocks()
})

describe('App navigation — JobSelect → GameMain (AC-3)', () => {
  test('tap on unlocked card → runStore.selectJob + uni.navigateTo /pages/index/index', async () => {
    const wrapper = mount(JobSelectPage)
    await wrapper.vm.$nextTick()

    const runStore = useRunStore()
    const selectJobSpy = vi.spyOn(runStore, 'selectJob').mockImplementation(() => {})

    // Programmer is default-unlocked; tap that card
    const cards = wrapper.findAll('[data-job-id]')
    const programmerCard = cards.find((c) => c.attributes('data-job-id') === 'programmer')
    expect(programmerCard).toBeDefined()
    await programmerCard!.trigger('click')

    expect(selectJobSpy).toHaveBeenCalledWith('programmer')
    expect(navigateToSpy).toHaveBeenCalledWith({ url: '/pages/index/index' })
  })

  test('tap on locked card → showToast (no navigateTo)', async () => {
    const showToastSpy = vi.fn()
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    ;(globalThis as any).uni.showToast = showToastSpy

    const wrapper = mount(JobSelectPage)
    await wrapper.vm.$nextTick()

    const cards = wrapper.findAll('[data-job-id]')
    const salesCard = cards.find((c) => c.attributes('data-job-id') === 'sales')
    expect(salesCard).toBeDefined()
    await salesCard!.trigger('click')

    expect(navigateToSpy).not.toHaveBeenCalled()
    expect(showToastSpy).toHaveBeenCalled()
    expect(showToastSpy.mock.calls[0]![0].title).toBe('条件未满足')
  })
})

describe('App navigation — Settle → GameMain replay / Settle → JobSelect (AC-5/6)', () => {
  function seedRunResult(jobId = 'programmer'): RunResult {
    const runStore = useRunStore()
    const r: RunResult = {
      jobId,
      jobName: jobId === 'programmer' ? '程序员' : '其他',
      won: true,
      survivalDays: 5,
      totalDays: 5,
      finalMoney: 80,
      totalChoices: 12,
      uniqueChoices: 10,
      rating: 'A',
      ratingLabel: '打工达人',
      endedAt: 0
    }
    runStore.lastRunResult = r
    return r
  }

  test('AC-5: 再来一局 → reLaunch /pages/index/index with same job', async () => {
    seedRunResult('programmer')
    const runStore = useRunStore()
    const selectJobSpy = vi.spyOn(runStore, 'selectJob').mockImplementation(() => {})

    const wrapper = mount(SettlePage)
    await wrapper.vm.$nextTick()
    await wrapper.find('.btn-replay').trigger('click')

    expect(selectJobSpy).toHaveBeenCalledWith('programmer')
    expect(reLaunchSpy).toHaveBeenCalledWith({ url: '/pages/index/index' })
  })

  test('AC-6: 换份工 → reLaunch /pages/job-select/index (no selectJob)', async () => {
    seedRunResult()
    const runStore = useRunStore()
    const selectJobSpy = vi.spyOn(runStore, 'selectJob').mockImplementation(() => {})

    const wrapper = mount(SettlePage)
    await wrapper.vm.$nextTick()
    await wrapper.find('.btn-switch').trigger('click')

    expect(selectJobSpy).not.toHaveBeenCalled()
    expect(reLaunchSpy).toHaveBeenCalledWith({ url: '/pages/job-select/index' })
  })
})

describe('App navigation — Cross-page store persistence (AC-7)', () => {
  test('resourceStore singleton state persists across page mount/unmount cycles', async () => {
    // Mount JobSelectPage, mutate resource store, unmount, mount SettlePage,
    // verify state preserved (Pinia singletons, not page-local state).
    const job = mount(JobSelectPage)
    await job.vm.$nextTick()

    const resourceStore = useResourceStore()
    resourceStore.applyEffects([{ target: 'money', value: 42 }])
    expect(resourceStore.resources.money).toBe(42)

    job.unmount()

    // Settle requires lastRunResult — seed minimal
    const runStore = useRunStore()
    runStore.lastRunResult = {
      jobId: 'programmer', jobName: '程序员', won: true,
      survivalDays: 5, totalDays: 5, finalMoney: 0,
      totalChoices: 0, uniqueChoices: 0,
      rating: 'A', ratingLabel: '打工达人', endedAt: 0
    }
    const settle = mount(SettlePage)
    await settle.vm.$nextTick()

    // Same Pinia store — money still 42
    expect(resourceStore.resources.money).toBe(42)
    settle.unmount()
  })

  test('jobStore unlockedIds persist across pages', async () => {
    const job = mount(JobSelectPage)
    await job.vm.$nextTick()

    const jobStore = useJobStore()
    expect(jobStore.unlockedIds).toContain('intern')
    expect(jobStore.unlockedIds).toContain('programmer')
    expect(jobStore.unlockedIds.length).toBe(2)

    job.unmount()

    // After unmount, new page mount; same store
    const runStore = useRunStore()
    runStore.lastRunResult = {
      jobId: 'programmer', jobName: '程序员', won: true,
      survivalDays: 5, totalDays: 5, finalMoney: 0,
      totalChoices: 0, uniqueChoices: 0,
      rating: 'A', ratingLabel: '打工达人', endedAt: 0
    }
    const settle = mount(SettlePage)
    await settle.vm.$nextTick()
    expect(jobStore.unlockedIds.length).toBe(2)
    settle.unmount()
  })
})

describe('App navigation — onUnload save persistence (AC-8)', () => {
  test('saveStore.save() flushes to adapter (verifies the persistence path)', () => {
    vi.useFakeTimers()
    const adapter = makeMemoryAdapter()
    const svc = new SaveService(adapter)
    const data: SaveData = {
      version: 1,
      jobUnlocks: ['intern', 'programmer'],
      currentRun: null,
      stats: {
        totalRuns: 3, totalWins: 1, totalDeaths: 2,
        totalMoneyEarned: 120, jobsPlayed: { programmer: 3 }, achievements: []
      },
      firstStatusShown: true,
      updatedAt: 0
    }
    svc.save(data)
    // Debounced — needs 100ms
    expect(adapter.snapshot()).toBeNull()
    vi.advanceTimersByTime(150)
    const snap = adapter.snapshot()
    expect(snap).not.toBeNull()
    expect(JSON.parse(snap!).stats.totalRuns).toBe(3)
  })

  test('saveImmediate flushes synchronously (use case for onUnload)', () => {
    const adapter = makeMemoryAdapter()
    const svc = new SaveService(adapter)
    const data: SaveData = {
      version: 1,
      jobUnlocks: ['intern', 'programmer'],
      currentRun: null,
      stats: {
        totalRuns: 5, totalWins: 2, totalDeaths: 3,
        totalMoneyEarned: 250, jobsPlayed: {}, achievements: []
      },
      updatedAt: 0
    }
    svc.saveImmediate(data)
    const snap = adapter.snapshot()
    expect(snap).not.toBeNull()
    expect(JSON.parse(snap!).stats.totalRuns).toBe(5)
  })
})

describe('App navigation — Save round-trip across instances (AC-9)', () => {
  test('stats + jobUnlocks + firstStatusShown survive new SaveService instance', () => {
    vi.useFakeTimers()
    const adapter = makeMemoryAdapter()
    const svc1 = new SaveService(adapter)
    svc1.save({
      version: 1,
      jobUnlocks: ['intern', 'programmer', 'sales'],
      currentRun: null,
      stats: {
        totalRuns: 7, totalWins: 4, totalDeaths: 3,
        totalMoneyEarned: 580, jobsPlayed: { programmer: 5, intern: 2 },
        achievements: ['first-win']
      },
      firstStatusShown: true,
      updatedAt: 0
    })
    vi.advanceTimersByTime(150)

    // Simulate process restart — new SaveService instance hitting same adapter
    const svc2 = new SaveService(adapter)
    const loaded = svc2.load()
    expect(loaded).not.toBeNull()
    expect(loaded!.stats.totalRuns).toBe(7)
    expect(loaded!.stats.totalWins).toBe(4)
    expect(loaded!.jobUnlocks).toEqual(['intern', 'programmer', 'sales'])
    expect(loaded!.firstStatusShown).toBe(true)
    expect(loaded!.stats.jobsPlayed.programmer).toBe(5)
    expect(loaded!.stats.achievements).toEqual(['first-win'])
  })
})

describe('App navigation — Full run lifecycle integration (AC-10)', () => {
  test('selectJob → run → endRun → progressionSystem.recordRun → unlock fires', () => {
    // Wire minimal services manually (mirroring the production wiring done
    // in store modules) to verify the run-end chain works end-to-end.
    const adapter = makeMemoryAdapter()
    const saveService = new SaveService(adapter)
    const jobSystem = new JobRotationSystem()
    jobSystem.init(null) // fresh: ['intern', 'programmer']

    const progression = new ProgressionSystem({
      saveServiceLoad: () => saveService.load(),
      saveServiceUpdate: (patch) => {
        const cur = saveService.load() ?? {
          version: 1,
          jobUnlocks: ['intern', 'programmer'],
          currentRun: null,
          stats: {
            totalRuns: 0, totalWins: 0, totalDeaths: 0,
            totalMoneyEarned: 0, jobsPlayed: {}, achievements: []
          },
          updatedAt: 0
        } satisfies SaveData
        saveService.saveImmediate({ ...cur, ...patch })
      },
      checkUnlocks: (stats) => jobSystem.checkUnlocks(stats)
    })

    const runManager = new RunManager({
      showReviveAd: async () => false
    })
    runManager.onRunEnded.on((result) => progression.recordRun(result))

    // Subscribe runManager to a synthetic week-completed emitter
    const weekCompleted = new TypedEventEmitter<{ totalSalary: number }>()
    runManager.subscribeToCareerCompleted(weekCompleted)

    // Player picks programmer
    runManager.selectJob('programmer')
    expect(runManager.getPhase()).toBe('INITIALIZING')
    runManager.startPlaying()
    expect(runManager.getPhase()).toBe('PLAYING')

    // Synthetic 1 win — sales unlock condition is wins >= 1
    weekCompleted.emit({ totalSalary: 65 })
    expect(runManager.getPhase()).toBe('SETTLING')

    // Game-main triggers endRun (production behavior)
    const result = runManager.endRun(
      { survivalDays: 5, totalDays: 5, finalMoney: 65, expectedMoney: 65, totalChoices: 12, uniqueChoices: 10 },
      { jobId: 'programmer', jobName: '程序员' }
    )
    expect(result.won).toBe(true)

    // After end: phase loops back to JOB_SELECT, save persisted with stats + unlock
    expect(runManager.getPhase()).toBe('JOB_SELECT')
    const saved = saveService.load()
    expect(saved).not.toBeNull()
    expect(saved!.stats.totalRuns).toBe(1)
    expect(saved!.stats.totalWins).toBe(1)
    expect(saved!.stats.jobsPlayed.programmer).toBe(1)
    expect(saved!.jobUnlocks).toContain('sales')

    // Second run with the same job — accumulates correctly + sales already unlocked
    runManager.selectJob('programmer')
    runManager.startPlaying()
    weekCompleted.emit({ totalSalary: 65 })
    runManager.endRun(
      { survivalDays: 5, totalDays: 5, finalMoney: 65, expectedMoney: 65, totalChoices: 8, uniqueChoices: 8 },
      { jobId: 'programmer', jobName: '程序员' }
    )
    const after2 = saveService.load()!
    expect(after2.stats.totalRuns).toBe(2)
    expect(after2.stats.totalWins).toBe(2)
    expect(after2.stats.jobsPlayed.programmer).toBe(2)
    expect(after2.jobUnlocks).toEqual(['intern', 'programmer', 'sales']) // no duplicate
  })

  test('losing run still records totalDeaths + does not unlock wins-gated jobs', () => {
    const adapter = makeMemoryAdapter()
    const saveService = new SaveService(adapter)
    const jobSystem = new JobRotationSystem()
    jobSystem.init(null)

    const progression = new ProgressionSystem({
      saveServiceLoad: () => saveService.load(),
      saveServiceUpdate: (patch) => {
        const cur = saveService.load() ?? {
          version: 1, jobUnlocks: ['intern', 'programmer'], currentRun: null,
          stats: { totalRuns: 0, totalWins: 0, totalDeaths: 0, totalMoneyEarned: 0, jobsPlayed: {}, achievements: [] },
          updatedAt: 0
        } satisfies SaveData
        saveService.saveImmediate({ ...cur, ...patch })
      },
      checkUnlocks: (stats) => jobSystem.checkUnlocks(stats)
    })

    const runManager = new RunManager({ showReviveAd: async () => false })
    runManager.onRunEnded.on((result) => progression.recordRun(result))

    const depleted = new TypedEventEmitter<{ which: 'energy' | 'mood' | 'health' }>()
    runManager.subscribeToResourceDepletion(depleted)

    runManager.selectJob('programmer')
    runManager.startPlaying()
    depleted.emit({ which: 'energy' })
    expect(runManager.getPhase()).toBe('DYING')
    runManager.declineRevive()
    expect(runManager.getPhase()).toBe('SETTLING')

    runManager.endRun(
      { survivalDays: 2, totalDays: 5, finalMoney: 30, expectedMoney: 65, totalChoices: 6, uniqueChoices: 5 },
      { jobId: 'programmer', jobName: '程序员' }
    )

    const saved = saveService.load()!
    expect(saved.stats.totalRuns).toBe(1)
    expect(saved.stats.totalWins).toBe(0)
    expect(saved.stats.totalDeaths).toBe(1)
    expect(saved.jobUnlocks).toEqual(['intern', 'programmer']) // sales NOT unlocked
  })
})

describe('App navigation — Save store wiring through Pinia stores (AC-7)', () => {
  test('saveStore.save() exposed and callable from page composables', () => {
    const saveStore = useSaveStore()
    expect(typeof saveStore.save).toBe('function')
    expect(typeof saveStore.saveImmediate).toBe('function')
    expect(typeof saveStore.update).toBe('function')
    expect(typeof saveStore.clear).toBe('function')
    // Calling save shouldn't throw even with default empty data
    expect(() => saveStore.save()).not.toThrow()
  })
})
