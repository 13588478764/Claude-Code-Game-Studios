/**
 * Item store (S4-4) — bridges ItemSystem to Vue.
 *
 * Module-level wiring:
 *   - ItemSystem deps wired with: items catalog lookup, resource money read,
 *     resource applyEffects, run-store currentJob.
 *   - runManager.onJobSelected → itemSystem.reset (fresh inventory each run)
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { ItemSystem } from '@/services/item/item-system'
import { getItemById } from '@/config/items'
import { resourceManager } from './resource-store'
import { runManager } from './run-store'
import type { InventoryEntry } from '@/types/item'

const itemSystem = new ItemSystem({
  getItemById,
  getMoney: () => resourceManager.getResources().money,
  applyEffects: (effects) => resourceManager.applyEffects(effects),
  getCurrentJobId: () => runManager.getCurrentJob()
})

// Reset inventory at run boundary
runManager.onJobSelected.on(() => {
  itemSystem.reset()
})

export const useItemStore = defineStore('item', () => {
  const inventory = ref<InventoryEntry[]>([])
  const lastRefusal = ref<{
    itemId: string
    reason: 'unknown-item' | 'insufficient-funds' | 'wrong-job' | 'not-in-inventory'
  } | null>(null)

  function refreshInventory(): void {
    inventory.value = itemSystem.getInventory()
  }

  itemSystem.onItemPurchased.on(() => {
    refreshInventory()
    lastRefusal.value = null
  })
  itemSystem.onItemUsed.on(() => {
    refreshInventory()
  })
  itemSystem.onItemRefused.on((event) => {
    lastRefusal.value = { itemId: event.itemId, reason: event.reason }
  })

  // Reset reactive state at job-selected too
  runManager.onJobSelected.on(() => {
    refreshInventory()
    lastRefusal.value = null
  })

  function buy(itemId: string): boolean {
    return itemSystem.buyItem(itemId)
  }
  function use(itemId: string): boolean {
    return itemSystem.useItem(itemId)
  }

  return {
    inventory,
    lastRefusal,
    buy,
    use
  }
})

export { itemSystem }
