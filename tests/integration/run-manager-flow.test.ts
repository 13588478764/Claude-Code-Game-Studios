/**
 * S2-4 integration tests — RunManager 6-phase state machine + cross-system
 * coordination (resource depletion, week completion, status clearing on END).
 *
 * Uses real TypedEventEmitter mocks for upstream subscriptions to verify
 * end-to-end event flow.
 */

import { describe, test, expect, vi } from 'vitest'
import {
  RunManager,
  type RunManagerDeps,
  type ResourceDepletedPayload
} from '@/services/run-manager/run-manager'
import { TypedEventEmitter } from '@/services/common/event-emitter'
import { StatusSystem } from '@/services/status/status-system'
import type { RatingContext, JobInfo } from '@/types/run-phase'

const DEFAULT_JOB: JobInfo = { jobId: 'programmer', jobName: '程序员' }

function buildDeps(overrides: Partial<RunManagerDeps> = {}) {
  // Wrap overrides (or defaults) in spies so callers can both inject behavior
  // AND assert call counts.
  const showReviveAdSpy = vi.fn(overrides.showReviveAd ?? (async () => false))
  const applyResourceEffectsSpy = vi.fn(overrides.applyResourceEffects ?? (() => {}))
  const clearRunStateSpy = vi.fn(overrides.clearRunState ?? (() => {}))
  const deps: RunManagerDeps = {
    showReviveAd: showReviveAdSpy,
    applyResourceEffects: applyResourceEffectsSpy,
    clearRunState: clearRunStateSpy
  }
  return Object.assign(deps, {
    showReviveAdSpy,
    applyResourceEffectsSpy,
    clearRunStateSpy
  })
}

function buildAndStart(deps?: RunManagerDeps): RunManager {
  const rm = new RunManager(deps ?? buildDeps())
  rm.selectJob('programmer')
  rm.startPlaying()
  return rm
}

function defaultRatingCtx(overrides: Partial<RatingContext> = {}): RatingContext {
  return {
    survivalDays: 5,
    totalDays: 5,
    finalMoney: 70,
    expectedMoney: 100,
    totalChoices: 15,
    uniqueChoices: 15,
    ...overrides
  }
}

describe('RunManager — phase transitions', () => {
  test('initial phase is JOB_SELECT', () => {
    const rm = new RunManager(buildDeps())
    expect(rm.getPhase()).toBe('JOB_SELECT')
  })

  test('selectJob: JOB_SELECT → INITIALIZING + emit onJobSelected', () => {
    const rm = new RunManager(buildDeps())
    const selected = vi.fn()
    rm.onJobSelected.on(selected)
    rm.selectJob('programmer')
    expect(rm.getPhase()).toBe('INITIALIZING')
    expect(rm.getCurrentJob()).toBe('programmer')
    expect(selected).toHaveBeenCalledWith({ jobId: 'programmer' })
  })

  test('selectJob ignored when not in JOB_SELECT', () => {
    const rm = buildAndStart()
    rm.selectJob('intern')
    expect(rm.getCurrentJob()).toBe('programmer')  // unchanged
    expect(rm.getPhase()).toBe('PLAYING')
  })

  test('startPlaying: INITIALIZING → PLAYING + resets per-run state', () => {
    const rm = new RunManager(buildDeps())
    rm.selectJob('programmer')
    rm.startPlaying()
    expect(rm.getPhase()).toBe('PLAYING')
    expect(rm.hasRevived()).toBe(false)
    expect(rm.getRunStats()).toEqual({ totalChoices: 0, uniqueChoices: 0 })
  })

  test('startPlaying ignored if not in INITIALIZING', () => {
    const rm = new RunManager(buildDeps())
    rm.startPlaying()  // still in JOB_SELECT
    expect(rm.getPhase()).toBe('JOB_SELECT')
  })

  test('emit onPhaseChanged for every transition', () => {
    const rm = new RunManager(buildDeps())
    const phases = vi.fn()
    rm.onPhaseChanged.on(phases)
    rm.selectJob('programmer')
    rm.startPlaying()
    expect(phases).toHaveBeenCalledWith({ from: 'JOB_SELECT', to: 'INITIALIZING' })
    expect(phases).toHaveBeenCalledWith({ from: 'INITIALIZING', to: 'PLAYING' })
  })
})

