<script setup lang="ts">
/**
 * RiskDiceOverlay — fullscreen dice animation shown when a risk choice resolves.
 *
 * Displays for ~2s total: dice rolls 720° in 1s, then outcome text pops in
 * over 0.4s starting at 0.8s. Parent (game-main) controls visibility via v-if
 * and is responsible for the dismiss timer.
 *
 * Visual reference: prototypes/core-loop/index.html .risk-overlay block.
 */
import type { RiskOutcome } from '@/types/resolve'

interface Props {
  outcome: RiskOutcome
  detail?: string
}

defineProps<Props>()
</script>

<template>
  <view class="risk-overlay" :data-outcome="outcome">
    <text class="dice">🎲</text>
    <text
      class="risk-result-text"
      :class="outcome === 'success' ? 'risk-success' : 'risk-fail'"
    >{{ outcome === 'success' ? '✨ 成功' : '💀 翻车' }}</text>
    <text v-if="detail" class="risk-detail">{{ detail }}</text>
  </view>
</template>

<style scoped>
.risk-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.85);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 35;
  animation: fadeIn 0.2s;
}

.dice {
  font-size: 200rpx;
  line-height: 1;
  animation: diceRoll 1s ease-out;
}

.risk-result-text {
  margin-top: 40rpx;
  font-size: 44rpx;
  font-weight: 800;
  letter-spacing: 4rpx;
  animation: resolvePop 0.4s 0.8s both;
}

.risk-success {
  color: #4CD964;
  text-shadow: 0 0 40rpx rgba(76, 217, 100, 0.6);
}

.risk-fail {
  color: #FF6B6B;
  text-shadow: 0 0 40rpx rgba(255, 107, 107, 0.6);
}

.risk-detail {
  margin-top: 16rpx;
  font-size: 26rpx;
  color: #ddd;
  max-width: 560rpx;
  text-align: center;
  padding: 0 32rpx;
  animation: fadeIn 0.4s 1s both;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes diceRoll {
  0% { transform: rotate(0) scale(0.5); opacity: 0; }
  50% { transform: rotate(360deg) scale(1.3); opacity: 1; }
  100% { transform: rotate(720deg) scale(1); opacity: 1; }
}

@keyframes resolvePop {
  0% { transform: scale(0.5) translateY(20rpx); opacity: 0; }
  60% { transform: scale(1.15); }
  100% { transform: scale(1) translateY(0); opacity: 1; }
}
</style>
