<script setup lang="ts">
/**
 * CareerBadge (H-2) — compact display of careerLevel + title + score progress.
 * Renders as a pill: "Lv N · 头衔" + thin progress bar below for next-level
 * threshold. At max level (Lv4), shows "MAX" instead of progress.
 */
import { computed } from 'vue'
import { PROMOTION_THRESHOLDS, type CareerLevel } from '@/types/career'

interface Props {
  level: CareerLevel
  score: number
  title: string
}

const props = defineProps<Props>()

const isMaxLevel = computed(() => props.level >= 4)

const nextThreshold = computed(() => {
  if (isMaxLevel.value) return null
  const next = (props.level + 1) as CareerLevel
  return PROMOTION_THRESHOLDS[next]
})

const currentLevelThreshold = computed(() => PROMOTION_THRESHOLDS[props.level])

const progressPercent = computed(() => {
  if (isMaxLevel.value) return 100
  const start = currentLevelThreshold.value
  const end = nextThreshold.value!
  const span = end - start
  if (span <= 0) return 100
  const into = Math.max(0, props.score - start)
  return Math.max(0, Math.min(100, (into / span) * 100))
})

const progressText = computed(() => {
  if (isMaxLevel.value) return 'MAX'
  return `${props.score} / ${nextThreshold.value}`
})
</script>

<template>
  <view class="career-badge" :data-level="level" :class="`level-${level}`">
    <view class="badge-row">
      <text class="level-tag">Lv {{ level }}</text>
      <text class="title-text">{{ title }}</text>
    </view>
    <view class="progress-row">
      <view class="bar-track">
        <view
          class="bar-fill"
          :style="{ width: progressPercent + '%' }"
          :class="{ 'fill-max': isMaxLevel }"
        ></view>
      </view>
      <text class="progress-text">{{ progressText }}</text>
    </view>
  </view>
</template>

<style scoped>
.career-badge {
  display: flex;
  flex-direction: column;
  gap: 6rpx;
  padding: 10rpx 18rpx;
  border-radius: 18rpx;
  background: linear-gradient(135deg, #5a3a00 0%, #3a2659 100%);
  border: 1rpx solid rgba(255, 214, 107, 0.3);
}

.badge-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 10rpx;
}

.level-tag {
  font-size: 20rpx;
  font-weight: 800;
  padding: 2rpx 10rpx;
  border-radius: 12rpx;
  background: linear-gradient(180deg, #ffd66b, #f5a623);
  color: #5a3a00;
  letter-spacing: 1rpx;
}

.title-text {
  font-size: 22rpx;
  font-weight: 700;
  color: #ffd86f;
  letter-spacing: 1rpx;
}

.progress-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 8rpx;
}

.bar-track {
  flex: 1;
  height: 6rpx;
  border-radius: 999rpx;
  background: rgba(0, 0, 0, 0.4);
  overflow: hidden;
}

.bar-fill {
  height: 100%;
  background: linear-gradient(90deg, #ffd66b, #f5a623);
  border-radius: 999rpx;
  transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
}

.bar-fill.fill-max {
  background: linear-gradient(90deg, #ffd66b, #f5a623, #ff7a1a);
}

.progress-text {
  font-size: 18rpx;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.7);
  letter-spacing: 1rpx;
  min-width: 80rpx;
  text-align: right;
}
</style>
