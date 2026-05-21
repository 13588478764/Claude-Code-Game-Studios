import { describe, test, expect, vi } from 'vitest'
import { ResourceManager } from '@/services/resource/resource-manager'
import { DEFAULT_RESOURCE_CONFIG } from '@/types/resource'

describe('ResourceManager', () => {
  test('init() sets initial values from config', () => {
    const rm = new ResourceManager()
    expect(rm.getResources()).toEqual({ energy: 80, mood: 60, money: 0, health: 100 })
  })

  test('init() override partial values', () => {
    const rm = new ResourceManager()
    rm.init({ energy: 50 })
    expect(rm.getResources().energy).toBe(50)
    expect(rm.getResources().mood).toBe(60)
  })

  test('applyEffects() clamps energy 0-100', () => {
    const rm = new ResourceManager()
    rm.applyEffects([{ target: 'energy', value: 50 }])
    expect(rm.getResources().energy).toBe(100)
    rm.applyEffects([{ target: 'energy', value: -200 }])
    expect(rm.getResources().energy).toBe(0)
  })

  test('applyEffects() clamps mood 0-100', () => {
    const rm = new ResourceManager()
    rm.applyEffects([{ target: 'mood', value: 200 }])
    expect(rm.getResources().mood).toBe(100)
    rm.applyEffects([{ target: 'mood', value: -300 }])
    expect(rm.getResources().mood).toBe(0)
  })

  test('money has no clamp (can go negative)', () => {
    const rm = new ResourceManager()
    rm.applyEffects([{ target: 'money', value: -50 }])
    expect(rm.getResources().money).toBe(-50)
    rm.applyEffects([{ target: 'money', value: 10000 }])
    expect(rm.getResources().money).toBe(9950)
  })

  test('state: NORMAL → WARNING when energy <= 30', () => {
    const rm = new ResourceManager()
    expect(rm.getState()).toBe('NORMAL')
    rm.applyEffects([{ target: 'energy', value: -55 }])  // 80 → 25
    expect(rm.getState()).toBe('WARNING')
  })

  test('state: NORMAL → WARNING when mood <= 30 (>20)', () => {
    const rm = new ResourceManager()
    rm.applyEffects([{ target: 'mood', value: -35 }])  // 60 → 25
    expect(rm.getState()).toBe('WARNING')
  })

  test('state: → CRISIS when mood <= 20', () => {
    const rm = new ResourceManager()
    rm.applyEffects([{ target: 'mood', value: -45 }])  // 60 → 15
    expect(rm.getState()).toBe('CRISIS')
  })

  test('state: → DEAD when energy = 0', () => {
    const rm = new ResourceManager()
    rm.applyEffects([{ target: 'energy', value: -200 }])
    expect(rm.getState()).toBe('DEAD')
  })

  test('state: → DEAD when mood = 0', () => {
    const rm = new ResourceManager()
    rm.applyEffects([{ target: 'mood', value: -200 }])
    expect(rm.getState()).toBe('DEAD')
  })

  test('emit onResourceChanged with deltas', () => {
    const rm = new ResourceManager()
    const fn = vi.fn()
    rm.onResourceChanged.on(fn)
    rm.applyEffects([{ target: 'energy', value: -10 }])
    expect(fn).toHaveBeenCalledWith(expect.objectContaining({
      before: { energy: 80, mood: 60, money: 0, health: 100 },
      after: { energy: 70, mood: 60, money: 0, health: 100 },
      deltas: [expect.objectContaining({ target: 'energy', delta: -10 })]
    }))
  })

  test('emit onStateChanged on transition', () => {
    const rm = new ResourceManager()
    const fn = vi.fn()
    rm.onStateChanged.on(fn)
    rm.applyEffects([{ target: 'energy', value: -55 }])
    expect(fn).toHaveBeenCalledWith({ from: 'NORMAL', to: 'WARNING' })
  })

  test('does NOT emit onStateChanged when state unchanged', () => {
    const rm = new ResourceManager()
    const fn = vi.fn()
    rm.onStateChanged.on(fn)
    rm.applyEffects([{ target: 'energy', value: -5 }])
    expect(fn).not.toHaveBeenCalled()
  })

  test('emit onResourceDepleted with which', () => {
    const rm = new ResourceManager()
    const fn = vi.fn()
    rm.onResourceDepleted.on(fn)
    rm.applyEffects([{ target: 'energy', value: -200 }])
    expect(fn).toHaveBeenCalledWith({ which: 'energy' })
  })

  test('multiple effects in one call coalesce per target', () => {
    const rm = new ResourceManager()
    const fn = vi.fn()
    rm.onResourceChanged.on(fn)
    rm.applyEffects([
      { target: 'energy', value: -10 },
      { target: 'mood', value: 5 },
      { target: 'energy', value: -5 }
    ])
    const arg = fn.mock.calls[0]![0]
    expect(arg.deltas).toHaveLength(2)
    const energyDelta = arg.deltas.find((d: any) => d.target === 'energy')
    expect(energyDelta.delta).toBe(-15)
  })

  test('rawDelta vs delta differ when clamp applies', () => {
    const rm = new ResourceManager()
    rm.init({ energy: 5 })
    const result = rm.applyEffects([{ target: 'energy', value: -20 }])
    const d = result.deltas[0]!
    expect(d.delta).toBe(-5)  // clamped
    expect(d.rawDelta).toBe(-20)
    expect(d.wasModified).toBe(true)
  })

  test('reset() returns to initial state', () => {
    const rm = new ResourceManager()
    rm.applyEffects([{ target: 'energy', value: -50 }])
    rm.reset()
    expect(rm.getResources()).toEqual({ energy: 80, mood: 60, money: 0, health: 100 })
    expect(rm.getState()).toBe('NORMAL')
  })

  test('reset() emits state change if needed', () => {
    const rm = new ResourceManager()
    rm.applyEffects([{ target: 'energy', value: -55 }])  // → WARNING
    const fn = vi.fn()
    rm.onStateChanged.on(fn)
    rm.reset()
    expect(fn).toHaveBeenCalledWith({ from: 'WARNING', to: 'NORMAL' })
  })

  test('event order: changed → state → depleted', () => {
    const rm = new ResourceManager()
    rm.init({ energy: 5 })
    const order: string[] = []
    rm.onResourceChanged.on(() => order.push('changed'))
    rm.onStateChanged.on(() => order.push('state'))
    rm.onResourceDepleted.on(() => order.push('depleted'))
    rm.applyEffects([{ target: 'energy', value: -100 }])
    expect(order).toEqual(['changed', 'state', 'depleted'])
  })

  test('config thresholds are configurable', () => {
    const rm = new ResourceManager({
      ...DEFAULT_RESOURCE_CONFIG,
      warningThreshold: 50
    })
    rm.applyEffects([{ target: 'energy', value: -35 }])  // 80 → 45
    expect(rm.getState()).toBe('WARNING')
  })

  test('does not double-emit depleted on follow-up applies', () => {
    const rm = new ResourceManager()
    const fn = vi.fn()
    rm.onResourceDepleted.on(fn)
    rm.applyEffects([{ target: 'energy', value: -200 }])
    rm.applyEffects([{ target: 'energy', value: -10 }])  // already 0
    expect(fn).toHaveBeenCalledTimes(1)
  })
})

