# S3-3: 完整结算页面（替换 S2-5 占位 overlay）

> **Sprint**: 3 | **Status**: Done | **Layer**: Presentation (Alpha) | **Type**: UI（次 Logic for rating display）| **Owner**: ui-programmer | **Estimate**: 1.5 days
> **TR-ID**: pending | **Manifest Version**: N/A

## Quick-Spec（lite design）

**意图**：替换 Sprint 2 game-main 中的占位 overlay，提供完整结算体验：rating 大字 + RunResult 全部 stats + 解锁通知 + 双行动按钮。

**视觉**（对齐 prototype v3 win-overlay / death-overlay）：
- 顶部：动画 emoji（🎉 win / 💀 dead-energy / 🤬 dead-mood）
- 标题大字（rating-derived 文案："撑过了一周！" / "燃尽了" / "暴走离职"）
- Rating 大字（S/A/B/C/D + 评级文案"卷王"等，渐变金）
- Stats 列表：总收入 / 选择次数 / 独特事件 / 用时
- 解锁通知 toast（如 RunResult 触发了 unlock）
- 双按钮：「再来一局」（同职业）/「换份工」（→ job-select）

**交互**：
- 进入页：从 runStore.lastRunResult 读取（已由 S2-4 填充）
- 解锁通知：检查 progressionStore.recentlyUnlocked → 显示 toast 1.5s
- 「再来一局」→ runManager 重置 + selectJob(同 jobId) + startPlaying → navigateBack to game-main
- 「换份工」→ uni.navigateBack to job-select

## Context

**ADRs**:
- **ADR-003**（Service emit → Store subscribe）

**Engine**: uni-app + Vue 3 + TypeScript strict | **Risk**: LOW

## Acceptance Criteria

- [x] AC-1: `pages/settle/index.vue` 新页面 + pages.json 路由配置
- [x] AC-2: 进入页时从 runStore.lastRunResult 读取数据并渲染
- [x] AC-3: rating 大字显示正确（runResult.rating + ratingLabel）+ D 级独立 monochrome class
- [x] AC-4: stats 列表渲染（survival 天数 / finalMoney / totalChoices / uniqueChoices）
- [x] AC-5: 通关 vs 死亡：标题（撑过了一周！/ 中途折戟）+ emoji（🎉/💔）+ 背景渐变颜色不同
- [x] AC-6: 解锁通知：从 progressionStore.recentlyUnlocked 读取（onMounted 时快照，避免 1.5s timeout 后消失）
- [x] AC-7: 「再来一局」按钮：runStore.selectJob(jobId) + uni.reLaunch /pages/index/index（详见 Completion Notes 关于 reLaunch vs navigateBack 决策）
- [x] AC-8: 「换份工」按钮：uni.reLaunch /pages/job-select/index
- [x] AC-9: game-main 移除 SETTLING overlay → 替换为 "正在结算…" 短暂 fade + watch on phase=SETTLING 触发 endRun + navigateTo settle
- [x] AC-10: Rating 视觉对齐 prototype v3 风格（渐变金 + 180rpx 大字 + glow 动画 + drop-shadow）

## Implementation Notes

### 文件
- `src/pages/settle/index.vue` — 主结算页
- 修改 `src/pages.json` — 添加 settle 路由
- 修改 `src/pages/index/index.vue` — 移除 overlay；监听 phase=SETTLING → navigateTo settle
- 修改 `src/stores/progression-store.ts` — 暴露 recentlyUnlocked ref（onJobUnlocked 监听）

### Page 结构
```vue
<view class="page">
  <view class="header">
    <text class="emoji">{{ headerEmoji }}</text>
    <text class="title">{{ title }}</text>
  </view>
  <view class="rating-display">
    <text class="rating-grade">{{ result.rating }}</text>
    <text class="rating-label">{{ result.ratingLabel }}</text>
  </view>
  <view class="stats-grid">
    <view class="stat-row" v-for="stat in displayStats" :key="stat.label">
      <text class="stat-label">{{ stat.label }}</text>
      <text class="stat-value">{{ stat.value }}</text>
    </view>
  </view>
  <view v-if="unlockedJob" class="unlock-toast">
    🎊 解锁了新职业：{{ unlockedJob.name }}
  </view>
  <view class="actions">
    <button class="btn btn-replay" @click="onReplay">再来一局</button>
    <button class="btn btn-switch" @click="onSwitch">换份工</button>
  </view>
</view>
```

### Store 改造
progression-store 加 recentlyUnlocked：
```typescript
const recentlyUnlocked = ref<JobConfig | null>(null)

progressionSystem.onJobUnlocked.on(({ jobId }) => {
  recentlyUnlocked.value = getJobById(jobId)
  setTimeout(() => recentlyUnlocked.value = null, 1500)
})
```

