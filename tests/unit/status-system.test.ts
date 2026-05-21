import { describe, test, expect, vi } from 'vitest'
import { StatusSystem, signFloor } from '@/services/status/status-system'
import { TypedEventEmitter } from '@/services/common/event-emitter'
import type { StatusEffect } from '@/types/status'
import type { PhaseChangedPayload } from '@/types/run-phase'

function makeBuff(overrides: Partial<StatusEffect> = {}): StatusEffect {
  return {
    id: 'caffeine',
    name: '亢奋',
    icon: '☕',
    type: 'buff',
    daysLeft: 2,
    energyMul: 0.5,
    ...overrides
  }
}

function makeDebuff(overrides: Partial<StatusEffect> = {}): StatusEffect {
  return {
    id: 'emo',
    name: 'emo',
    icon: '💔',
    type: 'debuff',
    daysLeft: 2,
    moodMul: 1.5,
    ...overrides
  }
}

describe('signFloor', () => {
  test('positive floor', () => {
    expect(signFloor(19.95)).toBe(19)
    expect(signFloor(19.0)).toBe(19)
    expect(signFloor(0.99)).toBe(0)
  })

  test('negative ceil-toward-zero', () => {
    expect(signFloor(-19.95)).toBe(-19)
    expect(signFloor(-19.0)).toBe(-19)
    expect(signFloor(-0.99)).toBe(0)
  })

  test('zero', () => {
    expect(signFloor(0)).toBe(0)
  })

  test('integer pass-through', () => {
    expect(signFloor(10)).toBe(10)
    expect(signFloor(-10)).toBe(-10)
  })
})

describe('StatusSystem — addStatus', () => {
  test('AC-1: empty slot fresh add → getBuff returns it, getDebuff null, emit onStatusAdded', () => {
    const sys = new StatusSystem()
    const fn = vi.fn()
    sys.onStatusAdded.on(fn)
    const buff = makeBuff()
    sys.addStatus(buff)
    expect(sys.getBuff()).toEqual(buff)
    expect(sys.getDebuff()).toBeNull()
    expect(fn).toHaveBeenCalledWith(buff)
  })

  test('AC-4: same id refresh → days+mul fully replaced, emit onStatusRefreshed', () => {
    const sys = new StatusSystem()
    const refreshed = vi.fn()
    sys.onStatusRefreshed.on(refreshed)
    sys.addStatus(makeDebuff({ daysLeft: 2, moodMul: 1.5 }))
    sys.addStatus(makeDebuff({ daysLeft: 1, moodMul: 1.3 }))
    const final = sys.getDebuff()!
    expect(final.daysLeft).toBe(1)
    expect(final.moodMul).toBe(1.3)
    expect(refreshed).toHaveBeenCalledWith({
      id: 'emo',
      oldDays: 2,
      newDays: 1
    })
  })

  test('AC-4 edge: same id refresh with missing mul → mul becomes undefined', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeBuff({ energyMul: 0.5 }))
    // re-add with no mul fields
    sys.addStatus({
      id: 'caffeine',
      name: '亢奋',
      icon: '☕',
      type: 'buff',
      daysLeft: 1
    })
    const final = sys.getBuff()!
    expect(final.daysLeft).toBe(1)
    expect(final.energyMul).toBeUndefined()
  })

  test('AC-5: same slot, different id → replace, emit onStatusReplaced', () => {
    const sys = new StatusSystem()
    const replaced = vi.fn()
    sys.onStatusReplaced.on(replaced)
    const old = makeBuff({ id: 'caffeine' })
    const next = makeBuff({ id: 'energetic', name: '元气满满', icon: '✨' })
    sys.addStatus(old)
    sys.addStatus(next)
    expect(sys.getBuff()?.id).toBe('energetic')
    expect(replaced).toHaveBeenCalledWith({
      slot: 'buff',
      old,
      new: next
    })
  })

  test('AC-5 edge: replacing buff slot does not affect debuff slot', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeBuff())
    sys.addStatus(makeDebuff())
    sys.addStatus(makeBuff({ id: 'energetic' }))
    expect(sys.getBuff()?.id).toBe('energetic')
    expect(sys.getDebuff()?.id).toBe('emo')
  })

  test('AC-12: addStatus with daysLeft=0 → rejected, console.warn with id', () => {
    const sys = new StatusSystem()
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    sys.addStatus(makeBuff({ daysLeft: 0 }))
    expect(sys.getBuff()).toBeNull()
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('caffeine'))
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('daysLeft=0'))
    warn.mockRestore()
  })

  test('AC-12: addStatus with daysLeft=-1 → rejected, no state change', () => {
    const sys = new StatusSystem()
    const fn = vi.fn()
    sys.onStatusChanged.on(fn)
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    sys.addStatus(makeBuff({ daysLeft: -1 }))
    expect(fn).not.toHaveBeenCalled()
    warn.mockRestore()
  })

  test('emitChanged fires on every successful mutation', () => {
    const sys = new StatusSystem()
    const fn = vi.fn()
    sys.onStatusChanged.on(fn)
    sys.addStatus(makeBuff())
    sys.addStatus(makeBuff({ id: 'other' }))  // replace
    sys.addStatus(makeBuff({ id: 'other', daysLeft: 1 }))  // refresh
    expect(fn).toHaveBeenCalledTimes(3)
  })

  test('addStatus stores a copy — external mutation does not affect state', () => {
    const sys = new StatusSystem()
    const spec = makeBuff({ daysLeft: 5 })
    sys.addStatus(spec)
    spec.daysLeft = 999
    expect(sys.getBuff()?.daysLeft).toBe(5)
  })
})

