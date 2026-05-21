/**
 * C-2 AchievementSystem unit tests — catalog evaluation, persistence,
 * manual unlock, event emission, edge cases. Target 100% coverage.
 */

import { describe, test, expect, vi } from 'vitest'
import { AchievementSystem } from '@/services/achievement/achievement-system'
import { ACHIEVEMENTS, evaluateAchievementCondition } from '@/types/achievement'
import type { GlobalStats } from '@/types/save'

function emptyStats(overrides: Partial<GlobalStats> = {}): GlobalStats {
  return {
    totalRuns: 0,
    totalWins: 0,
    totalDeaths: 0,
    totalMoneyEarned: 0,
    jobsPlayed: {},
    achievements: [],
    ...overrides
  }
}

describe('AchievementSystem — starting state', () => {
  test('begins with no unlocked achievements', () => {
    const sys = new AchievementSystem()
    expect(sys.getUnlocked()).toEqual([])
  })

  test('init([]) preserves empty state', () => {
    const sys = new AchievementSystem()
    sys.init([])
    expect(sys.getUnlocked()).toEqual([])
  })

  test('init with known ids restores them', () => {
    const sys = new AchievementSystem()
    sys.init(['first-blood', 'first-win'])
    expect(sys.hasAchievement('first-blood')).toBe(true)
    expect(sys.hasAchievement('first-win')).toBe(true)
  })

  test('init drops unknown ids silently', () => {
    const sys = new AchievementSystem()
    sys.init(['first-blood', 'ghost-achievement'])
    expect(sys.hasAchievement('first-blood')).toBe(true)
    expect(sys.hasAchievement('ghost-achievement')).toBe(false)
  })

  test('getUnlockedAchievements returns full Achievement objects', () => {
    const sys = new AchievementSystem()
    sys.init(['first-blood'])
    const list = sys.getUnlockedAchievements()
    expect(list).toHaveLength(1)
    expect(list[0]!.id).toBe('first-blood')
    expect(list[0]!.name).toBe('初出茅庐')
  })

  test('getUnlockedAchievements filters out invalid ids defensively', () => {
    const sys = new AchievementSystem()
    sys.init(['first-blood', 'fake'])  // fake dropped by init filter
    expect(sys.getUnlockedAchievements()).toHaveLength(1)
  })
})

describe('AchievementSystem — manual unlock', () => {
  test('returns true on first unlock + emits event', () => {
    const sys = new AchievementSystem()
    const fn = vi.fn()
    sys.onAchievementUnlocked.on(fn)
    expect(sys.unlockAchievement('first-blood')).toBe(true)
    expect(fn).toHaveBeenCalledWith({ achievementId: 'first-blood' })
    expect(sys.hasAchievement('first-blood')).toBe(true)
  })

  test('returns false on duplicate + no re-emit', () => {
    const sys = new AchievementSystem()
    const fn = vi.fn()
    sys.onAchievementUnlocked.on(fn)
    sys.unlockAchievement('first-blood')
    expect(sys.unlockAchievement('first-blood')).toBe(false)
    expect(fn).toHaveBeenCalledTimes(1)
  })

  test('returns false for unknown id + no emit', () => {
    const sys = new AchievementSystem()
    const fn = vi.fn()
    sys.onAchievementUnlocked.on(fn)
    expect(sys.unlockAchievement('does-not-exist')).toBe(false)
    expect(fn).not.toHaveBeenCalled()
  })
})