describe('RunManager — death (resource depletion) AC-1', () => {
  test('PLAYING + onResourceDepleted → DYING', () => {
    const depletion = new TypedEventEmitter<ResourceDepletedPayload>()
    const rm = buildAndStart()
    rm.subscribeToResourceDepletion(depletion)

    depletion.emit({ which: 'energy' })
    expect(rm.getPhase()).toBe('DYING')
  })

  test('depletion outside PLAYING is ignored', () => {
    const depletion = new TypedEventEmitter<ResourceDepletedPayload>()
    const rm = new RunManager(buildDeps())
    rm.subscribeToResourceDepletion(depletion)

    depletion.emit({ which: 'energy' })
    expect(rm.getPhase()).toBe('JOB_SELECT')  // no transition from JOB_SELECT
  })

  test('depletion source is recorded for revive', () => {
    const depletion = new TypedEventEmitter<ResourceDepletedPayload>()
    const deps = buildDeps({ showReviveAd: async () => true })
    const rm = buildAndStart(deps)
    rm.subscribeToResourceDepletion(depletion)

    depletion.emit({ which: 'mood' })
    return rm.requestRevive().then(() => {
      expect(deps.applyResourceEffectsSpy).toHaveBeenCalledWith([
        { target: 'mood', value: 50 }
      ])
    })
  })
})

describe('RunManager — revive flow AC-2/10/11', () => {
  test('AC-2: DYING + ad success → PLAYING + apply +50 energy', async () => {
    const depletion = new TypedEventEmitter<ResourceDepletedPayload>()
    const deps = buildDeps({ showReviveAd: async () => true })
    const rm = buildAndStart(deps)
    rm.subscribeToResourceDepletion(depletion)

    depletion.emit({ which: 'energy' })
    const result = await rm.requestRevive()

    expect(result).toBe(true)
    expect(rm.getPhase()).toBe('PLAYING')
    expect(rm.hasRevived()).toBe(true)
    expect(deps.applyResourceEffectsSpy).toHaveBeenCalledWith([
      { target: 'energy', value: 50 }
    ])
  })

  test('AC-11: DYING + ad fail → SETTLING', async () => {
    const depletion = new TypedEventEmitter<ResourceDepletedPayload>()
    const deps = buildDeps({ showReviveAd: async () => false })
    const rm = buildAndStart(deps)
    rm.subscribeToResourceDepletion(depletion)

    depletion.emit({ which: 'energy' })
    const result = await rm.requestRevive()

    expect(result).toBe(false)
    expect(rm.getPhase()).toBe('SETTLING')
  })

  test('AC-3: declineRevive: DYING → SETTLING', () => {
    const depletion = new TypedEventEmitter<ResourceDepletedPayload>()
    const rm = buildAndStart()
    rm.subscribeToResourceDepletion(depletion)

    depletion.emit({ which: 'energy' })
    rm.declineRevive()
    expect(rm.getPhase()).toBe('SETTLING')
  })

  test('declineRevive ignored outside DYING', () => {
    const rm = buildAndStart()
    rm.declineRevive()
    expect(rm.getPhase()).toBe('PLAYING')  // unchanged
  })

  test('AC-10: revivedThisRun blocks 2nd revive — 2nd depletion auto-declines to SETTLING', async () => {
    const depletion = new TypedEventEmitter<ResourceDepletedPayload>()
    const deps = buildDeps({ showReviveAd: async () => true })
    const rm = buildAndStart(deps)
    rm.subscribeToResourceDepletion(depletion)

    // 1st death → revive
    depletion.emit({ which: 'energy' })
    await rm.requestRevive()
    expect(rm.getPhase()).toBe('PLAYING')

    // 2nd death → DYING again
    depletion.emit({ which: 'energy' })
    expect(rm.getPhase()).toBe('DYING')

    // requestRevive auto-declines (revivedThisRun=true)
    const result = await rm.requestRevive()
    expect(result).toBe(false)
    expect(rm.getPhase()).toBe('SETTLING')
    expect(deps.showReviveAdSpy).toHaveBeenCalledTimes(1)  // ad NOT shown 2nd time
  })

  test('requestRevive outside DYING returns false', async () => {
    const rm = buildAndStart()
    const result = await rm.requestRevive()
    expect(result).toBe(false)
    expect(rm.getPhase()).toBe('PLAYING')  // unchanged
  })
})