describe('StatusSystem — applyToEffect', () => {
  test('AC-2: buff energyMul=0.5 + rawValue=-20 → -10', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeBuff({ energyMul: 0.5 }))
    expect(sys.applyToEffect('energy', -20)).toBe(-10)
  })

  test('AC-6: cross-slot independence (buff energy + debuff mood)', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeBuff({ energyMul: 0.5 }))  // no moodMul
    sys.addStatus(makeDebuff({ moodMul: 1.5 }))  // no energyMul

    expect(sys.applyToEffect('energy', -20)).toBe(-10)  // buff applies
    expect(sys.applyToEffect('mood', -10)).toBe(-15)    // debuff applies
  })

  test('no status → returns rawValue unchanged', () => {
    const sys = new StatusSystem()
    expect(sys.applyToEffect('energy', -20)).toBe(-20)
    expect(sys.applyToEffect('mood', 15)).toBe(15)
  })

  test('status with no mul for target → unchanged', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeBuff({ energyMul: 0.5 }))
    expect(sys.applyToEffect('mood', -20)).toBe(-20)
  })

  test('signFloor applied: rawValue=-19, mul=1.05 → -19 (ceil toward 0)', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeDebuff({ moodMul: 1.05 }))
    expect(sys.applyToEffect('mood', -19)).toBe(-19)
  })

  test('signFloor applied: rawValue=19, mul=1.05 → 19', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeDebuff({ moodMul: 1.05 }))
    expect(sys.applyToEffect('mood', 19)).toBe(19)
  })

  test('data violation: both buff and debuff with mul on same target → buff wins, console.warn', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeBuff({ energyMul: 0.5 }))
    sys.addStatus(makeDebuff({ id: 'bad', energyMul: 1.5 } as StatusEffect))
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})

    expect(sys.applyToEffect('energy', -20)).toBe(-10)  // buff (0.5) wins
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('data violation'))
    warn.mockRestore()
  })

  test('only debuff has mul → debuff applied', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeDebuff({ moodMul: 1.5 }))
    expect(sys.applyToEffect('mood', -10)).toBe(-15)
  })
})

describe('StatusSystem — tickStatuses', () => {
  test('AC-3: daysLeft=1 → tick → expired + emit onStatusExpired', () => {
    const sys = new StatusSystem()
    const expired = vi.fn()
    sys.onStatusExpired.on(expired)
    const buff = makeBuff({ daysLeft: 1 })
    sys.addStatus(buff)
    sys.tickStatuses()
    expect(sys.getBuff()).toBeNull()
    expect(expired).toHaveBeenCalledWith(expect.objectContaining({ id: 'caffeine' }))
  })

  test('daysLeft=2 → tick → still active with daysLeft=1', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeBuff({ daysLeft: 2 }))
    sys.tickStatuses()
    expect(sys.getBuff()?.daysLeft).toBe(1)
  })

  test('tick both slots simultaneously', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeBuff({ daysLeft: 1 }))
    sys.addStatus(makeDebuff({ daysLeft: 2 }))
    sys.tickStatuses()
    expect(sys.getBuff()).toBeNull()       // expired
    expect(sys.getDebuff()?.daysLeft).toBe(1)  // ticked
  })

  test('debuff-only expiration (covers line 163-166)', () => {
    const sys = new StatusSystem()
    const expired = vi.fn()
    sys.onStatusExpired.on(expired)
    sys.addStatus(makeDebuff({ daysLeft: 1 }))
    sys.tickStatuses()
    expect(sys.getDebuff()).toBeNull()
    expect(expired).toHaveBeenCalledWith(expect.objectContaining({ id: 'emo' }))
  })

  test('empty slots → tick is no-op, no emitChanged', () => {
    const sys = new StatusSystem()
    const fn = vi.fn()
    sys.onStatusChanged.on(fn)
    sys.tickStatuses()
    expect(fn).not.toHaveBeenCalled()
  })

  test('emitChanged fires once per tick when state changed', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeBuff({ daysLeft: 2 }))
    const fn = vi.fn()
    sys.onStatusChanged.on(fn)
    sys.tickStatuses()
    expect(fn).toHaveBeenCalledTimes(1)
  })
})