describe('AchievementSystem — checkUnlocks (stats-driven)', () => {
  test('runs threshold: 1 run → first-blood unlocks', () => {
    const sys = new AchievementSystem()
    const newly = sys.checkUnlocks(emptyStats({ totalRuns: 1 }))
    expect(newly).toContain('first-blood')
  })

  test('wins threshold: 1 win → first-win unlocks', () => {
    const sys = new AchievementSystem()
    const newly = sys.checkUnlocks(emptyStats({ totalWins: 1 }))
    expect(newly).toContain('first-win')
  })

  test('5 wins triggers both first-win + workaholic', () => {
    const sys = new AchievementSystem()
    const newly = sys.checkUnlocks(emptyStats({ totalWins: 5, totalRuns: 6 }))
    expect(newly).toContain('first-win')
    expect(newly).toContain('workaholic')
    expect(newly).toContain('first-blood')
  })

  test('deaths threshold: 5 deaths → broke-survivor unlocks', () => {
    const sys = new AchievementSystem()
    const newly = sys.checkUnlocks(emptyStats({ totalDeaths: 5 }))
    expect(newly).toContain('broke-survivor')
  })

  test('totalMoney threshold: 1000 → small-bank unlocks', () => {
    const sys = new AchievementSystem()
    const newly = sys.checkUnlocks(emptyStats({ totalMoneyEarned: 1000 }))
    expect(newly).toContain('small-bank')
  })

  test('jobPlays threshold: programmer 5 → code-veteran unlocks', () => {
    const sys = new AchievementSystem()
    const newly = sys.checkUnlocks(
      emptyStats({ jobsPlayed: { programmer: 5 } })
    )
    expect(newly).toContain('code-veteran')
  })

  test('jobsTried threshold: 3 distinct jobs → jack-of-trades unlocks', () => {
    const sys = new AchievementSystem()
    const newly = sys.checkUnlocks(
      emptyStats({ jobsPlayed: { programmer: 1, intern: 1, sales: 1 } })
    )
    expect(newly).toContain('jack-of-trades')
  })

  test('checkUnlocks emits onAchievementUnlocked for each new', () => {
    const sys = new AchievementSystem()
    const fn = vi.fn()
    sys.onAchievementUnlocked.on(fn)
    sys.checkUnlocks(emptyStats({ totalRuns: 1, totalWins: 1 }))
    // first-blood + first-win
    expect(fn).toHaveBeenCalledTimes(2)
  })

  test('checkUnlocks idempotent — second call does not re-emit', () => {
    const sys = new AchievementSystem()
    const fn = vi.fn()
    sys.onAchievementUnlocked.on(fn)
    sys.checkUnlocks(emptyStats({ totalRuns: 1 }))
    sys.checkUnlocks(emptyStats({ totalRuns: 2 }))
    expect(fn).toHaveBeenCalledTimes(1)  // only first-blood once
  })

  test('returns empty array when nothing new unlocks', () => {
    const sys = new AchievementSystem()
    expect(sys.checkUnlocks(emptyStats())).toEqual([])
  })
})

describe('evaluateAchievementCondition — formula coverage', () => {
  test('runs condition compares totalRuns >= value', () => {
    expect(
      evaluateAchievementCondition({ type: 'runs', value: 5 }, emptyStats({ totalRuns: 4 }))
    ).toBe(false)
    expect(
      evaluateAchievementCondition({ type: 'runs', value: 5 }, emptyStats({ totalRuns: 5 }))
    ).toBe(true)
  })

  test('wins condition compares totalWins >= value', () => {
    expect(
      evaluateAchievementCondition({ type: 'wins', value: 3 }, emptyStats({ totalWins: 2 }))
    ).toBe(false)
    expect(
      evaluateAchievementCondition({ type: 'wins', value: 3 }, emptyStats({ totalWins: 3 }))
    ).toBe(true)
  })

  test('deaths condition compares totalDeaths >= value', () => {
    expect(
      evaluateAchievementCondition(
        { type: 'deaths', value: 2 },
        emptyStats({ totalDeaths: 2 })
      )
    ).toBe(true)
  })

  test('totalMoney condition compares totalMoneyEarned >= value', () => {
    expect(
      evaluateAchievementCondition(
        { type: 'totalMoney', value: 500 },
        emptyStats({ totalMoneyEarned: 500 })
      )
    ).toBe(true)
  })

  test('jobPlays condition compares jobsPlayed[jobId] >= value', () => {
    expect(
      evaluateAchievementCondition(
        { type: 'jobPlays', jobId: 'sales', value: 2 },
        emptyStats({ jobsPlayed: { sales: 2 } })
      )
    ).toBe(true)
    expect(
      evaluateAchievementCondition(
        { type: 'jobPlays', jobId: 'sales', value: 2 },
        emptyStats({ jobsPlayed: { sales: 1 } })
      )
    ).toBe(false)
    expect(
      evaluateAchievementCondition(
        { type: 'jobPlays', jobId: 'never-played', value: 1 },
        emptyStats()
      )
    ).toBe(false)
  })

  test('jobsTried condition compares distinct jobsPlayed keys >= value', () => {
    expect(
      evaluateAchievementCondition(
        { type: 'jobsTried', value: 2 },
        emptyStats({ jobsPlayed: { a: 1, b: 1 } })
      )
    ).toBe(true)
    expect(
      evaluateAchievementCondition(
        { type: 'jobsTried', value: 3 },
        emptyStats({ jobsPlayed: { a: 1, b: 1 } })
      )
    ).toBe(false)
  })

  test('unknown condition type returns false (defensive)', () => {
    // Force an unknown branch via cast
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const cond = { type: 'unknown-type', value: 1 } as any
    expect(evaluateAchievementCondition(cond, emptyStats())).toBe(false)
  })
})

describe('AchievementSystem — catalog integrity', () => {
  test('all ACHIEVEMENTS have unique ids', () => {
    const ids = ACHIEVEMENTS.map((a) => a.id)
    expect(new Set(ids).size).toBe(ids.length)
  })

  test('all ACHIEVEMENTS have required fields', () => {
    for (const a of ACHIEVEMENTS) {
      expect(a.id).toBeTruthy()
      expect(a.name).toBeTruthy()
      expect(a.description).toBeTruthy()
      expect(a.icon).toBeTruthy()
      expect(a.unlockCondition).toBeTruthy()
    }
  })
})
