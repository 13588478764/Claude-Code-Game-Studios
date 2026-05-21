# S3-2: 职业选择页（5 职业卡 + 推荐高亮 + 解锁条件展示）

> **Sprint**: 3 | **Status**: Done | **Layer**: Presentation (Alpha) | **Type**: UI | **Owner**: ui-programmer | **Estimate**: 1.5 days
> **TR-ID**: pending | **Manifest Version**: N/A

## Quick-Spec（lite design）

**意图**：玩家进入游戏后第一个看到的页面。展示 5 个职业（intern/programmer/sales/designer/runner），高亮推荐的，灰显示锁定的（含解锁条件文案）。

**视觉**：
- 标题 "选份工" + 全局 stats 简显示（"已通关 X 局 · 解锁 Y 个职业"）
- 5 个 JobCard 纵向排列（或 2×3 grid 看屏幕高度）
- 已解锁 + 推荐：金色边框 + 跳动
- 已解锁 非推荐：默认样式
- 锁定：灰底 + 锁图标 + 解锁条件文案

**交互**：
- tap 解锁职业 → runManager.selectJob(jobId) → uni.navigateTo('/pages/index/index')
- tap 锁定职业 → 无反应或 toast "条件未满足"

## Context

**ADRs**:
- **ADR-003**（Service emit → Store subscribe）— 用 storeToRefs 订阅 jobStore + saveStore

**Engine**: uni-app + Vue 3 + TypeScript strict | **Risk**: LOW

## Acceptance Criteria

- [x] AC-1: `pages/job-select/index.vue` 新页面 + `pages.json` 配置路由（首位 → 启动页）
- [x] AC-2: 渲染 5 个 JobCard（intern/programmer/sales/designer/runner，从 jobs.ts 获取）
- [x] AC-3: 已解锁职业（jobStore.unlockedIds）正常显示
- [x] AC-4: 锁定职业灰显示 + 解锁条件文案（"通关 1 次解锁" / "累计赚到 200 元解锁" / "被炒 3 次解锁" / 含 achievement 4 类型）
- [x] AC-5: 推荐职业（jobStore.getRecommendations(2)）金色边框 + glow 动画 + "推荐" badge
- [x] AC-6: tap 已解锁职业 → runStore.selectJob → uni.navigateTo /pages/index/index
- [x] AC-7: tap 锁定职业 → uni.showToast "条件未满足" 1.2s
- [x] AC-8: 顶部显示 stats 概览（totalWins / unlocked count / total）
- [x] AC-9: 触控热区 ≥ 88rpx（min-height: 88rpx 在 .job-card）

## Implementation Notes

### 文件
- `src/pages/job-select/index.vue` — 主页面
- `src/components/JobCard.vue` — 单个职业卡
- 修改 `src/pages.json` — 添加 job-select 路由
- 修改 `src/main.ts` 或 `src/manifest.json` — 启动页指向 job-select
- 测试：组件 test 难做（需要 mock store）；focus 验证逻辑层 + 视觉手测

### JobCard.vue Props
```typescript
defineProps<{
  job: JobConfig
  unlocked: boolean
  recommended: boolean
}>()
defineEmits<{
  (e: 'select', jobId: string): void
}>()
```

### Page 结构
```vue
<view class="page">
  <view class="header">
    <text class="title">选份工</text>
    <text class="stats">已通关 {{ totalWins }} 局 · 解锁 {{ unlockedCount }} 职业</text>
  </view>
  <view class="jobs-list">
    <JobCard
      v-for="job in allJobs"
      :key="job.id"
      :job="job"
      :unlocked="isUnlocked(job.id)"
      :recommended="isRecommended(job.id)"
      @select="onSelect"
    />
  </view>
</view>
```

### 路由
```json
// pages.json
{
  "pages": [
    { "path": "pages/job-select/index", "style": { "navigationBarTitleText": "选份工" } },
    { "path": "pages/index/index", "style": { "navigationBarTitleText": "打工轮回" } }
  ]
}
```

