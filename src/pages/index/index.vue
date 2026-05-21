<script setup lang="ts">
/**
 * GameMain — Sprint 2 main game screen.
 *
 * Composes: DayBadge / ResourceBar (×3) / StatusChip (×0-2) / EventCard /
 * ChoiceButton (×2). State comes from stores; player input flows through
 * eventCardStore.selectChoice + commitResolve.
 *
 * Lifecycle: useGameSession() handles bootstrapping (load events, init resources,
 * start day 1). Death/win overlays render based on runStore.phase.
 */
import { computed, ref, watch } from 'vue'
import { onUnload } from '@dcloudio/uni-app'
import { storeToRefs } from 'pinia'
import { useResourceStore } from '@/stores/resource-store'
import { useStatusStore } from '@/stores/status-store'
import { useEventCardStore } from '@/stores/event-card-store'
import { useDayCycleStore } from '@/stores/day-cycle-store'
import { useRunStore } from '@/stores/run-store'
import { useSaveStore } from '@/stores/save-store'
import { useChoiceResolutionStore } from '@/stores/choice-resolution-store'
import { useGameSession } from '@/composables/useGameSession'
import { DAYS_PER_WEEK, TOTAL_WEEK_SALARY, DEFAULT_WEEKS_PER_CAREER } from '@/types/day-cycle'
import ResourceBar from '@/components/ResourceBar.vue'
import StatusChip from '@/components/StatusChip.vue'
import EventCard from '@/components/EventCard.vue'
import ChoiceButton from '@/components/ChoiceButton.vue'
import DayBadge from '@/components/DayBadge.vue'
import CareerBadge from '@/components/CareerBadge.vue'
import RiskDiceOverlay from '@/components/RiskDiceOverlay.vue'
import StatusOnboardingTip from '@/components/StatusOnboardingTip.vue'
import FloatingDelta from '@/components/FloatingDelta.vue'
import PromotionBanner from '@/components/PromotionBanner.vue'
import LowEnergyHint from '@/components/LowEnergyHint.vue'
import { useCareerStore } from '@/stores/career-store'
import { useSoundEffect } from '@/composables/useSoundEffect'
import type { RiskOutcome } from '@/types/resolve'
import type { ResourceTarget } from '@/types/resource'

useGameSession()
const saveStore = useSaveStore()

onUnload(() => {
  saveStore.save()
})

const resourceStore = useResourceStore()
const statusStore = useStatusStore()
const eventCardStore = useEventCardStore()
const dayCycleStore = useDayCycleStore()
const runStore = useRunStore()
const choiceResolutionStore = useChoiceResolutionStore()
const careerStore = useCareerStore()

const { resources, state: resourceState, lastResourceChange } = storeToRefs(resourceStore)
const { buff, debuff } = storeToRefs(statusStore)
const { currentCard } = storeToRefs(eventCardStore)
const { currentDay, currentWeekIndex, weeksPerCareer, dayName, eventsToday } = storeToRefs(dayCycleStore)
const { phase: runPhase, lastRunResult } = storeToRefs(runStore)
const { lastResult: lastChoiceResult } = storeToRefs(choiceResolutionStore)
const { lastPromotion, level: careerLevel, score: careerScore, title: careerTitle } = storeToRefs(careerStore)

const sfx = useSoundEffect()

// S4-8: clear promotion banner after 1.5s (matches CSS animation total duration)
const PROMOTION_BANNER_MS = 1500
watch(lastPromotion, (val) => {
  if (val == null) return
  setTimeout(() => {
    careerStore.lastPromotion = null
  }, PROMOTION_BANNER_MS)
})

// S4-9: low-energy nudge — surface shop hint when energy < threshold AND
// the player has at least cheapest consumable's worth of money. Hint
// auto-hides via reactive computed when energy recovers.
const LOW_ENERGY_THRESHOLD = 30
const MIN_MONEY_FOR_HINT = 10  // cheapest item: 心灵鸡汤 12; 蹭饭 0; show if has any chance
const showLowEnergyHint = computed(() => {
  if (resources.value.energy >= LOW_ENERGY_THRESHOLD) return false
  if (resources.value.money < MIN_MONEY_FOR_HINT) return false
  // Don't show during DYING/SETTLING — too late to help
  if (runPhase.value === 'DYING' || runPhase.value === 'SETTLING') return false
  return true
})

