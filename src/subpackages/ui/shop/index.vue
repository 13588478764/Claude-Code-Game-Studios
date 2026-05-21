<script setup lang="ts">
/**
 * ShopPage (S4-5) — in-run item store. Reached from game-main via 🛒 button.
 *
 * Lists items filtered by current job (universal + job-specific). Tabs by
 * category (Sprint 4 ships consumable only — other tabs render empty hint).
 *
 * Affordability is reactive — items with cost > current money are dimmed
 * with "钱不够" hint. Purchase via itemStore.buy; refusal reasons surface
 * via uni.showToast.
 */
import { computed, ref } from 'vue'
import { onUnload } from '@dcloudio/uni-app'
import { storeToRefs } from 'pinia'
import { useResourceStore } from '@/stores/resource-store'
import { useItemStore } from '@/stores/item-store'
import { useRunStore } from '@/stores/run-store'
import { useSaveStore } from '@/stores/save-store'
import { getItemsForJob } from '@/config/items'
import { formatMoney } from '@/utils/format'
import type { Item, ItemCategory } from '@/types/item'

const resourceStore = useResourceStore()
const itemStore = useItemStore()
const runStore = useRunStore()
const saveStore = useSaveStore()

const { resources } = storeToRefs(resourceStore)
const { inventory } = storeToRefs(itemStore)
const { currentJob } = storeToRefs(runStore)

onUnload(() => {
  saveStore.save()
})

type Tab = ItemCategory
const TABS: Array<{ id: Tab; label: string }> = [
  { id: 'consumable', label: '消耗品' },
  { id: 'equipment', label: '装备' },
  { id: 'transport', label: '交通' },
  { id: 'housing', label: '住所' }
]
const activeTab = ref<Tab>('consumable')

const availableItems = computed(() => getItemsForJob(currentJob.value))

/**
 * H-3: items for current tab, sorted by:
 *   1. affordable first (player can act on them)
 *   2. cost ascending (cheap to expensive within each affordability bucket)
 */
const itemsForTab = computed(() => {
  const filtered = availableItems.value.filter((i) => i.category === activeTab.value)
  return [...filtered].sort((a, b) => {
    const aAfford = resources.value.money >= a.cost ? 0 : 1
    const bAfford = resources.value.money >= b.cost ? 0 : 1
    if (aAfford !== bAfford) return aAfford - bAfford
    return a.cost - b.cost
  })
})

function inventoryCount(itemId: string): number {
  const entry = inventory.value.find((e) => e.itemId === itemId)
  return entry?.count ?? 0
}

function canAfford(item: Item): boolean {
  return resources.value.money >= item.cost
}

function effectSummary(item: Item): string {
  if (!item.effects || item.effects.length === 0) {
    if (item.modifiers) {
      const parts: string[] = []
      if (item.modifiers.energyMul != null) parts.push(`体力 ×${item.modifiers.energyMul}`)
      if (item.modifiers.moodMul != null) parts.push(`心情 ×${item.modifiers.moodMul}`)
      return parts.join(' / ')
    }
    return ''
  }
  return item.effects
    .map((fx) => {
      const sign = fx.value > 0 ? '+' : ''
      const label = fx.target === 'energy' ? '体力' : fx.target === 'mood' ? '心情' : '钱'
      return `${label} ${sign}${fx.value}`
    })
    .join(' / ')
}

function onBuy(item: Item): void {
  const ok = itemStore.buy(item.id)
  if (ok) {
    uni.showToast({
      title: `购入「${item.name}」`,
      icon: 'success',
      duration: 1000
    })
  } else {
    const reason = itemStore.lastRefusal?.reason
    const msg =
      reason === 'insufficient-funds' ? '钱不够'
      : reason === 'wrong-job' ? '当前职业不可购买'
      : reason === 'unknown-item' ? '道具不存在'
      : '购买失败'
    uni.showToast({ title: msg, icon: 'none', duration: 1200 })
  }
}

function onBack(): void {
  uni.navigateBack({ delta: 1 })
}

function tabHint(tab: string): string {
  if (tab === 'equipment') return '装备系统 Sprint 5 上线'
  if (tab === 'transport') return '交通工具 Sprint 5 上线'
  if (tab === 'housing') return '租房 / 买房 Sprint 5 上线'
  return ''
}
</script>