describe('StatusSystem — clearAll', () => {
  test('clear removes both slots + emit onStatusesCleared', () => {
    const sys = new StatusSystem()
    const cleared = vi.fn()
    sys.onStatusesCleared.on(cleared)
    sys.addStatus(makeBuff())
    sys.addStatus(makeDebuff())
    sys.clearAll()
    expect(sys.getBuff()).toBeNull()
    expect(sys.getDebuff()).toBeNull()
    expect(cleared).toHaveBeenCalled()
  })

  test('idempotent: clearAll on empty system is no-op', () => {
    const sys = new StatusSystem()
    const cleared = vi.fn()
    sys.onStatusesCleared.on(cleared)
    sys.clearAll()
    expect(cleared).not.toHaveBeenCalled()
  })
})

describe('StatusSystem — query', () => {
  test('hasStatus returns true for active status, false otherwise', () => {
    const sys = new StatusSystem()
    expect(sys.hasStatus('caffeine')).toBe(false)
    sys.addStatus(makeBuff())
    expect(sys.hasStatus('caffeine')).toBe(true)
    expect(sys.hasStatus('emo')).toBe(false)
    sys.addStatus(makeDebuff())
    expect(sys.hasStatus('emo')).toBe(true)
  })
})

describe('StatusSystem — subscribeToRunPhase', () => {
  test('AC-9: emit ENDED → clearAll called + onStatusesCleared', () => {
    const sys = new StatusSystem()
    const phaseEmitter = new TypedEventEmitter<PhaseChangedPayload>()
    const cleared = vi.fn()
    sys.onStatusesCleared.on(cleared)
    sys.addStatus(makeBuff())
    sys.subscribeToRunPhase(phaseEmitter)

    phaseEmitter.emit({ from: 'SETTLING', to: 'ENDED' })
    expect(sys.getBuff()).toBeNull()
    expect(cleared).toHaveBeenCalled()
  })

  test('AC-8: emit DYING → clearAll NOT called, statuses preserved', () => {
    const sys = new StatusSystem()
    const phaseEmitter = new TypedEventEmitter<PhaseChangedPayload>()
    const clearSpy = vi.spyOn(sys, 'clearAll')
    sys.addStatus(makeBuff())
    sys.subscribeToRunPhase(phaseEmitter)

    phaseEmitter.emit({ from: 'PLAYING', to: 'DYING' })
    expect(clearSpy).not.toHaveBeenCalled()
    expect(sys.getBuff()).not.toBeNull()
  })

  test('emit SETTLING → not cleared (revive flow may follow)', () => {
    const sys = new StatusSystem()
    const phaseEmitter = new TypedEventEmitter<PhaseChangedPayload>()
    sys.addStatus(makeBuff())
    sys.subscribeToRunPhase(phaseEmitter)

    phaseEmitter.emit({ from: 'DYING', to: 'SETTLING' })
    expect(sys.getBuff()).not.toBeNull()
  })

  test('multiple phase transitions → only ENDED triggers clear', () => {
    const sys = new StatusSystem()
    const phaseEmitter = new TypedEventEmitter<PhaseChangedPayload>()
    sys.addStatus(makeBuff())
    sys.subscribeToRunPhase(phaseEmitter)

    phaseEmitter.emit({ from: 'JOB_SELECT', to: 'INITIALIZING' })
    phaseEmitter.emit({ from: 'INITIALIZING', to: 'PLAYING' })
    phaseEmitter.emit({ from: 'PLAYING', to: 'DYING' })
    phaseEmitter.emit({ from: 'DYING', to: 'SETTLING' })
    expect(sys.getBuff()).not.toBeNull()
    phaseEmitter.emit({ from: 'SETTLING', to: 'ENDED' })
    expect(sys.getBuff()).toBeNull()
  })
})

