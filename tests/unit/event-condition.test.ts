/**
 * M-1: evaluateCondition pure function tests. Conditions are evaluated
 * against an EventDrawContext at draw time. Missing context fields fall
 * back to "condition not enforced" (conservative, preserves old behavior
 * for callers that don't yet pass context).
 */

import { describe, test, expect } from 'vitest'
import { evaluateCondition } from '@/services/event-data/event-data-engine'
import type { EventCondition, EventDrawContext } from '@/types/event'

const fullCtx: EventDrawContext = {
  day: 3,
  weekIndex: 2,
  money: 120,
  health: 60,
  careerLevel: 2,
  jobId: 'programmer',
  activeBuffIds: ['caffeine', 'sleepy']
}

function cond(type: EventCondition['type'], value: number | string): EventCondition {
  return { type, value }
}

describe('evaluateCondition — no context provided', () => {
  test('returns true for any condition when ctx is undefined', () => {
    expect(evaluateCondition(cond('minWeek', 99), undefined)).toBe(true)
    expect(evaluateCondition(cond('maxMoney', -1), undefined)).toBe(true)
  })
})

describe('evaluateCondition — day/week thresholds', () => {
  test('minDay: passes when day >= value', () => {
    expect(evaluateCondition(cond('minDay', 3), fullCtx)).toBe(true)
    expect(evaluateCondition(cond('minDay', 4), fullCtx)).toBe(false)
  })

  test('maxDay: passes when day <= value', () => {
    expect(evaluateCondition(cond('maxDay', 3), fullCtx)).toBe(true)
    expect(evaluateCondition(cond('maxDay', 2), fullCtx)).toBe(false)
  })

  test('minWeek: passes when week >= value', () => {
    expect(evaluateCondition(cond('minWeek', 2), fullCtx)).toBe(true)
    expect(evaluateCondition(cond('minWeek', 3), fullCtx)).toBe(false)
  })

  test('maxWeek: passes when week <= value', () => {
    expect(evaluateCondition(cond('maxWeek', 2), fullCtx)).toBe(true)
    expect(evaluateCondition(cond('maxWeek', 1), fullCtx)).toBe(false)
  })
})

describe('evaluateCondition — resource thresholds', () => {
  test('minMoney: passes when money >= value (rich check)', () => {
    expect(evaluateCondition(cond('minMoney', 100), fullCtx)).toBe(true)
    expect(evaluateCondition(cond('minMoney', 200), fullCtx)).toBe(false)
  })

  test('maxMoney: passes when money <= value (broke check)', () => {
    expect(evaluateCondition(cond('maxMoney', 200), fullCtx)).toBe(true)
    expect(evaluateCondition(cond('maxMoney', 100), fullCtx)).toBe(false)
  })

  test('minHealth: passes when health >= value', () => {
    expect(evaluateCondition(cond('minHealth', 60), fullCtx)).toBe(true)
    expect(evaluateCondition(cond('minHealth', 70), fullCtx)).toBe(false)
  })

  test('maxHealth: passes when health <= value (frail check)', () => {
    expect(evaluateCondition(cond('maxHealth', 60), fullCtx)).toBe(true)
    expect(evaluateCondition(cond('maxHealth', 50), fullCtx)).toBe(false)
  })
})

describe('evaluateCondition — career level', () => {
  test('minCareerLevel passes when level >= value', () => {
    expect(evaluateCondition(cond('minCareerLevel', 2), fullCtx)).toBe(true)
    expect(evaluateCondition(cond('minCareerLevel', 3), fullCtx)).toBe(false)
  })

  test('maxCareerLevel passes when level <= value (rookie check)', () => {
    expect(evaluateCondition(cond('maxCareerLevel', 2), fullCtx)).toBe(true)
    expect(evaluateCondition(cond('maxCareerLevel', 1), fullCtx)).toBe(false)
  })
})

describe('evaluateCondition — categorical', () => {
  test('job: exact-match jobId', () => {
    expect(evaluateCondition(cond('job', 'programmer'), fullCtx)).toBe(true)
    expect(evaluateCondition(cond('job', 'sales'), fullCtx)).toBe(false)
  })

  test('hasBuff: passes when buff id in active list', () => {
    expect(evaluateCondition(cond('hasBuff', 'caffeine'), fullCtx)).toBe(true)
    expect(evaluateCondition(cond('hasBuff', 'angry'), fullCtx)).toBe(false)
  })
})

describe('evaluateCondition — missing field falls back to true', () => {
  test('partial ctx without money → minMoney/maxMoney both pass', () => {
    const noMoney: EventDrawContext = { day: 3 }
    expect(evaluateCondition(cond('minMoney', 9999), noMoney)).toBe(true)
    expect(evaluateCondition(cond('maxMoney', -1), noMoney)).toBe(true)
  })

  test('partial ctx without health → minHealth/maxHealth both pass', () => {
    const noHealth: EventDrawContext = { day: 3 }
    expect(evaluateCondition(cond('minHealth', 100), noHealth)).toBe(true)
    expect(evaluateCondition(cond('maxHealth', 0), noHealth)).toBe(true)
  })

  test('partial ctx without buffs → hasBuff passes', () => {
    const noBuffs: EventDrawContext = { day: 3 }
    expect(evaluateCondition(cond('hasBuff', 'whatever'), noBuffs)).toBe(true)
  })
})
