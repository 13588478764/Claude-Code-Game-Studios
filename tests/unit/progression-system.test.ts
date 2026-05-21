import { describe, test, expect, vi } from 'vitest'
import {
  ProgressionSystem,
  type ProgressionDeps
} from '@/services/progression/progression-system'
import type { SaveData, GlobalStats } from '@/types/save'
import type { RunResult } from '@/types/run-phase'

function emptyStats(): GlobalStats {
  return {
    totalRuns: 0,
    totalWins: 0,
    totalDeaths: 0,
    totalMoneyEarned: 0,
    jobsPlayed: {},
    achievements: []
  }
}

function createSave(overrides: Partial<SaveData> = {}): SaveData {
  return {
    version: 1,
    jobUnlocks: ['intern', 'programmer'],
    currentRun: null,
    stats: emptyStats(),
    updatedAt: 0,
    ...overrides
  }
}

function makeRunResult(overrides: Partial<RunResult> = {}): RunResult {
  return {
    jobId: 'programmer',
    jobName: '程序员',
    won: true,
    survivalDays: 5,
    totalDays: 5,
    finalMoney: 50,
    totalChoices: 15,
    uniqueChoices: 15,
    rating: 'A',
    ratingLabel: '打工达人',
    endedAt: Date.now(),
    ...overrides
  }
}

function buildDeps(
  initialSave: SaveData | null = createSave(),
  unlocksReturn: string[] = []
) {
  const saveServiceLoadSpy = vi.fn((): SaveData | null => initialSave)
  const saveServiceUpdateSpy = vi.fn((_patch: Partial<SaveData>): void => {})
  const checkUnlocksSpy = vi.fn((_stats: GlobalStats): string[] => unlocksReturn)
  const deps: ProgressionDeps = {
    saveServiceLoad: saveServiceLoadSpy,
    saveServiceUpdate: saveServiceUpdateSpy,
    checkUnlocks: checkUnlocksSpy
  }
  return Object.assign(deps, {
    saveServiceLoadSpy,
    saveServiceUpdateSpy,
    checkUnlocksSpy
  })
}

type PatchedSave = Required<Pick<SaveData, 'stats' | 'jobUnlocks' | 'currentRun'>>

function lastPatch(spy: { mock: { calls: unknown[][] } }): PatchedSave {
  return spy.mock.calls[0]![0] as PatchedSave
}

describe('ProgressionSystem — recordRun stat accumulation', () => {
  test('AC-1: totalRuns += 1', () => {
    const deps = buildDeps(createSave({ stats: emptyStats() }))
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult())
    const patch = lastPatch(deps.saveServiceUpdateSpy)
    expect(patch.stats.totalRuns).toBe(1)
  })

  test('AC-2: result.won=true → totalWins += 1, totalDeaths unchanged', () => {
    const deps = buildDeps(createSave({ stats: emptyStats() }))
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult({ won: true }))
    const patch = lastPatch(deps.saveServiceUpdateSpy)
    expect(patch.stats.totalWins).toBe(1)
    expect(patch.stats.totalDeaths).toBe(0)
  })

  test('AC-3: result.won=false → totalDeaths += 1, totalWins unchanged', () => {
    const deps = buildDeps(createSave({ stats: emptyStats() }))
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult({ won: false }))
    const patch = lastPatch(deps.saveServiceUpdateSpy)
    expect(patch.stats.totalDeaths).toBe(1)
    expect(patch.stats.totalWins).toBe(0)
  })

  test('AC-4: totalMoneyEarned accumulates positive', () => {
    const deps = buildDeps(createSave({ stats: { ...emptyStats(), totalMoneyEarned: 50 } }))
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult({ finalMoney: 30 }))
    const patch = lastPatch(deps.saveServiceUpdateSpy)
    expect(patch.stats.totalMoneyEarned).toBe(80)
  })

  test('AC-4 edge: negative finalMoney decrements totalMoneyEarned', () => {
    const deps = buildDeps(createSave({ stats: { ...emptyStats(), totalMoneyEarned: 100 } }))
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult({ finalMoney: -20 }))
    const patch = lastPatch(deps.saveServiceUpdateSpy)
    expect(patch.stats.totalMoneyEarned).toBe(80)
  })

  test('AC-5: jobsPlayed[jobId] increments from 0 to 1 on first play', () => {
    const deps = buildDeps(createSave({ stats: emptyStats() }))
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult({ jobId: 'programmer' }))
    const patch = lastPatch(deps.saveServiceUpdateSpy)
    expect(patch.stats.jobsPlayed.programmer).toBe(1)
  })

  test('AC-5: jobsPlayed[jobId] increments existing count', () => {
    const deps = buildDeps(
      createSave({ stats: { ...emptyStats(), jobsPlayed: { programmer: 3 } } })
    )
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult({ jobId: 'programmer' }))
    const patch = lastPatch(deps.saveServiceUpdateSpy)
    expect(patch.stats.jobsPlayed.programmer).toBe(4)
  })

  test('AC-5: different jobId initializes new key', () => {
    const deps = buildDeps(
      createSave({ stats: { ...emptyStats(), jobsPlayed: { programmer: 2 } } })
    )
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult({ jobId: 'sales' }))
    const patch = lastPatch(deps.saveServiceUpdateSpy)
    expect(patch.stats.jobsPlayed.programmer).toBe(2)
    expect(patch.stats.jobsPlayed.sales).toBe(1)
  })

  test('preserves achievements array in stats', () => {
    const deps = buildDeps(
      createSave({ stats: { ...emptyStats(), achievements: ['first-win'] } })
    )
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult())
    const patch = lastPatch(deps.saveServiceUpdateSpy)
    expect(patch.stats.achievements).toEqual(['first-win'])
  })
})

