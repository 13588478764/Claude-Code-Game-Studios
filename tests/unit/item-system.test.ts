/**
 * S4-4 ItemSystem unit tests — buy/use/refusal/inventory/reset/loadInventory.
 * Target 100% coverage on src/services/item/item-system.ts.
 */

import { describe, test, expect, vi, beforeEach } from 'vitest'
import { ItemSystem, type ItemSystemDeps } from '@/services/item/item-system'
import type { Item } from '@/types/item'
import type { Effect } from '@/types/resource'

// ============== Test catalog ==============

const itemCatalog: Record<string, Item> = {
  'redbull': {
    id: 'redbull',
    name: '红牛',
    icon: '🥤',
    description: '提神',
    category: 'consumable',
    cost: 18,
    effects: [{ target: 'energy', value: 25 }]
  },
  'free-coffee': {
    id: 'free-coffee',
    name: '免费咖啡',
    icon: '☕',
    description: '蹭',
    category: 'consumable',
    cost: 0,
    effects: [{ target: 'energy', value: 10 }]
  },
  'no-effect': {
    id: 'no-effect',
    name: '空效果道具',
    icon: '❓',
    description: '什么也没',
    category: 'consumable',
    cost: 5
    // no effects field
  },
  'programmer-only': {
    id: 'programmer-only',
    name: '程序员专属',
    icon: '💻',
    description: '仅程序员',
    category: 'consumable',
    cost: 30,
    jobId: 'programmer',
    effects: [{ target: 'mood', value: 15 }]
  },
  'bike': {
    id: 'bike',
    name: '自行车',
    icon: '🚲',
    description: '通勤',
    category: 'transport',
    cost: 200,
    slot: 'transport',
    modifiers: { energyMul: 0.9 }
  },
  'mystery-item': {
    id: 'mystery-item',
    name: '迷之道具',
    icon: '🎁',
    description: '无 slot 的非消耗品',
    category: 'equipment',
    cost: 50
    // no slot field — falls through to inventory
  },
  'chair': {
    id: 'chair',
    name: '人体工学椅',
    icon: '💺',
    description: 'energy mul',
    category: 'equipment',
    cost: 200,
    slot: 'tool',
    modifiers: { energyMul: 0.85 }
  },
  'headphones': {
    id: 'headphones',
    name: '降噪耳机',
    icon: '🎧',
    description: 'mood mul',
    category: 'equipment',
    cost: 150,
    slot: 'wearable',
    modifiers: { moodMul: 0.85 }
  },
  'apartment': {
    id: 'apartment',
    name: '高档公寓',
    icon: '🏙️',
    description: 'both muls',
    category: 'housing',
    cost: 500,
    slot: 'housing',
    modifiers: { energyMul: 0.9, moodMul: 0.9 }
  }
}

// ============== Mock deps factory ==============

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyMock = ReturnType<typeof vi.fn<any[], any>>

function makeDeps(overrides: {
  money?: number
  currentJobId?: string | null
} = {}): {
  deps: ItemSystemDeps
  applyEffectsSpy: AnyMock
  getMoneySpy: AnyMock
  setMoney: (v: number) => void
} {
  let currentMoney = overrides.money ?? 100
  // Use `in` check so caller can explicitly pass null and have it stick
  const jobIdResolved = 'currentJobId' in overrides ? overrides.currentJobId! : 'programmer'
  const getMoneySpy = vi.fn(() => currentMoney)
  const applyEffectsSpy = vi.fn((effects: Effect[]) => {
    for (const fx of effects) {
      if (fx.target === 'money') currentMoney += fx.value
    }
  })
  return {
    deps: {
      getItemById: (id) => itemCatalog[id],
      getMoney: getMoneySpy,
      applyEffects: applyEffectsSpy,
      getCurrentJobId: () => jobIdResolved
    },
    applyEffectsSpy,
    getMoneySpy,
    setMoney: (v) => { currentMoney = v }
  }
}

let bag: ReturnType<typeof makeDeps>

beforeEach(() => {
  bag = makeDeps()
})

// ============== buyItem ==============

