import { describe, test, expect, vi } from 'vitest'
import { JobRotationSystem } from '@/services/job-rotation/job-rotation-system'
import { EMPTY_SAVE, type SaveData } from '@/types/save'

function mkSave(overrides: Partial<SaveData> = {}): SaveData {
  return { ...EMPTY_SAVE, ...overrides }
}

describe('JobRotationSystem', () => {
  test('init: default unlocks intern + programmer', () => {
    const jr = new JobRotationSystem()
    jr.init(null)
    const ids = jr.getUnlocked()
    expect(ids).toContain('intern')
    expect(ids).toContain('programmer')
    expect(ids).not.toContain('sales')
  })

  test('init from saveData uses provided unlocks', () => {
    const jr = new JobRotationSystem()
    jr.init(mkSave({ jobUnlocks: ['intern', 'programmer', 'sales'] }))
    expect(jr.getUnlocked()).toContain('sales')
  })

  test('selectJob() throws on unknown', () => {
    const jr = new JobRotationSystem()
    jr.init(null)
    expect(() => jr.selectJob('martian')).toThrow()
  })

  test('selectJob() throws on locked', () => {
    const jr = new JobRotationSystem()
    jr.init(null)
    expect(() => jr.selectJob('sales')).toThrow()
  })

  test('selectJob() emits onJobSelected', () => {
    const jr = new JobRotationSystem()
    jr.init(null)
    const fn = vi.fn()
    jr.onJobSelected.on(fn)
    jr.selectJob('programmer')
    expect(fn).toHaveBeenCalledWith({ jobId: 'programmer' })
  })

  test('checkUnlocks unlocks based on save stats', () => {
    const jr = new JobRotationSystem()
    jr.init(null)
    const fn = vi.fn()
    jr.onJobUnlocked.on(fn)
    const newly = jr.checkUnlocks({
      ...EMPTY_SAVE.stats,
      totalWins: 1
    })
    expect(newly).toContain('sales')
    expect(jr.getUnlocked()).toContain('sales')
    expect(fn).toHaveBeenCalledWith({ jobId: 'sales' })
  })

  test('checkUnlocks: totalMoney threshold', () => {
    const jr = new JobRotationSystem()
    jr.init(null)
    const newly = jr.checkUnlocks({ ...EMPTY_SAVE.stats, totalMoneyEarned: 200 })
    expect(newly).toContain('designer')
  })

  test('checkUnlocks: deaths threshold', () => {
    const jr = new JobRotationSystem()
    jr.init(null)
    const newly = jr.checkUnlocks({ ...EMPTY_SAVE.stats, totalDeaths: 3 })
    expect(newly).toContain('runner')
  })

  test('recommend: never played gets boost', () => {
    const jr = new JobRotationSystem()
    jr.init(mkSave({ jobUnlocks: ['intern', 'programmer'] }))
    // Mark intern as played
    jr.selectJob('intern')

    const recs = jr.getRecommendedJobs(2)
    // Programmer is never-played → should be ranked higher
    expect(recs[0]?.id).toBe('programmer')
  })

  test('recommend: recently played gets nerf', () => {
    const jr = new JobRotationSystem()
    jr.init(mkSave({
      jobUnlocks: ['intern', 'programmer', 'sales'],
      stats: {
        ...EMPTY_SAVE.stats,
        jobsPlayed: { intern: 1, programmer: 1, sales: 1 }
      }
    }))
    jr.selectJob('intern')  // most recent
    const recs = jr.getRecommendedJobs(3)
    expect(recs[recs.length - 1]?.id).toBe('intern')
  })

  test('recommend: locked jobs excluded', () => {
    const jr = new JobRotationSystem()
    jr.init(null)
    const recs = jr.getRecommendedJobs(5)
    expect(recs.every((j) => ['intern', 'programmer'].includes(j.id))).toBe(true)
  })

  test('checkUnlocks does not re-emit for already unlocked jobs', () => {
    const jr = new JobRotationSystem()
    jr.init(mkSave({ jobUnlocks: ['intern', 'programmer', 'sales'] }))
    const fn = vi.fn()
    jr.onJobUnlocked.on(fn)
    jr.checkUnlocks({ ...EMPTY_SAVE.stats, totalWins: 1 })
    expect(fn).not.toHaveBeenCalled()
  })

  test('getAvailableJobs returns only unlocked', () => {
    const jr = new JobRotationSystem()
    jr.init(null)
    const avail = jr.getAvailableJobs()
    expect(avail.map((j) => j.id).sort()).toEqual(['intern', 'programmer'])
  })
})
