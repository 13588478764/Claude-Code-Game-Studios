/**
 * Save data types — schema versioned for future migrations.
 */

import type { Resources } from './resource'
import type { CareerState } from './career'
import type { StatusEffect } from './status'
import type { InventoryEntry, ItemSlot } from './item'

export const SAVE_SCHEMA_VERSION = 1
export const SAVE_KEY = 'wlb:save:v1'

/**
 * RunSnapshot — checkpoint of an in-progress run, saved at each day boundary.
 * On resume, the player loses any mid-day progress but doesn't restart the
 * career. All sub-system snapshots are optional for back-compat with v1 saves
 * that pre-date G-1.
 */
export interface RunSnapshot {
  jobId: string
  /** Week index 1..weeksPerCareer (G-1 added; falls back to 1 if missing) */
  weekIndex?: number
  /** Day-of-week 1..5. After resume the next day starts here. */
  day: number
  doneInDay: number
  resources: Resources
  totalChoices: number
  /** G-1: unique event ids resolved this run (for rating + recent buffer). */
  uniqueEventIds?: string[]
  /** G-1: which resource depleted (for ending resolution if it ends here). */
  depletionSource?: 'energy' | 'mood' | 'health' | null
  startedAt: number
  /** S4-2: in-progress career level + score. */
  career?: CareerState
  /** G-1: active buff/debuff snapshots. */
  statuses?: StatusEffect[]
  /** G-1: per-run inventory (consumables remaining). */
  inventory?: InventoryEntry[]
  /** G-1: equipped items per slot. */
  equipped?: Array<{ slot: ItemSlot; itemId: string }>
}

export interface GlobalStats {
  totalRuns: number
  totalWins: number
  totalDeaths: number
  totalMoneyEarned: number
  jobsPlayed: Record<string, number>  // jobId → run count
  achievements: string[]
  /** G-3: unlocked ending ids; optional for back-compat with v1 saves. */
  endings?: string[]
}

export interface SaveData {
  version: number
  jobUnlocks: string[]
  currentRun: RunSnapshot | null
  stats: GlobalStats
  /**
   * Permanent UI flags that persist across runs (NOT cleared with currentRun).
   * Schema v1 backward compatible — new saves omit firstStatusShown by default;
   * old saves loaded into the same shape with the field undefined.
   */
  firstStatusShown?: boolean
  /** H-1: first time health drops below 80 → show health tutorial tip once. */
  firstHealthDropShown?: boolean
  /**
   * Permanently-unlocked passive skill IDs (S3-9). Optional for backward
   * compat — old saves load with undefined, treated as empty array.
   */
  passiveSkills?: string[]
  updatedAt: number
}

export const EMPTY_SAVE: SaveData = {
  version: SAVE_SCHEMA_VERSION,
  jobUnlocks: ['intern', 'programmer'],
  currentRun: null,
  stats: {
    totalRuns: 0,
    totalWins: 0,
    totalDeaths: 0,
    totalMoneyEarned: 0,
    jobsPlayed: {},
    achievements: []
  },
  updatedAt: 0
}
