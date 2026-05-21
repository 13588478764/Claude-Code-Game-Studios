/**
 * S3-8 FloatingDelta + useSoundEffect tests.
 *
 * FloatingDelta: verifies sign formatting, target classes, target icons.
 * useSoundEffect: verifies graceful no-op behavior when uni audio is missing
 * (the production case in tests + web preview).
 */

import { describe, test, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import FloatingDelta from '@/components/FloatingDelta.vue'
import { useSoundEffect, _resetSoundEffectState } from '@/composables/useSoundEffect'

describe('FloatingDelta — formatting', () => {
  test('positive value renders +N with energy icon + gain class', () => {
    const wrapper = mount(FloatingDelta, {
      props: { target: 'energy', value: 10 }
    })
    expect(wrapper.text()).toBe('⚡+10')
    expect(wrapper.classes()).toContain('float-energy')
    expect(wrapper.classes()).toContain('float-gain')
    expect(wrapper.classes()).not.toContain('float-loss')
  })

  test('negative value renders -N with mood icon + loss class', () => {
    const wrapper = mount(FloatingDelta, {
      props: { target: 'mood', value: -15 }
    })
    expect(wrapper.text()).toBe('😊-15')
    expect(wrapper.classes()).toContain('float-mood')
    expect(wrapper.classes()).toContain('float-loss')
    expect(wrapper.classes()).not.toContain('float-gain')
  })

  test('money target uses 💰 icon + money class', () => {
    const wrapper = mount(FloatingDelta, {
      props: { target: 'money', value: 25 }
    })
    expect(wrapper.text()).toBe('💰+25')
    expect(wrapper.classes()).toContain('float-money')
  })

  test('zero value renders + sign (caller is expected to skip zeros)', () => {
    const wrapper = mount(FloatingDelta, {
      props: { target: 'energy', value: 0 }
    })
    // 0 >= 0, so sign is '+'; gain class
    expect(wrapper.text()).toBe('⚡+0')
    expect(wrapper.classes()).toContain('float-gain')
  })

  test('exposes data-target and data-value for testability', () => {
    const wrapper = mount(FloatingDelta, {
      props: { target: 'money', value: -5 }
    })
    expect(wrapper.attributes('data-target')).toBe('money')
    expect(wrapper.attributes('data-value')).toBe('-5')
  })
})

describe('useSoundEffect — graceful degradation (AC-6)', () => {
  beforeEach(() => {
    _resetSoundEffectState()
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    delete (globalThis as any).uni
  })

  test('play() is a no-op when uni global is undefined', () => {
    const sfx = useSoundEffect()
    expect(() => sfx.play('click')).not.toThrow()
  })

  test('play() is a no-op when uni.createInnerAudioContext is missing', () => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    ;(globalThis as any).uni = {} // present but no audio API
    const sfx = useSoundEffect()
    expect(() => sfx.play('click')).not.toThrow()
  })

  test('play() invokes uni.createInnerAudioContext + sets src + autoplay', () => {
    const audioMock = {
      src: '',
      autoplay: false,
      onError: vi.fn(),
      onEnded: vi.fn(),
      destroy: vi.fn()
    }
    const createSpy = vi.fn(() => audioMock)
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    ;(globalThis as any).uni = {
      createInnerAudioContext: createSpy,
      getSystemInfoSync: () => ({ theme: 'normal' })
    }
    const sfx = useSoundEffect()
    sfx.play('click')
    expect(createSpy).toHaveBeenCalled()
    expect(audioMock.src).toBe('/static/audio/click.mp3')
    expect(audioMock.autoplay).toBe(true)
    expect(audioMock.onError).toHaveBeenCalled()
    expect(audioMock.onEnded).toHaveBeenCalled()
  })

  test('play() skips when reduced-motion theme is set (AC-7)', () => {
    const createSpy = vi.fn()
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    ;(globalThis as any).uni = {
      createInnerAudioContext: createSpy,
      getSystemInfoSync: () => ({ theme: 'reducedMotion' })
    }
    const sfx = useSoundEffect()
    sfx.play('click')
    expect(createSpy).not.toHaveBeenCalled()
  })

  test('play() skips when accessibility flag enabled', () => {
    const createSpy = vi.fn()
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    ;(globalThis as any).uni = {
      createInnerAudioContext: createSpy,
      getSystemInfoSync: () => ({ enableAccessibility: true })
    }
    const sfx = useSoundEffect()
    sfx.play('death')
    expect(createSpy).not.toHaveBeenCalled()
  })

  test('play() supports all SoundName values without throwing', () => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    ;(globalThis as any).uni = undefined
    const sfx = useSoundEffect()
    const names = ['click', 'day-end', 'death', 'win', 'unlock'] as const
    for (const n of names) {
      expect(() => sfx.play(n)).not.toThrow()
    }
  })
})
