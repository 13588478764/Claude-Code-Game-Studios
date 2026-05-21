<script setup lang="ts">
/**
 * ChoiceButton — A/B option button with optional risk badge.
 *
 * Features:
 *  - Risk percentage badge (top-right) when choice has risk field
 *  - 300ms debounce on click (AC-5: 100ms 内 3 次点击 → handler 仅 1 次)
 *  - Disabled state visual
 *  - Variant a (blue gradient) vs b (orange gradient)
 */
import { ref } from 'vue'
import type { Choice } from '@/types/event'

interface Props {
  choice: Choice
  variant: 'a' | 'b'
  disabled?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  disabled: false
})

const emit = defineEmits<{
  (e: 'pick'): void
}>()

const DEBOUNCE_MS = 300
const cooldown = ref(false)

function onClick() {
  if (props.disabled || cooldown.value) return
  cooldown.value = true
  emit('pick')
  setTimeout(() => {
    cooldown.value = false
  }, DEBOUNCE_MS)
}

function riskPercent(): string | null {
  if (!props.choice.risk) return null
  return `🎲 ${Math.round(props.choice.risk.chance * 100)}%`
}
</script>

<template>
  <button
    class="choice-btn"
    :class="`btn-${variant}`"
    :disabled="disabled || cooldown"
    @click="onClick"
  >
    <text v-if="riskPercent()" class="risk-tag">{{ riskPercent() }}</text>
    <text class="btn-icon">{{ choice.icon || (variant === 'a' ? 'A' : 'B') }}</text>
    <text class="btn-text">{{ choice.text }}</text>
  </button>
</template>

<style scoped>
.choice-btn {
  flex: 1;
  position: relative;
  padding: 24rpx 16rpx;
  border: none;
  border-radius: 24rpx;
  font-size: 26rpx;
  line-height: 1.35;
  font-weight: 600;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8rpx;
  min-height: 132rpx;
  transition: transform 0.1s;
  color: #fff;
}

.choice-btn:active:not([disabled]) {
  transform: scale(0.96) translateY(4rpx);
}

.choice-btn[disabled] {
  opacity: 0.4;
}

.btn-a {
  background: linear-gradient(180deg, #5cc8ff 0%, #2789cf 100%);
  box-shadow: 0 10rpx 0 #1c5f99, 0 12rpx 24rpx rgba(39, 137, 207, 0.4);
}

.btn-b {
  background: linear-gradient(180deg, #ffb84d 0%, #ff7a1a 100%);
  box-shadow: 0 10rpx 0 #c75510, 0 12rpx 24rpx rgba(255, 122, 26, 0.4);
}

.btn-icon {
  font-size: 36rpx;
}

.btn-text {
  font-size: 24rpx;
  padding: 0 8rpx;
}

.risk-tag {
  position: absolute;
  top: 6rpx;
  right: 10rpx;
  font-size: 18rpx;
  font-weight: 800;
  padding: 2rpx 10rpx;
  background: rgba(0, 0, 0, 0.4);
  border-radius: 12rpx;
  letter-spacing: 1rpx;
}
</style>