describe('ItemSystem — buyItem (consumable)', () => {
  test('successful purchase debits money + adds to inventory + emits onItemPurchased', () => {
    const sys = new ItemSystem(bag.deps)
    const fn = vi.fn()
    sys.onItemPurchased.on(fn)

    const ok = sys.buyItem('redbull')
    expect(ok).toBe(true)
    expect(bag.applyEffectsSpy).toHaveBeenCalledWith([{ target: 'money', value: -18 }])
    expect(sys.getInventoryCount('redbull')).toBe(1)
    expect(fn).toHaveBeenCalledWith({ itemId: 'redbull', cost: 18 })
  })

  test('free item (cost=0) skips money debit but still adds to inventory', () => {
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('free-coffee')
    expect(bag.applyEffectsSpy).not.toHaveBeenCalled()
    expect(sys.getInventoryCount('free-coffee')).toBe(1)
  })

  test('multiple purchases stack count', () => {
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('redbull')
    sys.buyItem('redbull')
    sys.buyItem('redbull')
    expect(sys.getInventoryCount('redbull')).toBe(3)
  })

  test('refused on unknown id + emits onItemRefused unknown-item', () => {
    const sys = new ItemSystem(bag.deps)
    const fn = vi.fn()
    sys.onItemRefused.on(fn)

    const ok = sys.buyItem('does-not-exist')
    expect(ok).toBe(false)
    expect(fn).toHaveBeenCalledWith({ itemId: 'does-not-exist', reason: 'unknown-item' })
    expect(bag.applyEffectsSpy).not.toHaveBeenCalled()
  })

  test('refused on insufficient funds', () => {
    bag = makeDeps({ money: 10 })  // < redbull cost 18
    const sys = new ItemSystem(bag.deps)
    const fn = vi.fn()
    sys.onItemRefused.on(fn)

    const ok = sys.buyItem('redbull')
    expect(ok).toBe(false)
    expect(fn).toHaveBeenCalledWith({ itemId: 'redbull', reason: 'insufficient-funds' })
    expect(sys.getInventoryCount('redbull')).toBe(0)
  })

  test('refused on wrong-job for job-locked item', () => {
    bag = makeDeps({ currentJobId: 'intern' })
    const sys = new ItemSystem(bag.deps)
    const fn = vi.fn()
    sys.onItemRefused.on(fn)

    const ok = sys.buyItem('programmer-only')
    expect(ok).toBe(false)
    expect(fn).toHaveBeenCalledWith({ itemId: 'programmer-only', reason: 'wrong-job' })
  })

  test('job-locked item buyable when currentJobId matches', () => {
    bag = makeDeps({ currentJobId: 'programmer' })
    const sys = new ItemSystem(bag.deps)
    const ok = sys.buyItem('programmer-only')
    expect(ok).toBe(true)
  })

  test('job-locked check happens before insufficient-funds check', () => {
    bag = makeDeps({ money: 5, currentJobId: 'intern' })
    const sys = new ItemSystem(bag.deps)
    const fn = vi.fn()
    sys.onItemRefused.on(fn)
    sys.buyItem('programmer-only')
    expect(fn).toHaveBeenCalledWith({ itemId: 'programmer-only', reason: 'wrong-job' })
  })

  test('null currentJobId blocks job-locked items', () => {
    bag = makeDeps({ currentJobId: null })
    const sys = new ItemSystem(bag.deps)
    const fn = vi.fn()
    sys.onItemRefused.on(fn)
    sys.buyItem('programmer-only')
    expect(fn).toHaveBeenCalledWith({ itemId: 'programmer-only', reason: 'wrong-job' })
  })
})

describe('ItemSystem — buyItem (equipment/slot)', () => {
  test('slot item goes to equipped not inventory', () => {
    bag = makeDeps({ money: 500 })
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('bike')
    expect(sys.getInventoryCount('bike')).toBe(0)
    expect(sys.getEquipped('transport')).toBe('bike')
  })

  test('slot item replaces prior occupant', () => {
    bag = makeDeps({ money: 500 })
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('bike')
    // Add another transport item (synthesized)
    itemCatalog['scooter'] = {
      id: 'scooter', name: '电动车', icon: '🛵', description: 'x',
      category: 'transport', cost: 100, slot: 'transport'
    }
    sys.buyItem('scooter')
    expect(sys.getEquipped('transport')).toBe('scooter')
    delete itemCatalog['scooter']
  })

  test('getAllEquipped returns all slot occupants', () => {
    bag = makeDeps({ money: 500 })
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('bike')
    const all = sys.getAllEquipped()
    expect(all).toEqual([{ slot: 'transport', itemId: 'bike' }])
  })

  test('non-consumable WITHOUT slot falls to inventory', () => {
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('mystery-item')
    expect(sys.getInventoryCount('mystery-item')).toBe(1)
    expect(sys.getEquipped('tool')).toBeNull()
  })
})