// Risk dice overlay — populated when a choice with risk resolves; auto-clears
// after the dice animation cycle completes (~2s, mirrors prototype v3 timing).
const RISK_DICE_DISMISS_MS = 2000
const riskOverlay = ref<{ outcome: RiskOutcome; detail?: string } | null>(null)

watch(lastChoiceResult, (val) => {
  if (val?.result.riskOutcome) {
    riskOverlay.value = {
      outcome: val.result.riskOutcome,
      detail: val.result.choiceText
    }
    setTimeout(() => {
      riskOverlay.value = null
    }, RISK_DICE_DISMISS_MS)
  }
})

// S3-7: first-time onboarding tip on first status acquisition.
// Trigger fires once per save: when (buff || debuff) appears AND
// firstStatusShown is falsy. After 1.5s the flag is persisted, suppressing
// the tip on every subsequent status — including across sessions (S2-7
// already proved firstStatusShown round-trips through SaveData).
const ONBOARDING_TIP_DURATION_MS = 1500
const onboardingTip = ref<{ text: string } | null>(null)

const activeStatus = computed(() => buff.value ?? debuff.value)

watch(activeStatus, (status) => {
  if (!status) return
  if (saveStore.data.firstStatusShown) return
  if (onboardingTip.value) return
  onboardingTip.value = { text: `新效果！持续 ${status.daysLeft} 天` }
  setTimeout(() => {
    onboardingTip.value = null
    saveStore.update({ firstStatusShown: true })
  }, ONBOARDING_TIP_DURATION_MS)
})

// H-1: health tutorial tip — fires once per save when health drops below
// HEALTH_TIP_THRESHOLD. Explains the CRISIS-drain mechanic before health
// hits zero so player has time to react.
const HEALTH_TIP_THRESHOLD = 80
watch(() => resources.value.health, (newHealth, oldHealth) => {
  if (newHealth >= HEALTH_TIP_THRESHOLD) return
  if (oldHealth != null && oldHealth < HEALTH_TIP_THRESHOLD) return  // already triggered this watch
  if (saveStore.data.firstHealthDropShown) return
  if (onboardingTip.value) return  // don't compete with status tip
  onboardingTip.value = {
    text: '健康下降了！心情持续低落会扣血，记得调节'
  }
  setTimeout(() => {
    onboardingTip.value = null
    saveStore.update({ firstHealthDropShown: true })
  }, ONBOARDING_TIP_DURATION_MS + 500)  // slightly longer — denser text
})

// S3-8: floating delta numbers on resource change. Each non-zero delta
// spawns a self-removing floating element. Money / energy / mood get
// distinct colors via FloatingDelta's :class binding.
const FLOAT_LIFETIME_MS = 1500
let floatIdCounter = 0
const floats = ref<Array<{ id: number; target: ResourceTarget; value: number }>>([])

function spawnFloat(target: ResourceTarget, value: number) {
  if (value === 0) return
  const id = ++floatIdCounter
  floats.value.push({ id, target, value })
  setTimeout(() => {
    floats.value = floats.value.filter((f) => f.id !== id)
  }, FLOAT_LIFETIME_MS)
}

watch(lastResourceChange, (change) => {
  if (!change) return
  for (const d of change.deltas) {
    spawnFloat(d.target, d.delta)
  }
})

// S3-8: phase-driven sound + screen effects.
// Death → death.mp3 (no-ops if asset missing). Win path resolves on settle page.
watch(runPhase, (phase, prev) => {
  if (phase === 'DYING' && prev !== 'DYING') {
    sfx.play('death')
  }
  if (phase === 'SETTLING' && prev === 'PLAYING') {
    // Reaching SETTLING from PLAYING means a win-path week-completed (death
    // path goes PLAYING → DYING → SETTLING). RunResult.won is the truth, but
    // it's set later inside endRun; the transition itself is a positive cue.
    sfx.play('day-end')
  }
})

// SFX hook for choice click — exposed for ChoiceButton via emit (already in S2-5).
function onChoiceClick() {
  sfx.play('click')
}

