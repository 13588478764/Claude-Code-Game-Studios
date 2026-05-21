<script setup lang="ts">
/**
 * LowEnergyHint (S4-9) — small toast at top of game-main when energy drops
 * below LOW_THRESHOLD. Pulses gently to draw attention; tap navigates to
 * shop. Auto-dismisses on energy recovery (via parent v-if).
 *
 * Educational nudge for new players unaware of the shop / consumables.
 */
defineProps<{
  energy: number
  money: number
}>()

const emit = defineEmits<{
  (e: 'open-shop'): void
}>()

function onTap() {
  emit('open-shop')
}
</script>

<template>
  <view class="hint" data-test-id="low-energy-hint" @click="onTap">
    <text class="hint-icon">⚡</text>
    <text class="hint-text">体力快空了！去商店买点续命？</text>
    <text class="hint-arrow">›</text>
  </view>
</template>

<style scoped>
.hint {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 12rpx;
  padding: 16rpx 24rpx;
  margin: 8rpx 0;
  border-radius: 16rpx;
  background: linear-gradient(180deg, rgba(255, 122, 26, 0.95) 0%, rgba(199, 85, 16, 0.95) 100%);
  border: 2rpx solid rgba(255, 214, 107, 0.5);
  box-shadow: 0 4rpx 16rpx rgba(255, 122, 26, 0.4);
  animation: hintPulse 1.6s ease-in-out infinite;
  z-index: 10;
}

.hint:active {
  transform: scale(0.97);
}

.hint-icon {
  font-size: 32rpx;
  line-height: 1;
}

.hint-text {
  flex: 1;
  font-size: 24rpx;
  font-weight: 600;
  color: #fff;
  letter-spacing: 1rpx;
}

.hint-arrow {
  font-size: 32rpx;
  font-weight: 800;
  color: #fff;
}

@keyframes hintPulse {
  0%, 100% {
    transform: scale(1);
    box-shadow: 0 4rpx 16rpx rgba(255, 122, 26, 0.4);
  }
  50% {
    transform: scale(1.02);
    box-shadow: 0 6rpx 24rpx rgba(255, 122, 26, 0.7);
  }
}

@media (prefers-reduced-motion: reduce) {
  .hint {
    animation: none;
  }
}
</style>
