<script setup lang="ts">
/**
 * MenuPage — Beta-stage 图鉴 placeholder. Read-only summary of:
 *   - global stats (totalRuns / totalWins / unlocked jobs / totalMoneyEarned)
 *   - unlocked jobs (with jobsPlayed[id] count)
 *   - unlocked passive skills (S3-9)
 *
 * Reachable from job-select via the "图鉴" entry button. Back button uses
 * uni.navigateBack — this page is always pushed (never reLaunched-to), so
 * stack contains [job-select, menu].
 */
import { computed, onMounted, ref } from 'vue'
import { onUnload } from '@dcloudio/uni-app'
import { storeToRefs } from 'pinia'
import { useSaveStore } from '@/stores/save-store'
import { useJobStore } from '@/stores/job-store'
import { useProgressionStore } from '@/stores/progression-store'
import { usePassiveSkillStore } from '@/stores/passive-skill-store'
import { useEndingStore } from '@/stores/ending-store'
import { JOBS, getJobById } from '@/config/jobs'
import { getPassiveSkillById } from '@/types/passive-skill'
import { ENDINGS } from '@/types/ending'
import { formatMoney } from '@/utils/format'

const saveStore = useSaveStore()
const jobStore = useJobStore()
const progressionStore = useProgressionStore()
const passiveStore = usePassiveSkillStore()
const endingStore = useEndingStore()

const { stats } = storeToRefs(progressionStore)
const { unlockedIds: unlockedJobIds } = storeToRefs(jobStore)
const { unlockedIds: unlockedSkillIds } = storeToRefs(passiveStore)
const { unlockedIds: unlockedEndingIds } = storeToRefs(endingStore)

const initialized = ref(false)

onMounted(() => {
  // Defensive — menu page may be entered before save load on first render.
  // Re-load to guarantee stores reflect persisted state.
  saveStore.load()
  jobStore.init(saveStore.data)
  initialized.value = true
})

onUnload(() => {
  saveStore.save()
})

const statCards = computed(() => [
  { label: '通关', value: `${stats.value.totalWins} 次`, key: 'wins' },
  { label: '总尝试', value: `${stats.value.totalRuns} 次`, key: 'runs' },
  { label: '解锁职业', value: `${unlockedJobIds.value.length} / ${JOBS.length}`, key: 'jobs' },
  { label: '解锁结局', value: `${endingUnlockedCount.value} / ${ENDINGS.length}`, key: 'endings' },
  { label: '累计收入', value: `${formatMoney(stats.value.totalMoneyEarned)} 元`, key: 'money' }
])

const unlockedJobsDetail = computed(() =>
  unlockedJobIds.value
    .map((id) => getJobById(id))
    .filter((j): j is NonNullable<ReturnType<typeof getJobById>> => j != null)
    .map((job) => ({
      job,
      playCount: stats.value.jobsPlayed[job.id] ?? 0
    }))
)

const unlockedSkillsDetail = computed(() =>
  unlockedSkillIds.value
    .map((id) => getPassiveSkillById(id))
    .filter((s): s is NonNullable<ReturnType<typeof getPassiveSkillById>> => s != null)
)

/**
 * G-4: ending collection — every ending in catalog mapped to its lock state.
 * Locked endings show name as "???" to preserve discovery surprise.
 */
const endingsDetail = computed(() =>
  ENDINGS.map((e) => {
    const unlocked = unlockedEndingIds.value.includes(e.id)
    return {
      ending: e,
      unlocked,
      displayName: unlocked ? e.name : '???',
      displayDesc: unlocked ? e.description : '尚未解锁'
    }
  })
)

const endingUnlockedCount = computed(() => unlockedEndingIds.value.length)

function onBack() {
  uni.navigateBack({ delta: 1 })
}
</script>

<template>
  <view class="page">
    <view class="header">
      <text class="title">图鉴</text>
      <text class="subtitle">你的打工人生</text>
    </view>

    <view class="stats-grid">
      <view v-for="card in statCards" :key="card.key" class="stat-card">
        <text class="stat-value">{{ card.value }}</text>
        <text class="stat-label">{{ card.label }}</text>
      </view>
    </view>

    <view class="section">
      <text class="section-title">已解锁职业</text>
      <view v-if="unlockedJobsDetail.length === 0" class="empty-hint">
        <text>还没有解锁的职业</text>
      </view>
      <view v-else class="job-list">
        <view
          v-for="entry in unlockedJobsDetail"
          :key="entry.job.id"
          class="job-row"
          :data-job-id="entry.job.id"
        >
          <text class="job-icon">{{ entry.job.icon }}</text>
          <view class="job-info">
            <text class="job-name">{{ entry.job.name }}</text>
            <text class="job-count">玩过 {{ entry.playCount }} 次</text>
          </view>
        </view>
      </view>
    </view>

    <view class="section">
      <text class="section-title">已解锁被动技能</text>
      <view v-if="unlockedSkillsDetail.length === 0" class="empty-hint">
        <text>还没有解锁的被动技能</text>
      </view>
      <view v-else class="skill-list">
        <view
          v-for="skill in unlockedSkillsDetail"
          :key="skill.id"
          class="skill-row"
          :data-skill-id="skill.id"
        >
          <text class="skill-name">{{ skill.name }}</text>
          <text class="skill-desc">{{ skill.description }}</text>
        </view>
      </view>
    </view>

    <view class="section">
      <text class="section-title">结局收集 ({{ endingUnlockedCount }} / {{ ENDINGS.length }})</text>
      <view class="ending-list">
        <view
          v-for="entry in endingsDetail"
          :key="entry.ending.id"
          class="ending-row"
          :class="[
            { locked: !entry.unlocked },
            `rarity-${entry.ending.rarity}`
          ]"
          :data-ending-id="entry.ending.id"
        >
          <text class="ending-icon">{{ entry.unlocked ? entry.ending.icon : '🔒' }}</text>
          <view class="ending-info">
            <text class="ending-name">{{ entry.displayName }}</text>
            <text class="ending-desc">{{ entry.displayDesc }}</text>
          </view>
        </view>
      </view>
    </view>

    <button class="btn-back" @click="onBack">返回</button>
  </view>
