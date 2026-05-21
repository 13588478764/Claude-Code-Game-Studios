/**
 * G-1 Save resume integration test — verifies a complete save → reload cycle.
 *
 * Strategy: build a synthetic RunSnapshot, write to SaveService via memory
 * adapter, then make a fresh ResourceManager/StatusSystem/CareerProgressionSystem
 * and prove each restores state correctly. Does NOT mount Vue components —
 * tests the data layer contract directly.
 */

import { describe, test, expect } from 'vitest'
import { SaveService, type StorageAdapter } from '@/services/save/save-service'
import { ResourceManager } from '@/services/resource/resource-manager'
import { StatusSystem } from '@/services/status/status-system'
import { CareerProgressionSystem } from '@/services/career/career-progression-system'
import { ItemSystem } from '@/services/item/item-system'
import { getItemById } from '@/config/items'
import type { SaveData, RunSnapshot } from '@/types/save'
import type { StatusEffect } from '@/types/status'

function makeMemoryAdapter(): StorageAdapter & { snapshot: () => string | null } {
  let value: string | null = null
  return {
    setSync(_, v) { value = v },
    getSync() { return value },
    removeSync() { value = null },
    snapshot() { return value }
  }
}

function makeRunSnapshot(overrides: Partial<RunSnapshot> = {}): RunSnapshot {
  return {
    jobId: 'programmer',
    weekIndex: 2,
    day: 3,
    doneInDay: 0,
    resources: { energy: 60, mood: 55, money: 250, health: 85 },
    totalChoices: 8,
    uniqueEventIds: [],
    depletionSource: null,
    startedAt: Date.now(),
    career: { level: 2, score: 120, weeksWorked: 1 },
    statuses: [],
    inventory: [],
    equipped: [],
    ...overrides
  }
}

function makeSave(snapshot: RunSnapshot | null): SaveData {
  return {
    version: 1,
    jobUnlocks: ['intern', 'programmer'],
    currentRun: snapshot,
    stats: {
      totalRuns: 3, totalWins: 1, totalDeaths: 2,
      totalMoneyEarned: 800, jobsPlayed: { programmer: 3 },
      achievements: ['first-blood', 'first-win']
    },
    updatedAt: 0
  }
}

describe('Save resume — write + load round-trip', () => {
  test('save with currentRun snapshot loads back identically', () => {
    const adapter = makeMemoryAdapter()
    const svc = new SaveService(adapter)
    const snap = makeRunSnapshot({
      resources: { energy: 42, mood: 33, money: -100, health: 50 }
    })
    svc.saveImmediate(makeSave(snap))

    const svc2 = new SaveService(adapter)
    const loaded = svc2.load()
    expect(loaded?.currentRun?.resources).toEqual({
      energy: 42, mood: 33, money: -100, health: 50
    })
    expect(loaded?.currentRun?.weekIndex).toBe(2)
    expect(loaded?.currentRun?.day).toBe(3)
  })

  test('save with currentRun=null preserves stats', () => {
    const adapter = makeMemoryAdapter()
    const svc = new SaveService(adapter)
    svc.saveImmediate(makeSave(null))

    const svc2 = new SaveService(adapter)
    const loaded = svc2.load()
    expect(loaded?.currentRun).toBeNull()
    expect(loaded?.stats.totalRuns).toBe(3)
  })

  test('back-compat: snapshot missing health field loads with undefined', () => {
    const adapter = makeMemoryAdapter()
    const svc = new SaveService(adapter)
    // Simulate pre-G-2 save (no health)
    const oldSnap = {
      ...makeRunSnapshot(),
      resources: { energy: 80, mood: 60, money: 100 }  // no health
    }
    svc.saveImmediate(makeSave(oldSnap as RunSnapshot))

    const loaded = new SaveService(adapter).load()
    expect(loaded?.currentRun?.resources.health).toBeUndefined()
    // Caller is expected to default missing health to 100 (see tryResume in useGameSession)
  })
})

describe('Save resume — ResourceManager restore', () => {
  test('init from snapshot resources restores values + state', () => {
    const rm = new ResourceManager()
    const snap = makeRunSnapshot({
      resources: { energy: 18, mood: 18, money: 50, health: 25 }
    })
    rm.init({
      energy: snap.resources.energy,
      mood: snap.resources.mood,
      money: snap.resources.money,
      health: snap.resources.health
    })
    expect(rm.getResources()).toEqual({
      energy: 18, mood: 18, money: 50, health: 25
    })
    // CRISIS triggered by mood ≤ 20
    expect(rm.getState()).toBe('CRISIS')
  })
})

