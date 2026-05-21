/**
 * S4-2 CareerProgressionSystem unit tests — score formula, promotion thresholds,
 * snapshot round-trip, event emission, edge cases. Target 100% coverage.
 */

import { describe, test, expect, vi } from 'vitest'
import { CareerProgressionSystem } from '@/services/career/career-progression-system'
import {
  PROMOTION_THRESHOLDS,
  SALARY_MULTIPLIER_PER_LEVEL,
  LEVEL_TITLES,
  getJobLevelTitle,
  type WeekScoreInputs,
  type CareerState
} from '@/types/career'

function neutralInputs(overrides: Partial<WeekScoreInputs> = {}): WeekScoreInputs {
  return {
    endOfWeekMoney: 0,
    avgEnergy: 50,
    avgMood: 50,
    uniqueEventsThisWeek: 0,
    choicesThisWeek: 0,
    reviewBonus: 0,
    ...overrides
  }
}

describe('CareerProgressionSystem — starting state', () => {
  test('begins at level 1, score 0, weeksWorked 0', () => {
    const sys = new CareerProgressionSystem()
    expect(sys.getLevel()).toBe(1)
    expect(sys.getScore()).toBe(0)
    expect(sys.getWeeksWorked()).toBe(0)
  })

  test('starting salary multiplier is 1.0', () => {
    const sys = new CareerProgressionSystem()
    expect(sys.getSalaryMultiplier()).toBe(1.0)
  })

  test('starting title is 初出茅庐', () => {
    const sys = new CareerProgressionSystem()
    expect(sys.getTitle()).toBe('初出茅庐')
  })

  test('scoreToNextLevel returns threshold for level 2 (100)', () => {
    const sys = new CareerProgressionSystem()
    expect(sys.scoreToNextLevel()).toBe(PROMOTION_THRESHOLDS[2])
    expect(PROMOTION_THRESHOLDS[2]).toBe(100)
  })
})

describe('CareerProgressionSystem — week score formula', () => {
  test('all-neutral week → ~ +20 from resourceComp (50+50)/200 × 40', () => {
    const sys = new CareerProgressionSystem()
    const delta = sys.computeWeekScore(neutralInputs())
    expect(delta).toBe(20)
  })

  test('rich week: money 200, full resources, full variety → near max', () => {
    const sys = new CareerProgressionSystem()
    const delta = sys.computeWeekScore({
      endOfWeekMoney: 200,
      avgEnergy: 100,
      avgMood: 100,
      uniqueEventsThisWeek: 10,
      choicesThisWeek: 10,
      reviewBonus: 0
    })
    // moneyComp: clamp(200/100, -1, 2)×25 = 2×25 = 50
    // resourceComp: (100+100)/200 × 40 = 40
    // varietyComp: 10/10 × 20 = 20
    // total = 110
    expect(delta).toBe(110)
  })

  test('broke week: money -100, low resources, no variety → negative score', () => {
    const sys = new CareerProgressionSystem()
    const delta = sys.computeWeekScore({
      endOfWeekMoney: -100,
      avgEnergy: 20,
      avgMood: 20,
      uniqueEventsThisWeek: 0,
      choicesThisWeek: 5,
      reviewBonus: 0
    })
    // moneyComp: clamp(-1, -1, 2)×25 = -25
    // resourceComp: 40/200 × 40 = 8
    // varietyComp: 0
    // total = -17
    expect(delta).toBe(-17)
  })

  test('money clamps at -1 lower bound (huge debt no worse than -25)', () => {
    const sys = new CareerProgressionSystem()
    const a = sys.computeWeekScore(neutralInputs({ endOfWeekMoney: -500 }))
    const b = sys.computeWeekScore(neutralInputs({ endOfWeekMoney: -100 }))
    expect(a).toBe(b)
  })

  test('money clamps at +2 upper bound (huge wealth not better than +50)', () => {
    const sys = new CareerProgressionSystem()
    const a = sys.computeWeekScore(neutralInputs({ endOfWeekMoney: 200 }))
    const b = sys.computeWeekScore(neutralInputs({ endOfWeekMoney: 99999 }))
    expect(a).toBe(b)
  })

  test('variety ratio caps at 1 (uniqueEvents > choices)', () => {
    const sys = new CareerProgressionSystem()
    const delta = sys.computeWeekScore(neutralInputs({
      uniqueEventsThisWeek: 100,
      choicesThisWeek: 1
    }))
    // varietyComp would be 100/1 × 20 = 2000, but clamped to 1 × 20 = 20
    // neutral base = 20; total = 40
    expect(delta).toBe(40)
  })

  test('choices=0 → varietyComp 0 (no divide-by-zero)', () => {
    const sys = new CareerProgressionSystem()
    const delta = sys.computeWeekScore(neutralInputs({
      uniqueEventsThisWeek: 5,
      choicesThisWeek: 0
    }))
    expect(delta).toBe(20)  // just resourceComp
  })

  test('reviewBonus passes through unchanged', () => {
    const sys = new CareerProgressionSystem()
    const a = sys.computeWeekScore(neutralInputs({ reviewBonus: 30 }))
    const b = sys.computeWeekScore(neutralInputs({ reviewBonus: 0 }))
    expect(a - b).toBe(30)
  })
})

