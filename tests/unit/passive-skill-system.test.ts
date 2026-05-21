/**
 * S3-9 PassiveSkillSystem unit tests — covers the example skill (厚脸皮 Lv1)
 * + applyToEffect math + checkUnlocks + persistence round-trip + 100% line coverage.
 */

import { describe, test, expect, vi } from 'vitest'
import { PassiveSkillSystem } from '@/services/passive-skill/passive-skill-system'
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

describe('PassiveSkillSystem — applyToEffect identity (AC-3)', () => {
  test('default no skills → applyToEffect returns rawValue unchanged', () => {
    const sys = new PassiveSkillSystem()
    expect(sys.applyToEffect('mood', -10)).toBe(-10)
    expect(sys.applyToEffect('energy', 20)).toBe(20)
    expect(sys.applyToEffect('mood', 0)).toBe(0)
  })

  test('init([]) preserves identity', () => {
    const sys = new PassiveSkillSystem()
    sys.init([])
    expect(sys.applyToEffect('mood', -10)).toBe(-10)
    expect(sys.getUnlocked()).toEqual([])
  })

  test('init with unknown ids drops them silently', () => {
    const sys = new PassiveSkillSystem()
    sys.init(['ghost-skill', 'imaginary-buff'])
    expect(sys.getUnlocked()).toEqual([])
    expect(sys.applyToEffect('mood', -10)).toBe(-10)
  })
})

describe('PassiveSkillSystem — thick-skin-1 mood reduction (AC-2)', () => {
  test('unlocked thick-skin-1 → mood loss reduced 20%', () => {
    const sys = new PassiveSkillSystem()
    sys.unlockSkill('thick-skin-1')
    // -10 × 0.8 = -8
    expect(sys.applyToEffect('mood', -10)).toBe(-8)
  })

  test('thick-skin-1 also reduces positive mood gain by same factor (mul applies both ways)', () => {
    const sys = new PassiveSkillSystem()
    sys.unlockSkill('thick-skin-1')
    // +10 × 0.8 = +8 (signFloor(8) = 8)
    expect(sys.applyToEffect('mood', 10)).toBe(8)
  })

  test('thick-skin-1 does not affect energy (no energyMul on skill)', () => {
    const sys = new PassiveSkillSystem()
    sys.unlockSkill('thick-skin-1')
    expect(sys.applyToEffect('energy', -20)).toBe(-20)
    expect(sys.applyToEffect('energy', 30)).toBe(30)
  })

  test('signFloor rounds toward zero on both sides', () => {
    const sys = new PassiveSkillSystem()
    sys.unlockSkill('thick-skin-1')
    // -7 × 0.8 = -5.6 → ceil to -5 (toward zero)
    expect(sys.applyToEffect('mood', -7)).toBe(-5)
    // 7 × 0.8 = 5.6 → floor to 5 (toward zero)
    expect(sys.applyToEffect('mood', 7)).toBe(5)
  })

  test('signFloor of zero stays zero', () => {
    const sys = new PassiveSkillSystem()
    sys.unlockSkill('thick-skin-1')
    expect(sys.applyToEffect('mood', 0)).toBe(0)
  })

  test('signFloor coerces small results to canonical 0 (not -0)', () => {
    const sys = new PassiveSkillSystem()
    sys.unlockSkill('thick-skin-1')
    // 1 × 0.8 = 0.8 → floor = 0 → coerced to canonical 0
    expect(Object.is(sys.applyToEffect('mood', 1), 0)).toBe(true)
    // -1 × 0.8 = -0.8 → ceil = -0 → coerced to canonical 0 (not -0)
    expect(Object.is(sys.applyToEffect('mood', -1), 0)).toBe(true)
  })
})

