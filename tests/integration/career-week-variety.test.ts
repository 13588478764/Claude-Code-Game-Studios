/**
 * J-3 regression — career-store passes actual choice count (not day-end
 * sampling count) to careerProgressionSystem.recordWeek.
 *
 * Bug it guards: prior code computed `choicesThisWeek = max(uniqueEvents,
 * energySamples.length)` where energySamples.length is 1-5 (one per day).
 * That made `varietyRatio = uniqueEvents / max(uniqueEvents, ≤5) = 1` once
 * any events happened — variety component always saturated at 20/20.
 *
 * Fix: increment a separate `weekChoiceCount` counter in `recordWeekEvent`
 * and pass it through to `recordWeek`.
 *
 * This is an integration test against module-level singletons (career-store
 * subscribes at module init). It spies on `careerProgressionSystem.recordWeek`
 * to capture what `choicesThisWeek` value is actually passed.
 */

import { describe, test, expect, beforeEach, vi } from 'vitest'
import {
  recordWeekEvent,
  careerProgressionSystem
} from '@/stores/career-store'
import { dayCycleSystem } from '@/stores/day-cycle-store'
import { resourceManager } from '@/stores/resource-store'
import { runManager } from '@/stores/run-store'

beforeEach(() => {
  // Reset module-level week state by triggering job-selected (also resets
  // careerProgressionSystem). We don't actually start a run — just fire the
  // event so the store's per-week counters zero out.
  runManager.onJobSelected.emit({ jobId: 'test-job' })
  // Put resources in a known place — recordWeek pulls money + samples avg.
  resourceManager.init({ energy: 80, mood: 60, money: 0, health: 100 })
})

describe('J-3 regression — choicesThisWeek reflects real call count', () => {
  test('recording 8 events (4 unique) → choicesThisWeek=8, unique=4', () => {
    const spy = vi.spyOn(careerProgressionSystem, 'recordWeek')

    // 4 unique event ids each chosen twice = 8 choices, 4 unique
    const ids = ['e1', 'e1', 'e2', 'e2', 'e3', 'e3', 'e4', 'e4']
    for (const id of ids) recordWeekEvent(id)

    dayCycleSystem.onWeekCompleted.emit({ weekIndex: 1, weekSalary: 175 })

    expect(spy).toHaveBeenCalledTimes(1)
    const inputs = spy.mock.calls[0]![0]
    expect(inputs.choicesThisWeek).toBe(8)
    expect(inputs.uniqueEventsThisWeek).toBe(4)
    // varietyRatio = 4/8 = 0.5 → varietyComp = 10 (not saturated to 20)
    // Don't assert exact final score (depends on resource/money) — just confirm
    // the broken case is gone: a perfect 1.0 ratio is impossible with 4/8.

    spy.mockRestore()
  })

  test('all unique events → varietyRatio=1.0 (the legitimate ceiling case)', () => {
    const spy = vi.spyOn(careerProgressionSystem, 'recordWeek')

    for (const id of ['a', 'b', 'c']) recordWeekEvent(id)
    dayCycleSystem.onWeekCompleted.emit({ weekIndex: 1, weekSalary: 175 })

    const inputs = spy.mock.calls[0]![0]
    expect(inputs.choicesThisWeek).toBe(3)
    expect(inputs.uniqueEventsThisWeek).toBe(3)

    spy.mockRestore()
  })

  test('counters reset after onWeekCompleted (no carryover into next week)', () => {
    const spy = vi.spyOn(careerProgressionSystem, 'recordWeek')

    recordWeekEvent('x')
    recordWeekEvent('y')
    dayCycleSystem.onWeekCompleted.emit({ weekIndex: 1, weekSalary: 175 })
    expect(spy.mock.calls[0]![0].choicesThisWeek).toBe(2)

    // Next week — only one new event
    recordWeekEvent('z')
    dayCycleSystem.onWeekCompleted.emit({ weekIndex: 2, weekSalary: 175 })
    expect(spy.mock.calls[1]![0].choicesThisWeek).toBe(1)
    expect(spy.mock.calls[1]![0].uniqueEventsThisWeek).toBe(1)

    spy.mockRestore()
  })

  test('zero events this week → choicesThisWeek=0, varietyComp=0 (no divide-by-zero)', () => {
    const spy = vi.spyOn(careerProgressionSystem, 'recordWeek')

    // No recordWeekEvent calls this week
    dayCycleSystem.onWeekCompleted.emit({ weekIndex: 1, weekSalary: 175 })

    const inputs = spy.mock.calls[0]![0]
    expect(inputs.choicesThisWeek).toBe(0)
    expect(inputs.uniqueEventsThisWeek).toBe(0)

    spy.mockRestore()
  })

  test('reviewBonus passed to recordWeek is 0 (J-3: applyReviewBonus uses immediate path)', () => {
    const spy = vi.spyOn(careerProgressionSystem, 'recordWeek')

    recordWeekEvent('x')
    dayCycleSystem.onWeekCompleted.emit({ weekIndex: 1, weekSalary: 175 })

    expect(spy.mock.calls[0]![0].reviewBonus).toBe(0)

    spy.mockRestore()
  })
})