describe('CareerProgressionSystem — recordWeek + promotion', () => {
  test('recordWeek increments weeksWorked + adds delta to score', () => {
    const sys = new CareerProgressionSystem()
    sys.recordWeek(neutralInputs())  // +20
    expect(sys.getWeeksWorked()).toBe(1)
    expect(sys.getScore()).toBe(20)
  })

  test('emits onScoreChanged with delta + total + before-level', () => {
    const sys = new CareerProgressionSystem()
    const fn = vi.fn()
    sys.onScoreChanged.on(fn)
    sys.recordWeek(neutralInputs())
    expect(fn).toHaveBeenCalledWith({
      delta: 20,
      totalScore: 20,
      fromLevel: 1
    })
  })

  test('crossing 100 → promotes 1→2 + emits onPromoted', () => {
    const sys = new CareerProgressionSystem()
    const fn = vi.fn()
    sys.onPromoted.on(fn)
    // 50/week × 2 = 100; should promote on second tick
    sys.recordWeek(neutralInputs({ endOfWeekMoney: 100, avgEnergy: 80, avgMood: 80 }))
    expect(sys.getLevel()).toBe(1)
    sys.recordWeek(neutralInputs({ endOfWeekMoney: 100, avgEnergy: 80, avgMood: 80 }))
    expect(sys.getLevel()).toBe(2)
    expect(fn).toHaveBeenCalledTimes(1)
    expect(fn).toHaveBeenCalledWith({
      fromLevel: 1,
      toLevel: 2,
      newSalaryMul: SALARY_MULTIPLIER_PER_LEVEL[2]
    })
  })

  test('massive single tick can skip levels (1 → 3 if score > 250)', () => {
    const sys = new CareerProgressionSystem()
    const fn = vi.fn()
    sys.onPromoted.on(fn)
    sys.applyScoreDelta(300)
    expect(sys.getLevel()).toBe(3)
    // Single onPromoted event, but it reports the final landing level
    expect(fn).toHaveBeenCalledTimes(1)
    expect(fn).toHaveBeenCalledWith({
      fromLevel: 1,
      toLevel: 3,
      newSalaryMul: SALARY_MULTIPLIER_PER_LEVEL[3]
    })
  })

  test('promotion caps at level 4 (no level 5)', () => {
    const sys = new CareerProgressionSystem()
    sys.applyScoreDelta(10000)
    expect(sys.getLevel()).toBe(4)
    expect(sys.scoreToNextLevel()).toBe(Infinity)
    expect(sys.getSalaryMultiplier()).toBe(SALARY_MULTIPLIER_PER_LEVEL[4])
  })

  test('no promotion when delta keeps score below threshold', () => {
    const sys = new CareerProgressionSystem()
    const fn = vi.fn()
    sys.onPromoted.on(fn)
    sys.recordWeek(neutralInputs())
    expect(fn).not.toHaveBeenCalled()
  })
})

describe('CareerProgressionSystem — applyScoreDelta', () => {
  test('positive delta accumulates', () => {
    const sys = new CareerProgressionSystem()
    sys.applyScoreDelta(50)
    expect(sys.getScore()).toBe(50)
  })

  test('negative delta deducts but floors at 0', () => {
    const sys = new CareerProgressionSystem()
    sys.applyScoreDelta(20)
    sys.applyScoreDelta(-50)
    expect(sys.getScore()).toBe(0)  // floor
  })

  test('applyScoreDelta also fires onScoreChanged', () => {
    const sys = new CareerProgressionSystem()
    const fn = vi.fn()
    sys.onScoreChanged.on(fn)
    sys.applyScoreDelta(30)
    expect(fn).toHaveBeenCalledWith({
      delta: 30,
      totalScore: 30,
      fromLevel: 1
    })
  })
})

