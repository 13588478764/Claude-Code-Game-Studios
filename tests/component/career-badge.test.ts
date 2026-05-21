/**
 * H-2 CareerBadge component tests — render + progress calc + max-level state.
 */

import { describe, test, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import CareerBadge from '@/components/CareerBadge.vue'

describe('CareerBadge', () => {
  test('Lv 1 with 50/100 score shows 50% progress + "50 / 100"', () => {
    const wrapper = mount(CareerBadge, {
      props: { level: 1, score: 50, title: '初级码农' }
    })
    expect(wrapper.text()).toContain('Lv 1')
    expect(wrapper.text()).toContain('初级码农')
    expect(wrapper.text()).toContain('50 / 100')
    const fill = wrapper.find('.bar-fill')
    expect(fill.attributes('style')).toContain('width: 50%')
  })

  test('Lv 2 with 175 score shows mid-range progress to Lv3 (175-100 = 75/150)', () => {
    const wrapper = mount(CareerBadge, {
      props: { level: 2, score: 175, title: '高级工程师' }
    })
    expect(wrapper.text()).toContain('Lv 2')
    expect(wrapper.text()).toContain('175 / 250')
    // (175-100)/(250-100) = 75/150 = 50%
    const fill = wrapper.find('.bar-fill')
    expect(fill.attributes('style')).toContain('width: 50%')
  })

  test('Lv 4 shows MAX text + fill-max class', () => {
    const wrapper = mount(CareerBadge, {
      props: { level: 4, score: 500, title: '技术总监' }
    })
    expect(wrapper.text()).toContain('Lv 4')
    expect(wrapper.text()).toContain('MAX')
    expect(wrapper.find('.bar-fill').classes()).toContain('fill-max')
  })

  test('progress clamps at 0 when score below current threshold (shouldnt happen but defensive)', () => {
    const wrapper = mount(CareerBadge, {
      props: { level: 2, score: 50, title: 'X' }
    })
    // 50 < 100 (Lv2 threshold) — into = max(0, 50-100) = 0
    const fill = wrapper.find('.bar-fill')
    expect(fill.attributes('style')).toContain('width: 0%')
  })

  test('progress clamps at 100 when score exceeds next threshold', () => {
    const wrapper = mount(CareerBadge, {
      props: { level: 1, score: 200, title: 'X' }  // Lv1 at 200 → should have promoted
    })
    const fill = wrapper.find('.bar-fill')
    expect(fill.attributes('style')).toContain('width: 100%')
  })

  test('exposes data-level attribute', () => {
    const wrapper = mount(CareerBadge, {
      props: { level: 3, score: 280, title: '架构师' }
    })
    expect(wrapper.attributes('data-level')).toBe('3')
  })
})
