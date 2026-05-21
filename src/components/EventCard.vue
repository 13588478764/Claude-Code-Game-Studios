<script setup lang="ts">
/**
 * EventCard — paper-styled card display with auto-fitting font size.
 *
 * Font size adapts to text length per AC-4:
 *   fontSize = max(MIN_FONT, BASE_FONT - (lineCount - 3) * 2)
 *   BASE = 32rpx, MIN = 24rpx
 */
import { computed } from 'vue'
import type { EventCard } from '@/types/event'

interface Props {
  card: EventCard | null
  isFollowUp?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  isFollowUp: false
})

const BASE_FONT_RPX = 32
const MIN_FONT_RPX = 24
const CHARS_PER_LINE = 18  // approximate Chinese chars per line at base width

const lineCount = computed(() => {
  if (!props.card) return 0
  return Math.max(1, Math.ceil(props.card.text.length / CHARS_PER_LINE))
})

const fontSize = computed(() => {
  if (!props.card) return BASE_FONT_RPX
  const adjusted = BASE_FONT_RPX - Math.max(0, lineCount.value - 3) * 2
  return Math.max(MIN_FONT_RPX, adjusted)
})

const cornerLabel = computed(() => (props.isFollowUp ? '后续' : 'EVENT'))
const cornerEmoji = computed(() => (props.isFollowUp ? '🔗' : '📋'))
</script>

<template>
  <view v-if="card" class="card" :class="{ 'card-followup': isFollowUp }">
    <text class="corner-label">{{ cornerLabel }}</text>
    <text class="corner-emoji">{{ cornerEmoji }}</text>
    <text
      class="card-text"
      :style="`font-size: ${fontSize}rpx;`"
      :data-fontsize="fontSize"
    >{{ card.text }}</text>
    <view class="card-divider"></view>
  </view>
</template>

<style scoped>
.card {
  position: relative;
  background: linear-gradient(160deg, #fdf6e8 0%, #f5e8c8 100%);
  color: #2a2230;
  border-radius: 32rpx;
  padding: 36rpx 36rpx 32rpx;
  box-shadow:
    0 24rpx 60rpx rgba(0, 0, 0, 0.5),
    0 2rpx 4rpx rgba(255, 255, 255, 0.6) inset;
  border: 1rpx solid rgba(160, 110, 60, 0.3);
  width: 100%;
  animation: cardEnter 0.5s cubic-bezier(0.4, 0, 0.2, 1);
}

.card-followup {
  background: linear-gradient(160deg, #f0e4ff 0%, #d6c8ff 100%);
  border-color: rgba(120, 80, 200, 0.4);
}

.corner-label {
  position: absolute;
  top: 14rpx;
  left: 24rpx;
  font-size: 20rpx;
  font-weight: 700;
  color: #8b6e3a;
  letter-spacing: 4rpx;
}

.card-followup .corner-label {
  color: #6a4eb0;
}

.corner-emoji {
  position: absolute;
  top: 12rpx;
  right: 24rpx;
  font-size: 28rpx;
}

.card-text {
  display: block;
  margin-top: 28rpx;
  font-weight: 500;
  line-height: 1.65;
}

.card-divider {
  height: 2rpx;
  background: linear-gradient(90deg, transparent, rgba(139, 110, 58, 0.4), transparent);
  margin-top: 20rpx;
}

@keyframes cardEnter {
  0% { opacity: 0; transform: rotateX(-30deg) translateY(40rpx); }
  100% { opacity: 1; transform: rotateX(0) translateY(0); }
}
</style>
