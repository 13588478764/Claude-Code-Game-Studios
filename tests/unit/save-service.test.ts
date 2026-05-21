import { describe, test, expect, vi, beforeEach } from 'vitest'
import { SaveService, type StorageAdapter } from '@/services/save/save-service'
import { SAVE_KEY, SAVE_SCHEMA_VERSION, EMPTY_SAVE, type SaveData } from '@/types/save'

function makeMockAdapter(): StorageAdapter & { _store: Map<string, string> } {
  const store = new Map<string, string>()
  return {
    _store: store,
    setSync(key, value) { store.set(key, value) },
    getSync(key) { return store.get(key) ?? null },
    removeSync(key) { store.delete(key) }
  }
}

function makeSave(overrides: Partial<SaveData> = {}): SaveData {
  return { ...EMPTY_SAVE, version: SAVE_SCHEMA_VERSION, ...overrides }
}

describe('SaveService', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  test('save() persists to storage with correct key (after debounce)', () => {
    const adapter = makeMockAdapter()
    const svc = new SaveService(adapter)
    svc.save(makeSave({ stats: { ...EMPTY_SAVE.stats, totalRuns: 5 } }))
    vi.advanceTimersByTime(110)
    expect(adapter._store.has(SAVE_KEY)).toBe(true)
    const parsed = JSON.parse(adapter._store.get(SAVE_KEY)!)
    expect(parsed.stats.totalRuns).toBe(5)
  })

  test('load() returns parsed object', () => {
    const adapter = makeMockAdapter()
    adapter.setSync(SAVE_KEY, JSON.stringify(makeSave({
      stats: { ...EMPTY_SAVE.stats, totalRuns: 7 }
    })))
    const svc = new SaveService(adapter)
    const data = svc.load()
    expect(data?.stats.totalRuns).toBe(7)
  })

  test('load() returns null when key not exists', () => {
    const svc = new SaveService(makeMockAdapter())
    expect(svc.load()).toBeNull()
  })

  test('save() includes schema version', () => {
    const adapter = makeMockAdapter()
    const svc = new SaveService(adapter)
    svc.save(makeSave())
    vi.advanceTimersByTime(110)
    const parsed = JSON.parse(adapter._store.get(SAVE_KEY)!)
    expect(parsed.version).toBe(SAVE_SCHEMA_VERSION)
  })

  test('load() triggers migration when schema version differs', () => {
    const adapter = makeMockAdapter()
    adapter.setSync(SAVE_KEY, JSON.stringify({
      version: 0,
      stats: { totalRuns: 3 }
    }))
    const svc = new SaveService(adapter)
    const data = svc.load()
    expect(data?.version).toBe(SAVE_SCHEMA_VERSION)
    expect(data?.stats.totalRuns).toBe(3)
    expect(data?.jobUnlocks).toEqual(['intern', 'programmer'])
  })

  test('migrate() preserves stats from old data', () => {
    const svc = new SaveService(makeMockAdapter())
    const migrated = svc.migrate({ version: 0, stats: { totalRuns: 99 } }, 0)
    expect(migrated.stats.totalRuns).toBe(99)
    expect(migrated.version).toBe(SAVE_SCHEMA_VERSION)
  })

  test('migrate() handles missing stats gracefully', () => {
    const svc = new SaveService(makeMockAdapter())
    const migrated = svc.migrate({ version: 0 }, 0)
    expect(migrated.stats).toEqual(EMPTY_SAVE.stats)
  })

  test('clear() removes data from storage', () => {
    const adapter = makeMockAdapter()
    adapter.setSync(SAVE_KEY, JSON.stringify(makeSave()))
    const svc = new SaveService(adapter)
    svc.clear()
    expect(adapter._store.has(SAVE_KEY)).toBe(false)
  })

  test('save() debounces rapid calls within 100ms', () => {
    const adapter = makeMockAdapter()
    const setSpy = vi.spyOn(adapter, 'setSync')
    const svc = new SaveService(adapter)
    svc.save(makeSave({ stats: { ...EMPTY_SAVE.stats, totalRuns: 1 } }))
    svc.save(makeSave({ stats: { ...EMPTY_SAVE.stats, totalRuns: 2 } }))
    svc.save(makeSave({ stats: { ...EMPTY_SAVE.stats, totalRuns: 3 } }))
    vi.advanceTimersByTime(110)
    expect(setSpy).toHaveBeenCalledTimes(1)
    const parsed = JSON.parse(adapter._store.get(SAVE_KEY)!)
    expect(parsed.stats.totalRuns).toBe(3)  // last write wins
  })

  test('saveImmediate() bypasses debounce', () => {
    const adapter = makeMockAdapter()
    const svc = new SaveService(adapter)
    svc.save(makeSave({ stats: { ...EMPTY_SAVE.stats, totalRuns: 1 } }))
    svc.saveImmediate(makeSave({ stats: { ...EMPTY_SAVE.stats, totalRuns: 99 } }))
    expect(adapter._store.has(SAVE_KEY)).toBe(true)
    const parsed = JSON.parse(adapter._store.get(SAVE_KEY)!)
    expect(parsed.stats.totalRuns).toBe(99)
  })

  test('emit onSaved after successful save', () => {
    const svc = new SaveService(makeMockAdapter())
    const fn = vi.fn()
    svc.onSaved.on(fn)
    svc.save(makeSave())
    vi.advanceTimersByTime(110)
    expect(fn).toHaveBeenCalled()
  })

  test('emit onLoadFailed when storage corrupted', () => {
    const adapter = makeMockAdapter()
    adapter.setSync(SAVE_KEY, '{not valid json')
    const svc = new SaveService(adapter)
    const fn = vi.fn()
    svc.onLoadFailed.on(fn)
    expect(svc.load()).toBeNull()
    expect(fn).toHaveBeenCalled()
  })

  test('load() rejects non-object payload', () => {
    const adapter = makeMockAdapter()
    adapter.setSync(SAVE_KEY, 'null')
    const svc = new SaveService(adapter)
    const fn = vi.fn()
    svc.onLoadFailed.on(fn)
    expect(svc.load()).toBeNull()
    expect(fn).toHaveBeenCalledWith(expect.objectContaining({
      reason: expect.stringContaining('corrupted')
    }))
  })

  test('clear() cancels pending debounced save', () => {
    const adapter = makeMockAdapter()
    const svc = new SaveService(adapter)
    svc.save(makeSave({ stats: { ...EMPTY_SAVE.stats, totalRuns: 1 } }))
    svc.clear()
    vi.advanceTimersByTime(110)
    expect(adapter._store.has(SAVE_KEY)).toBe(false)
  })

  // ============== S2-7: firstStatusShown profile field ==============

  test('S2-7 AC-2: old save without firstStatusShown loads as undefined', () => {
    // Simulate an old save written before the new field was added.
    const adapter = makeMockAdapter()
    adapter.setSync(
      SAVE_KEY,
      JSON.stringify({
        version: SAVE_SCHEMA_VERSION,
        jobUnlocks: ['intern', 'programmer'],
        currentRun: null,
        stats: EMPTY_SAVE.stats,
        updatedAt: 0
        // NOTE: firstStatusShown intentionally absent
      })
    )
    const svc = new SaveService(adapter)
    const data = svc.load()
    expect(data?.firstStatusShown).toBeUndefined()
  })

  test('S2-7 AC-3: round-trip preserves firstStatusShown=true', () => {
    const adapter = makeMockAdapter()
    const svc = new SaveService(adapter)
    svc.save(makeSave({ firstStatusShown: true }))
    vi.advanceTimersByTime(110)
    const data = svc.load()
    expect(data?.firstStatusShown).toBe(true)
  })

  test('S2-7 AC-3: round-trip preserves firstStatusShown=false', () => {
    const adapter = makeMockAdapter()
    const svc = new SaveService(adapter)
    svc.save(makeSave({ firstStatusShown: false }))
    vi.advanceTimersByTime(110)
    const data = svc.load()
    expect(data?.firstStatusShown).toBe(false)
  })

  test('S2-7: omitting firstStatusShown on save round-trips as undefined', () => {
    const adapter = makeMockAdapter()
    const svc = new SaveService(adapter)
    // makeSave doesn't set firstStatusShown — should remain undefined
    svc.save(makeSave())
    vi.advanceTimersByTime(110)
    const data = svc.load()
    expect(data?.firstStatusShown).toBeUndefined()
  })
})