const charFace = computed(() => {
  if (resources.value.energy <= 20 || resources.value.mood <= 20) return '😵'
  if (resources.value.energy <= 40 && resources.value.mood <= 40) return '😩'
  if (resources.value.energy <= 40) return '😪'
  if (resources.value.mood <= 30) return '😠'
  if (resources.value.energy >= 70 && resources.value.mood >= 70) return '😎'
  if (resources.value.mood >= 70) return '😄'
  return '🙂'
})

const charClass = computed(() => {
  if (resources.value.energy <= 20 || resources.value.mood <= 20) return 'crisis'
  if (resources.value.energy <= 30 || resources.value.mood <= 30) return 'warning'
  return ''
})

const isFollowUp = computed(() => {
  // Identify followUp by phase — when phase is FOLLOW_UP we just shown a followUp card
  return currentCard.value?.phase === 'FOLLOW_UP'
})

const showDying = computed(() => runPhase.value === 'DYING')
const showSettling = computed(() => runPhase.value === 'SETTLING')

function pickA() {
  onChoiceClick()
  eventCardStore.selectChoice('A')
  // For Sprint 2 MVP, immediately commit (no separate resolve animation phase).
  // Future: UI animation triggers commitResolve after 1s.
  setTimeout(() => eventCardStore.commitResolve(), 1000)
}
function pickB() {
  onChoiceClick()
  eventCardStore.selectChoice('B')
  setTimeout(() => eventCardStore.commitResolve(), 1000)
}

function declineRevive() {
  runStore.declineRevive()
}

function onOpenShop() {
  uni.navigateTo({ url: '/subpackages/ui/shop/index' })
}

// On phase=SETTLING: finalize the run (computes RunResult + emits onRunEnded
// → progressionSystem.recordRun via run-store wiring), then navigate to settle
// page. The 800ms delay gives the player a beat to register the transition
// before the overlay disappears.
const SETTLE_NAVIGATION_DELAY_MS = 800
watch(showSettling, (val) => {
  if (!val || lastRunResult.value !== null) return
  setTimeout(() => {
    void import('@/stores/run-store').then(({ runManager }) => {
      if (runManager.getPhase() !== 'SETTLING') return
      const jobId = runManager.getCurrentJob() ?? 'programmer'
      void import('@/config/jobs').then(({ getJobById }) => {
        const job = getJobById(jobId)
        const weeksPerCareer = job?.weeksPerCareer ?? DEFAULT_WEEKS_PER_CAREER
        const stats = runManager.getRunStats()
        runManager.endRun(
          {
            // S4-1: survivalDays now counts across whole career; totalDays =
            // weeksPerCareer × DAYS_PER_WEEK; expectedMoney scales with weeks.
            survivalDays: (currentWeekIndex.value - 1) * DAYS_PER_WEEK + currentDay.value,
            totalDays: weeksPerCareer * DAYS_PER_WEEK,
            finalMoney: resources.value.money,
            expectedMoney: TOTAL_WEEK_SALARY * weeksPerCareer,
            totalChoices: stats.totalChoices,
            uniqueChoices: stats.uniqueChoices
          },
          { jobId, jobName: job?.name ?? '打工人' }
        )
        uni.navigateTo({ url: '/pages/settle/index' })
      })
    })
  }, SETTLE_NAVIGATION_DELAY_MS)
})

</script>