### game-main 集成
```typescript
// pages/index/index.vue
watch(runPhase, (phase) => {
  if (phase === 'SETTLING') {
    setTimeout(() => uni.navigateTo({ url: '/pages/settle/index' }), 1000)
  }
})
```

## Out of Scope

- **S3-1** progressionSystem 实现：本故事仅消费 recentlyUnlocked
- **S3-2** 职业选择页：本故事不渲染 job select
- **S3-4** 多页面导航完整流程：本故事仅 navigateTo settle，复杂导航 S3-4 处理
- 完整成就解锁动画（Sprint 4 / Beta）

## QA Test Cases

```
AC-3: rating 显示
- Setup: lastRunResult={ rating:'S', ratingLabel:'卷王', ... }
- When: mount settle page
- Verify: 看到 'S' + '卷王' 大字

AC-5: 通关 vs 死亡
- Setup: lastRunResult.won=true → header emoji='🎉' / title='撑过了一周！'
- Setup: lastRunResult.won=false + finalMoney→energy depleted → emoji='💀' / title='燃尽了'

AC-6: 解锁通知
- Setup: progressionStore.recentlyUnlocked={ id:'sales', name:'销售' }
- When: mount settle
- Verify: 看到 toast "🎊 解锁了新职业：销售"
- Verify: 1.5s 后 toast 消失

AC-7: 再来一局
- Setup: lastRunResult.jobId='programmer'
- When: 点击「再来一局」
- Verify: runManager.selectJob('programmer') 调用 + navigateBack 到 game-main + run state 重置

AC-8: 换份工
- When: 点击「换份工」
- Verify: uni.navigateBack 到 job-select page

AC-9: phase=SETTLING 触发 navigateTo
- Setup: game-main 监听 phase
- When: phase 变 SETTLING
- Verify: uni.navigateTo('/pages/settle/index') 1s 后调用
```

## Test Evidence

**Story Type**: UI（次 Logic）
**Required**:
- `production/qa/evidence/s3-3-settle-page.md` — 截图（通关/死亡两种状态各一组）+ 手测 checklist + sign-off（DEFERRED：用户未搭建小程序开发环境）
- 可选：`tests/component/settle-page.test.ts` — rating 显示 + 按钮 emit 单测

**Status**: [x] `tests/component/settle-page.test.ts` 已创建（12 tests，覆盖 rendering/unlock-toast/button-routing 三个 describe block）

## Dependencies

- 前置: S2-4（runManager.lastRunResult）✓ + S3-1（progressionStore.recentlyUnlocked）✓
- 阻塞: S3-4（多页面导航完整流程）

## Completion Notes (2026-05-19)

**Files created**:
- `src/pages/settle/index.vue` — 完整结算页（rating 渐变金大字 + bounce emoji + stats grid + unlock toast + 双按钮）
- `tests/component/settle-page.test.ts` — 12 component tests

**Files modified**:
- `src/pages.json` — 添加 settle 路由（pages[2]）
- `src/pages/index/index.vue` — 移除 SETTLING overlay；watch phase=SETTLING → endRun(动态 jobId/jobName from getCurrentJob + getJobById) → 800ms 后 uni.navigateTo settle
- `src/composables/useGameSession.ts` — 改用 runManager.getCurrentJob() 读取 jobId（不再硬编码 'programmer'）；bootstrap 条件支持 INITIALIZING phase（job-select tap 后到达 game-main 时的状态）

**Design decisions**:
- **使用 uni.reLaunch 代替 navigateBack**（与 AC-7/AC-8 文字描述偏离，但功能等价）。原因：navigateBack 复用页面实例，game-main 的 onMounted 不会重新触发，无法重置 resourceManager / runManager / dayCycleSystem 状态；reLaunch 关闭所有页面打开新实例，确保 game-main 干净启动。等价于"返回 game-main"语义但更可靠。
- **unlockedAtMount 快照**：onMounted 时把 progressionStore.recentlyUnlocked 复制到本地 ref，避免 1.5s 后 store 自动清空导致 toast 提前消失。
- **endRun 动态 jobInfo**：从 runManager.getCurrentJob() + getJobById 查 jobName，移除 'programmer'/'程序员' 硬编码（解锁了多职业 e2e）。
- **D rating 例外**：渐变金 + glow 动画用于 S/A/B/C，D 级用 monochrome 灰色（"第一天就寄了" 无需金色 celebration）。
- **navigateBack vs navigateTo 链路**：游戏内部不用 navigateBack — 完全 reLaunch 模式简化栈管理。

**Gates**:
- 326/326 tests pass（314 → 326，+12 新组件测试）
- type-check clean
- mp-weixin build 356KB（3 页面，远低于 2MB 主包限制）

**Manual verification deferred**: 视觉/动画/手势 + endRun timing + reLaunch 流畅度待用户配置开发工具后在 simulator 验证（含 S3-5 smoke）。
