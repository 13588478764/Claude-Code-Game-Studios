<script setup lang="ts">
/**
 * StatusOnboardingTip — first-time onboarding tooltip explaining status duration.
 *
 * Shown only on the player's very first encounter with any status (per
 * SaveData.firstStatusShown). Parent (game-main) controls visibility and
 * is responsible for marking firstStatusShown=true when the tip dismisses.
 */

interface Props {
  text: string
}

defineProps<Props>()
</script>

<template>
  <view class="tip">
    <text class="tip-arrow">▾</text>
    <text class="tip-text">{{ text }}</text>
  </view>
</template>

<style scoped>
.tip {
  position: absolute;
  top: 88rpx;
  left: 50%;
  transform: translateX(-50%);
  z-index: 25;
  padding: 16rpx 24rpx;
  border-radius: 16rpx;
  background: linear-gradient(180deg, #ffd66b 0%, #f5a623 100%);
  color: #5a3a00;
  font-size: 24rpx;
  font-weight: 700;
  letter-spacing: 1rpx;
  box-shadow: 0 8rpx 24rpx rgba(245, 166, 35, 0.4);
  animation: tipBounce 0.4s ease-out, tipFadeOut 0.3s ease-in 1.2s forwards;
  white-space: nowrap;
}

.tip-arrow {
  position: absolute;
  top: -16rpx;
  left: 50%;
  transform: translateX(-50%);
  font-size: 28rpx;
  color: #ffd66b;
  text-shadow: 0 -2rpx 0 #f5a623;
}

.tip-text {
  display: inline-block;
}

@keyframes tipBounce {
  0% { transform: translateX(-50%) translateY(-8rpx) scale(0.85); opacity: 0; }
  60% { transform: translateX(-50%) translateY(2rpx) scale(1.05); opacity: 1; }
  100% { transform: translateX(-50%) translateY(0) scale(1); opacity: 1; }
}

@keyframes tipFadeOut {
  to { opacity: 0; }
}

@media (prefers-reduced-motion: reduce) {
  .tip {
    animation: tipFadeOut 0.3s ease-in 1.2s forwards;
  }
}
</style>
