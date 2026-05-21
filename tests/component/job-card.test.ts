/**
 * S3-2 JobCard component tests — verify three render states and tap routing.
 */

import { describe, test, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import JobCard from '@/components/JobCard.vue'
import type { JobConfig } from '@/types/job'

const programmer: JobConfig = {
  id: 'programmer',
  name: '程序员',
  icon: '💻',
  description: '代码改世界，但下班遥遥无期。',
  salaryMul: 2.0,
  baseWeight: 1.0,
  eventPack: '/x',
  initialEnergy: 80,
  initialMood: 60
}

const sales: JobConfig = {
  id: 'sales',
  name: '销售',
  icon: '🤝',
  description: 'KPI 是生命，客户是上帝，提成是信仰。',
  salaryMul: 3.0,
  baseWeight: 1.0,
  unlockCondition: { type: 'wins', value: 1 },
  eventPack: '/x'
}

const designer: JobConfig = {
  id: 'designer',
  name: '设计师',
  icon: '🎨',
  description: '能不能再大点？',
  salaryMul: 1.8,
  baseWeight: 1.0,
  unlockCondition: { type: 'totalMoney', value: 200 },
  eventPack: '/x'
}

const runner: JobConfig = {
  id: 'runner',
  name: '外卖员',
  icon: '🛵',
  description: '风里来雨里去。',
  salaryMul: 1.0,
  baseWeight: 1.0,
  unlockCondition: { type: 'deaths', value: 3 },
  eventPack: '/x'
}

describe('JobCard — render states', () => {
  test('AC-3: unlocked + non-recommended shows default style (no badge, no lock)', () => {
    const wrapper = mount(JobCard, {
      props: { job: programmer, unlocked: true, recommended: false }
    })
    expect(wrapper.classes()).not.toContain('locked')
    expect(wrapper.classes()).not.toContain('recommended')
    expect(wrapper.find('.lock-icon').exists()).toBe(false)
    expect(wrapper.find('.badge').exists()).toBe(false)
    expect(wrapper.find('.condition').exists()).toBe(false)
    expect(wrapper.text()).toContain('程序员')
  })

  test('AC-5: unlocked + recommended adds .recommended class + 推荐 badge', () => {
    const wrapper = mount(JobCard, {
      props: { job: programmer, unlocked: true, recommended: true }
    })
    expect(wrapper.classes()).toContain('recommended')
    expect(wrapper.find('.badge').exists()).toBe(true)
    expect(wrapper.find('.badge').text()).toBe('推荐')
  })

  test('AC-4: locked card adds .locked class + lock icon', () => {
    const wrapper = mount(JobCard, {
      props: { job: sales, unlocked: false, recommended: false }
    })
    expect(wrapper.classes()).toContain('locked')
    expect(wrapper.find('.lock-icon').exists()).toBe(true)
    expect(wrapper.find('.condition').exists()).toBe(true)
  })

  test('AC-4: locked + recommended ignores recommended (cannot recommend a locked job)', () => {
    const wrapper = mount(JobCard, {
      props: { job: sales, unlocked: false, recommended: true }
    })
    expect(wrapper.classes()).toContain('locked')
    expect(wrapper.classes()).not.toContain('recommended')
    expect(wrapper.find('.badge').exists()).toBe(false)
  })
})

describe('JobCard — unlock condition copy', () => {
  test('AC-4: wins condition → "通关 N 次解锁"', () => {
    const wrapper = mount(JobCard, {
      props: { job: sales, unlocked: false, recommended: false }
    })
    expect(wrapper.find('.condition').text()).toBe('通关 1 次解锁')
  })

  test('AC-4: totalMoney condition → "累计赚到 X 元解锁"', () => {
    const wrapper = mount(JobCard, {
      props: { job: designer, unlocked: false, recommended: false }
    })
    expect(wrapper.find('.condition').text()).toBe('累计赚到 200 元解锁')
  })

  test('AC-4: deaths condition → "被炒 N 次解锁"', () => {
    const wrapper = mount(JobCard, {
      props: { job: runner, unlocked: false, recommended: false }
    })
    expect(wrapper.find('.condition').text()).toBe('被炒 3 次解锁')
  })

  test('AC-4: achievement condition → "成就「name」解锁"', () => {
    const job: JobConfig = {
      ...runner,
      unlockCondition: { type: 'achievement', value: 'workaholic' }
    }
    const wrapper = mount(JobCard, {
      props: { job, unlocked: false, recommended: false }
    })
    expect(wrapper.find('.condition').text()).toBe('成就「workaholic」解锁')
  })

  test('AC-4: locked job with no condition → empty condition text', () => {
    const job: JobConfig = { ...programmer, unlockCondition: undefined }
    const wrapper = mount(JobCard, {
      props: { job, unlocked: false, recommended: false }
    })
    // Empty string still renders the element with whitespace; just assert no condition value
    const conditionEl = wrapper.find('.condition')
    expect(conditionEl.exists()).toBe(true)
    expect(conditionEl.text()).toBe('')
  })
})

describe('JobCard — tap routing', () => {
  test('AC-6: tap on unlocked emits select(jobId)', async () => {
    const wrapper = mount(JobCard, {
      props: { job: programmer, unlocked: true, recommended: false }
    })
    await wrapper.trigger('click')
    expect(wrapper.emitted('select')).toBeTruthy()
    expect(wrapper.emitted('select')![0]).toEqual(['programmer'])
    expect(wrapper.emitted('lockedTap')).toBeUndefined()
  })

  test('AC-7: tap on locked emits lockedTap (not select)', async () => {
    const wrapper = mount(JobCard, {
      props: { job: sales, unlocked: false, recommended: false }
    })
    await wrapper.trigger('click')
    expect(wrapper.emitted('lockedTap')).toBeTruthy()
    expect(wrapper.emitted('lockedTap')![0]).toEqual(['sales'])
    expect(wrapper.emitted('select')).toBeUndefined()
  })
})

describe('JobCard — touch target', () => {
  test('AC-9: card exposes data-job-id for parent identification', () => {
    const wrapper = mount(JobCard, {
      props: { job: programmer, unlocked: true, recommended: false }
    })
    expect(wrapper.attributes('data-job-id')).toBe('programmer')
  })
})
