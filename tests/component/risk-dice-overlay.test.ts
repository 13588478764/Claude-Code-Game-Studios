/**
 * S3-6 RiskDiceOverlay component tests — verify outcome rendering + style class
 * application. Visual fidelity (animation timing, glow color) verified manually
 * via prototype-aligned screenshot in production/qa/evidence/s3-6-risk-dice.md.
 */

import { describe, test, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import RiskDiceOverlay from '@/components/RiskDiceOverlay.vue'

describe('RiskDiceOverlay — outcome rendering', () => {
  test('AC-3: success → green text + 成功 copy + risk-success class', () => {
    const wrapper = mount(RiskDiceOverlay, {
      props: { outcome: 'success' }
    })
    const result = wrapper.find('.risk-result-text')
    expect(result.text()).toBe('✨ 成功')
    expect(result.classes()).toContain('risk-success')
    expect(result.classes()).not.toContain('risk-fail')
  })

  test('AC-4: fail → red text + 翻车 copy + risk-fail class', () => {
    const wrapper = mount(RiskDiceOverlay, {
      props: { outcome: 'fail' }
    })
    const result = wrapper.find('.risk-result-text')
    expect(result.text()).toBe('💀 翻车')
    expect(result.classes()).toContain('risk-fail')
    expect(result.classes()).not.toContain('risk-success')
  })

  test('AC-1: dice element always present', () => {
    const wrapper = mount(RiskDiceOverlay, {
      props: { outcome: 'success' }
    })
    expect(wrapper.find('.dice').text()).toBe('🎲')
  })

  test('outcome attribute exposed on root for testability + analytics hooks', () => {
    const wrapper = mount(RiskDiceOverlay, {
      props: { outcome: 'fail' }
    })
    expect(wrapper.attributes('data-outcome')).toBe('fail')
  })
})

describe('RiskDiceOverlay — detail copy', () => {
  test('shows detail text when prop provided', () => {
    const wrapper = mount(RiskDiceOverlay, {
      props: { outcome: 'success', detail: '试试看，没准能成' }
    })
    const detail = wrapper.find('.risk-detail')
    expect(detail.exists()).toBe(true)
    expect(detail.text()).toBe('试试看，没准能成')
  })

  test('hides detail element when prop omitted', () => {
    const wrapper = mount(RiskDiceOverlay, {
      props: { outcome: 'success' }
    })
    expect(wrapper.find('.risk-detail').exists()).toBe(false)
  })

  test('hides detail element when prop is empty string', () => {
    const wrapper = mount(RiskDiceOverlay, {
      props: { outcome: 'fail', detail: '' }
    })
    expect(wrapper.find('.risk-detail').exists()).toBe(false)
  })
})
