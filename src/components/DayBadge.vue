<script setup lang="ts">
/**
 * DayBadge — top day indicator with progress dots.
 * Displays "第N周 周X · 子标题" plus per-day dots for the current week and
 * a separate week-counter badge for multi-week careers (S4-1).
 */
import { computed } from 'vue'

interface Props {
  currentDay: number          // 1-5 within current week
  totalDays?: number          // events-per-day total positions (defaults to DAYS_PER_WEEK)
  currentWeekIndex?: number   // S4-1: 1..weeksPerCareer
  weeksPerCareer?: number     // S4-1: total weeks in career
}

const props = withDefaults(defineProps<Props>(), {
  totalDays: 5,
  currentWeekIndex: 1,
  weeksPerCareer: 1
})

const dayNames = ['周一', '周二', '周三', '周四', '周五'] as const
const daySubs = ['新的一周', '已经周二', '过半了', '快周末', '冲鸭'] as const

const dayName = computed(() => dayNames[props.currentDay - 1] ?? '周?')
const daySub = computed(() => daySubs[props.currentDay - 1] ?? '')

const showWeekCounter = computed(() => props.weeksPerCareer > 1)

const dots = computed(() => {
  return Array.from({ length: props.totalDays }, (_, i) => {
    const idx = i + 1
    if (idx < props.currentDay) return 'done'
    if (idx === props.currentDay) return 'current'
    return 'pending'
  })
})
</script>

<template>
  <view class="day-badge">
    <view class="badge-header">
      <view class="day-icon">{{ currentDay }}</view>
      <text class="day-text">
        <text v-if="showWeekCounter" class="week-prefix">第{{ currentWeekIndex }}/{{ weeksPerCareer }}周 · </text>{{ dayName }} · {{ daySub }}
      </text>
    </view>
    <view class="dots">
      <view
        v-for="(state, i) in dots"
        :key="i"
        class="dot"
        :class="`dot-${state}`"
      ></view>
    </view>
  </view>
</template>

<style scoped>
.day-badge {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12rpx 24rpx 12rpx 12rpx;
  background: linear-gradient(135deg, #4a3675 0%, #2a1f4a 100%);
  border-radius: 999rpx;
  border: 1rpx solid rgba(180, 140, 255, 0.3);
}

.badge-header {
  display: flex;
  align-items: center;
  gap: 16rpx;
}

.day-icon {
  width: 44rpx;
  height: 44rpx;
  border-radius: 50%;
  background: linear-gradient(135deg, #ffb84d, #ff7a1a);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24rpx;
  font-weight: 900;
  color: #fff;
}

.day-text {
  font-size: 24rpx;
  font-weight: 600;
  color: #e8dcff;
  letter-spacing: 2rpx;
}

.week-prefix {
  color: #ffd86f;
  font-weight: 700;
}

.dots {
  display: flex;
  gap: 10rpx;
}

.dot {
  width: 14rpx;
  height: 14rpx;
  border-radius: 50%;
  transition: all 0.3s;
}

.dot-pending {
  background: rgba(255, 255, 255, 0.12);
}

.dot-done {
  background: #4cd964;
  box-shadow: 0 0 16rpx rgba(76, 217, 100, 0.6);
}

.dot-current {
  background: #ffcc00;
  box-shadow: 0 0 24rpx rgba(255, 204, 0, 0.8);
  width: 18rpx;
  height: 18rpx;
  animation: pulse 1s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
</style>