<template>
  <view
    class="page"
    :class="{
      'crisis-bg': resourceState === 'CRISIS',
      'death-shake': showDying
    }"
  >
    <!-- Top: Day badge -->
    <view class="top-section">
      <DayBadge
        :current-day="currentDay"
        :total-days="5"
        :current-week-index="currentWeekIndex"
        :weeks-per-career="weeksPerCareer"
      />
      <CareerBadge
        :level="careerLevel"
        :score="careerScore"
        :title="careerTitle"
      />
    </view>

    <!-- Character + Resources -->
    <view class="char-section">
      <view class="avatar" :class="charClass">{{ charFace }}</view>
      <view class="resources-stack">
        <ResourceBar type="health" :value="resources.health" />
        <ResourceBar type="energy" :value="resources.energy" />
        <ResourceBar type="mood" :value="resources.mood" />
        <ResourceBar type="money" :value="resources.money" />
      </view>
      <button class="btn-shop" data-test-id="shop-entry" @click="onOpenShop">🛒</button>
    </view>

    <!-- S4-9: low-energy shop nudge -->
    <LowEnergyHint
      v-if="showLowEnergyHint"
      :energy="resources.energy"
      :money="resources.money"
      @open-shop="onOpenShop"
    />

    <!-- Status chips -->
    <view class="status-bar">
      <StatusChip v-if="buff" :status="buff" />
      <StatusChip v-if="debuff" :status="debuff" />
      <StatusOnboardingTip v-if="onboardingTip" :text="onboardingTip.text" />
    </view>

    <!-- Event card -->
    <view class="card-area">
      <EventCard v-if="currentCard" :card="currentCard.card" :is-follow-up="isFollowUp" />
      <view v-else class="loading">
        <text class="loading-text">{{ dayName }} 准备中…</text>
      </view>
    </view>

    <!-- Counter -->
    <view v-if="currentCard" class="counter">
      — {{ eventsToday.done + 1 }} / {{ eventsToday.total }} —
    </view>

    <!-- Choices -->
    <view v-if="currentCard" class="choices">
      <ChoiceButton
        :choice="currentCard.card.choiceA"
        variant="a"
        :disabled="currentCard.phase === 'RESOLVING'"
        @pick="pickA"
      />
      <ChoiceButton
        :choice="currentCard.card.choiceB"
        variant="b"
        :disabled="currentCard.phase === 'RESOLVING'"
        @pick="pickB"
      />
    </view>

    <!-- Death overlay -->
    <view v-if="showDying" class="overlay overlay-death">
      <text class="overlay-emoji">💀</text>
      <text class="overlay-title">扛不住了</text>
      <text class="overlay-detail">你的{{ resources.energy <= 0 ? '身体' : '心情' }}已经撑不住</text>
      <button class="overlay-btn" @click="declineRevive">认了</button>
    </view>

    <!-- SETTLING transitional fade — page navigates to /pages/settle/ after finalize -->
    <view v-if="showSettling" class="overlay overlay-settling">
      <text class="overlay-title">正在结算…</text>
    </view>

    <!-- Risk dice overlay (auto-dismisses; blocks clicks via z-index 35) -->
    <RiskDiceOverlay
      v-if="riskOverlay"
      :outcome="riskOverlay.outcome"
      :detail="riskOverlay.detail"
    />

    <!-- S4-8: career promotion banner (auto-dismisses 1.5s) -->
    <PromotionBanner
      v-if="lastPromotion"
      :from-level="lastPromotion.fromLevel"
      :to-level="lastPromotion.toLevel"
      :title="lastPromotion.title"
      :new-salary-mul="careerStore.salaryMul"
    />

    <!-- Floating delta numbers (S3-8). Anchored to .floats-layer overlaying char-section. -->
    <view class="floats-layer" aria-hidden="true">
      <FloatingDelta
        v-for="float in floats"
        :key="float.id"
        :target="float.target"
        :value="float.value"
      />
    </view>
  </view>
</template>

