/**
 * G-3 EndingSystem unit tests — resolution priority, persistence, edge cases.
 */

import { describe, test, expect, vi } from 'vitest'
import { EndingSystem } from '@/services/ending/ending-system'
import { resolveEnding, getEndingById, ENDINGS } from '@/types/ending'
import type { RunResult } from '@/types/run-phase'
import type { EndingContext } from '@/types/ending'

function makeResult(overrides: Partial<RunResult> = {}): RunResult {
  return {
    jobId: 'programmer',
    jobName: '程序员',
    won: true,
    survivalDays: 20,
    totalDays: 20,
    finalMoney: 500,
    totalChoices: 50,
    uniqueChoices: 45,
    rating: 'A',
    ratingLabel: '打工达人',
    endedAt: 0,
    ...overrides
  }
}

describe('resolveEnding — catalog priority', () => {
  test('tycoon-ending fires when money >= 3000 + Lv4 + won', () => {
    const ctx: EndingContext = {
      result: makeResult({ finalMoney: 5000 }),
      finalCareerLevel: 4,
      depletionSource: null
    }
    expect(resolveEnding(ctx).id).toBe('tycoon-ending')
  })

  test('workaholic-king fires on S + Lv3 + won (no tycoon match)', () => {
    const ctx: EndingContext = {
      result: makeResult({ rating: 'S', finalMoney: 100 }),
      finalCareerLevel: 3,
      depletionSource: null
    }
    expect(resolveEnding(ctx).id).toBe('workaholic-king')
  })

  test('overwork-death fires on health depletion regardless of won status', () => {
    const ctx: EndingContext = {
      result: makeResult({ won: false }),
      finalCareerLevel: 2,
      depletionSource: 'health'
    }
    expect(resolveEnding(ctx).id).toBe('overwork-death')
  })

  test('mental-breakdown fires on mood depletion when lost', () => {
    const ctx: EndingContext = {
      result: makeResult({ won: false }),
      finalCareerLevel: 1,
      depletionSource: 'mood'
    }
    expect(resolveEnding(ctx).id).toBe('mental-breakdown')
  })

  test('burnt-out fires on energy depletion when lost', () => {
    const ctx: EndingContext = {
      result: makeResult({ won: false }),
      finalCareerLevel: 1,
      depletionSource: 'energy'
    }
    expect(resolveEnding(ctx).id).toBe('burnt-out')
  })

  test('broke-but-survived fires when won + money < 100 + low level', () => {
    const ctx: EndingContext = {
      result: makeResult({ finalMoney: 50, rating: 'C' }),
      finalCareerLevel: 1,
      depletionSource: null
    }
    expect(resolveEnding(ctx).id).toBe('broke-but-survived')
  })

  test('promoted-rookie fires on won + Lv2', () => {
    const ctx: EndingContext = {
      result: makeResult({ finalMoney: 200, rating: 'B' }),
      finalCareerLevel: 2,
      depletionSource: null
    }
    expect(resolveEnding(ctx).id).toBe('promoted-rookie')
  })

  test('senior-veteran fires on won + Lv3 (no S — workaholic-king takes that)', () => {
    const ctx: EndingContext = {
      result: makeResult({ rating: 'A', finalMoney: 200 }),
      finalCareerLevel: 3,
      depletionSource: null
    }
    expect(resolveEnding(ctx).id).toBe('senior-veteran')
  })

  test('early-quit fires on quick loss (survivalDays <= 5)', () => {
    const ctx: EndingContext = {
      result: makeResult({ won: false, survivalDays: 3 }),
      finalCareerLevel: 1,
      depletionSource: null
    }
    expect(resolveEnding(ctx).id).toBe('early-quit')
  })

  test('just-another-week fallback when nothing else matches', () => {
    const ctx: EndingContext = {
      result: makeResult({ rating: 'D', finalMoney: 150 }),
      finalCareerLevel: 1,
      depletionSource: null
    }
    expect(resolveEnding(ctx).id).toBe('just-another-week')
  })
})