describe('RunManager — week completion AC-5', () => {
  test('AC-5: PLAYING + onWeekCompleted → SETTLING (won path)', () => {
    const week = new TypedEventEmitter<unknown>()
    const rm = buildAndStart()
    rm.subscribeToCareerCompleted(week)

    week.emit({})
    expect(rm.getPhase()).toBe('SETTLING')
  })

  test('week completion outside PLAYING is ignored', () => {
    const week = new TypedEventEmitter<unknown>()
    const rm = new RunManager(buildDeps())  // JOB_SELECT
    rm.subscribeToCareerCompleted(week)

    week.emit({})
    expect(rm.getPhase()).toBe('JOB_SELECT')
  })
})

describe('RunManager — same-frame death + week-completion AC-6', () => {
  test('death wins: depletion before week-completed → DYING; subsequent week emit ignored', () => {
    const depletion = new TypedEventEmitter<ResourceDepletedPayload>()
    const week = new TypedEventEmitter<unknown>()
    const rm = buildAndStart()
    rm.subscribeToResourceDepletion(depletion)
    rm.subscribeToCareerCompleted(week)

    // Same-frame: resource depleted fires first (per ResourceManager.applyEffects emit order)
    depletion.emit({ which: 'energy' })
    expect(rm.getPhase()).toBe('DYING')

    // Then DayCycleSystem emits onWeekCompleted (race with day end)
    week.emit({})
    expect(rm.getPhase()).toBe('DYING')  // unchanged — death wins
  })
})

describe('RunManager — endRun AC-4/9', () => {
  test('AC-4: SETTLING + endRun → ENDED + emit onRunEnded', () => {
    const week = new TypedEventEmitter<unknown>()
    const rm = buildAndStart()
    rm.subscribeToCareerCompleted(week)
    week.emit({})  // → SETTLING

    const ended = vi.fn()
    rm.onRunEnded.on(ended)
    const result = rm.endRun(defaultRatingCtx(), DEFAULT_JOB)

    expect(result.won).toBe(true)
    expect(result.jobId).toBe('programmer')
    expect(result.jobName).toBe('程序员')
    expect(ended).toHaveBeenCalledWith(result)
  })

  test('AC-9: endRun → ENDED → JOB_SELECT, with clearRunState called', () => {
    const week = new TypedEventEmitter<unknown>()
    const deps = buildDeps()
    const rm = buildAndStart(deps)
    rm.subscribeToCareerCompleted(week)
    week.emit({})

    const phaseLog: string[] = []
    rm.onPhaseChanged.on((event) => phaseLog.push(`${event.from}→${event.to}`))

    rm.endRun(defaultRatingCtx(), DEFAULT_JOB)

    expect(phaseLog).toEqual(['SETTLING→ENDED', 'ENDED→JOB_SELECT'])
    expect(deps.clearRunStateSpy).toHaveBeenCalled()
    expect(rm.getPhase()).toBe('JOB_SELECT')
  })

  test('endRun in invalid phase throws', () => {
    const rm = buildAndStart()  // PLAYING
    expect(() =>
      rm.endRun(defaultRatingCtx(), DEFAULT_JOB)
    ).toThrow(/invalid phase/)
  })

  test('endRun records loss when survivalDays < totalDays', () => {
    const week = new TypedEventEmitter<unknown>()
    const rm = buildAndStart()
    rm.subscribeToCareerCompleted(week)
    week.emit({})
    const result = rm.endRun(defaultRatingCtx({ survivalDays: 3, totalDays: 5 }), DEFAULT_JOB)
    expect(result.won).toBe(false)
  })
})

describe('RunManager — AC-7 ENDED triggers status clearAll via subscription', () => {
  test('StatusSystem subscribed to phase changes → clearAll on ENDED', () => {
    const week = new TypedEventEmitter<unknown>()
    const rm = buildAndStart()
    const status = new StatusSystem()
    rm.subscribeToCareerCompleted(week)
    status.subscribeToRunPhase(rm.onPhaseChanged)

    // Add a buff to verify clearAll happens
    status.addStatus({
      id: 'caffeine',
      name: '亢奋',
      icon: '☕',
      type: 'buff',
      daysLeft: 2,
      energyMul: 0.5
    })
    expect(status.getBuff()).not.toBeNull()

    week.emit({})  // → SETTLING
    expect(status.getBuff()).not.toBeNull()  // still alive in SETTLING

    rm.endRun(defaultRatingCtx(), DEFAULT_JOB)
    // ENDED phase triggered → status cleared
    expect(status.getBuff()).toBeNull()
  })

  test('DYING/SETTLING phases do NOT clear status', () => {
    const depletion = new TypedEventEmitter<ResourceDepletedPayload>()
    const rm = buildAndStart()
    const status = new StatusSystem()
    rm.subscribeToResourceDepletion(depletion)
    status.subscribeToRunPhase(rm.onPhaseChanged)

    status.addStatus({
      id: 'emo',
      name: 'emo',
      icon: '💔',
      type: 'debuff',
      daysLeft: 2,
      moodMul: 1.5
    })

    depletion.emit({ which: 'energy' })  // → DYING
    expect(status.getDebuff()).not.toBeNull()

    rm.declineRevive()  // → SETTLING
    expect(status.getDebuff()).not.toBeNull()
  })
})

