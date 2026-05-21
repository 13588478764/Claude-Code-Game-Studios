<script setup lang="ts">
/**
 * JobSelectPage — Sprint 3 entry screen.
 *
 * Renders all 5 jobs from config; highlights the top-2 recommendations
 * (computed once on mount to avoid re-shuffling on every render). Tap on
 * an unlocked card calls runStore.selectJob and navigateTo game-main.
 *
 * Save initialization happens here because this is the first user-visible
 * page — saveStore.load() + jobStore.init() must complete before any
 * down-stream store reads valid unlockedIds.
 */
import { computed, onMounted, ref } from 'vue'
import { onUnload } from '@dcloudio/uni-app'
import { storeToRefs } from 'pinia'
import { useSaveStore } from '@/stores/save-store'
import { useJobStore } from '@/stores/job-store'
import { useRunStore } from '@/stores/run-store'
import { useProgressionStore } from '@/stores/progression-store'
import { JOBS } from '@/config/jobs'
import JobCard from '@/components/JobCard.vue'

const saveStore = useSaveStore()
const jobStore = useJobStore()
const runStore = useRunStore()
const progressionStore = useProgressionStore()

const { unlockedIds } = storeToRefs(jobStore)
const { stats } = storeToRefs(progressionStore)

const allJobs = JOBS

const recommendedIds = ref<string[]>([])

onMounted(() => {
  saveStore.load()
  jobStore.init(saveStore.data)
  recommendedIds.value = jobStore.getRecommendations(2).map((j) => j.id)
})

// Persist save on page unload (defensive — most writes already commit through
// saveService directly, but this guards against unsaved profile field mutations).
onUnload(() => {
  saveStore.save()
})

const totalWins = computed(() => stats.value.totalWins)
const unlockedCount = computed(() => unlockedIds.value.length)

function isUnlocked(id: string): boolean {
  return unlockedIds.value.includes(id)
}

function isRecommended(id: string): boolean {
  return recommendedIds.value.includes(id)
}

function onSelect(jobId: string): void {
  runStore.selectJob(jobId)
  uni.navigateTo({ url: '/pages/index/index' })
}

function onLockedTap(jobId: string): void {
  const job = allJobs.find((j) => j.id === jobId)
  if (!job) return
  uni.showToast({
    title: '条件未满足',
    icon: 'none',
    duration: 1200
  })
}

function onOpenMenu(): void {
  uni.navigateTo({ url: '/subpackages/ui/menu/index' })
}
</script>

<template>
  <view class="page">
    <view class="header">
      <text class="title">选份工</text>
      <text class="subtitle">已通关 {{ totalWins }} 局 · 解锁 {{ unlockedCount }} / {{ allJobs.length }} 职业</text>
      <button class="btn-menu" data-test-id="menu-entry" @click="onOpenMenu">📖 图鉴</button>
    </view>

    <view class="jobs-list">
      <JobCard
        v-for="job in allJobs"
        :key="job.id"
        :job="job"
        :unlocked="isUnlocked(job.id)"
        :recommended="isRecommended(job.id)"
        @select="onSelect"
        @locked-tap="onLockedTap"
      />
    </view>

    <view class="footer">
      <text class="hint">点击解锁的职业开始打工</text>
    </view>
  </view>
</template>

<style scoped>
.page {
  min-height: 100vh;
  padding: 40rpx 32rpx 80rpx;
  background: linear-gradient(180deg, #0f0a26 0%, #1a1340 100%);
  display: flex;
  flex-direction: column;
}

.header {
  margin-bottom: 32rpx;
  text-align: center;
  display: flex;
  flex-direction: column;
  gap: 12rpx;
}

.title {
  font-size: 56rpx;
  font-weight: 800;
  color: #fff;
  letter-spacing: 4rpx;
}

.subtitle {
  font-size: 24rpx;
  color: #a8a4c0;
}

.btn-menu {
  margin-top: 16rpx;
  align-self: center;
  padding: 12rpx 32rpx;
  border: 2rpx solid rgba(255, 214, 107, 0.3);
  border-radius: 999rpx;
  font-size: 22rpx;
  font-weight: 600;
  color: #ffd86f;
  background: rgba(255, 214, 107, 0.08);
  letter-spacing: 2rpx;
  min-height: 56rpx;
  line-height: 1;
}

.btn-menu:active {
  transform: scale(0.96);
}

.jobs-list {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.footer {
  margin-top: 32rpx;
  text-align: center;
}

.hint {
  font-size: 22rpx;
  color: #6e6a8a;
}
</style>
