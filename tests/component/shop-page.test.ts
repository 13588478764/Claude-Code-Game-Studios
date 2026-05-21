/**
 * S4-5 ShopPage component tests — tab switching, affordability gating,
 * buy / back routing. Uses real Pinia stores (catalog from items.json).
 */

import { describe, test, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import ShopPage from '@/subpackages/ui/shop/index.vue'
import { useResourceStore } from '@/stores/resource-store'
import { useItemStore, itemSystem } from '@/stores/item-store'
import { ITEMS } from '@/config/items'

let navigateBackSpy: ReturnType<typeof vi.fn>
let showToastSpy: ReturnType<typeof vi.fn>

beforeEach(() => {
  setActivePinia(createPinia())
  // The itemSystem service is a module singleton (created once on import) —
  // explicit reset isolates each test from prior inventory accumulation.
  itemSystem.reset()
  navigateBackSpy = vi.fn()
  showToastSpy = vi.fn()
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  ;(globalThis as any).uni = {
    navigateBack: navigateBackSpy,
    showToast: showToastSpy,
    navigateTo: vi.fn(),
    reLaunch: vi.fn()
  }
})

describe('ShopPage — rendering (AC-1/2)', () => {
  test('renders header + balance from resourceStore', async () => {
    const res = useResourceStore()
    res.init({ energy: 80, mood: 60, money: 250 })
    const wrapper = mount(ShopPage)
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.title').text()).toContain('商店')
    expect(wrapper.find('.balance-value').text()).toBe('250 元')
  })

  test('renders 4 category tabs', async () => {
    const wrapper = mount(ShopPage)
    await wrapper.vm.$nextTick()
    const tabs = wrapper.findAll('.tab')
    expect(tabs).toHaveLength(4)
    expect(tabs.map((t) => t.text())).toEqual(['消耗品', '装备', '交通', '住所'])
  })

  test('default tab is 消耗品 (consumable)', async () => {
    const wrapper = mount(ShopPage)
    await wrapper.vm.$nextTick()
    const active = wrapper.find('.tab-active')
    expect(active.text()).toBe('消耗品')
  })
})

describe('ShopPage — item list (AC-3)', () => {
  test('shows universal consumables when no current job', async () => {
    const wrapper = mount(ShopPage)
    await wrapper.vm.$nextTick()
    const rows = wrapper.findAll('[data-item-id]')
    // 6 universal consumables in items.json
    const universalConsumables = ITEMS.filter(
      (i) => i.category === 'consumable' && i.jobId == null
    )
    expect(rows.length).toBe(universalConsumables.length)
  })

  test('empty category tab shows Sprint 5 上线 hint when no items', async () => {
    // After C-4 + C-1, equipment + housing have items; only transport
    // remains empty until Sprint 5 adds bikes/scooters.
    const wrapper = mount(ShopPage)
    await wrapper.vm.$nextTick()
    const tabs = wrapper.findAll('.tab')
    const transportTab = tabs.find((t) => t.text() === '交通')!
    await transportTab.trigger('click')
    expect(wrapper.find('.empty-hint').text()).toContain('Sprint 5')
  })

  test('equipment tab now has items (C-1 + C-4 catalog)', async () => {
    const wrapper = mount(ShopPage)
    await wrapper.vm.$nextTick()
    const tabs = wrapper.findAll('.tab')
    const equipmentTab = tabs.find((t) => t.text() === '装备')!
    await equipmentTab.trigger('click')
    const rows = wrapper.findAll('[data-item-id]')
    expect(rows.length).toBeGreaterThan(0)
  })
})

describe('ShopPage — affordability (AC-4)', () => {
  test('item with cost > money has unaffordable class + disabled buy', async () => {
    const res = useResourceStore()
    res.init({ energy: 80, mood: 60, money: 0 })  // broke
    const wrapper = mount(ShopPage)
    await wrapper.vm.$nextTick()
    const rows = wrapper.findAll('[data-item-id]')
    const expensive = rows.find((r) => parseInt(r.find('.item-cost').text()) > 0)
    expect(expensive).toBeDefined()
    expect(expensive!.classes()).toContain('unaffordable')
    const buyBtn = expensive!.find('.btn-buy')
    expect(buyBtn.attributes('disabled')).toBeDefined()
  })

  test('affordable items have no unaffordable class + enabled buy', async () => {
    const res = useResourceStore()
    res.init({ energy: 80, mood: 60, money: 10000 })
    const wrapper = mount(ShopPage)
    await wrapper.vm.$nextTick()
    const rows = wrapper.findAll('[data-item-id]')
    for (const r of rows) {
      expect(r.classes()).not.toContain('unaffordable')
    }
  })
})

describe('ShopPage — buy routing (AC-5)', () => {
  test('tap buy on affordable consumable → itemStore.buy + success toast', async () => {
    const res = useResourceStore()
    res.init({ energy: 80, mood: 60, money: 100 })
    const itemStore = useItemStore()
    const buySpy = vi.spyOn(itemStore, 'buy')

    const wrapper = mount(ShopPage)
    await wrapper.vm.$nextTick()
    const rows = wrapper.findAll('[data-item-id]')
    const redbull = rows.find((r) => r.attributes('data-item-id') === 'redbull')
    expect(redbull).toBeDefined()
    await redbull!.find('.btn-buy').trigger('click')

    expect(buySpy).toHaveBeenCalledWith('redbull')
    expect(showToastSpy).toHaveBeenCalled()
    expect(showToastSpy.mock.calls[0]![0].title).toContain('红牛')
  })

  test('buy success deducts money via real ItemSystem pipeline', async () => {
    const res = useResourceStore()
    res.init({ energy: 80, mood: 60, money: 100 })
    const wrapper = mount(ShopPage)
    await wrapper.vm.$nextTick()
    const rows = wrapper.findAll('[data-item-id]')
    const redbull = rows.find((r) => r.attributes('data-item-id') === 'redbull')!
    await redbull.find('.btn-buy').trigger('click')
    expect(res.resources.money).toBe(100 - 18)  // redbull cost 18
  })

  test('buying an item shows "已有 N" badge on subsequent renders', async () => {
    const res = useResourceStore()
    res.init({ energy: 80, mood: 60, money: 100 })
    const wrapper = mount(ShopPage)
    await wrapper.vm.$nextTick()
    const rows = wrapper.findAll('[data-item-id]')
    const redbull = rows.find((r) => r.attributes('data-item-id') === 'redbull')!
    await redbull.find('.btn-buy').trigger('click')
    await wrapper.vm.$nextTick()
    expect(redbull.text()).toContain('已有 1')
  })
})

describe('ShopPage — back button', () => {
  test('tap 返回 → uni.navigateBack({ delta: 1 })', async () => {
    const wrapper = mount(ShopPage)
    await wrapper.vm.$nextTick()
    await wrapper.find('.btn-back').trigger('click')
    expect(navigateBackSpy).toHaveBeenCalledWith({ delta: 1 })
  })
})