describe('StatusSystem — subscribeToDayEnded', () => {
  test('emit onDayEnded → tickStatuses called', () => {
    const sys = new StatusSystem()
    const dayEmitter = new TypedEventEmitter<{ day: number; weekIndex: number; salary: number }>()
    sys.addStatus(makeBuff({ daysLeft: 2 }))
    sys.subscribeToDayEnded(dayEmitter)

    dayEmitter.emit({ day: 1, weekIndex: 1, salary: 10 })
    expect(sys.getBuff()?.daysLeft).toBe(1)
  })
})

describe('StatusSystem — getSnapshot / loadSnapshot', () => {
  test('getSnapshot returns all active statuses', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeBuff())
    sys.addStatus(makeDebuff())
    expect(sys.getSnapshot()).toHaveLength(2)
    expect(sys.getSnapshot().map(s => s.id).sort()).toEqual(['caffeine', 'emo'])
  })

  test('getSnapshot returns copies (not internal references)', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeBuff({ daysLeft: 5 }))
    const snap = sys.getSnapshot()
    snap[0]!.daysLeft = 999
    expect(sys.getBuff()?.daysLeft).toBe(5)
  })

  test('AC-10: loadSnapshot(undefined) → empty, no error', () => {
    const sys = new StatusSystem()
    sys.loadSnapshot(undefined)
    expect(sys.getBuff()).toBeNull()
    expect(sys.getDebuff()).toBeNull()
  })

  test('loadSnapshot([]) → empty', () => {
    const sys = new StatusSystem()
    sys.loadSnapshot([])
    expect(sys.getBuff()).toBeNull()
  })

  test('loadSnapshot replaces current state', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeBuff())
    sys.loadSnapshot([makeDebuff()])
    expect(sys.getBuff()).toBeNull()
    expect(sys.getDebuff()?.id).toBe('emo')
  })

  test('AC-11: loadSnapshot with daysLeft=0 entry → filtered + emit onLoadCorrected', () => {
    const sys = new StatusSystem()
    const corrected = vi.fn()
    sys.onLoadCorrected.on(corrected)
    const corruptedEntry = makeBuff({ daysLeft: 0 })
    sys.loadSnapshot([corruptedEntry, makeDebuff()])
    expect(sys.getBuff()).toBeNull()
    expect(sys.getDebuff()?.id).toBe('emo')
    expect(corrected).toHaveBeenCalledWith({ dropped: [corruptedEntry] })
  })

  test('loadSnapshot with duplicate slot entries → keep first, drop rest', () => {
    const sys = new StatusSystem()
    const corrected = vi.fn()
    sys.onLoadCorrected.on(corrected)
    const buff1 = makeBuff({ id: 'first' })
    const buff2 = makeBuff({ id: 'second' })
    sys.loadSnapshot([buff1, buff2])
    expect(sys.getBuff()?.id).toBe('first')
    expect(corrected).toHaveBeenCalledWith({ dropped: [buff2] })
  })

  test('roundtrip: snapshot → load preserves state', () => {
    const sys1 = new StatusSystem()
    sys1.addStatus(makeBuff({ daysLeft: 2 }))
    sys1.addStatus(makeDebuff({ daysLeft: 1 }))
    const snap = sys1.getSnapshot()

    const sys2 = new StatusSystem()
    sys2.loadSnapshot(snap)
    expect(sys2.getBuff()?.daysLeft).toBe(2)
    expect(sys2.getDebuff()?.daysLeft).toBe(1)
  })
})

describe('StatusSystem — onStatusChanged aggregation', () => {
  test('emits snapshot on add', () => {
    const sys = new StatusSystem()
    const fn = vi.fn()
    sys.onStatusChanged.on(fn)
    sys.addStatus(makeBuff())
    expect(fn).toHaveBeenCalledWith([expect.objectContaining({ id: 'caffeine' })])
  })

  test('emits snapshot on clearAll', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeBuff())
    const fn = vi.fn()
    sys.onStatusChanged.on(fn)
    sys.clearAll()
    expect(fn).toHaveBeenCalledWith([])
  })

  test('emits snapshot on tick that expires', () => {
    const sys = new StatusSystem()
    sys.addStatus(makeBuff({ daysLeft: 1 }))
    const fn = vi.fn()
    sys.onStatusChanged.on(fn)
    sys.tickStatuses()
    expect(fn).toHaveBeenCalledWith([])
  })
})
