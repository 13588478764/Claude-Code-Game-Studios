<script setup lang="ts">
/**
 * FloatingDelta — single rising number that fades upward over 1.5s.
 *
 * Parent (game-main) spawns one per non-zero ResourceDelta and removes it
 * via setTimeout. Pure CSS animation; no canvas. Color encodes target;
 * positive vs negative delta drives sign + class.
 */
import { computed } from 'vue'
import type { ResourceTarget } from '@/types/resource'

interface Props {
  target: ResourceTarget
  value: number
}

const props = defineProps<Props>()

const sign = computed(() => (props.value >= 0 ? '+' : ''))
const direction = computed<'gain' | 'loss'>(() =>
  props.value >= 0 ? 'gain' : 'loss'
)

const targetIcon = computed(() => {
  switch (props.target) {
    case 'energy': return '⚡'
    case 'mood': return '😊'
    case 'money': return '💰'
    default: return ''
  }
})
</script>

<template>
  <text
    class="float"
    :class="[`float-${target}`, `float-${direction}`]"
    :data-target="target"
    :data-value="value"
  >{{ targetIcon }}{{ sign }}{{ value }}</text>
</template>

<style scoped>
.float {
  position: absolute;
  pointer-events: none;
  font-size: 28rpx;
  font-weight: 800;
  letter-spacing: 1rpx;
  white-space: nowrap;
  text-shadow: 0 2rpx 8rpx rgba(0, 0, 0, 0.7);
  animation: floatRise 1.5s ease-out forwards;
  z-index: 20;
}

.float-energy { color: #ffd86f; }
.float-mood { color: #c0fbff; }
.float-money { color: #4cd964; }

.float-loss {
  color: #ff6b6b;
}

@keyframes floatRise {
  0% { opacity: 0; transform: translateY(0) scale(0.7); }
  20% { opacity: 1; transform: translateY(-20rpx) scale(1.1); }
  100% { opacity: 0; transform: translateY(-120rpx) scale(0.95); }
}

@media (prefers-reduced-motion: reduce) {
  .float {
    animation: floatRiseQuiet 0.8s ease-out forwards;
  }
  @keyframes floatRiseQuiet {
    0% { opacity: 0; }
    20% { opacity: 1; }
    100% { opacity: 0; }
  }
}
</style>
