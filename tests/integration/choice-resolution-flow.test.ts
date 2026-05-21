/**
 * S2-3 integration tests — ChoiceResolutionEngine across statusSystem +
 * resourceManager (real instances) and mocked saveService.recordChoice.
 *
 * These are integration tests because ChoiceResolutionEngine coordinates
 * multiple services. The KEY test is the call-order spy verifying the
 * applyToEffect → applyEffects → addStatus invariant.
 */

import { describe, test, expect, vi } from 'vitest'
import {
  ChoiceResolutionEngine,
  type ChoiceResolutionDeps
} from '@/services/choice-resolution/choice-resolution-engine'
import { StatusSystem } from '@/services/status/status-system'
import { ResourceManager } from '@/services/resource/resource-manager'
import type { EventCard, BuffSpec, RiskSpec } from '@/types/event'
import type { StatusEffect } from '@/types/status'

function makeCard(overrides: Partial<EventCard> = {}): EventCard {
  return {
    id: 'test-1',
    text: 'test event',
    choiceA: { text: 'A', effects: [] },
    choiceB: { text: 'B', effects: [] },
    ...overrides
  }
}

function buildEngine(opts: {
  statusSystem?: StatusSystem
  resourceManager?: ResourceManager
  randomRoll?: () => number
  recordChoiceSpy?: ReturnType<typeof vi.fn>
} = {}) {
  const status = opts.statusSystem ?? new StatusSystem()
  const resources = opts.resourceManager ?? new ResourceManager()
  const recordChoice = opts.recordChoiceSpy ?? vi.fn()

  const deps: ChoiceResolutionDeps = {
    statusApplyToEffect: (target, raw) => status.applyToEffect(target, raw),
    statusAddStatus: (spec) => status.addStatus(spec),
    resourceApplyEffects: (effects) => resources.applyEffects(effects),
    recordChoice,
    ...(opts.randomRoll ? { randomRoll: opts.randomRoll } : {})
  }
  const engine = new ChoiceResolutionEngine(deps)
  return { engine, status, resources, recordChoice, deps }
}

