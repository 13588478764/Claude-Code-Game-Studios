/**
 * S4-9 LowEnergyHint component tests — render + emit on tap.
 */

import { describe, test, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import LowEnergyHint from '@/components/LowEnergyHint.vue'

describe('LowEnergyHint', () => {
  test('renders the energy + shop CTA copy', () => {
    const wrapper = mount(LowEnergyHint, {
      props: { energy: 20, money: 50 }
    })
    expect(wrapper.text()).toContain('体力快空了')
    expect(wrapper.text()).toContain('商店')
  })

  test('exposes data-test-id="low-energy-hint" for parent test queries', () => {
    const wrapper = mount(LowEnergyHint, {
      props: { energy: 20, money: 50 }
    })
    expect(wrapper.attributes('data-test-id')).toBe('low-energy-hint')
  })

  test('tap emits open-shop event', async () => {
    const wrapper = mount(LowEnergyHint, {
      props: { energy: 20, money: 50 }
    })
    await wrapper.trigger('click')
    expect(wrapper.emitted('open-shop')).toHaveLength(1)
  })
})