describe('RunManager — AC-8 rating computation', () => {
  test('formula: survival 5/5, money 80/100, variety 15/20 → 0.865 → A', () => {
    const rm = new RunManager(buildDeps())
    const rating = rm.computeRating({
      survivalDays: 5,
      totalDays: 5,
      finalMoney: 80,
      expectedMoney: 100,
      totalChoices: 20,
      uniqueChoices: 15
    })
    // 5/5*0.4 + 80/100*0.3 + 15/20*0.3 = 0.4 + 0.24 + 0.225 = 0.865 → A
    expect(rating).toBe('A')
  })

  test('all max → S', () => {
    const rm = new RunManager(buildDeps())
    expect(
      rm.computeRating({
        survivalDays: 5,
        totalDays: 5,
        finalMoney: 100,
        expectedMoney: 100,
        totalChoices: 20,
        uniqueChoices: 20
      })
    ).toBe('S')
  })

  test('all zero → D', () => {
    const rm = new RunManager(buildDeps())
    expect(
      rm.computeRating({
        survivalDays: 0,
        totalDays: 5,
        finalMoney: 0,
        expectedMoney: 100,
        totalChoices: 0,
        uniqueChoices: 0
      })
    ).toBe('D')
  })

  test('clamps over 1.0 to avoid bonus boost', () => {
    const rm = new RunManager(buildDeps())
    // survival=10/5 (somehow exceeded) — should be clamped to 1.0
    expect(
      rm.computeRating({
        survivalDays: 10,
        totalDays: 5,
        finalMoney: 1000,
        expectedMoney: 100,
        totalChoices: 20,
        uniqueChoices: 20
      })
    ).toBe('S')  // clamped values cap score at 1.0
  })

  test('zero divisors are handled (totalDays=0, expectedMoney=0)', () => {
    const rm = new RunManager(buildDeps())
    expect(
      rm.computeRating({
        survivalDays: 0,
        totalDays: 0,
        finalMoney: 0,
        expectedMoney: 0,
        totalChoices: 0,
        uniqueChoices: 0
      })
    ).toBe('D')
  })

  test('B grade boundary (~0.5)', () => {
    const rm = new RunManager(buildDeps())
    // 0.4 (survival half) + 0.15 (money half) + 0 = 0.55 → B
    expect(
      rm.computeRating({
        survivalDays: 5,
        totalDays: 5,
        finalMoney: 50,
        expectedMoney: 100,
        totalChoices: 10,
        uniqueChoices: 0
      })
    ).toBe('B')
  })

  test('rating label included in run result', () => {
    const week = new TypedEventEmitter<unknown>()
    const rm = buildAndStart()
    rm.subscribeToCareerCompleted(week)
    week.emit({})
    const result = rm.endRun(defaultRatingCtx(), DEFAULT_JOB)
    expect(result.rating).toBe('S')
    expect(result.ratingLabel).toBe('卷王')
  })

  test('rating labels cover all 5 grades', () => {
    const labels = new Map<string, string>([
      ['S', '卷王'],
      ['A', '打工达人'],
      ['B', '勉强混过'],
      ['C', '摸鱼被抓'],
      ['D', '第一天就寄了']
    ])
    const rm = new RunManager(buildDeps())
    const week = new TypedEventEmitter<unknown>()

    for (const [grade, expected] of labels) {
      const ctx =
        grade === 'S'
          ? defaultRatingCtx({ finalMoney: 100, expectedMoney: 100 })
          : grade === 'A'
            ? defaultRatingCtx({ finalMoney: 80, expectedMoney: 100, totalChoices: 20, uniqueChoices: 15 })
            : grade === 'B'
              ? defaultRatingCtx({ finalMoney: 50, expectedMoney: 100, totalChoices: 10, uniqueChoices: 0 })
              : grade === 'C'
                ? defaultRatingCtx({ survivalDays: 2, totalDays: 5, finalMoney: 30, expectedMoney: 100, totalChoices: 6, uniqueChoices: 3 })
                : { survivalDays: 0, totalDays: 5, finalMoney: 0, expectedMoney: 100, totalChoices: 0, uniqueChoices: 0 }
      // Drive through PLAYING → SETTLING for each rating test
      const fresh = new RunManager(buildDeps())
      fresh.selectJob('programmer')
      fresh.startPlaying()
      fresh.subscribeToCareerCompleted(week)
      week.emit({})
      const result = fresh.endRun(ctx, DEFAULT_JOB)
      expect(result.rating).toBe(grade)
      expect(result.ratingLabel).toBe(expected)
      // Reset week emitter handlers don't accumulate across iterations
    }
    void rm  // not used, but referenced to satisfy unused-var
  })
})

