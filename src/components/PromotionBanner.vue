<script setup lang="ts">
/**
 * PromotionBanner (S4-8) — fullscreen 1.5s toast on career promotion.
 *
 * Parent (game-main) controls visibility via v-if. Banner self-renders
 * with bounce-in / fade-out CSS animation. Uses per-job title resolved by
 * career-store, NOT generic LEVEL_TITLES.
 */
import type { CareerLevel } from '@/types/career'

interface Props {
  fromLevel: CareerLevel
  toLevel: CareerLevel
  title: string  // per-job, pre-resolved by parent
  newSalaryMul: number
}

defineProps<Props>()
</script>

<template>
  <view class="promotion-overlay" :data-to-level="toLevel">
    <view class="promotion-card">
      <text class="promotion-emoji">🎉</text>
      <text class="promotion-headline">升职 Lv {{ fromLevel }} → Lv {{ toLevel }}</text>
      <text class="promotion-title">{{ title }}</text>
      <text class="promotion-salary">薪水 ×{{ newSalaryMul.toFixed(2) }}</text>
    </view>
  </view>
</template>

<style scoped>
.promotion-overlay {
  position: fixed;
  inset: 0;
  background: radial-gradient(ellipse at center, rgba(255, 200, 80, 0.25) 0%, rgba(0, 0, 0, 0.85) 70%);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 40;
  animation: overlayFade 1.5s ease-out forwards;
}

.promotion-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16rpx;
  padding: 60rpx 80rpx;
  border-radius: 32rpx;
  background: linear-gradient(180deg, rgba(255, 214, 107, 0.95) 0%, rgba(245, 166, 35, 0.95) 100%);
  border: 4rpx solid rgba(255, 255, 255, 0.5);
  box-shadow: 0 20rpx 60rpx rgba(245, 166, 35, 0.6);
  animation: cardBounce 0.6s ease-out;
}

.promotion-emoji {
  font-size: 120rpx;
  line-height: 1;
  animation: emojiSpin 0.8s ease-out;
}

.promotion-headline {
  font-size: 36rpx;
  font-weight: 800;
  color: #5a3a00;
  letter-spacing: 4rpx;
}

.promotion-title {
  font-size: 56rpx;
  font-weight: 900;
  color: #fff;
  text-shadow: 0 4rpx 12rpx rgba(245, 166, 35, 0.8);
  letter-spacing: 8rpx;
}

.promotion-salary {
  margin-top: 8rpx;
  font-size: 28rpx;
  font-weight: 700;
  color: #5a3a00;
  padding: 6rpx 24rpx;
  border-radius: 999rpx;
  background: rgba(255, 255, 255, 0.4);
}

@keyframes overlayFade {
  0% { opacity: 0; }
  10% { opacity: 1; }
  85% { opacity: 1; }
  100% { opacity: 0; }
}

@keyframes cardBounce {
  0% { transform: scale(0.4) translateY(40rpx); opacity: 0; }
  60% { transform: scale(1.1); opacity: 1; }
  100% { transform: scale(1) translateY(0); opacity: 1; }
}

@keyframes emojiSpin {
  0% { transform: rotate(-180deg) scale(0); }
  100% { transform: rotate(0) scale(1); }
}

@media (prefers-reduced-motion: reduce) {
  .promotion-overlay { animation: overlayFade 1.5s ease-out forwards; }
  .promotion-card { animation: none; }
  .promotion-emoji { animation: none; }
}
</style>
