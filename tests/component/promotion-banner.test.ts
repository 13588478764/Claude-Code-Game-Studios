/**
 * S4-8 PromotionBanner component tests — verify rendering of from→to,
 * per-job title, salary multiplier display.
 */

import { describe, test, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import PromotionBanner from '@/components/PromotionBanner.vue'

describe('PromotionBanner — render', () => {
  test('shows from→to level transition', () => {
    const wrapper = mount(PromotionBanner, {
      props: { fromLevel: 1, toLevel: 2, title: '高级工程师', newSalaryMul: 1.5 }
    })
    expect(wrapper.text()).toContain('Lv 1')
    expect(wrapper.text()).toContain('Lv 2')
  })

  test('shows per-job title (not generic)', () => {
    const wrapper = mount(PromotionBanner, {
      props: { fromLevel: 2, toLevel: 3, title: '架构师', newSalaryMul: 2.25 }
    })
    expect(wrapper.find('.promotion-title').text()).toBe('架构师')
  })

  test('shows salary multiplier with 2 decimal places', () => {
    const wrapper = mount(PromotionBanner, {
      props: { fromLevel: 1, toLevel: 2, title: 'X', newSalaryMul: 1.5 }
    })
    expect(wrapper.find('.promotion-salary').text()).toBe('薪水 ×1.50')
  })

  test('exposes data-to-level for testability', () => {
    const wrapper = mount(PromotionBanner, {
      props: { fromLevel: 1, toLevel: 4, title: 'X', newSalaryMul: 3.5 }
    })
    expect(wrapper.attributes('data-to-level')).toBe('4')
  })

  test('emoji always rendered', () => {
    const wrapper = mount(PromotionBanner, {
      props: { fromLevel: 1, toLevel: 2, title: 'X', newSalaryMul: 1.5 }
    })
    expect(wrapper.find('.promotion-emoji').text()).toBe('🎉')
  })
})
