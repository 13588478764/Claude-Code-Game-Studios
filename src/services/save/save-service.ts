/**
 * SaveService — wraps platform storage with schema versioning and debouncing.
 * See ADR-003: Service emit → Store subscribe.
 */

import { TypedEventEmitter } from '../common/event-emitter'
import {
  SAVE_KEY,
  SAVE_SCHEMA_VERSION,
  EMPTY_SAVE,
  type SaveData
} from '@/types/save'

export interface StorageAdapter {
  setSync(key: string, value: string): void
  getSync(key: string): string | null
  removeSync(key: string): void
}

/**
 * Default uni adapter — uses uni.setStorageSync / uni.getStorageSync.
 * Tests inject a mock adapter.
 */
export const uniStorageAdapter: StorageAdapter = {
  setSync(key, value) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const u = (globalThis as any).uni
    if (u && typeof u.setStorageSync === 'function') {
      u.setStorageSync(key, value)
    } else {
      // Fallback for non-uni environments (e.g. tests, web preview)
      try { localStorage.setItem(key, value) } catch { /* noop */ }
    }
  },
  getSync(key) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const u = (globalThis as any).uni
    if (u && typeof u.getStorageSync === 'function') {
      const v = u.getStorageSync(key)
      return v === '' || v == null ? null : String(v)
    }
    try { return localStorage.getItem(key) } catch { return null }
  },
  removeSync(key) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const u = (globalThis as any).uni
    if (u && typeof u.removeStorageSync === 'function') {
      u.removeStorageSync(key)
    } else {
      try { localStorage.removeItem(key) } catch { /* noop */ }
    }
  }
}

const DEBOUNCE_MS = 100

export class SaveService {
  private adapter: StorageAdapter
  private debounceTimer: ReturnType<typeof setTimeout> | null = null
  private pendingData: SaveData | null = null

  readonly onSaved = new TypedEventEmitter<{ at: number }>()
  readonly onLoadFailed = new TypedEventEmitter<{ reason: string }>()

  constructor(adapter: StorageAdapter = uniStorageAdapter) {
    this.adapter = adapter
  }

  load(): SaveData | null {
    try {
      const raw = this.adapter.getSync(SAVE_KEY)
      if (raw == null) return null
      const parsed = JSON.parse(raw)
      if (typeof parsed !== 'object' || parsed === null) {
        this.onLoadFailed.emit({ reason: 'corrupted: not an object' })
        return null
      }
      const version: number = parsed.version ?? 0
      if (version === SAVE_SCHEMA_VERSION) {
        return parsed as SaveData
      }
      // Migration path
      return this.migrate(parsed, version)
    } catch (err) {
      this.onLoadFailed.emit({ reason: String(err) })
      return null
    }
  }

  /**
   * Save with 100ms debounce — batches rapid successive writes.
   */
  save(data: SaveData): void {
    this.pendingData = { ...data, updatedAt: Date.now() }
    if (this.debounceTimer != null) {
      clearTimeout(this.debounceTimer)
    }
    this.debounceTimer = setTimeout(() => {
      if (this.pendingData) this.flush(this.pendingData)
    }, DEBOUNCE_MS)
  }

  /**
   * Save immediately, bypassing debounce — use for app-pause and critical writes.
   */
  saveImmediate(data: SaveData): void {
    if (this.debounceTimer != null) {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = null
    }
    this.flush({ ...data, updatedAt: Date.now() })
  }

  clear(): void {
    if (this.debounceTimer != null) {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = null
    }
    this.pendingData = null
    this.adapter.removeSync(SAVE_KEY)
  }

  /**
   * Migrate from older schema versions. Sprint 1 only has v1.
   * When schema version bumps, add a `migrateNtoN+1` function and chain here.
   */
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  migrate(oldData: any, fromVersion: number): SaveData {
    let data = oldData
    let v = fromVersion

    // Future migrations: while (v < SAVE_SCHEMA_VERSION) { ... v++ }
    // For now, fromVersion can only be < 1 (i.e. unknown/missing) → reset
    if (v < SAVE_SCHEMA_VERSION) {
      // Best-effort merge: keep stats if present
      data = {
        ...EMPTY_SAVE,
        stats: (data && typeof data.stats === 'object')
          ? { ...EMPTY_SAVE.stats, ...data.stats }
          : EMPTY_SAVE.stats,
        version: SAVE_SCHEMA_VERSION
      }
      v = SAVE_SCHEMA_VERSION
    }

    return data as SaveData
  }

  private flush(data: SaveData): void {
    try {
      this.adapter.setSync(SAVE_KEY, JSON.stringify(data))
      this.onSaved.emit({ at: Date.now() })
      this.pendingData = null
      this.debounceTimer = null
    } catch (err) {
      console.error('[SaveService] flush failed:', err)
    }
  }
}