describe('PassiveSkillSystem — checkUnlocks (AC-5)', () => {
  test('totalWins<3 → no unlock', () => {
    const sys = new PassiveSkillSystem()
    expect(sys.checkUnlocks(emptyStats({ totalWins: 0 }))).toEqual([])
    expect(sys.checkUnlocks(emptyStats({ totalWins: 2 }))).toEqual([])
  })

  test('totalWins>=3 → thick-skin-1 unlocks', () => {
    const sys = new PassiveSkillSystem()
    expect(sys.checkUnlocks(emptyStats({ totalWins: 3 }))).toEqual(['thick-skin-1'])
    expect(sys.hasSkill('thick-skin-1')).toBe(true)
  })

  test('checkUnlocks emits onSkillUnlocked', () => {
    const sys = new PassiveSkillSystem()
    const fn = vi.fn()
    sys.onSkillUnlocked.on(fn)
    sys.checkUnlocks(emptyStats({ totalWins: 5 }))
    expect(fn).toHaveBeenCalledWith({ skillId: 'thick-skin-1' })
  })

  test('checkUnlocks called twice does not re-unlock', () => {
    const sys = new PassiveSkillSystem()
    sys.checkUnlocks(emptyStats({ totalWins: 5 }))
    const second = sys.checkUnlocks(emptyStats({ totalWins: 6 }))
    expect(second).toEqual([])  // already unlocked, no new unlocks
  })

  test('checkUnlocks idempotent emit — no duplicate events', () => {
    const sys = new PassiveSkillSystem()
    const fn = vi.fn()
    sys.onSkillUnlocked.on(fn)
    sys.checkUnlocks(emptyStats({ totalWins: 3 }))
    sys.checkUnlocks(emptyStats({ totalWins: 4 }))
    expect(fn).toHaveBeenCalledTimes(1)
  })
})

describe('PassiveSkillSystem — unlockSkill direct API', () => {
  test('returns true on first unlock + emits', () => {
    const sys = new PassiveSkillSystem()
    const fn = vi.fn()
    sys.onSkillUnlocked.on(fn)
    expect(sys.unlockSkill('thick-skin-1')).toBe(true)
    expect(fn).toHaveBeenCalledTimes(1)
    expect(sys.hasSkill('thick-skin-1')).toBe(true)
  })

  test('returns false on duplicate unlock + no re-emit', () => {
    const sys = new PassiveSkillSystem()
    const fn = vi.fn()
    sys.onSkillUnlocked.on(fn)
    sys.unlockSkill('thick-skin-1')
    expect(sys.unlockSkill('thick-skin-1')).toBe(false)
    expect(fn).toHaveBeenCalledTimes(1)
  })

  test('returns false for unknown id + no emit', () => {
    const sys = new PassiveSkillSystem()
    const fn = vi.fn()
    sys.onSkillUnlocked.on(fn)
    expect(sys.unlockSkill('nonexistent-skill')).toBe(false)
    expect(fn).not.toHaveBeenCalled()
  })
})

describe('PassiveSkillSystem — persistence round-trip (AC-4)', () => {
  test('init from save restores unlocked set', () => {
    const sys = new PassiveSkillSystem()
    sys.init(['thick-skin-1'])
    expect(sys.hasSkill('thick-skin-1')).toBe(true)
    expect(sys.applyToEffect('mood', -10)).toBe(-8)  // active
  })

  test('getUnlocked returns sorted-stable list for save serialization', () => {
    const sys = new PassiveSkillSystem()
    sys.unlockSkill('thick-skin-1')
    expect(sys.getUnlocked()).toEqual(['thick-skin-1'])
  })

  test('getUnlockedSkills returns full skill objects', () => {
    const sys = new PassiveSkillSystem()
    sys.unlockSkill('thick-skin-1')
    const skills = sys.getUnlockedSkills()
    expect(skills).toHaveLength(1)
    expect(skills[0]!.id).toBe('thick-skin-1')
    expect(skills[0]!.moodMul).toBe(0.8)
  })

  test('getUnlockedSkills filters out unknown ids gracefully', () => {
    const sys = new PassiveSkillSystem()
    // Forcibly inject unknown via init path
    sys.init(['thick-skin-1', 'unknown-id'])
    expect(sys.getUnlockedSkills()).toHaveLength(1)
  })
})

describe('PassiveSkillSystem — backward compat (AC-7)', () => {
  test('Sprint 1+2 behavior preserved when no passive deps configured', () => {
    // The engine's passiveApplyToEffect dep is optional; absent → identity.
    // This test simulates that contract: applyToEffect is never called when
    // engine has no passive dep. Here we just confirm the system itself
    // is a pure identity transform with no skills.
    const sys = new PassiveSkillSystem()
    for (const v of [-100, -50, -10, 0, 10, 50, 100]) {
      expect(sys.applyToEffect('energy', v)).toBe(v)
      expect(sys.applyToEffect('mood', v)).toBe(v)
    }
  })
})
