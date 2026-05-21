/**
 * Item types (S4-4).
 *
 * Data-driven catalog stored in src/static/items.json. Three categories so
 * far — consumable (used once, immediate effect), equipment (permanent
 * modifier per-run, slot-based, S5+), housing (permanent modifier + daily
 * upkeep, S5+). Sprint 4 ships consumables only; equipment / housing slot
 * fields exist for forward-compat but aren't yet active in modifier pipeline.
 */

import type { Effect, ResourceTarget } from './resource'

export type ItemCategory = 'consumable' | 'equipment' | 'housing' | 'transport'

/** Slot for permanent equipment/housing — one item per slot at a time. */
export type ItemSlot = 'tool' | 'housing' | 'transport' | 'wearable'

export interface ItemModifiers {
  energyMul?: number  // multiplier on energy effects
  moodMul?: number    // multiplier on mood effects
}

export interface Item {
  id: string
  name: string
  icon: string
  description: string
  category: ItemCategory
  cost: number
  /** Immediate effects on use (consumable). Empty/omitted for equipment. */
  effects?: Effect[]
  /** Permanent modifiers while equipped (equipment/housing). */
  modifiers?: ItemModifiers
  /** Slot the item occupies (equipment/housing only). */
  slot?: ItemSlot
  /** Recurring cost per day end (housing rent). 0 or omitted = none. */
  dailyUpkeep?: number
  /** If set, only this jobId may purchase the item. Omit for universal. */
  jobId?: string
  /** Optional in-game tag for filtering/display (e.g. 'coffee'). */
  tag?: string
}

/** Convenience: which targets a modifier-bearing item affects. */
export const MODIFIER_TARGETS: ReadonlyArray<ResourceTarget> = ['energy', 'mood'] as const

/** One row in the player's inventory — consumables stack via count. */
export interface InventoryEntry {
  itemId: string
  count: number
}
