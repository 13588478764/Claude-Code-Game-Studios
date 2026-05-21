<script setup lang="ts">
/**
 * ResourceBar — pure presentational component for energy/mood/money resources.
 * Receives value via props; does NOT subscribe to store directly.
 */
import { computed } from 'vue'
import { formatMoney } from '@/utils/format'

interface Props {
  value: number
  max?: number
  type: 'energy' | 'mood' | 'money' | 'health'
  showIcon?: boolean
  showValue?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  max: 100,
  showIcon: true,
  showValue: true
})

const icon = computed(() => {
  switch (props.type) {
    case 'energy': return '⚡'
    case 'mood': return '😊'
    case 'money': return '💰'
    case 'health': return '❤️'
  }
})

const fillColor = computed(() => {
  if (props.type === 'energy') {
    if (props.value <= 30) return '#FF6B6B'
    if (props.value <= 50) return '#FFCC00'
    return '#4CD964'
  }
  if (props.type === 'mood') {
    if (props.value <= 20) return '#9B6BFF'
    if (props.value <= 30) return '#8E8E93'
    return '#FF9500'
  }
  if (props.type === 'health') {
    // health is critical — strong red signal below 30, pink at 50, green when ample
    if (props.value <= 30) return '#FF1744'
    if (props.value <= 60) return '#FF5252'
    return '#E91E63'
  }
  return '#FFCC00'
})

const moneyColor = computed(() =>
  props.value < 0 ? '#FF6B6B' : '#FFCC00'
)

const fillPercent = computed(() => {
  if (props.type === 'money') return 0
  const pct = Math.max(0, Math.min(100, (props.value / props.max) * 100))
  return pct
})

const isMoney = computed(() => props.type === 'money')
</script>

<template>
  <view class="resource-row">
    <view v-if="showIcon" :class="['icon-box', `icon-${type}`]">
      {{ icon }}
    </view>

    <view v-if="!isMoney" class="bar-wrap">
      <view
        class="bar-fill"
        :style="{ width: fillPercent + '%', background: fillColor, color: fillColor }"
      ></view>
    </view>

    <view v-else class="money-display" :style="{ color: moneyColor }">
      {{ formatMoney(value) }} 元
    </view>

    <view v-if="showValue && !isMoney" class="value-num">
      {{ value }}
    </view>
  </view>
</template>

<style scoped>
.resource-row {
  display: flex;
  align-items: center;
  gap: 16rpx;
  min-height: 88rpx;
}

.icon-box {
  width: 56rpx;
  height: 56rpx;
  border-radius: 14rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28rpx;
  flex-shrink: 0;
}
.icon-energy { background: rgba(76, 217, 100, 0.15); }
.icon-mood { background: rgba(255, 149, 0, 0.15); }
.icon-money { background: rgba(255, 204, 0, 0.15); }
.icon-health { background: rgba(233, 30, 99, 0.15); }

.bar-wrap {
  flex: 1;
  height: 24rpx;
  background: rgba(0, 0, 0, 0.4);
  border-radius: 999rpx;
  overflow: hidden;
  position: relative;
  border: 1rpx solid rgba(255, 255, 255, 0.05);
}

.bar-fill {
  height: 100%;
  border-radius: 999rpx;
  transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1), background 0.3s;
  position: relative;
  box-shadow: 0 0 16rpx currentColor;
}

.bar-fill::after {
  content: '';
  position: absolute;
  top: 0; left: 0; right: 0; height: 50%;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.4), transparent);
  border-radius: 999rpx 999rpx 0 0;
}

.value-num {
  font-size: 22rpx;
  font-weight: 800;
  min-width: 56rpx;
  text-align: right;
  color: #fff;
  text-shadow: 0 1rpx 2rpx rgba(0, 0, 0, 0.6);
}

.money-display {
  flex: 1;
  font-size: 28rpx;
  font-weight: 800;
  text-shadow: 0 0 24rpx currentColor;
}
</style>
