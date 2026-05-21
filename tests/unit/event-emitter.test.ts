import { describe, test, expect, vi } from 'vitest'
import { TypedEventEmitter } from '@/services/common/event-emitter'

describe('TypedEventEmitter', () => {
  test('on() registers handler', () => {
    const e = new TypedEventEmitter<number>()
    const fn = vi.fn()
    e.on(fn)
    expect(e.size).toBe(1)
  })

  test('emit() invokes registered handlers', () => {
    const e = new TypedEventEmitter<number>()
    const fn1 = vi.fn()
    const fn2 = vi.fn()
    e.on(fn1)
    e.on(fn2)
    e.emit(42)
    expect(fn1).toHaveBeenCalledWith(42)
    expect(fn2).toHaveBeenCalledWith(42)
  })

  test('emit() with no handlers is no-op', () => {
    const e = new TypedEventEmitter<string>()
    expect(() => e.emit('hello')).not.toThrow()
  })

  test('off() unregisters specific handler', () => {
    const e = new TypedEventEmitter<number>()
    const fn1 = vi.fn()
    const fn2 = vi.fn()
    e.on(fn1)
    e.on(fn2)
    e.off(fn1)
    e.emit(1)
    expect(fn1).not.toHaveBeenCalled()
    expect(fn2).toHaveBeenCalledWith(1)
  })

  test('off() with unknown handler is no-op', () => {
    const e = new TypedEventEmitter<number>()
    const fn = vi.fn()
    expect(() => e.off(fn)).not.toThrow()
    expect(e.size).toBe(0)
  })

  test('once() invokes handler exactly once', () => {
    const e = new TypedEventEmitter<number>()
    const fn = vi.fn()
    e.once(fn)
    e.emit(1)
    e.emit(2)
    e.emit(3)
    expect(fn).toHaveBeenCalledTimes(1)
    expect(fn).toHaveBeenCalledWith(1)
    expect(e.size).toBe(0)
  })

  test('clear() removes all handlers', () => {
    const e = new TypedEventEmitter<number>()
    e.on(vi.fn())
    e.on(vi.fn())
    e.on(vi.fn())
    expect(e.size).toBe(3)
    e.clear()
    expect(e.size).toBe(0)
  })

  test('handler exception does not block other handlers', () => {
    const e = new TypedEventEmitter<number>()
    const consoleErr = vi.spyOn(console, 'error').mockImplementation(() => {})
    const fnBad = vi.fn(() => { throw new Error('boom') })
    const fnGood = vi.fn()
    e.on(fnBad)
    e.on(fnGood)
    e.emit(99)
    expect(fnBad).toHaveBeenCalled()
    expect(fnGood).toHaveBeenCalledWith(99)
    expect(consoleErr).toHaveBeenCalled()
    consoleErr.mockRestore()
  })

  test('payload typing is preserved (compiles)', () => {
    interface Payload { value: number; tag: string }
    const e = new TypedEventEmitter<Payload>()
    const fn = vi.fn<[Payload], void>()
    e.on(fn)
    e.emit({ value: 1, tag: 'a' })
    expect(fn).toHaveBeenCalledWith({ value: 1, tag: 'a' })
  })

  test('emit during emit (re-entrancy) does not double-invoke', () => {
    const e = new TypedEventEmitter<number>()
    const calls: number[] = []
    e.on((v) => {
      calls.push(v)
      if (v === 1) e.emit(2)
    })
    e.emit(1)
    expect(calls).toEqual([1, 2])
  })

  test('off during emit does not skip subsequent handlers', () => {
    const e = new TypedEventEmitter<number>()
    const fn1 = vi.fn()
    const fn2 = vi.fn()
    const fn3 = vi.fn(() => { e.off(fn1) })
    e.on(fn1)
    e.on(fn2)
    e.on(fn3)
    e.emit(7)
    expect(fn1).toHaveBeenCalledWith(7)
    expect(fn2).toHaveBeenCalledWith(7)
    expect(fn3).toHaveBeenCalledWith(7)
    e.emit(8)
    expect(fn1).toHaveBeenCalledTimes(1)
    expect(fn2).toHaveBeenCalledTimes(2)
  })
})