<template>
  <view class="page">
    <view class="header">
      <text class="title">🛒 商店</text>
      <view class="balance">
        <text class="balance-label">钱包</text>
        <text class="balance-value">{{ formatMoney(resources.money) }} 元</text>
      </view>
    </view>

    <view class="tabs">
      <view
        v-for="tab in TABS"
        :key="tab.id"
        class="tab"
        :class="{ 'tab-active': activeTab === tab.id }"
        :data-tab="tab.id"
        @click="activeTab = tab.id"
      >
        <text>{{ tab.label }}</text>
      </view>
    </view>

    <view class="items-list">
      <view v-if="itemsForTab.length === 0" class="empty-hint">
        <text v-if="activeTab === 'consumable'">这个职业暂无可用消耗品</text>
        <text v-else>{{ tabHint(activeTab) }}</text>
      </view>
      <view
        v-for="item in itemsForTab"
        :key="item.id"
        class="item-row"
        :class="{ unaffordable: !canAfford(item) }"
        :data-item-id="item.id"
      >
        <text class="item-icon">{{ item.icon }}</text>
        <view class="item-info">
          <view class="item-title-row">
            <text class="item-name">{{ item.name }}</text>
            <text v-if="inventoryCount(item.id) > 0" class="item-owned">
              已有 {{ inventoryCount(item.id) }}
            </text>
          </view>
          <text class="item-desc">{{ item.description }}</text>
          <text class="item-effect">{{ effectSummary(item) }}</text>
        </view>
        <view class="item-buy">
          <text class="item-cost">{{ formatMoney(item.cost) }} 元</text>
          <button
            class="btn-buy"
            :class="{ 'btn-buy-disabled': !canAfford(item) }"
            :disabled="!canAfford(item)"
            @click="onBuy(item)"
          >{{ canAfford(item) ? '买' : '钱不够' }}</button>
        </view>
      </view>
    </view>

    <button class="btn-back" @click="onBack">返回</button>
  </view>
</template>

<style scoped>
.page {
  min-height: 100vh;
  padding: 32rpx 24rpx 80rpx;
  display: flex;
  flex-direction: column;
  gap: 20rpx;
  background: linear-gradient(180deg, #0f0a26 0%, #1a1340 100%);
}

.header {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  padding: 0 8rpx;
}

.title {
  font-size: 48rpx;
  font-weight: 800;
  color: #fff;
  letter-spacing: 4rpx;
}

.balance {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4rpx;
}

.balance-label {
  font-size: 20rpx;
  color: #a8a4c0;
}

.balance-value {
  font-size: 32rpx;
  font-weight: 700;
  color: #4cd964;
}

.tabs {
  display: flex;
  flex-direction: row;
  gap: 8rpx;
  padding: 4rpx;
  border-radius: 16rpx;
  background: rgba(255, 255, 255, 0.04);
}

.tab {
  flex: 1;
  padding: 14rpx 0;
  text-align: center;
  font-size: 24rpx;
  font-weight: 600;
  color: #a8a4c0;
  border-radius: 12rpx;
  transition: all 0.2s;
}

.tab-active {
  background: linear-gradient(180deg, #5cc8ff 0%, #2789cf 100%);
  color: #fff;
  box-shadow: 0 4rpx 12rpx rgba(39, 137, 207, 0.3);
}

.items-list {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 12rpx;
}

.empty-hint {
  padding: 40rpx 24rpx;
  text-align: center;
  font-size: 24rpx;
  color: #6e6a8a;
  border-radius: 16rpx;
  border: 2rpx dashed rgba(255, 255, 255, 0.08);
}

.item-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 16rpx;
  padding: 20rpx;
  border-radius: 20rpx;
  background: rgba(255, 255, 255, 0.04);
  border: 2rpx solid rgba(255, 255, 255, 0.06);
}

.item-row.unaffordable {
  opacity: 0.5;
}

.item-icon {
  font-size: 48rpx;
  width: 64rpx;
  text-align: center;
}

.item-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4rpx;
  min-width: 0;
}

.item-title-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 12rpx;
}

.item-name {
  font-size: 28rpx;
  font-weight: 700;
  color: #fff;
}

.item-owned {
  font-size: 20rpx;
  padding: 2rpx 10rpx;
  border-radius: 12rpx;
  background: rgba(76, 217, 100, 0.2);
  color: #4cd964;
  font-weight: 600;
}

.item-desc {
  font-size: 22rpx;
  color: #a8a4c0;
  line-height: 1.4;
}

.item-effect {
  font-size: 22rpx;
  color: #ffd86f;
  font-weight: 600;
  margin-top: 2rpx;
}

.item-buy {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8rpx;
  min-width: 96rpx;
}

.item-cost {
  font-size: 22rpx;
  color: #fff;
  font-weight: 600;
}

.btn-buy {
  padding: 10rpx 20rpx;
  border: none;
  border-radius: 999rpx;
  font-size: 22rpx;
  font-weight: 700;
  letter-spacing: 1rpx;
  color: #fff;
  background: linear-gradient(180deg, #ff7a1a 0%, #c75510 100%);
  white-space: nowrap;
  min-height: 56rpx;
  line-height: 1;
}

.btn-buy:active {
  transform: scale(0.95);
}

.btn-buy-disabled {
  background: rgba(255, 255, 255, 0.1);
  color: #6e6a8a;
}

.btn-back {
  margin-top: auto;
  padding: 24rpx 40rpx;
  border: none;
  border-radius: 999rpx;
  font-size: 28rpx;
  font-weight: 700;
  letter-spacing: 4rpx;
  color: #fff;
  background: linear-gradient(180deg, #5cc8ff 0%, #2789cf 100%);
  box-shadow: 0 8rpx 0 #1c5f99;
  min-height: 88rpx;
}

.btn-back:active {
  transform: translateY(4rpx);
}
</style>
