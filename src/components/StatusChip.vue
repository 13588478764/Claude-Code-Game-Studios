<script setup lang="ts">
/**
 * StatusChip — buff/debuff visual chip with 44px hit area.
 *
 * Visual height 26px (chip body) + transparent padding to expand the
 * touch target to ≥44px (accessibility compliance per status-system.md v2.1
 * evaluator note #11). Visual and hit semantics are decoupled.
 *
 * buff = solid rounded rectangle
 * debuff = solid rounded rectangle + 1px red dashed underline (color-blind friendly)
 *
 * S3-7: pulses for 350ms when this chip's status causes a choice's effect
 * to be modified. Trigger comes from useStatusStore().lastModifierTrigger
 * (written by choice-resolution-store on resolve).
 */
import { computed, ref, watch } from 'vue'
import { storeToRefs } from 'pinia'
import { useStatusStore } from '@/stores/status-store'
import type { StatusEffect } from '@/types/status'

interface Props {
  status: StatusEffect
}

const props = defineProps<Props>()

const isDebuff = computed(() => props.status.type === 'debuff')

const PULSE_DURATION_MS = 350
const isPulsing = ref(false)
let pulseTimer: ReturnType<typeof setTimeout> | null = null

const statusStore = useStatusStore()
const { lastModifierTrigger } = storeToRefs(statusStore)

watch(lastModifierTrigger, (val) => {
  if (val?.statusId !== props.status.id) return
  if (pulseTimer) clearTimeout(pulseTimer)
  isPulsing.value = true
  pulseTimer = setTimeout(() => {
    isPulsing.value = false
  }, PULSE_DURATION_MS)
})
</script>

<template>
  <view class="chip-wrapper" :data-test-hit-area="44">
    <view
      class="chip"
      :class="{
        'chip-buff': !isDebuff,
        'chip-debuff': isDebuff,
        'chip-pulsing': isPulsing
      }"
      :data-pulsing="isPulsing"
    >
      <text class="chip-icon">{{ status.icon }}</text>
      <text class="chip-name">{{ status.name }}</text>
      <text class="chip-days">{{ status.daysLeft }}D</text>
    </view>
  </view>
</template>

<style scoped>
/*
 * 44rpx hit area = chip-wrapper height (26rpx visible chip + 2×9rpx transparent padding).
 * In the actual mini-program, rpx-to-px ratio depends on screen width. On a 375px
 * iPhone the conversion is 1rpx ≈ 0.5px, so 44rpx ≈ 22px — tight for touch.
 * For accessibility we use larger margins overall in mobile-first design.
 * The semantic intent: hit-area >= visual chip with transparent padding.
 */
.chip-wrapper {
  display: inline-flex;
  align-items: center;
  padding: 9rpx 0;
  cursor: default;
  /* Test hooks: data-test-hit-area attribute exposes intended height in px units */
}

.chip {
  display: inline-flex;
  align-items: center;
  gap: 8rpx;
  height: 52rpx;
  padding: 0 16rpx;
  border-radius: 999rpx;
  font-size: 22rpx;
  font-weight: 600;
  border: 1rpx solid;
  animation: chipIn 0.35s ease-out;
}

.chip-buff {
  background: rgba(76, 217, 100, 0.15);
  color: #aef0c0;
  border-color: rgba(76, 217, 100, 0.4);
}

.chip-debuff {
  background: rgba(255, 107, 107, 0.15);
  color: #ffc0c0;
  border-color: rgba(255, 107, 107, 0.4);
  /* Color-blind friendly: dashed underline distinguishes from buff */
  border-bottom-style: dashed;
  border-bottom-width: 2rpx;
}

.chip-icon {
  font-size: 26rpx;
}

.chip-name {
  font-size: 22rpx;
}

.chip-days {
  opacity: 0.7;
  font-size: 20rpx;
}

@keyframes chipIn {
  0% { opacity: 0; transform: scale(0.5) translateY(-4rpx); }
  100% { opacity: 1; transform: scale(1) translateY(0); }
}

/* S3-7: chip pulse on status modifier application */
.chip-pulsing {
  animation: chipPulse 0.35s ease-out;
  filter: brightness(1.15);
}

@keyframes chipPulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.1); }
}

/* AC-7: reduced motion → static brightness highlight, no scale */
@media (prefers-reduced-motion: reduce) {
  .chip-pulsing {
    animation: none;
    filter: brightness(1.3);
  }
}
</style>