describe('resolveEnding — order/priority', () => {
  test('tycoon-ending takes priority over workaholic-king when both match', () => {
    const ctx: EndingContext = {
      result: makeResult({ finalMoney: 5000, rating: 'S' }),
      finalCareerLevel: 4,
      depletionSource: null
    }
    // tycoon-ending appears first in catalog → wins
    expect(resolveEnding(ctx).id).toBe('tycoon-ending')
  })

  test('overwork-death takes priority over mental-breakdown when both could match', () => {
    // depletionSource='health' guarantees overwork-death; depletionSource
    // is single-valued so they can't both match — verifying first-match rule
    const ctx: EndingContext = {
      result: makeResult({ won: false }),
      finalCareerLevel: 1,
      depletionSource: 'health'
    }
    expect(resolveEnding(ctx).id).toBe('overwork-death')
  })
})

describe('EndingSystem — persistence', () => {
  test('init() with empty list → no endings', () => {
    const sys = new EndingSystem()
    sys.init([])
    expect(sys.getUnlocked()).toEqual([])
    expect(sys.getUnlockedCount()).toBe(0)
  })

  test('init() drops unknown ids defensively', () => {
    const sys = new EndingSystem()
    sys.init(['tycoon-ending', 'ghost-ending-999'])
    expect(sys.getUnlocked()).toEqual(['tycoon-ending'])
  })

  test('recordEnding adds ending + returns full Ending object', () => {
    const sys = new EndingSystem()
    const ctx: EndingContext = {
      result: makeResult({ finalMoney: 5000 }),
      finalCareerLevel: 4,
      depletionSource: null
    }
    const ending = sys.recordEnding(ctx)
    expect(ending.id).toBe('tycoon-ending')
    expect(sys.hasEnding('tycoon-ending')).toBe(true)
    expect(sys.getUnlockedCount()).toBe(1)
  })

  test('recordEnding fires onRunEnded always', () => {
    const sys = new EndingSystem()
    const fn = vi.fn()
    sys.onRunEnded.on(fn)
    const ctx: EndingContext = {
      result: makeResult(),
      finalCareerLevel: 2,
      depletionSource: null
    }
    sys.recordEnding(ctx)
    sys.recordEnding(ctx)
    expect(fn).toHaveBeenCalledTimes(2)
  })

  test('onEndingUnlocked: isFirstTime=true only first time', () => {
    const sys = new EndingSystem()
    const fn = vi.fn()
    sys.onEndingUnlocked.on(fn)
    const ctx: EndingContext = {
      result: makeResult(),
      finalCareerLevel: 2,
      depletionSource: null
    }
    sys.recordEnding(ctx)
    sys.recordEnding(ctx)
    expect(fn).toHaveBeenCalledTimes(2)
    expect(fn).toHaveBeenNthCalledWith(1, { endingId: 'promoted-rookie', isFirstTime: true })
    expect(fn).toHaveBeenNthCalledWith(2, { endingId: 'promoted-rookie', isFirstTime: false })
  })
})

describe('Ending catalog integrity', () => {
  test('all ENDINGS have unique ids', () => {
    const ids = ENDINGS.map((e) => e.id)
    expect(new Set(ids).size).toBe(ids.length)
  })

  test('all ENDINGS have required fields', () => {
    for (const e of ENDINGS) {
      expect(e.id).toBeTruthy()
      expect(e.name).toBeTruthy()
      expect(e.description).toBeTruthy()
      expect(e.icon).toBeTruthy()
      expect(['common', 'rare', 'legendary']).toContain(e.rarity)
      expect(typeof e.matches).toBe('function')
    }
  })

  test('last entry in ENDINGS is the unconditional fallback', () => {
    const last = ENDINGS[ENDINGS.length - 1]!
    expect(
      last.matches({
        result: makeResult(),
        finalCareerLevel: 1,
        depletionSource: null
      })
    ).toBe(true)
  })

  test('getEndingById finds known + returns undefined for unknown', () => {
    expect(getEndingById('tycoon-ending')?.name).toBe('财富自由')
    expect(getEndingById('ghost')).toBeUndefined()
  })
})
