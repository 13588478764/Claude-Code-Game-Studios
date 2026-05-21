<script setup lang="ts">
/**
 * SettlePage — Sprint 3 run-end summary screen.
 *
 * Reads runStore.lastRunResult (populated by runManager.endRun before
 * navigation). Shows rating + stats + optional unlock toast + 2 buttons
 * (再来一局 / 换份工).
 *
 * Replay/switch use uni.reLaunch (not navigateBack) so the game-main page
 * mounts fresh — onMounted re-runs and restores game state cleanly.
 */
import { computed, onMounted, ref } from 'vue'
import { onUnload } from '@dcloudio/uni-app'
import { storeToRefs } from 'pinia'
import { useRunStore } from '@/stores/run-store'
import { useProgressionStore } from '@/stores/progression-store'
import { useSaveStore } from '@/stores/save-store'
import { useCareerStore } from '@/stores/career-store'
import { useEndingStore } from '@/stores/ending-store'
import { formatMoney } from '@/utils/format'

const runStore = useRunStore()
const progressionStore = useProgressionStore()
const saveStore = useSaveStore()
const careerStore = useCareerStore()
const endingStore = useEndingStore()

onUnload(() => {
  saveStore.save()
})

const { lastRunResult } = storeToRefs(runStore)
const { recentlyUnlocked } = storeToRefs(progressionStore)
const { level: finalCareerLevel, title: finalCareerTitle } = storeToRefs(careerStore)
const { lastEnding, lastIsFirstTime: endingIsFirstTime } = storeToRefs(endingStore)

// Sticky copy of unlock at mount time — toast otherwise flickers off after 1.5s
const unlockedAtMount = ref<typeof recentlyUnlocked.value>(null)

onMounted(() => {
  unlockedAtMount.value = recentlyUnlocked.value
})

const headerEmoji = computed(() => {
  if (!lastRunResult.value) return '…'
  return lastRunResult.value.won ? '🎉' : '💔'
})

const title = computed(() => {
  if (!lastRunResult.value) return '加载中…'
  return lastRunResult.value.won ? '撑过了一周！' : '中途折戟'
})

const ratingClass = computed(() => {
  const r = lastRunResult.value?.rating
  if (!r) return ''
  return `rating-${r.toLowerCase()}`
})

const playTimeText = computed(() => {
  if (!lastRunResult.value) return ''
  const r = lastRunResult.value
  return `${r.survivalDays} / ${r.totalDays} 天`
})

const displayStats = computed(() => {
  const r = lastRunResult.value
  if (!r) return []
  return [
    { label: '存活', value: playTimeText.value },
    { label: '到手钞票', value: `${formatMoney(r.finalMoney)} 元` },
    { label: '做出选择', value: `${r.totalChoices} 次` },
    { label: '独特事件', value: `${r.uniqueChoices} 个` }
  ]
})

function onReplay() {
  const jobId = lastRunResult.value?.jobId
  if (!jobId) {
    uni.reLaunch({ url: '/pages/job-select/index' })
    return
  }
  runStore.selectJob(jobId)
  uni.reLaunch({ url: '/pages/index/index' })
}

function onSwitch() {
  uni.reLaunch({ url: '/pages/job-select/index' })
}
</script>

<template>
  <view class="page" :class="{ 'won-bg': lastRunResult?.won, 'lost-bg': lastRunResult && !lastRunResult.won }">
    <view v-if="lastRunResult" class="content">
      <view class="header">
        <text class="emoji">{{ headerEmoji }}</text>
        <text class="title">{{ title }}</text>
        <text class="job-name">{{ lastRunResult.jobName }} · {{ playTimeText }}</text>
      </view>

      <view class="rating-display">
        <text class="rating-grade" :class="ratingClass">{{ lastRunResult.rating }}</text>
        <text class="rating-label">{{ lastRunResult.ratingLabel }}</text>
        <text class="career-final">最终职级 · Lv {{ finalCareerLevel }} · {{ finalCareerTitle }}</text>
      </view>

      <view v-if="lastEnding" class="ending-display" :class="`rarity-${lastEnding.rarity}`">
        <text class="ending-icon">{{ lastEnding.icon }}</text>
        <view class="ending-info">
          <view class="ending-title-row">
            <text class="ending-name">{{ lastEnding.name }}</text>
            <text v-if="endingIsFirstTime" class="new-ending-badge">🎉 新结局！</text>
          </view>
          <text class="ending-desc">{{ lastEnding.description }}</text>
        </view>
      </view>

      <view class="stats-grid">
        <view v-for="stat in displayStats" :key="stat.label" class="stat-row">
          <text class="stat-label">{{ stat.label }}</text>
          <text class="stat-value">{{ stat.value }}</text>
        </view>
      </view>

      <view v-if="unlockedAtMount" class="unlock-toast">
        <text>🎊 解锁了新职业：{{ unlockedAtMount.name }}</text>
      </view>

      <view class="actions">
        <button class="btn btn-replay" @click="onReplay">再来一局</button>
        <button class="btn btn-switch" @click="onSwitch">换份工</button>
      </view>
    </view>

    <view v-else class="loading">
      <text>结算中…</text>
    </view>
  </view>
</template>

<style scoped>
.page {
  min-height: 100vh;
  padding: 56rpx 32rpx 80rpx;
  display: flex;
  flex-direction: column;
  background: #0f0a26;
}