describe('ChoiceResolutionEngine — basic effect application', () => {
  test('AC-1: multiple effects → ResolveResult.deltas reflects each', () => {
    const { engine, resources } = buildEngine()
    const card = makeCard({
      choiceA: {
        text: 'work hard',
        effects: [
          { target: 'energy', value: -20 },
          { target: 'money', value: 10 }
        ]
      }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(result.deltas).toHaveLength(2)
    const energyDelta = result.deltas.find((d) => d.target === 'energy')!
    const moneyDelta = result.deltas.find((d) => d.target === 'money')!
    expect(energyDelta.delta).toBe(-20)
    expect(moneyDelta.delta).toBe(10)
    expect(resources.getResources()).toMatchObject({ energy: 60, money: 10 })
  })

  test('AC-7: empty effects → empty deltas, recordChoice still called', () => {
    const { engine, recordChoice } = buildEngine()
    const card = makeCard({
      choiceA: { text: 'do nothing', effects: [] }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(result.deltas).toHaveLength(0)
    expect(recordChoice).toHaveBeenCalledWith('test-1', 'A')
  })

  test('result.choiceText echoes selected choice text', () => {
    const { engine } = buildEngine()
    const card = makeCard({
      choiceA: { text: '硬着头皮接', effects: [] },
      choiceB: { text: '婉拒', effects: [] }
    })
    const resultA = engine.resolveChoice(card, 'A')
    const resultB = engine.resolveChoice(card, 'B')
    expect(resultA.choiceText).toBe('硬着头皮接')
    expect(resultB.choiceText).toBe('婉拒')
  })
})

describe('ChoiceResolutionEngine — status modifier integration (AC-2)', () => {
  test('buff energyMul=0.5 reduces energy loss from -20 to -10', () => {
    const { engine, status, resources } = buildEngine()
    const buff: StatusEffect = {
      id: 'caffeine',
      name: '亢奋',
      icon: '☕',
      type: 'buff',
      daysLeft: 2,
      energyMul: 0.5
    }
    status.addStatus(buff)

    const card = makeCard({
      choiceA: { text: 'A', effects: [{ target: 'energy', value: -20 }] }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(resources.getResources().energy).toBe(70)  // 80 - 10
    const delta = result.deltas[0]!
    expect(delta.delta).toBe(-10)
    expect(delta.rawDelta).toBe(-20)
    expect(delta.wasStatusModified).toBe(true)
  })

  test('no status → wasStatusModified=false on deltas', () => {
    const { engine } = buildEngine()
    const card = makeCard({
      choiceA: { text: 'A', effects: [{ target: 'mood', value: -10 }] }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(result.deltas[0]!.wasStatusModified).toBe(false)
  })

  test('money effects bypass status (status only applies to energy/mood)', () => {
    const { engine, status } = buildEngine()
    // Add a buff that would theoretically modify money (but moneyMul not in v2.1)
    status.addStatus({
      id: 'fake',
      name: 'fake',
      icon: '?',
      type: 'buff',
      daysLeft: 1,
      energyMul: 0.5
    })

    const card = makeCard({
      choiceA: { text: 'A', effects: [{ target: 'money', value: 100 }] }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(result.deltas[0]!.delta).toBe(100)
    expect(result.deltas[0]!.wasStatusModified).toBe(false)
  })

  test('coalesced effects (multiple energy effects) sum rawDelta correctly', () => {
    const { engine } = buildEngine()
    const card = makeCard({
      choiceA: {
        text: 'A',
        effects: [
          { target: 'energy', value: -10 },
          { target: 'energy', value: -5 }
        ]
      }
    })
    const result = engine.resolveChoice(card, 'A')
    const delta = result.deltas[0]!
    expect(delta.rawDelta).toBe(-15)
    expect(delta.delta).toBe(-15)
  })

  // J-2 regression: health effects must bypass ALL modifier layers (passive,
  // equipment, status). Health is irreversible vitality (G-2); items/buffs
  // don't restore it. Before the fix, target='health' was unsafely cast to
  // StatusModifierTarget ('energy'|'mood') and fell through to moodMul.
  test('J-2 regression: health effect bypasses passive + equipment + status', () => {
    const status = new StatusSystem()
    const resources = new ResourceManager()
    // All 3 modifier layers configured to mutate. None should touch health.
    const passiveSpy = vi.fn((_t, v) => v * 0.5)
    const equipSpy = vi.fn((_t, v) => v * 0.5)
    const statusSpy = vi.fn((target, v) => status.applyToEffect(target, v))
    status.addStatus({
      id: 'mood-debuff', name: 'emo', icon: '💔',
      type: 'debuff', daysLeft: 1, moodMul: 2.0
    })

    const deps: ChoiceResolutionDeps = {
      statusApplyToEffect: statusSpy,
      passiveApplyToEffect: passiveSpy,
      equipmentApplyToEffect: equipSpy,
      statusAddStatus: (s) => status.addStatus(s),
      resourceApplyEffects: (e) => resources.applyEffects(e),
      recordChoice: vi.fn()
    }
    const engine = new ChoiceResolutionEngine(deps)

    const card = makeCard({
      choiceA: { text: 'A', effects: [{ target: 'health', value: -10 }] }
    })
    const result = engine.resolveChoice(card, 'A')

    // Health value untouched by any modifier
    expect(result.deltas[0]!.delta).toBe(-10)
    expect(result.deltas[0]!.rawDelta).toBe(-10)
    expect(result.deltas[0]!.wasStatusModified).toBe(false)
    expect(resources.getResources().health).toBe(90)
    // Critical: NONE of the modifier layers was invoked for the health target
    expect(passiveSpy).not.toHaveBeenCalled()
    expect(equipSpy).not.toHaveBeenCalled()
    expect(statusSpy).not.toHaveBeenCalled()
  })

  // J-2 regression: when both health and energy effects exist in same choice,
  // energy still goes through pipeline; only health is bypassed.
  test('J-2 regression: mixed health + energy → only energy through pipeline', () => {
    const status = new StatusSystem()
    const resources = new ResourceManager()
    const passiveSpy = vi.fn((_t, v) => v * 0.5)  // halves energy
    const deps: ChoiceResolutionDeps = {
      statusApplyToEffect: (t, v) => status.applyToEffect(t, v),
      passiveApplyToEffect: passiveSpy,
      statusAddStatus: (s) => status.addStatus(s),
      resourceApplyEffects: (e) => resources.applyEffects(e),
      recordChoice: vi.fn()
    }
    const engine = new ChoiceResolutionEngine(deps)
    const card = makeCard({
      choiceA: {
        text: 'A',
        effects: [
          { target: 'health', value: -8 },
          { target: 'energy', value: -20 }
        ]
      }
    })
    engine.resolveChoice(card, 'A')

    expect(resources.getResources().health).toBe(92)   // raw -8
    expect(resources.getResources().energy).toBe(70)   // -20 × 0.5 = -10
    // Passive invoked once (for energy), never for health
    expect(passiveSpy).toHaveBeenCalledTimes(1)
    expect(passiveSpy).toHaveBeenCalledWith('energy', -20)
  })
})

describe('ChoiceResolutionEngine — risk mechanic (AC-3)', () => {
  function makeRiskCard(risk: RiskSpec): EventCard {
    return makeCard({
      choiceA: { text: '赌一把', effects: [], risk }
    })
  }

  test('roll < chance → success outcome applied', () => {
    const { engine, resources } = buildEngine({ randomRoll: () => 0.3 })
    const card = makeRiskCard({
      chance: 0.7,
      success: { text: '中了', effects: [{ target: 'mood', value: 30 }] },
      fail: { text: '没中', effects: [{ target: 'mood', value: -20 }] }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(result.riskOutcome).toBe('success')
    expect(resources.getResources().mood).toBe(90)  // 60 + 30
  })

  test('roll >= chance → fail outcome applied', () => {
    const { engine, resources } = buildEngine({ randomRoll: () => 0.8 })
    const card = makeRiskCard({
      chance: 0.7,
      success: { text: '中了', effects: [{ target: 'mood', value: 30 }] },
      fail: { text: '没中', effects: [{ target: 'mood', value: -20 }] }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(result.riskOutcome).toBe('fail')
    expect(resources.getResources().mood).toBe(40)  // 60 - 20
  })

  test('non-risk choice → riskOutcome undefined', () => {
    const { engine } = buildEngine()
    const card = makeCard({
      choiceA: { text: 'A', effects: [{ target: 'energy', value: -5 }] }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(result.riskOutcome).toBeUndefined()
  })

  test('risk + status modifier composes correctly', () => {
    const { engine, status, resources } = buildEngine({ randomRoll: () => 0.1 })
    status.addStatus({
      id: 'lucky',
      name: '幸运',
      icon: '🍀',
      type: 'buff',
      daysLeft: 1,
      moodMul: 0.5
    })
    const card = makeCard({
      choiceA: {
        text: 'A',
        effects: [],
        risk: {
          chance: 0.5,
          success: { text: 'win', effects: [{ target: 'mood', value: -20 }] },
          fail: { text: 'lose', effects: [{ target: 'mood', value: 0 }] }
        }
      }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(result.riskOutcome).toBe('success')
    // -20 * 0.5 = -10 (status applies to risk outcome effects)
    expect(resources.getResources().mood).toBe(50)
    expect(result.deltas[0]!.wasStatusModified).toBe(true)
  })

  test('Math.random default works without explicit randomRoll', () => {
    const { engine } = buildEngine()  // no randomRoll override
    const card = makeCard({
      choiceA: {
        text: 'A',
        effects: [],
        risk: {
          chance: 1.0,  // always success
          success: { text: 'win', effects: [{ target: 'mood', value: 5 }] },
          fail: { text: 'lose', effects: [{ target: 'mood', value: -5 }] }
        }
      }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(result.riskOutcome).toBe('success')
  })
})

describe('ChoiceResolutionEngine — buff add ordering (AC-4 KEY INVARIANT)', () => {
  test('addStatus is called AFTER resourceApplyEffects (call order verification)', () => {
    const callOrder: string[] = []
    const status = new StatusSystem()
    const resources = new ResourceManager()
    const recordChoice = vi.fn()

    const deps: ChoiceResolutionDeps = {
      statusApplyToEffect: (target, raw) => {
        callOrder.push('applyToEffect')
        return status.applyToEffect(target, raw)
      },
      resourceApplyEffects: (effects) => {
        callOrder.push('applyEffects')
        return resources.applyEffects(effects)
      },
      statusAddStatus: (spec) => {
        callOrder.push('addStatus')
        status.addStatus(spec)
      },
      recordChoice
    }
    const engine = new ChoiceResolutionEngine(deps)

    const buff: BuffSpec = {
      id: 'caffeine',
      name: '亢奋',
      icon: '☕',
      type: 'buff',
      days: 2,
      energyMul: 0.5
    }
    const card = makeCard({
      choiceA: {
        text: 'drink coffee',
        effects: [{ target: 'energy', value: -10 }],
        buff
      }
    })

    engine.resolveChoice(card, 'A')

    // Ordering: applyToEffect (step 2) → applyEffects (step 3) → addStatus (step 4)
    expect(callOrder).toEqual(['applyToEffect', 'applyEffects', 'addStatus'])
  })

  test('current choice effect is NOT modified by the buff that this choice adds', () => {
    // GIVEN: no existing status, a coffee choice that loses 20 energy + adds buff
    // WHEN: resolveChoice
    // THEN: energy reduction is full -20 (NOT -10 from a hypothetical applied buff)
    const { engine, status, resources } = buildEngine()
    const card = makeCard({
      choiceA: {
        text: 'drink coffee',
        effects: [{ target: 'energy', value: -20 }],
        buff: {
          id: 'caffeine',
          name: '亢奋',
          icon: '☕',
          type: 'buff',
          days: 2,
          energyMul: 0.5  // would halve energy loss IF applied to this choice
        }
      }
    })
    engine.resolveChoice(card, 'A')

    // Energy went down by full 20 (NOT 10) — buff didn't affect this choice
    expect(resources.getResources().energy).toBe(60)
    // But buff IS now active for the NEXT choice
    expect(status.getBuff()?.id).toBe('caffeine')
    expect(status.getBuff()?.daysLeft).toBe(2)  // BuffSpec.days → StatusEffect.daysLeft
  })

  test('subsequent choice IS modified by the previously-added buff', () => {
    const { engine, status, resources } = buildEngine()
    // First choice: add coffee buff
    engine.resolveChoice(
      makeCard({
        choiceA: {
          text: 'drink coffee',
          effects: [],
          buff: { id: 'c', name: '亢奋', icon: '☕', type: 'buff', days: 2, energyMul: 0.5 }
        }
      }),
      'A'
    )
    expect(status.getBuff()?.id).toBe('c')

    // Second choice: -20 energy → modified by buff → -10
    const result = engine.resolveChoice(
      makeCard({
        id: 'second',
        choiceA: { text: 'work', effects: [{ target: 'energy', value: -20 }] }
      }),
      'A'
    )
    expect(resources.getResources().energy).toBe(70)
    expect(result.deltas[0]!.wasStatusModified).toBe(true)
  })

  test('risk outcome can carry its own buff', () => {
    const { engine, status } = buildEngine({ randomRoll: () => 0.1 })
    const card = makeCard({
      choiceA: {
        text: 'A',
        effects: [],
        risk: {
          chance: 0.5,
          success: {
            text: 'win',
            effects: [],
            buff: {
              id: 'lucky-buff',
              name: 'lucky',
              icon: '🍀',
              type: 'buff',
              days: 1,
              moodMul: 0.5
            }
          },
          fail: { text: 'lose', effects: [] }
        }
      }
    })
    engine.resolveChoice(card, 'A')
    expect(status.getBuff()?.id).toBe('lucky-buff')
  })

  test('risk outcome buff falls back to choice.buff if outcome has none', () => {
    const { engine, status } = buildEngine({ randomRoll: () => 0.9 })  // fail
    const card = makeCard({
      choiceA: {
        text: 'A',
        effects: [],
        buff: { id: 'fallback', name: 'fb', icon: '?', type: 'buff', days: 1 },
        risk: {
          chance: 0.5,
          success: { text: 'win', effects: [] },
          fail: { text: 'lose', effects: [] }  // no buff on fail
        }
      }
    })
    engine.resolveChoice(card, 'A')
    expect(status.getBuff()?.id).toBe('fallback')
  })
})

describe('ChoiceResolutionEngine — state change + followUp passthrough (AC-5/6)', () => {
  test('AC-5: ResourceManager triggers DEAD → ResolveResult.stateChange="DEAD"', () => {
    const { engine } = buildEngine()
    const card = makeCard({
      choiceA: { text: 'die', effects: [{ target: 'energy', value: -100 }] }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(result.stateChange).toBe('DEAD')
  })

  test('no state change → stateChange undefined', () => {
    const { engine } = buildEngine()
    const card = makeCard({
      choiceA: { text: 'mild', effects: [{ target: 'energy', value: -5 }] }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(result.stateChange).toBeUndefined()
  })

  test('AC-6: followUpId is passed through to result', () => {
    const { engine } = buildEngine()
    const card = makeCard({
      choiceA: { text: 'A', effects: [], followUpId: 'event-bonus' }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(result.followUpId).toBe('event-bonus')
  })

  test('no followUpId → followUpId undefined', () => {
    const { engine } = buildEngine()
    const card = makeCard({
      choiceA: { text: 'A', effects: [] }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(result.followUpId).toBeUndefined()
  })
})

describe('ChoiceResolutionEngine — recordChoice (AC-8)', () => {
  test('every resolveChoice triggers recordChoice with eventId + key', () => {
    const { engine, recordChoice } = buildEngine()
    const card = makeCard({ id: 'evt-1' })
    engine.resolveChoice(card, 'A')
    engine.resolveChoice(card, 'B')
    expect(recordChoice).toHaveBeenCalledTimes(2)
    expect(recordChoice).toHaveBeenNthCalledWith(1, 'evt-1', 'A')
    expect(recordChoice).toHaveBeenNthCalledWith(2, 'evt-1', 'B')
  })

  test('recordChoice called even when effects empty', () => {
    const { engine, recordChoice } = buildEngine()
    engine.resolveChoice(makeCard({ id: 'empty' }), 'A')
    expect(recordChoice).toHaveBeenCalledWith('empty', 'A')
  })
})

describe('ChoiceResolutionEngine — choice B path', () => {
  test('selecting B uses choiceB instead of choiceA', () => {
    const { engine, resources } = buildEngine()
    const card = makeCard({
      choiceA: { text: 'A', effects: [{ target: 'energy', value: -10 }] },
      choiceB: { text: 'B', effects: [{ target: 'energy', value: 5 }] }
    })
    engine.resolveChoice(card, 'B')
    expect(resources.getResources().energy).toBe(85)  // 80 + 5
  })
})

describe('ChoiceResolutionEngine — clamping behavior (wasClamped)', () => {
  test('value clamped at boundary → wasClamped=true on the delta', () => {
    const { engine } = buildEngine()
    const card = makeCard({
      choiceA: { text: 'overflow', effects: [{ target: 'energy', value: 50 }] }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(result.deltas[0]!.delta).toBe(20)  // clamped from 130 to 100
    expect(result.deltas[0]!.wasClamped).toBe(true)
    expect(result.deltas[0]!.rawDelta).toBe(50)
  })

  test('non-clamped delta → wasClamped=false', () => {
    const { engine } = buildEngine()
    const card = makeCard({
      choiceA: { text: 'mild', effects: [{ target: 'energy', value: -5 }] }
    })
    const result = engine.resolveChoice(card, 'A')
    expect(result.deltas[0]!.wasClamped).toBe(false)
  })
})