// ============== useItem ==============

describe('ItemSystem — useItem', () => {
  test('uses consumable, applies effects, decrements count', () => {
    const sys = new ItemSystem(bag.deps)
    const fn = vi.fn()
    sys.onItemUsed.on(fn)

    sys.buyItem('redbull')
    sys.buyItem('redbull')
    bag.applyEffectsSpy.mockClear()

    const ok = sys.useItem('redbull')
    expect(ok).toBe(true)
    expect(bag.applyEffectsSpy).toHaveBeenCalledWith([{ target: 'energy', value: 25 }])
    expect(sys.getInventoryCount('redbull')).toBe(1)
    expect(fn).toHaveBeenCalledWith({
      itemId: 'redbull',
      effects: [{ target: 'energy', value: 25 }]
    })
  })

  test('last unit consumed removes entry from inventory', () => {
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('redbull')
    sys.useItem('redbull')
    expect(sys.hasItem('redbull')).toBe(false)
    expect(sys.getInventory()).toEqual([])
  })

  test('refused not-in-inventory if never purchased', () => {
    const sys = new ItemSystem(bag.deps)
    const fn = vi.fn()
    sys.onItemRefused.on(fn)
    const ok = sys.useItem('redbull')
    expect(ok).toBe(false)
    expect(fn).toHaveBeenCalledWith({ itemId: 'redbull', reason: 'not-in-inventory' })
  })

  test('refused unknown-item', () => {
    const sys = new ItemSystem(bag.deps)
    const fn = vi.fn()
    sys.onItemRefused.on(fn)
    const ok = sys.useItem('does-not-exist')
    expect(ok).toBe(false)
    expect(fn).toHaveBeenCalledWith({ itemId: 'does-not-exist', reason: 'unknown-item' })
  })

  test('item with no effects array uses without applyEffects', () => {
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('no-effect')
    bag.applyEffectsSpy.mockClear()
    const ok = sys.useItem('no-effect')
    expect(ok).toBe(true)
    expect(bag.applyEffectsSpy).not.toHaveBeenCalled()
    expect(sys.getInventoryCount('no-effect')).toBe(0)
  })
})

// ============== reset + load ==============

describe('ItemSystem — getInventory shape', () => {
  test('returns array of {itemId, count} entries', () => {
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('redbull')
    sys.buyItem('redbull')
    sys.buyItem('free-coffee')
    const inv = sys.getInventory()
    expect(inv).toHaveLength(2)
    const redbull = inv.find((e) => e.itemId === 'redbull')
    const coffee = inv.find((e) => e.itemId === 'free-coffee')
    expect(redbull).toEqual({ itemId: 'redbull', count: 2 })
    expect(coffee).toEqual({ itemId: 'free-coffee', count: 1 })
  })
})

describe('ItemSystem — reset', () => {
  test('clears inventory + equipped', () => {
    bag = makeDeps({ money: 500 })
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('redbull')
    sys.buyItem('bike')
    sys.reset()
    expect(sys.getInventory()).toEqual([])
    expect(sys.getAllEquipped()).toEqual([])
  })
})