</template>

<style scoped>
.page {
  min-height: 100vh;
  padding: 40rpx 32rpx 80rpx;
  display: flex;
  flex-direction: column;
  gap: 32rpx;
  background: linear-gradient(180deg, #0f0a26 0%, #1a1340 100%);
}

.header {
  text-align: center;
  display: flex;
  flex-direction: column;
  gap: 8rpx;
}

.title {
  font-size: 56rpx;
  font-weight: 800;
  color: #fff;
  letter-spacing: 6rpx;
}

.subtitle {
  font-size: 24rpx;
  color: #a8a4c0;
}

.stats-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16rpx;
}

.stat-card {
  padding: 24rpx 16rpx;
  border-radius: 20rpx;
  background: rgba(255, 255, 255, 0.04);
  border: 2rpx solid rgba(255, 255, 255, 0.08);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6rpx;
}

.stat-value {
  font-size: 40rpx;
  font-weight: 800;
  color: #ffd86f;
}

.stat-label {
  font-size: 22rpx;
  color: #a8a4c0;
}

.section {
  display: flex;
  flex-direction: column;
  gap: 12rpx;
}

.section-title {
  font-size: 28rpx;
  font-weight: 700;
  color: #fff;
  letter-spacing: 2rpx;
  border-left: 4rpx solid #ffd86f;
  padding-left: 12rpx;
}

.empty-hint {
  padding: 24rpx;
  text-align: center;
  font-size: 24rpx;
  color: #6e6a8a;
  border-radius: 16rpx;
  background: rgba(255, 255, 255, 0.02);
  border: 2rpx dashed rgba(255, 255, 255, 0.08);
}

.job-list,
.skill-list {
  display: flex;
  flex-direction: column;
  gap: 12rpx;
}

.job-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 16rpx;
  padding: 16rpx 20rpx;
  border-radius: 16rpx;
  background: rgba(255, 255, 255, 0.04);
  border: 2rpx solid rgba(255, 255, 255, 0.06);
}

.job-icon {
  font-size: 48rpx;
  width: 64rpx;
  text-align: center;
}

.job-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4rpx;
}

.job-name {
  font-size: 28rpx;
  font-weight: 600;
  color: #fff;
}

.job-count {
  font-size: 22rpx;
  color: #a8a4c0;
}

.skill-row {
  display: flex;
  flex-direction: column;
  gap: 6rpx;
  padding: 16rpx 20rpx;
  border-radius: 16rpx;
  background: linear-gradient(180deg, rgba(255, 214, 107, 0.1) 0%, rgba(245, 166, 35, 0.05) 100%);
  border: 2rpx solid rgba(255, 214, 107, 0.2);
}

/* G-4: ending collection */
.ending-list {
  display: flex;
  flex-direction: column;
  gap: 10rpx;
}

.ending-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 16rpx;
  padding: 14rpx 18rpx;
  border-radius: 16rpx;
  background: rgba(255, 255, 255, 0.04);
  border: 2rpx solid rgba(255, 255, 255, 0.06);
}

.ending-row.locked {
  opacity: 0.45;
}

.ending-row.rarity-rare:not(.locked) {
  border-color: rgba(159, 122, 234, 0.4);
}

.ending-row.rarity-legendary:not(.locked) {
  border-color: rgba(255, 214, 107, 0.5);
  background: linear-gradient(180deg, rgba(255, 214, 107, 0.12) 0%, rgba(245, 166, 35, 0.04) 100%);
}

.ending-row .ending-icon {
  font-size: 40rpx;
  width: 48rpx;
  text-align: center;
  flex-shrink: 0;
}

.ending-row .ending-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4rpx;
}

.ending-row .ending-name {
  font-size: 26rpx;
  font-weight: 700;
  color: #fff;
}

.ending-row.rarity-legendary:not(.locked) .ending-name {
  color: #ffd86f;
}

.ending-row.rarity-rare:not(.locked) .ending-name {
  color: #c4a5ff;
}

.ending-row .ending-desc {
  font-size: 20rpx;
  color: #a8a4c0;
  line-height: 1.35;
}

.skill-name {
  font-size: 28rpx;
  font-weight: 700;
  color: #ffd86f;
}

.skill-desc {
  font-size: 22rpx;
  color: #d8c8e8;
  line-height: 1.4;
}

.btn-back {
  margin-top: auto;
  padding: 28rpx 40rpx;
  border: none;
  border-radius: 999rpx;
  font-size: 30rpx;
  font-weight: 700;
  letter-spacing: 6rpx;
  color: #fff;
  min-height: 88rpx;
  background: linear-gradient(180deg, #5cc8ff 0%, #2789cf 100%);
  box-shadow: 0 10rpx 0 #1c5f99;
}

.btn-back:active {
  transform: translateY(4rpx);
}
</style>
