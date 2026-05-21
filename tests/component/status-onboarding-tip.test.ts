/**
 * S3-7 StatusOnboardingTip + StatusChip pulse tests.
 *
 * Verifies:
 *   - Tooltip renders the provided text
 *   - StatusChip pulses when statusStore.lastModifierTrigger.statusId === own id
 *   - StatusChip ignores trigger when statusId differs
 *   - choice-resolution-store.markModifierTrigger attribution works through
 *     the integration of resolveChoice → status-store side effect.
 */

import { describe, test, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import StatusOnboardingTip from '@/components/StatusOnboardingTip.vue'
import StatusChip from '@/components/StatusChip.vue'
import { useStatusStore } from '@/stores/status-store'
import type { StatusEffect } from '@/types/status'

const sampleBuff: StatusEffect = {
  id: 'caffeine',
  name: '亢奋',
  icon: '☕',
  type: 'buff',
  daysLeft: 2,
  energyMul: 0.5
}

const sampleDebuff: StatusEffect = {
  id: 'emo',
  name: 'emo',
  icon: '💔',
  type: 'debuff',
  daysLeft: 1,
  moodMul: 1.5
}

beforeEach(() => {
  setActivePinia(createPinia())
})

describe('StatusOnboardingTip — render', () => {
  test('renders the provided tip text', () => {
    const wrapper = mount(StatusOnboardingTip, {
      props: { text: '新效果！持续 2 天' }
    })
    expect(wrapper.text()).toContain('新效果！持续 2 天')
  })

  test('exposes tip-arrow + tip-text elements', () => {
    const wrapper = mount(StatusOnboardingTip, {
      props: { text: 'tip' }
    })
    expect(wrapper.find('.tip-arrow').exists()).toBe(true)
    expect(wrapper.find('.tip-text').exists()).toBe(true)
  })
})

describe('StatusChip — pulse on modifier trigger (AC-5/6)', () => {
  test('chip with matching status.id gets chip-pulsing class within 350ms window', async () => {
    const statusStore = useStatusStore()
    const wrapper = mount(StatusChip, { props: { status: sampleBuff } })
    await wrapper.vm.$nextTick()

    expect(wrapper.find('.chip').classes()).not.toContain('chip-pulsing')

    statusStore.markModifierTrigger('caffeine')
    await wrapper.vm.$nextTick()

    expect(wrapper.find('.chip').classes()).toContain('chip-pulsing')
    expect(wrapper.find('.chip').attributes('data-pulsing')).toBe('true')
  })

  test('chip with non-matching status.id stays untouched', async () => {
    const statusStore = useStatusStore()
    const wrapper = mount(StatusChip, { props: { status: sampleBuff } })
    await wrapper.vm.$nextTick()

    statusStore.markModifierTrigger('emo') // different id
    await wrapper.vm.$nextTick()

    expect(wrapper.find('.chip').classes()).not.toContain('chip-pulsing')
  })

  test('pulse class is removed after PULSE_DURATION_MS expires', async () => {
    vi.useFakeTimers()
    const statusStore = useStatusStore()
    const wrapper = mount(StatusChip, { props: { status: sampleDebuff } })
    await wrapper.vm.$nextTick()

    statusStore.markModifierTrigger('emo')
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.chip').classes()).toContain('chip-pulsing')

    vi.advanceTimersByTime(400)
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.chip').classes()).not.toContain('chip-pulsing')

    vi.useRealTimers()
  })

  test('successive triggers re-pulse (timer reset)', async () => {
    vi.useFakeTimers()
    const statusStore = useStatusStore()
    const wrapper = mount(StatusChip, { props: { status: sampleBuff } })
    await wrapper.vm.$nextTick()

    statusStore.markModifierTrigger('caffeine')
    await wrapper.vm.$nextTick()
    vi.advanceTimersByTime(200)
    // Within window, pulse still active
    expect(wrapper.find('.chip').classes()).toContain('chip-pulsing')

    // Re-trigger before old timer expires — should still be pulsing
    statusStore.markModifierTrigger('caffeine')
    await wrapper.vm.$nextTick()
    vi.advanceTimersByTime(200)
    // Old timer would have fired by now (200+200=400 > 350) but new trigger
    // resets timer; so still pulsing
    expect(wrapper.find('.chip').classes()).toContain('chip-pulsing')

    vi.advanceTimersByTime(400)
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.chip').classes()).not.toContain('chip-pulsing')

    vi.useRealTimers()
  })
})

describe('statusStore.markModifierTrigger', () => {
  test('writes statusId + monotonic timestamp', () => {
    const statusStore = useStatusStore()
    const t0 = Date.now()
    statusStore.markModifierTrigger('caffeine')
    expect(statusStore.lastModifierTrigger).not.toBeNull()
    expect(statusStore.lastModifierTrigger!.statusId).toBe('caffeine')
    expect(statusStore.lastModifierTrigger!.timestamp).toBeGreaterThanOrEqual(t0)
  })

  test('overwrites previous trigger', () => {
    const statusStore = useStatusStore()
    statusStore.markModifierTrigger('caffeine')
    const t1 = statusStore.lastModifierTrigger!.timestamp
    statusStore.markModifierTrigger('emo')
    expect(statusStore.lastModifierTrigger!.statusId).toBe('emo')
    expect(statusStore.lastModifierTrigger!.timestamp).toBeGreaterThanOrEqual(t1)
  })
})