describe('ItemSystem — applyToEffect (C-1 equipment pipeline)', () => {
  test('no equipped items → identity passthrough', () => {
    const sys = new ItemSystem(bag.deps)
    expect(sys.applyToEffect('energy', -20)).toBe(-20)
    expect(sys.applyToEffect('mood', 10)).toBe(10)
  })

  test('equipped energyMul 0.85 reduces energy effect (loss less harsh)', () => {
    bag = makeDeps({ money: 500 })
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('chair')  // 0.85 energyMul
    // -20 × 0.85 = -17
    expect(sys.applyToEffect('energy', -20)).toBe(-17)
    // mood not affected (no moodMul on chair)
    expect(sys.applyToEffect('mood', -20)).toBe(-20)
  })

  test('multiple equipped items stack multiplicatively across slots', () => {
    bag = makeDeps({ money: 1000 })
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('chair')        // energyMul 0.85 (slot=tool)
    sys.buyItem('apartment')    // energyMul 0.9 + moodMul 0.9 (slot=housing)
    // energy: -20 × 0.85 × 0.9 = -15.3 → signFloor toward 0 = -15
    expect(sys.applyToEffect('energy', -20)).toBe(-15)
    // mood: -20 × 0.9 = -18 (only apartment touches mood)
    expect(sys.applyToEffect('mood', -20)).toBe(-18)
  })

  test('equipment modifier applies to positive values too', () => {
    bag = makeDeps({ money: 500 })
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('headphones')  // moodMul 0.85
    // +10 × 0.85 = +8.5 → signFloor = +8
    expect(sys.applyToEffect('mood', 10)).toBe(8)
  })

  test('signFloor rounds toward zero on both sides', () => {
    bag = makeDeps({ money: 500 })
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('chair')  // 0.85
    // -7 × 0.85 = -5.95 → ceil to -5
    expect(sys.applyToEffect('energy', -7)).toBe(-5)
    // 7 × 0.85 = 5.95 → floor to 5
    expect(sys.applyToEffect('energy', 7)).toBe(5)
  })

  test('signFloor coerces small results to canonical 0', () => {
    bag = makeDeps({ money: 500 })
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('chair')
    // 1 × 0.85 = 0.85 → floor = 0
    expect(Object.is(sys.applyToEffect('energy', 1), 0)).toBe(true)
    // -1 × 0.85 = -0.85 → ceil = -0 → coerced to canonical 0
    expect(Object.is(sys.applyToEffect('energy', -1), 0)).toBe(true)
  })

  test('zero input stays zero regardless of equipped items', () => {
    bag = makeDeps({ money: 500 })
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('chair')
    expect(sys.applyToEffect('energy', 0)).toBe(0)
  })

  test('equipped item with no modifiers field is ignored', () => {
    bag = makeDeps({ money: 500 })
    const sys = new ItemSystem(bag.deps)
    // Inject a no-modifiers slot item for this test
    itemCatalog['plain-tool'] = {
      id: 'plain-tool',
      name: '普通工具',
      icon: '🔧',
      description: 'no modifiers',
      category: 'equipment',
      cost: 50,
      slot: 'tool'
      // no modifiers field
    }
    sys.buyItem('plain-tool')
    expect(sys.applyToEffect('energy', -20)).toBe(-20)
    delete itemCatalog['plain-tool']
  })

  test('equipped item removed from catalog mid-run is skipped (defensive)', () => {
    bag = makeDeps({ money: 500 })
    const sys = new ItemSystem(bag.deps)
    itemCatalog['transient'] = {
      id: 'transient',
      name: '临时',
      icon: '⚠️',
      description: 'will vanish',
      category: 'equipment',
      cost: 100,
      slot: 'tool',
      modifiers: { energyMul: 0.5 }
    }
    sys.buyItem('transient')
    // Verify it's working first
    expect(sys.applyToEffect('energy', -20)).toBe(-10)
    // Now mutate catalog out from under it
    delete itemCatalog['transient']
    // getEquipmentMul iterates equipped Map → catalog lookup returns undefined → skip
    expect(sys.applyToEffect('energy', -20)).toBe(-20)
  })

  test('reset clears equipment modifier state', () => {
    bag = makeDeps({ money: 500 })
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('chair')
    sys.reset()
    expect(sys.applyToEffect('energy', -20)).toBe(-20)
  })
})

describe('ItemSystem — loadInventory (save resume)', () => {
  test('restores entries from snapshot', () => {
    const sys = new ItemSystem(bag.deps)
    sys.loadInventory([
      { itemId: 'redbull', count: 3 },
      { itemId: 'free-coffee', count: 1 }
    ])
    expect(sys.getInventoryCount('redbull')).toBe(3)
    expect(sys.getInventoryCount('free-coffee')).toBe(1)
  })

  test('silently drops unknown ids', () => {
    const sys = new ItemSystem(bag.deps)
    sys.loadInventory([
      { itemId: 'redbull', count: 1 },
      { itemId: 'ghost-item', count: 5 }
    ])
    expect(sys.getInventoryCount('redbull')).toBe(1)
    expect(sys.getInventoryCount('ghost-item')).toBe(0)
  })

  test('skips entries with count <= 0', () => {
    const sys = new ItemSystem(bag.deps)
    sys.loadInventory([{ itemId: 'redbull', count: 0 }])
    expect(sys.getInventoryCount('redbull')).toBe(0)
  })

  test('clears prior inventory before loading', () => {
    const sys = new ItemSystem(bag.deps)
    sys.buyItem('redbull')
    sys.loadInventory([{ itemId: 'free-coffee', count: 2 }])
    expect(sys.hasItem('redbull')).toBe(false)
    expect(sys.getInventoryCount('free-coffee')).toBe(2)
  })
})