describe('CareerProgressionSystem — reset + snapshot', () => {
  test('reset returns to starting state', () => {
    const sys = new CareerProgressionSystem()
    sys.applyScoreDelta(300)
    sys.reset()
    expect(sys.getLevel()).toBe(1)
    expect(sys.getScore()).toBe(0)
    expect(sys.getWeeksWorked()).toBe(0)
  })

  test('getSnapshot returns level + score + weeksWorked', () => {
    const sys = new CareerProgressionSystem()
    sys.applyScoreDelta(50)
    sys.recordWeek(neutralInputs())
    const snap = sys.getSnapshot()
    expect(snap.level).toBe(1)
    expect(snap.score).toBe(70)
    expect(snap.weeksWorked).toBe(1)
  })

  test('loadSnapshot restores all state', () => {
    const sys = new CareerProgressionSystem()
    const snap: CareerState = { level: 3, score: 280, weeksWorked: 3 }
    sys.loadSnapshot(snap)
    expect(sys.getLevel()).toBe(3)
    expect(sys.getScore()).toBe(280)
    expect(sys.getWeeksWorked()).toBe(3)
    expect(sys.getTitle()).toBe(LEVEL_TITLES[3])
  })

  test('loadSnapshot with invalid level falls back to 1', () => {
    const sys = new CareerProgressionSystem()
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    sys.loadSnapshot({ level: 99 as any, score: 100, weeksWorked: 1 })
    expect(sys.getLevel()).toBe(1)
  })

  test('loadSnapshot clamps negative score to 0', () => {
    const sys = new CareerProgressionSystem()
    sys.loadSnapshot({ level: 1, score: -50, weeksWorked: 1 })
    expect(sys.getScore()).toBe(0)
  })

  test('loadSnapshot clamps negative weeksWorked to 0', () => {
    const sys = new CareerProgressionSystem()
    sys.loadSnapshot({ level: 1, score: 0, weeksWorked: -3 })
    expect(sys.getWeeksWorked()).toBe(0)
  })
})

describe('getJobLevelTitle — per-job ladder resolution', () => {
  const programmerLadder = ['初级码农', '高级工程师', '架构师', '技术总监'] as const

  test('returns job-specific title at each level', () => {
    expect(getJobLevelTitle(programmerLadder, 1)).toBe('初级码农')
    expect(getJobLevelTitle(programmerLadder, 2)).toBe('高级工程师')
    expect(getJobLevelTitle(programmerLadder, 3)).toBe('架构师')
    expect(getJobLevelTitle(programmerLadder, 4)).toBe('技术总监')
  })

  test('falls back to generic LEVEL_TITLES when ladder is undefined', () => {
    expect(getJobLevelTitle(undefined, 1)).toBe(LEVEL_TITLES[1])
    expect(getJobLevelTitle(undefined, 4)).toBe(LEVEL_TITLES[4])
  })

  test('falls back to generic when ladder is too short', () => {
    expect(getJobLevelTitle(['只有一个'], 2)).toBe(LEVEL_TITLES[2])
  })

  test('falls back at index when ladder slot is empty/undefined', () => {
    // 4-length but with explicit undefined slot — pathological data
    const broken = ['一', undefined as unknown as string, '三', '四']
    expect(getJobLevelTitle(broken, 2)).toBe(LEVEL_TITLES[2])
  })
})

describe('CareerProgressionSystem — scoreToNextLevel', () => {
  test('at level 1 score 0 → returns 100', () => {
    const sys = new CareerProgressionSystem()
    expect(sys.scoreToNextLevel()).toBe(100)
  })

  test('at level 1 score 60 → returns 40 (delta to 100)', () => {
    const sys = new CareerProgressionSystem()
    sys.applyScoreDelta(60)
    expect(sys.scoreToNextLevel()).toBe(40)
  })

  test('at level 2 score 100 → returns 150 (delta to 250)', () => {
    const sys = new CareerProgressionSystem()
    sys.applyScoreDelta(100)
    expect(sys.getLevel()).toBe(2)
    expect(sys.scoreToNextLevel()).toBe(150)
  })

  test('overshoot at current level → returns 0 (already at/past threshold)', () => {
    const sys = new CareerProgressionSystem()
    sys.applyScoreDelta(100)  // exactly at threshold → promoted to 2
    expect(sys.getLevel()).toBe(2)
    // Next level (3) threshold is 250; score is 100; gap is 150
    expect(sys.scoreToNextLevel()).toBe(150)
  })
})