<style scoped>
.page {
  position: relative;
  min-height: 100vh;
  padding: 24rpx;
  display: flex;
  flex-direction: column;
  gap: 16rpx;
  background:
    radial-gradient(ellipse at top, rgba(120, 80, 200, 0.15) 0%, transparent 60%),
    linear-gradient(160deg, #1e1b3a 0%, #0f0a26 100%);
  color: #eee;
}

.crisis-bg {
  animation: crisis 1.2s infinite;
}

@keyframes crisis {
  0%, 100% { background: linear-gradient(160deg, #1e1b3a 0%, #0f0a26 100%); }
  50% { background: linear-gradient(160deg, #3a1b2e 0%, #260a1e 100%); }
}

/* S3-8 AC-4: death shake + darken */
.death-shake {
  animation: pageShake 0.5s ease-out;
  filter: brightness(0.55) saturate(0.7);
}

@keyframes pageShake {
  0%, 100% { transform: translateX(0); }
  20% { transform: translateX(-8rpx) translateY(2rpx); }
  40% { transform: translateX(8rpx) translateY(-2rpx); }
  60% { transform: translateX(-6rpx) translateY(2rpx); }
  80% { transform: translateX(4rpx); }
}

@media (prefers-reduced-motion: reduce) {
  .death-shake { animation: none; }
  .crisis-bg { animation: none; }
}

/* S3-8 AC-1: floats layer — overlays char-section to anchor floating deltas */
.floats-layer {
  position: absolute;
  inset: 0;
  pointer-events: none;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 15;
}

.top-section {
  display: flex;
  flex-direction: column;
  gap: 12rpx;
}

.char-section {
  display: flex;
  align-items: center;
  gap: 24rpx;
}

.avatar {
  width: 120rpx;
  height: 120rpx;
  border-radius: 50%;
  background: linear-gradient(135deg, #6a4ea3 0%, #3a2659 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 72rpx;
  border: 4rpx solid rgba(180, 140, 255, 0.4);
  box-shadow: 0 8rpx 32rpx rgba(120, 80, 200, 0.4);
  flex-shrink: 0;
  transition: all 0.4s;
}

.avatar.crisis {
  border-color: #ff3b30;
  box-shadow: 0 0 48rpx rgba(255, 59, 48, 0.6);
  animation: shake 0.4s infinite;
}

.avatar.warning {
  border-color: #ffcc00;
  box-shadow: 0 0 32rpx rgba(255, 204, 0, 0.4);
}

@keyframes shake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-4rpx); }
  75% { transform: translateX(4rpx); }
}

.resources-stack {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 12rpx;
}

/* S4-5: shop entry button — small, top-right of char-section */
.btn-shop {
  flex-shrink: 0;
  width: 80rpx;
  height: 80rpx;
  padding: 0;
  border-radius: 50%;
  border: 2rpx solid rgba(255, 214, 107, 0.4);
  background: linear-gradient(135deg, #ffd66b, #ff7a1a);
  font-size: 36rpx;
  line-height: 80rpx;
  box-shadow: 0 6rpx 16rpx rgba(255, 122, 26, 0.4);
}

.btn-shop:active {
  transform: scale(0.92);
}

.status-bar {
  position: relative;
  display: flex;
  flex-wrap: wrap;
  gap: 12rpx;
  min-height: 88rpx;
  align-items: center;
}

.card-area {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24rpx 8rpx;
}

.loading {
  font-size: 32rpx;
  color: #b8a4d4;
  text-align: center;
}

.counter {
  text-align: center;
  font-size: 22rpx;
  color: #b8a4d4;
  letter-spacing: 8rpx;
}

.choices {
  display: flex;
  gap: 16rpx;
}

.overlay {
  position: fixed;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 48rpx;
  text-align: center;
  z-index: 30;
  animation: fadeIn 0.5s;
}

.overlay-death {
  background: radial-gradient(ellipse at center, rgba(60, 20, 30, 0.95) 0%, rgba(0, 0, 0, 0.95) 80%);
}

.overlay-win {
  background: radial-gradient(ellipse at center, rgba(20, 60, 40, 0.95) 0%, rgba(0, 30, 15, 0.95) 80%);
}

.overlay-settling {
  background: radial-gradient(ellipse at center, rgba(40, 30, 70, 0.95) 0%, rgba(15, 10, 38, 0.98) 80%);
}

.overlay-emoji {
  font-size: 180rpx;
  margin-bottom: 24rpx;
  display: block;
}

.overlay-title {
  font-size: 56rpx;
  font-weight: 800;
  display: block;
  margin-bottom: 16rpx;
  background: linear-gradient(180deg, #fff, #ffd86f);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

.overlay-detail {
  font-size: 28rpx;
  color: #c8b8d8;
  margin-bottom: 32rpx;
}

.overlay-stats {
  display: flex;
  flex-direction: column;
  gap: 12rpx;
  font-size: 26rpx;
  color: #d8c8e8;
  margin-bottom: 32rpx;
}

.overlay-rating {
  font-size: 32rpx;
  color: #ffd86f;
  font-weight: 700;
  margin-top: 12rpx;
}

.overlay-btn {
  padding: 28rpx 80rpx;
  border: none;
  border-radius: 999rpx;
  font-size: 32rpx;
  font-weight: 700;
  letter-spacing: 8rpx;
  background: linear-gradient(180deg, #ff6b6b 0%, #c92a2a 100%);
  color: #fff;
  box-shadow: 0 12rpx 0 #8b1a1a;
}

.overlay-btn:active { transform: translateY(6rpx); }

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}
</style>
