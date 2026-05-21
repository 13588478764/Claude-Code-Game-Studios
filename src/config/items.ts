/**
 * Items catalog — loaded statically at module load time from items.json.
 * Sprint 4 ships 13 items (6 universal + 3 programmer + 2 intern + 2 sales).
 * Adding a new item = push entry to items.json, zero code change.
 */

import itemsData from './items.json'
import type { Item } from '@/types/item'

export const ITEMS: ReadonlyArray<Item> = itemsData as ReadonlyArray<Item>

const byId = new Map<string, Item>()
for (const item of ITEMS) {
  byId.set(item.id, item)
}

export function getItemById(id: string): Item | undefined {
  return byId.get(id)
}

/**
 * Items available to a given job — includes universal (no jobId) + job-specific.
 * Pass null to get only universal items.
 */
export function getItemsForJob(jobId: string | null): Item[] {
  if (jobId == null) {
    return ITEMS.filter((i) => i.jobId == null)
  }
  return ITEMS.filter((i) => i.jobId == null || i.jobId === jobId)
}

/** Filter helper for shop tabs. */
export function getItemsByCategory(
  jobId: string | null,
  category: Item['category']
): Item[] {
  return getItemsForJob(jobId).filter((i) => i.category === category)
}