.won-bg {
  background:
    radial-gradient(ellipse at top, rgba(255, 200, 80, 0.18) 0%, transparent 60%),
    linear-gradient(180deg, #1e1b3a 0%, #0f0a26 100%);
}

.lost-bg {
  background:
    radial-gradient(ellipse at top, rgba(180, 60, 80, 0.18) 0%, transparent 60%),
    linear-gradient(180deg, #2a0f1f 0%, #0f0a26 100%);
}

.content {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 36rpx;
}

.header {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12rpx;
}

.emoji {
  font-size: 160rpx;
  line-height: 1;
  display: block;
  animation: bounce 0.8s ease-out;
}

.title {
  font-size: 56rpx;
  font-weight: 800;
  letter-spacing: 4rpx;
  background: linear-gradient(180deg, #fff 0%, #ffd86f 100%);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

.job-name {
  font-size: 24rpx;
  color: #b8a4d4;
  letter-spacing: 2rpx;
}

.rating-display {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10rpx;
  padding: 20rpx 60rpx;
  border-radius: 32rpx;
  background: rgba(255, 255, 255, 0.04);
  border: 2rpx solid rgba(255, 216, 111, 0.3);
}

.rating-grade {
  font-size: 180rpx;
  font-weight: 900;
  line-height: 1;
  background: linear-gradient(180deg, #ffe89a 0%, #f5a623 50%, #c97a18 100%);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  filter: drop-shadow(0 6rpx 12rpx rgba(245, 166, 35, 0.5));
  animation: glow 1.6s ease-in-out infinite alternate;
}

.rating-grade.rating-d {
  background: linear-gradient(180deg, #999 0%, #555 100%);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  filter: none;
  animation: none;
}

.rating-label {
  font-size: 32rpx;
  font-weight: 700;
  color: #fff;
  letter-spacing: 6rpx;
}

.career-final {
  margin-top: 8rpx;
  font-size: 22rpx;
  font-weight: 600;
  color: #ffd86f;
  letter-spacing: 2rpx;
  padding: 4rpx 16rpx;
  border-radius: 999rpx;
  background: rgba(255, 214, 107, 0.15);
}

/* G-3: ending display block */
.ending-display {
  width: 100%;
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 20rpx;
  padding: 24rpx 28rpx;
  border-radius: 24rpx;
  border: 2rpx solid rgba(255, 255, 255, 0.08);
  background: rgba(255, 255, 255, 0.04);
}

.ending-display.rarity-rare {
  border-color: rgba(159, 122, 234, 0.4);
  background: linear-gradient(180deg, rgba(159, 122, 234, 0.12) 0%, rgba(159, 122, 234, 0.04) 100%);
}

.ending-display.rarity-legendary {
  border-color: rgba(255, 214, 107, 0.5);
  background: linear-gradient(180deg, rgba(255, 214, 107, 0.18) 0%, rgba(245, 166, 35, 0.08) 100%);
  box-shadow: 0 0 32rpx rgba(255, 214, 107, 0.3);
}

.ending-icon {
  font-size: 64rpx;
  line-height: 1;
  flex-shrink: 0;
}

.ending-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 6rpx;
}

.ending-title-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 12rpx;
  flex-wrap: wrap;
}

.ending-name {
  font-size: 32rpx;
  font-weight: 800;
  color: #fff;
  letter-spacing: 2rpx;
}

.new-ending-badge {
  font-size: 20rpx;
  font-weight: 700;
  padding: 4rpx 12rpx;
  border-radius: 999rpx;
  background: linear-gradient(180deg, #4cd964, #34a04a);
  color: #fff;
  letter-spacing: 1rpx;
  animation: badgePulse 1.6s ease-in-out infinite;
}

@keyframes badgePulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.08); }
}

.rarity-legendary .ending-name {
  color: #ffd86f;
}

.rarity-rare .ending-name {
  color: #c4a5ff;
}

.ending-desc {
  font-size: 22rpx;
  color: #b8a4d4;
  line-height: 1.4;
}

.stats-grid {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 16rpx;
  padding: 24rpx 32rpx;
  border-radius: 24rpx;
  background: rgba(255, 255, 255, 0.04);
}

.stat-row {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
}

.stat-label {
  font-size: 26rpx;
  color: #b8a4d4;
}

.stat-value {
  font-size: 28rpx;
  color: #fff;
  font-weight: 600;
}

.unlock-toast {
  padding: 20rpx 32rpx;
  border-radius: 999rpx;
  background: linear-gradient(180deg, #ffd66b 0%, #f5a623 100%);
  color: #5a3a00;
  font-size: 26rpx;
  font-weight: 700;
  box-shadow: 0 8rpx 32rpx rgba(245, 166, 35, 0.4);
  animation: pulse 1.6s ease-in-out infinite;
}

.actions {
  width: 100%;
  display: flex;
  flex-direction: row;
  gap: 16rpx;
  margin-top: auto;
}

.btn {
  flex: 1;
  padding: 28rpx 24rpx;
  border: none;
  border-radius: 24rpx;
  font-size: 30rpx;
  font-weight: 700;
  letter-spacing: 4rpx;
  color: #fff;
  min-height: 88rpx;
}

.btn-replay {
  background: linear-gradient(180deg, #ff6b6b 0%, #c92a2a 100%);
  box-shadow: 0 10rpx 0 #8b1a1a;
}

.btn-switch {
  background: linear-gradient(180deg, #5cc8ff 0%, #2789cf 100%);
  box-shadow: 0 10rpx 0 #1c5f99;
}

.btn:active {
  transform: translateY(4rpx);
}

.loading {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32rpx;
  color: #b8a4d4;
}

@keyframes bounce {
  0% { transform: scale(0.4); opacity: 0; }
  60% { transform: scale(1.15); opacity: 1; }
  100% { transform: scale(1); opacity: 1; }
}

@keyframes glow {
  from { filter: drop-shadow(0 6rpx 12rpx rgba(245, 166, 35, 0.5)); }
  to { filter: drop-shadow(0 6rpx 24rpx rgba(255, 230, 130, 0.85)); }
}

@keyframes pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.05); }
}
</style>