describe('ProgressionSystem — unlock orchestration (AC-6)', () => {
  test('checkUnlocks invoked with the new stats (post-increment)', () => {
    const deps = buildDeps(createSave({ stats: { ...emptyStats(), totalWins: 0 } }))
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult({ won: true }))
    expect(deps.checkUnlocksSpy).toHaveBeenCalledTimes(1)
    const passedStats = deps.checkUnlocksSpy.mock.calls[0]![0]
    expect(passedStats.totalWins).toBe(1)  // already incremented
  })

  test('newly unlocked jobs appended to jobUnlocks in save', () => {
    const deps = buildDeps(
      createSave({ jobUnlocks: ['intern', 'programmer'] }),
      ['sales']
    )
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult({ won: true }))
    const patch = lastPatch(deps.saveServiceUpdateSpy)
    expect(patch.jobUnlocks).toEqual(['intern', 'programmer', 'sales'])
  })

  test('multiple new unlocks all appended', () => {
    const deps = buildDeps(
      createSave({ jobUnlocks: ['intern', 'programmer'] }),
      ['sales', 'designer']
    )
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult())
    const patch = lastPatch(deps.saveServiceUpdateSpy)
    expect(patch.jobUnlocks).toContain('sales')
    expect(patch.jobUnlocks).toContain('designer')
  })

  test('no unlocks → jobUnlocks unchanged', () => {
    const deps = buildDeps(
      createSave({ jobUnlocks: ['intern', 'programmer'] }),
      []
    )
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult())
    const patch = lastPatch(deps.saveServiceUpdateSpy)
    expect(patch.jobUnlocks).toEqual(['intern', 'programmer'])
  })
})

describe('ProgressionSystem — persistence (AC-7)', () => {
  test('saveServiceUpdate called with stats + jobUnlocks + currentRun=null', () => {
    const deps = buildDeps(createSave())
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult())
    const patch = lastPatch(deps.saveServiceUpdateSpy)
    expect(patch).toMatchObject({
      stats: expect.any(Object),
      jobUnlocks: expect.any(Array),
      currentRun: null
    })
  })

  test('saveServiceUpdate called exactly once per recordRun', () => {
    const deps = buildDeps(createSave())
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult())
    expect(deps.saveServiceUpdateSpy).toHaveBeenCalledTimes(1)
  })
})