启动页改为 `pages/job-select/index`。

## Out of Scope

- **S3-1** 进度系统：本故事仅消费 stats，不更新
- **S3-3** 结算页面：本故事不接结算返回逻辑
- **S3-4** 多页面导航：本故事仅 navigateTo 到 game-main，不处理 game-main → settle → job-select 完整链
- **S3-10** 图鉴页：本故事不导航到图鉴

## QA Test Cases

```
AC-3: 已解锁职业渲染
- Setup: 全新存档（默认 jobUnlocks=['intern', 'programmer']）
- When: mount JobSelectPage
- Verify: 看到 5 个 JobCard；intern + programmer 正常样式；其他 3 个灰底

AC-4: 解锁条件文案
- Verify: sales 灰卡显示"通关 1 次解锁"
- Verify: designer 灰卡显示"赚到 200 元解锁"
- Verify: runner 灰卡显示"被炒 3 次解锁"

AC-5: 推荐高亮
- Setup: stats.jobsPlayed.programmer=5（频繁玩） + intern=0（never played）
- When: getRecommendations(2)
- Verify: intern 排第一推荐 + 金色边框 glow 显示

AC-6: 选择导航
- Setup: 已解锁 programmer
- When: tap programmer card
- Verify: runManager.selectJob('programmer') 调用；uni.navigateTo('/pages/index/index') 调用

AC-7: 锁定职业不响应
- Setup: sales 锁定（unlock 条件未满足）
- When: tap sales card
- Verify: runManager.selectJob 未调用；toast 显示或无任何反应
```

## Test Evidence

**Story Type**: UI
**Required**:
- `production/qa/evidence/s3-2-job-select.md` — 截图 + 手测 checklist + sign-off（DEFERRED：用户未搭建小程序开发环境）
- 可选：`tests/component/job-card.test.ts` — JobCard 组件单测（推荐高亮/锁定状态切换）

**Status**: [x] `tests/component/job-card.test.ts` 已创建（12 tests，覆盖 3 渲染状态 + 4 unlock condition 文案 + tap 路由 + data hook）

## Dependencies

- 前置: S1-10（jobRotationSystem + jobs.ts）✓ + S3-1（stats 数据源）✓
- 阻塞: S3-4（多页面导航集成）

## Completion Notes (2026-05-19)

**Files created**:
- `src/components/JobCard.vue` — props {job, unlocked, recommended} + emits {select, lockedTap}; 3 渲染状态 + glow 动画
- `src/pages/job-select/index.vue` — 启动页：onMounted 时 saveStore.load + jobStore.init + getRecommendations(2)
- `tests/component/job-card.test.ts` — 12 component tests

**Files modified**:
- `src/pages.json` — job-select 移至 pages[0]（uni-app 启动页约定）；preloadRule 调整为 job-select 触发 events 分包预加载

**Design decisions**:
- 推荐高亮**只**显示已解锁的职业（locked + recommended → 视觉上仍按 locked 渲染，吸取 jobStore.getRecommendations() 在 init 后只返回 unlocked 的语义）
- recommendedIds 在 onMounted 时**计算一次**并存 ref，避免 getRecommendations 内部 random 排序导致每次 render 都重新洗牌
- onLockedTap 用 uni.showToast 1.2s 给予明确反馈而非沉默
- 触控热区: .job-card 设 min-height: 88rpx（44px × 2 dpr）满足 AC-9
- 没有改 App.vue：saveStore.load 移到了 entry page mounted hook（避免 launch hook 与 Pinia 激活时序问题）

**Gates**:
- 314/314 tests pass（302 → 314，+12 新组件测试）
- type-check clean
- mp-weixin build 340KB（远低于 2MB 主包限制）

**Manual verification deferred**: 视觉/动画/手势在小程序 simulator 待 S3-5 smoke 与用户配置开发工具后验证。