describe('RunManager — choice tracking', () => {
  test('trackChoice during PLAYING accumulates totalChoices and unique events', () => {
    const rm = buildAndStart()
    rm.trackChoice('event-1')
    rm.trackChoice('event-2')
    rm.trackChoice('event-1')  // duplicate eventId
    expect(rm.getRunStats()).toEqual({ totalChoices: 3, uniqueChoices: 2 })
  })

  test('trackChoice outside PLAYING is ignored', () => {
    const rm = new RunManager(buildDeps())  // JOB_SELECT
    rm.trackChoice('event-1')
    expect(rm.getRunStats()).toEqual({ totalChoices: 0, uniqueChoices: 0 })
  })

  test('startPlaying resets choice tracking', () => {
    const depletion = new TypedEventEmitter<ResourceDepletedPayload>()
    const deps = buildDeps({ showReviveAd: async () => false })
    const rm = buildAndStart(deps)
    rm.subscribeToResourceDepletion(depletion)
    rm.trackChoice('event-1')
    rm.trackChoice('event-2')
    expect(rm.getRunStats().totalChoices).toBe(2)

    // Die → settle → end → next run
    depletion.emit({ which: 'energy' })
    rm.declineRevive()
    rm.endRun(defaultRatingCtx({ survivalDays: 1 }), DEFAULT_JOB)

    // Start new run
    rm.selectJob('intern')
    rm.startPlaying()
    expect(rm.getRunStats()).toEqual({ totalChoices: 0, uniqueChoices: 0 })
  })
})

describe('RunManager — full lifecycle (death path)', () => {
  test('JOB_SELECT → INITIALIZING → PLAYING → DYING → SETTLING → ENDED → JOB_SELECT', async () => {
    const depletion = new TypedEventEmitter<ResourceDepletedPayload>()
    const deps = buildDeps({ showReviveAd: async () => false })
    const rm = new RunManager(deps)
    rm.subscribeToResourceDepletion(depletion)

    const phaseLog: string[] = [rm.getPhase()]
    rm.onPhaseChanged.on((e) => phaseLog.push(e.to))

    rm.selectJob('programmer')
    rm.startPlaying()
    rm.trackChoice('e1')
    depletion.emit({ which: 'energy' })  // → DYING
    await rm.requestRevive()  // ad fails → SETTLING
    rm.endRun(defaultRatingCtx({ survivalDays: 2, totalDays: 5 }), DEFAULT_JOB)

    expect(phaseLog).toEqual([
      'JOB_SELECT',
      'INITIALIZING',
      'PLAYING',
      'DYING',
      'SETTLING',
      'ENDED',
      'JOB_SELECT'
    ])
    expect(deps.clearRunStateSpy).toHaveBeenCalled()
  })
})

describe('RunManager — full lifecycle (win path)', () => {
  test('JOB_SELECT → INITIALIZING → PLAYING → SETTLING → ENDED → JOB_SELECT', () => {
    const week = new TypedEventEmitter<unknown>()
    const rm = new RunManager(buildDeps())
    rm.subscribeToCareerCompleted(week)

    const phaseLog: string[] = [rm.getPhase()]
    rm.onPhaseChanged.on((e) => phaseLog.push(e.to))

    rm.selectJob('programmer')
    rm.startPlaying()
    week.emit({})  // → SETTLING (won)
    const result = rm.endRun(defaultRatingCtx(), DEFAULT_JOB)

    expect(phaseLog).toEqual([
      'JOB_SELECT',
      'INITIALIZING',
      'PLAYING',
      'SETTLING',
      'ENDED',
      'JOB_SELECT'
    ])
    expect(result.won).toBe(true)
  })
})