describe('ProgressionSystem — multiple recordRun (AC-8)', () => {
  test('three sequential recordRun calls accumulate correctly', () => {
    let currentSave = createSave()
    const deps: ProgressionDeps = {
      saveServiceLoad: () => currentSave,
      saveServiceUpdate: (patch) => {
        currentSave = { ...currentSave, ...patch } as SaveData
      },
      checkUnlocks: () => []
    }
    const sys = new ProgressionSystem(deps)

    sys.recordRun(makeRunResult({ won: true, finalMoney: 50, jobId: 'programmer' }))
    sys.recordRun(makeRunResult({ won: false, finalMoney: 30, jobId: 'programmer' }))
    sys.recordRun(makeRunResult({ won: true, finalMoney: 70, jobId: 'intern' }))

    expect(currentSave.stats.totalRuns).toBe(3)
    expect(currentSave.stats.totalWins).toBe(2)
    expect(currentSave.stats.totalDeaths).toBe(1)
    expect(currentSave.stats.totalMoneyEarned).toBe(150)
    expect(currentSave.stats.jobsPlayed.programmer).toBe(2)
    expect(currentSave.stats.jobsPlayed.intern).toBe(1)
  })
})

describe('ProgressionSystem — fresh install / null save (defensive)', () => {
  test('saveServiceLoad returns null → uses empty stats', () => {
    const deps = buildDeps(null, [])
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult({ won: true, finalMoney: 50 }))
    const patch = lastPatch(deps.saveServiceUpdateSpy)
    expect(patch.stats.totalRuns).toBe(1)
    expect(patch.stats.totalWins).toBe(1)
    expect(patch.stats.totalMoneyEarned).toBe(50)
  })

  test('null save → jobUnlocks defaults to [intern, programmer]', () => {
    const deps = buildDeps(null, ['sales'])
    const sys = new ProgressionSystem(deps)
    sys.recordRun(makeRunResult())
    const patch = lastPatch(deps.saveServiceUpdateSpy)
    expect(patch.jobUnlocks).toEqual(['intern', 'programmer', 'sales'])
  })

  test('getStats with null save returns empty stats', () => {
    const deps = buildDeps(null, [])
    const sys = new ProgressionSystem(deps)
    const stats = sys.getStats()
    expect(stats).toEqual(emptyStats())
  })
})

describe('ProgressionSystem — onProgressRecorded event', () => {
  test('emits with correct stats + newlyUnlocked', () => {
    const deps = buildDeps(createSave(), ['sales'])
    const sys = new ProgressionSystem(deps)
    const fn = vi.fn()
    sys.onProgressRecorded.on(fn)
    sys.recordRun(makeRunResult({ won: true, finalMoney: 50 }))
    expect(fn).toHaveBeenCalledWith({
      stats: expect.objectContaining({
        totalRuns: 1,
        totalWins: 1,
        totalMoneyEarned: 50
      }),
      newlyUnlocked: ['sales']
    })
  })

  test('emits empty newlyUnlocked when no jobs newly unlock', () => {
    const deps = buildDeps(createSave(), [])
    const sys = new ProgressionSystem(deps)
    const fn = vi.fn()
    sys.onProgressRecorded.on(fn)
    sys.recordRun(makeRunResult())
    expect(fn).toHaveBeenCalledWith(
      expect.objectContaining({ newlyUnlocked: [] })
    )
  })
})

describe('ProgressionSystem — getStats', () => {
  test('returns current stats from save', () => {
    const deps = buildDeps(
      createSave({ stats: { ...emptyStats(), totalRuns: 5, totalWins: 3 } })
    )
    const sys = new ProgressionSystem(deps)
    const stats = sys.getStats()
    expect(stats.totalRuns).toBe(5)
    expect(stats.totalWins).toBe(3)
  })
})

describe('ProgressionSystem — AC-9 cross-session preservation (integration)', () => {
  test('save + reload preserves stats accumulation', () => {
    const storage = new Map<string, SaveData>()
    storage.set('save', createSave())

    const deps: ProgressionDeps = {
      saveServiceLoad: () => storage.get('save') ?? null,
      saveServiceUpdate: (patch) => {
        const cur = storage.get('save') ?? createSave()
        storage.set('save', { ...cur, ...patch } as SaveData)
      },
      checkUnlocks: () => []
    }
    const sys1 = new ProgressionSystem(deps)
    sys1.recordRun(makeRunResult({ won: true, finalMoney: 100 }))

    // Simulate process restart — new ProgressionSystem with same storage
    const sys2 = new ProgressionSystem(deps)
    const stats = sys2.getStats()
    expect(stats.totalRuns).toBe(1)
    expect(stats.totalWins).toBe(1)
    expect(stats.totalMoneyEarned).toBe(100)
  })
})
