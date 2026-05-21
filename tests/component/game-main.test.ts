/**
 * S2-5 component tests — focused on logic-level verification of the 5
 * components composing GameMain. Renders via @vue/test-utils + happy-dom.
 *
 * Visual fidelity (gradients, exact pixel sizes, animations) is verified
 * manually via three-platform smoke check (S2-8). Here we verify:
 *   - DayBadge renders correct day name and dot states
 *   - StatusChip exposes 44px hit-area intent (data attribute hook)
 *   - StatusChip distinguishes buff/debuff via class + form
 *   - EventCard auto-shrinks font for long text
 *   - ChoiceButton shows risk badge when applicable
 *   - ChoiceButton debounces 100ms-rapid clicks (300ms cooldown)
 */

import { describe, test, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import DayBadge from '@/components/DayBadge.vue'
import StatusChip from '@/components/StatusChip.vue'
import EventCard from '@/components/EventCard.vue'
import ChoiceButton from '@/components/ChoiceButton.vue'

beforeEach(() => {
  setActivePinia(createPinia())
})
import type { StatusEffect } from '@/types/status'
import type { EventCard as EventCardType, Choice } from '@/types/event'

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

describe('DayBadge', () => {
  test('AC-6: renders dayName + day index', () => {
    const wrapper = mount(DayBadge, { props: { currentDay: 3 } })
    expect(wrapper.text()).toContain('周三')
    expect(wrapper.text()).toContain('3')
  })

  test('renders 5 dots by default', () => {
    const wrapper = mount(DayBadge, { props: { currentDay: 1 } })
    const dots = wrapper.findAll('.dot')
    expect(dots).toHaveLength(5)
  })

  test('dots reflect day progress: done / current / pending', () => {
    const wrapper = mount(DayBadge, { props: { currentDay: 3 } })
    const dots = wrapper.findAll('.dot')
    expect(dots[0]!.classes()).toContain('dot-done')
    expect(dots[1]!.classes()).toContain('dot-done')
    expect(dots[2]!.classes()).toContain('dot-current')
    expect(dots[3]!.classes()).toContain('dot-pending')
    expect(dots[4]!.classes()).toContain('dot-pending')
  })

  test('out-of-range day → 周?', () => {
    const wrapper = mount(DayBadge, { props: { currentDay: 99 } })
    expect(wrapper.text()).toContain('周?')
  })
})

describe('StatusChip', () => {
  test('renders icon + name + days', () => {
    const wrapper = mount(StatusChip, { props: { status: sampleBuff } })
    expect(wrapper.text()).toContain('☕')
    expect(wrapper.text()).toContain('亢奋')
    expect(wrapper.text()).toContain('2D')
  })

  test('AC-3: chip wrapper carries data-test-hit-area attribute (44px)', () => {
    const wrapper = mount(StatusChip, { props: { status: sampleBuff } })
    const chipWrapper = wrapper.find('.chip-wrapper')
    expect(chipWrapper.attributes('data-test-hit-area')).toBe('44')
  })

  test('AC-13 part 1: buff has buff class, NOT debuff class', () => {
    const wrapper = mount(StatusChip, { props: { status: sampleBuff } })
    const chip = wrapper.find('.chip')
    expect(chip.classes()).toContain('chip-buff')
    expect(chip.classes()).not.toContain('chip-debuff')
  })

  test('AC-13 part 2: debuff has debuff class (+ dashed underline differentiator)', () => {
    const wrapper = mount(StatusChip, { props: { status: sampleDebuff } })
    const chip = wrapper.find('.chip')
    expect(chip.classes()).toContain('chip-debuff')
    expect(chip.classes()).not.toContain('chip-buff')
  })

  test('different status types produce distinct classes (color-blind friendly via shape)', () => {
    const buff = mount(StatusChip, { props: { status: sampleBuff } })
    const debuff = mount(StatusChip, { props: { status: sampleDebuff } })
    expect(buff.find('.chip').classes()).not.toEqual(debuff.find('.chip').classes())
  })
})

describe('EventCard', () => {
  function makeCard(text: string): EventCardType {
    return {
      id: 'test',
      text,
      choiceA: { text: 'A', effects: [] },
      choiceB: { text: 'B', effects: [] }
    }
  }

  test('renders nothing when card is null', () => {
    const wrapper = mount(EventCard, { props: { card: null } })
    expect(wrapper.find('.card').exists()).toBe(false)
  })

  test('renders text when card provided', () => {
    const wrapper = mount(EventCard, { props: { card: makeCard('老板找你聊聊') } })
    expect(wrapper.text()).toContain('老板找你聊聊')
  })

  test('AC-4: short text → base font 32rpx', () => {
    const wrapper = mount(EventCard, { props: { card: makeCard('短') } })
    const textEl = wrapper.find('.card-text')
    expect(textEl.attributes('data-fontsize')).toBe('32')
  })

  test('AC-4: long text → font shrinks (5+ lines → 24rpx min)', () => {
    const longText = '一'.repeat(120)  // ~7 lines at 18 chars/line
    const wrapper = mount(EventCard, { props: { card: makeCard(longText) } })
    const textEl = wrapper.find('.card-text')
    const fontSize = parseInt(textEl.attributes('data-fontsize') || '0', 10)
    expect(fontSize).toBeLessThan(32)
    expect(fontSize).toBeGreaterThanOrEqual(24)
  })

  test('isFollowUp prop applies followup class', () => {
    const wrapper = mount(EventCard, {
      props: { card: makeCard('后续事件'), isFollowUp: true }
    })
    expect(wrapper.find('.card').classes()).toContain('card-followup')
    expect(wrapper.text()).toContain('后续')
  })

  test('non-followup shows EVENT label', () => {
    const wrapper = mount(EventCard, { props: { card: makeCard('普通事件') } })
    expect(wrapper.text()).toContain('EVENT')
  })
})

describe('ChoiceButton', () => {
  function makeChoice(overrides: Partial<Choice> = {}): Choice {
    return {
      text: 'choose',
      effects: [],
      ...overrides
    }
  }

  test('renders text + custom icon when provided', () => {
    const wrapper = mount(ChoiceButton, {
      props: { choice: makeChoice({ icon: '💪', text: 'work' }), variant: 'a' }
    })
    expect(wrapper.text()).toContain('💪')
    expect(wrapper.text()).toContain('work')
  })

  test('falls back to A/B text when icon missing', () => {
    const wrapperA = mount(ChoiceButton, {
      props: { choice: makeChoice({ text: 'opt1' }), variant: 'a' }
    })
    const wrapperB = mount(ChoiceButton, {
      props: { choice: makeChoice({ text: 'opt2' }), variant: 'b' }
    })
    expect(wrapperA.text()).toContain('A')
    expect(wrapperB.text()).toContain('B')
  })

  test('emits pick on click', async () => {
    const wrapper = mount(ChoiceButton, {
      props: { choice: makeChoice(), variant: 'a' }
    })
    await wrapper.trigger('click')
    expect(wrapper.emitted('pick')).toHaveLength(1)
  })

  test('disabled prop blocks click', async () => {
    const wrapper = mount(ChoiceButton, {
      props: { choice: makeChoice(), variant: 'a', disabled: true }
    })
    await wrapper.trigger('click')
    expect(wrapper.emitted('pick')).toBeUndefined()
  })

  test('AC-5: 3 rapid clicks are debounced (cooldown active) — 1 emit', async () => {
    const wrapper = mount(ChoiceButton, {
      props: { choice: makeChoice(), variant: 'a' }
    })
    await wrapper.trigger('click')
    await wrapper.trigger('click')
    await wrapper.trigger('click')
    expect(wrapper.emitted('pick')).toHaveLength(1)
  })

  test('risk choice shows percentage badge', () => {
    const wrapper = mount(ChoiceButton, {
      props: {
        choice: makeChoice({
          risk: {
            chance: 0.7,
            success: { text: 'win', effects: [] },
            fail: { text: 'lose', effects: [] }
          }
        }),
        variant: 'a'
      }
    })
    expect(wrapper.text()).toContain('70%')
    expect(wrapper.text()).toContain('🎲')
  })

  test('non-risk choice has no risk badge', () => {
    const wrapper = mount(ChoiceButton, {
      props: { choice: makeChoice(), variant: 'a' }
    })
    expect(wrapper.text()).not.toContain('🎲')
  })

  test('variant a has btn-a class, variant b has btn-b', () => {
    const a = mount(ChoiceButton, { props: { choice: makeChoice(), variant: 'a' } })
    const b = mount(ChoiceButton, { props: { choice: makeChoice(), variant: 'b' } })
    expect(a.find('button').classes()).toContain('btn-a')
    expect(b.find('button').classes()).toContain('btn-b')
  })
})
