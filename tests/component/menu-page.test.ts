/**
 * S3-10 MenuPage component tests — read-only render of stats / unlocked
 * jobs / unlocked passive skills + back-button routing.
 */

import { describe, test, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import MenuPage from '@/subpackages/ui/menu/index.vue'
import { useProgressionStore } from '@/stores/progression-store'
import { usePassiveSkillStore } from '@/stores/passive-skill-store'

let navigateBackSpy: ReturnType<typeof vi.fn>

beforeEach(() => {
  setActivePinia(createPinia())
  navigateBackSpy = vi.fn()
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  ;(globalThis as any).uni = {
    navigateBack: navigateBackSpy,
    navigateTo: vi.fn(),
    reLaunch: vi.fn(),
    showToast: vi.fn()
  }
})

describe('MenuPage — stats grid (AC-2)', () => {
  test('renders 4 stat cards: wins / runs / unlocked jobs / total money', async () => {
    const progression = useProgressionStore()
    progression.stats = {
      totalRuns: 7,
      totalWins: 3,
      totalDeaths: 4,
      totalMoneyEarned: 580,
      jobsPlayed: { programmer: 5, intern: 2 },
      achievements: []
    }
    const wrapper = mount(MenuPage)
    await wrapper.vm.$nextTick()

    const cards = wrapper.findAll('.stat-card')
    expect(cards).toHaveLength(5)  // G-4 added 解锁结局 card
    const text = wrapper.text()
    expect(text).toContain('3 次')   // totalWins
    expect(text).toContain('7 次')   // totalRuns
    expect(text).toContain('580 元') // totalMoneyEarned
  })

  test('shows unlocked-job count out of total catalog', async () => {
    const wrapper = mount(MenuPage)
    await wrapper.vm.$nextTick()
    // Default-unlocked: intern + programmer (2). Catalog has 8 jobs total
    // (intern + programmer + sales + designer + runner + researcher + slacker + fortune).
    expect(wrapper.text()).toContain('2 / 8')
  })
})

describe('MenuPage — unlocked jobs list (AC-3)', () => {
  test('renders intern + programmer rows with playCount from stats', async () => {
    const progression = useProgressionStore()
    progression.stats = {
      ...progression.stats,
      jobsPlayed: { programmer: 5, intern: 2 }
    }
    const wrapper = mount(MenuPage)
    await wrapper.vm.$nextTick()

    const rows = wrapper.findAll('[data-job-id]')
    expect(rows.length).toBeGreaterThanOrEqual(2)
    const programmerRow = rows.find((r) => r.attributes('data-job-id') === 'programmer')
    const internRow = rows.find((r) => r.attributes('data-job-id') === 'intern')
    expect(programmerRow).toBeDefined()
    expect(internRow).toBeDefined()
    expect(programmerRow!.text()).toContain('玩过 5 次')
    expect(internRow!.text()).toContain('玩过 2 次')
  })

  test('unplayed unlocked jobs show "玩过 0 次"', async () => {
    const progression = useProgressionStore()
    progression.stats = {
      ...progression.stats,
      jobsPlayed: {}
    }
    const wrapper = mount(MenuPage)
    await wrapper.vm.$nextTick()
    const rows = wrapper.findAll('[data-job-id]')
    expect(rows[0]!.text()).toContain('玩过 0 次')
  })
})

describe('MenuPage — passive skills list (AC-4)', () => {
  test('empty state when no skills unlocked', async () => {
    const wrapper = mount(MenuPage)
    await wrapper.vm.$nextTick()
    const skillRows = wrapper.findAll('[data-skill-id]')
    expect(skillRows).toHaveLength(0)
    expect(wrapper.text()).toContain('还没有解锁的被动技能')
  })

  test('renders thick-skin-1 row when unlocked', async () => {
    const passive = usePassiveSkillStore()
    passive.unlockedIds = ['thick-skin-1']
    const wrapper = mount(MenuPage)
    await wrapper.vm.$nextTick()

    const rows = wrapper.findAll('[data-skill-id]')
    expect(rows).toHaveLength(1)
    expect(rows[0]!.attributes('data-skill-id')).toBe('thick-skin-1')
    expect(rows[0]!.text()).toContain('厚脸皮 Lv1')
    expect(rows[0]!.text()).toContain('心情损失减少')
  })

  test('unknown skill ids are filtered out gracefully', async () => {
    const passive = usePassiveSkillStore()
    passive.unlockedIds = ['thick-skin-1', 'ghost-skill-99']
    const wrapper = mount(MenuPage)
    await wrapper.vm.$nextTick()
    const rows = wrapper.findAll('[data-skill-id]')
    expect(rows).toHaveLength(1)
  })
})

describe('MenuPage — back button (AC-5)', () => {
  test('tap 返回 → uni.navigateBack({ delta: 1 })', async () => {
    const wrapper = mount(MenuPage)
    await wrapper.vm.$nextTick()
    await wrapper.find('.btn-back').trigger('click')
    expect(navigateBackSpy).toHaveBeenCalledWith({ delta: 1 })
  })
})
