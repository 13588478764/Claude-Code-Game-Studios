/**
 * ItemSystem (S4-4) — per-run item purchase + use + inventory.
 *
 * Pure TS service. Owns inventory state for the active run; reset at
 * job-selected (run boundary). Catalog loaded from src/static/items.json via
 * dependency injection — the store wires the real catalog at module load.
 *
 * Consumables: useItem(id) deducts one count, applies item.effects to
 * resources via injected hook. Money cost of consumables is debited at
 * buyItem time, not at useItem time.
 *
 * Equipment / housing: buyItem persists the slot occupant (replacing prior
 * if any). Modifier pipeline integration is Sprint 5 (forward-compat slot
 * field already there).
 */

import { TypedEventEmitter } from '../common/event-emitter'
import type { Effect, ResourceTarget } from '@/types/resource'
import type { Item, InventoryEntry, ItemSlot } from '@/types/item'

/** Targets that equipment modifiers can scale (mirrors PassiveSkill). */
export type EquipmentModifierTarget = Extract<ResourceTarget, 'energy' | 'mood'>

/** signFloor — rounds toward zero (mirrors status / passive). */
function signFloor(value: number): number {
  if (value === 0) return 0
  const result = value > 0 ? Math.floor(value) : Math.ceil(value)
  return result === 0 ? 0 : result
}

export interface ItemPurchaseEvent {
  itemId: string
  cost: number
}

export interface ItemUseEvent {
  itemId: string
  effects: Effect[]
}

export interface ItemRefusedEvent {
  itemId: string
  reason: 'unknown-item' | 'insufficient-funds' | 'wrong-job' | 'not-in-inventory'
}

export interface ItemSystemDeps {
  /** Catalog lookup — typically getItemById from items config. */
  getItemById: (id: string) => Item | undefined
  /** Current player resources (for affordability check). */
  getMoney: () => number
  /** Apply effects to resources (money debit, consumable effect application). */
  applyEffects: (effects: Effect[]) => void
  /** Current job id (for jobId-locked item gating). null = no job active. */
  getCurrentJobId: () => string | null
}

export class ItemSystem {
  private inventory = new Map<string, number>()
  /** Equipped item id per slot. Sprint 5 will read this for modifier pipeline. */
  private equipped = new Map<ItemSlot, string>()

  readonly onItemPurchased = new TypedEventEmitter<ItemPurchaseEvent>()
  readonly onItemUsed = new TypedEventEmitter<ItemUseEvent>()
  readonly onItemRefused = new TypedEventEmitter<ItemRefusedEvent>()

  constructor(private deps: ItemSystemDeps) {}

  /**
   * Attempt to purchase an item. Returns true on success.
   * Failure modes (emit onItemRefused):
   *   - unknown-item: id not in catalog
   *   - insufficient-funds: money < cost
   *   - wrong-job: item.jobId set and != currentJobId
   */
  buyItem(itemId: string): boolean {
    const item = this.deps.getItemById(itemId)
    if (!item) {
      this.onItemRefused.emit({ itemId, reason: 'unknown-item' })
      return false
    }
    if (item.jobId != null && item.jobId !== this.deps.getCurrentJobId()) {
      this.onItemRefused.emit({ itemId, reason: 'wrong-job' })
      return false
    }
    if (this.deps.getMoney() < item.cost) {
      this.onItemRefused.emit({ itemId, reason: 'insufficient-funds' })
      return false
    }

    // Debit money
    if (item.cost > 0) {
      this.deps.applyEffects([{ target: 'money', value: -item.cost }])
    }

    // Route by category
    if (item.category === 'consumable') {
      this.addToInventory(itemId, 1)
    } else if (item.slot != null) {
      this.equipped.set(item.slot, itemId)
    } else {
      // No slot specified for non-consumable — treat as one-time inventory entry
      this.addToInventory(itemId, 1)
    }

    this.onItemPurchased.emit({ itemId, cost: item.cost })
    return true
  }

  /**
   * Use a consumable from inventory. Returns true on success.
   * Refusal: not-in-inventory or unknown-item.
   */
  useItem(itemId: string): boolean {
    const item = this.deps.getItemById(itemId)
    if (!item) {
      this.onItemRefused.emit({ itemId, reason: 'unknown-item' })
      return false
    }
    const count = this.inventory.get(itemId) ?? 0
    if (count <= 0) {
      this.onItemRefused.emit({ itemId, reason: 'not-in-inventory' })
      return false
    }
    // Decrement
    if (count === 1) {
      this.inventory.delete(itemId)
    } else {
      this.inventory.set(itemId, count - 1)
    }
    // Apply effects (consumables only — non-consumable useItem is a no-op apart from inventory tick)
    const effects = item.effects ?? []
    if (effects.length > 0) {
      this.deps.applyEffects(effects)
    }
    this.onItemUsed.emit({ itemId, effects })
    return true
  }

  /** Reset all state — called at run boundary (RunManager.onJobSelected). */
  reset(): void {
    this.inventory.clear()
    this.equipped.clear()
  }

  // ============== Inventory query ==============

  getInventory(): InventoryEntry[] {
    return Array.from(this.inventory.entries()).map(([itemId, count]) => ({
      itemId,
      count
    }))
  }

  getInventoryCount(itemId: string): number {
    return this.inventory.get(itemId) ?? 0
  }

  hasItem(itemId: string): boolean {
    return (this.inventory.get(itemId) ?? 0) > 0
  }

  getEquipped(slot: ItemSlot): string | null {
    return this.equipped.get(slot) ?? null
  }

  getAllEquipped(): Array<{ slot: ItemSlot; itemId: string }> {
    return Array.from(this.equipped.entries()).map(([slot, itemId]) => ({
      slot,
      itemId
    }))
  }

  /**
   * C-1: equipment modifier pipeline hook. Accumulates multiplicatively across
   * ALL equipped items that declare item.modifiers[`${target}Mul`].
   * Pipeline position (per ChoiceResolutionEngine): raw → passive → equipment → status → resource.
   * Identity when no equipped item modifies the target.
   */
  applyToEffect(target: EquipmentModifierTarget, rawValue: number): number {
    const mul = this.getEquipmentMul(target)
    if (mul === 1.0) return rawValue
    return signFloor(rawValue * mul)
  }

  private getEquipmentMul(target: EquipmentModifierTarget): number {
    const field: 'energyMul' | 'moodMul' =
      target === 'energy' ? 'energyMul' : 'moodMul'
    let product = 1.0
    for (const itemId of this.equipped.values()) {
      const item = this.deps.getItemById(itemId)
      if (!item) continue
      const mul = item.modifiers?.[field]
      if (mul != null) product *= mul
    }
    return product
  }

  /**
   * Restore from save (G-1 resume). Caller must validate that itemIds still
   * exist in catalog — silently drops unknowns.
   */
  loadInventory(entries: InventoryEntry[]): void {
    this.inventory.clear()
    for (const e of entries) {
      if (!this.deps.getItemById(e.itemId)) continue
      if (e.count > 0) this.inventory.set(e.itemId, e.count)
    }
  }

  /**
   * G-1: restore equipped slots from save snapshot. Unknown ids silently
   * dropped; same-slot collisions overwrite (last entry wins).
   */
  loadEquipped(entries: Array<{ slot: ItemSlot; itemId: string }>): void {
    this.equipped.clear()
    for (const e of entries) {
      if (!this.deps.getItemById(e.itemId)) continue
      this.equipped.set(e.slot, e.itemId)
    }
  }

  private addToInventory(itemId: string, count: number): void {
    this.inventory.set(itemId, (this.inventory.get(itemId) ?? 0) + count)
  }
}
