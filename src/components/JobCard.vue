<script setup lang="ts">
/**
 * JobCard — single job entry on the job-select screen.
 *
 * Props: job (config), unlocked (bool), recommended (bool).
 * Emits: select(jobId) only when unlocked.
 * Locked cards show unlockCondition copy and ignore taps (parent toasts).
 */
import { computed } from 'vue'
import type { JobConfig, UnlockCondition } from '@/types/job'

interface Props {
  job: JobConfig
  unlocked: boolean
  recommended: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  (e: 'select', jobId: string): void
  (e: 'lockedTap', jobId: string): void
}>()

const conditionText = computed(() => formatCondition(props.job.unlockCondition))

function formatCondition(cond: UnlockCondition | undefined): string {
  if (!cond) return ''
  switch (cond.type) {
    case 'wins': return `通关 ${cond.value} 次解锁`
    case 'totalMoney': return `累计赚到 ${cond.value} 元解锁`
    case 'deaths': return `被炒 ${cond.value} 次解锁`
    case 'achievement': return `成就「${cond.value}」解锁`
    default: return '条件未知'
  }
}

function onTap() {
  if (props.unlocked) {
    emit('select', props.job.id)
  } else {
    emit('lockedTap', props.job.id)
  }
}
</script>

<template>
  <view
    class="job-card"
    :class="{
      locked: !unlocked,
      recommended: unlocked && recommended
    }"
    :data-job-id="job.id"
    @click="onTap"
  >
    <view class="card-row">
      <text class="icon">{{ job.icon }}</text>
      <view class="info">
        <view class="title-row">
          <text class="name">{{ job.name }}</text>
          <text v-if="recommended && unlocked" class="badge">推荐</text>
          <text v-if="!unlocked" class="lock-icon">🔒</text>
        </view>
        <text class="desc">{{ job.description }}</text>
        <text v-if="!unlocked" class="condition">{{ conditionText }}</text>
      </view>
    </view>
  </view>
</template>

<style scoped>
.job-card {
  position: relative;
  display: block;
  padding: 24rpx 28rpx;
  margin-bottom: 20rpx;
  border-radius: 24rpx;
  background: linear-gradient(180deg, #2a2554 0%, #1c1840 100%);
  border: 2rpx solid rgba(255, 255, 255, 0.08);
  min-height: 88rpx;
  transition: transform 0.1s ease;
}

.job-card:active {
  transform: scale(0.98);
}

.job-card.recommended {
  border-color: #ffd66b;
  box-shadow:
    0 0 0 2rpx rgba(255, 214, 107, 0.4),
    0 0 32rpx rgba(255, 214, 107, 0.5);
  animation: glow 1.6s ease-in-out infinite;
}

.job-card.locked {
  background: linear-gradient(180deg, #1a1730 0%, #14112a 100%);
  border-color: rgba(255, 255, 255, 0.05);
  opacity: 0.55;
}

.card-row {
  display: flex;
  flex-direction: row;
  align-items: flex-start;
  gap: 20rpx;
}

.icon {
  font-size: 64rpx;
  line-height: 1;
  flex-shrink: 0;
  width: 80rpx;
  text-align: center;
}

.info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8rpx;
}

.title-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 12rpx;
}

.name {
  font-size: 32rpx;
  font-weight: 700;
  color: #fff;
}

.badge {
  font-size: 20rpx;
  font-weight: 700;
  padding: 2rpx 12rpx;
  background: linear-gradient(180deg, #ffd66b, #f5a623);
  color: #5a3a00;
  border-radius: 16rpx;
}

.lock-icon {
  font-size: 26rpx;
}

.desc {
  font-size: 24rpx;
  color: #a8a4c0;
  line-height: 1.45;
}

.condition {
  font-size: 22rpx;
  color: #ffb84d;
  margin-top: 6rpx;
  font-weight: 600;
}

@keyframes glow {
  0%, 100% {
    box-shadow:
      0 0 0 2rpx rgba(255, 214, 107, 0.4),
      0 0 24rpx rgba(255, 214, 107, 0.4);
  }
  50% {
    box-shadow:
      0 0 0 2rpx rgba(255, 214, 107, 0.6),
      0 0 40rpx rgba(255, 214, 107, 0.7);
  }
}
</style>