describe('ResourceManager — health (G-2)', () => {
  test('default health starts at 100', () => {
    const rm = new ResourceManager()
    expect(rm.getResources().health).toBe(100)
  })

  test('health clamps at 0 lower bound', () => {
    const rm = new ResourceManager()
    rm.applyEffects([{ target: 'health', value: -200 }])
    expect(rm.getResources().health).toBe(0)
  })

  test('health clamps at maxHealth upper bound', () => {
    const rm = new ResourceManager()
    rm.applyEffects([{ target: 'health', value: 50 }])  // already 100
    expect(rm.getResources().health).toBe(100)
  })

  test('health depletion emits onResourceDepleted with which=health', () => {
    const rm = new ResourceManager()
    const fn = vi.fn()
    rm.onResourceDepleted.on(fn)
    rm.applyEffects([{ target: 'health', value: -100 }])
    expect(fn).toHaveBeenCalledWith({ which: 'health' })
  })

  test('health=0 triggers DEAD state', () => {
    const rm = new ResourceManager()
    rm.applyEffects([{ target: 'health', value: -100 }])
    expect(rm.getState()).toBe('DEAD')
  })

  test('health depletion takes priority over energy/mood in same applyEffects', () => {
    const rm = new ResourceManager()
    rm.init({ energy: 5, mood: 5, health: 5 })
    const fn = vi.fn()
    rm.onResourceDepleted.on(fn)
    rm.applyEffects([
      { target: 'health', value: -10 },
      { target: 'energy', value: -10 },
      { target: 'mood', value: -10 }
    ])
    // Health is most fatal — emit just for health (first matching guard)
    expect(fn).toHaveBeenCalledTimes(1)
    expect(fn).toHaveBeenCalledWith({ which: 'health' })
  })

  test('does not double-emit depleted on follow-up applies (health)', () => {
    const rm = new ResourceManager()
    const fn = vi.fn()
    rm.onResourceDepleted.on(fn)
    rm.applyEffects([{ target: 'health', value: -200 }])
    rm.applyEffects([{ target: 'health', value: -10 }])
    expect(fn).toHaveBeenCalledTimes(1)
  })
})