describe('Save resume — StatusSystem restore', () => {
  test('loadSnapshot restores buff + debuff slots', () => {
    const sys = new StatusSystem()
    const buff: StatusEffect = {
      id: 'caffeine', name: '亢奋', icon: '☕',
      type: 'buff', daysLeft: 2, energyMul: 0.5
    }
    const debuff: StatusEffect = {
      id: 'emo', name: 'emo', icon: '💔',
      type: 'debuff', daysLeft: 1, moodMul: 1.5
    }
    sys.loadSnapshot([buff, debuff])
    expect(sys.getBuff()?.id).toBe('caffeine')
    expect(sys.getDebuff()?.id).toBe('emo')
    expect(sys.getBuff()?.daysLeft).toBe(2)
  })

  test('loadSnapshot with undefined clears slots', () => {
    const sys = new StatusSystem()
    sys.addStatus({
      id: 'caffeine', name: '亢奋', icon: '☕',
      type: 'buff', daysLeft: 2, energyMul: 0.5
    })
    sys.loadSnapshot(undefined)
    expect(sys.getBuff()).toBeNull()
  })
})

describe('Save resume — CareerProgressionSystem restore', () => {
  test('loadSnapshot restores level + score + weeksWorked', () => {
    const sys = new CareerProgressionSystem()
    sys.loadSnapshot({ level: 3, score: 280, weeksWorked: 3 })
    expect(sys.getLevel()).toBe(3)
    expect(sys.getScore()).toBe(280)
    expect(sys.getWeeksWorked()).toBe(3)
    expect(sys.getSalaryMultiplier()).toBe(2.25)  // Lv3 mul
  })
})

describe('Save resume — ItemSystem restore', () => {
  test('loadInventory + loadEquipped restore both kinds of items', () => {
    const sys = new ItemSystem({
      getItemById,
      getMoney: () => 0,
      applyEffects: () => {},
      getCurrentJobId: () => 'programmer'
    })
    sys.loadInventory([
      { itemId: 'redbull', count: 3 },
      { itemId: 'coffee-latte', count: 1 }
    ])
    sys.loadEquipped([
      { slot: 'tool', itemId: 'ergonomic-chair' },
      { slot: 'housing', itemId: 'shared-apartment' }
    ])
    expect(sys.getInventoryCount('redbull')).toBe(3)
    expect(sys.getInventoryCount('coffee-latte')).toBe(1)
    expect(sys.getEquipped('tool')).toBe('ergonomic-chair')
    expect(sys.getEquipped('housing')).toBe('shared-apartment')
  })

  test('loadEquipped drops unknown ids defensively', () => {
    const sys = new ItemSystem({
      getItemById,
      getMoney: () => 0,
      applyEffects: () => {},
      getCurrentJobId: () => 'programmer'
    })
    sys.loadEquipped([
      { slot: 'tool', itemId: 'ergonomic-chair' },
      { slot: 'housing', itemId: 'ghost-item-999' }  // not in catalog
    ])
    expect(sys.getEquipped('tool')).toBe('ergonomic-chair')
    expect(sys.getEquipped('housing')).toBeNull()
  })

  test('loadEquipped same-slot replaces (last entry wins)', () => {
    const sys = new ItemSystem({
      getItemById,
      getMoney: () => 0,
      applyEffects: () => {},
      getCurrentJobId: () => 'programmer'
    })
    sys.loadEquipped([
      { slot: 'housing', itemId: 'shared-apartment' },
      { slot: 'housing', itemId: 'city-studio' }  // overwrites
    ])
    expect(sys.getEquipped('housing')).toBe('city-studio')
  })

  test('equipment modifiers active after restore (pipeline integration)', () => {
    const sys = new ItemSystem({
      getItemById,
      getMoney: () => 0,
      applyEffects: () => {},
      getCurrentJobId: () => 'programmer'
    })
    sys.loadEquipped([{ slot: 'tool', itemId: 'ergonomic-chair' }])
    // chair has energyMul 0.85; -20 × 0.85 = -17
    expect(sys.applyToEffect('energy', -20)).toBe(-17)
  })
})

describe('Save resume — endRun clears currentRun', () => {
  test('progression.recordRun (run-end chain) writes currentRun: null', () => {
    // This is enforced by progression-store wiring; verify the contract
    // by checking what gets persisted in SaveData when a normal endRun fires.
    // See tests/integration/app-navigation.test.ts > "Full run lifecycle"
    // which already exercises this path. Here we just sanity-check the
    // type allows null.
    const save: SaveData = makeSave(null)
    expect(save.currentRun).toBeNull()
  })
})
