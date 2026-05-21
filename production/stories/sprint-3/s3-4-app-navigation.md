# S3-4: 应用启动流程 + 多页面导航

> **Sprint**: 3 | **Status**: Done | **Layer**: Cross-cutting | **Type**: Integration | **Owner**: ui-programmer | **Estimate**: 1.0 day
> **TR-ID**: pending | **Manifest Version**: N/A

## Quick-Spec（lite design）

**意图**：把 S3-2（job-select）+ existing game-main + S3-3（settle）串成完整流程，处理 store 跨页面持久化、启动初始化、按钮路由。

**完整 e2e flow**：
```
启动 → load save → 进入 job-select page
  ↓ 玩家选职业
  selectJob → INITIALIZING → uni.navigateTo game-main
  ↓ 玩家完成 5 天 OR 死亡
  runStore.phase 变 SETTLING → game-main 监听 → uni.navigateTo settle
  ↓ 玩家选「再来一局」OR「换份工」
  - 再来一局：endRun → 同 jobId 重新初始化 → uni.navigateBack to game-main
  - 换份工：endRun → uni.navigateBack to job-select（runState 已清）
```

**Store 持久化策略**：
- onUnload 触发 saveStore.save（each page 退出时持久化）
- 跨页面 Pinia store 自然保留（singleton）

## Context

**ADRs**:
- **ADR-003**（Service emit → Store subscribe）

**Engine**: uni-app + Vue 3 | **Risk**: MEDIUM（多页面导航 + uni-app 生命周期 + store 同步）

## Acceptance Criteria

- [x] AC-1: 应用启动 → uni 加载 job-select 作为首页（pages.json pages[0]，已在 S3-2 配置）
- [x] AC-2: useGameSession 不拆分（设计偏离 — 见 Completion Notes）；job-select 自含 onMounted；settle 无 session 需求；保留 useGameSession 作为 game-main entry
- [x] AC-3: job-select 选职业 → runStore.selectJob + uni.navigateTo /pages/index/index（集成测试 mock 验证）
- [x] AC-4: game-main runPhase=SETTLING → 800ms 后 uni.navigateTo /pages/settle/index（S3-3 实现）
- [x] AC-5: settle 「再来一局」 → runStore.selectJob + uni.reLaunch /pages/index/index
- [x] AC-6: settle 「换份工」 → uni.reLaunch /pages/job-select/index（不是 navigateBack — 见 S3-3 完成笔记）
- [x] AC-7: 跨页面 Pinia store 状态保持（singleton，集成测试 mount → unmount → mount 验证 resourceStore/jobStore 持续）
- [x] AC-8: 三个 page 都加 onUnload → saveStore.save（job-select / game-main / settle）
- [x] AC-9: 关闭重启 stats + jobUnlocks + firstStatusShown 保留（集成测试 svc1.save → 新 SaveService 实例 → load 验证）
- [x] AC-10: 集成测试覆盖（tests/integration/app-navigation.test.ts，12 tests）

## Implementation Notes

### 文件修改
- `src/pages.json` — 启动页改为 job-select；保留 settle 路由（S3-3）
- `src/composables/useGameSession.ts` — 拆为 `useJobSelectSession` + `useGameMainSession` + `useSettleSession`
- `src/pages/job-select/index.vue` — 调用 useJobSelectSession
- `src/pages/index/index.vue`（game-main）— 调用 useGameMainSession + watch SETTLING
- `src/pages/settle/index.vue` — 调用 useSettleSession
- 全部 page 加 onUnload → saveStore.save

### useGameSession 拆分
```typescript
// useJobSelectSession.ts
export function useJobSelectSession() {
  onMounted(() => {
    saveService.load()  // 启动加载
    // 不初始化 resources / 不进入 PLAYING
  })
  onUnload(() => saveStore.save())
}

// useGameMainSession.ts
export function useGameMainSession() {
  // 已 wired services（cross-service event 链）
  onMounted(async () => {
    // load events for current job
    await eventDataEngine.loadJobEvents(currentJobId)
    runManager.startPlaying()
    dayCycleSystem.startDay(1)
  })
  onUnload(() => saveStore.save())
}

// useSettleSession.ts
export function useSettleSession() {
  onMounted(() => {
    // lastRunResult 已在 runStore；recentlyUnlocked 由 progression-store 处理
  })
  onUnload(() => saveStore.save())
}
```

### Service wiring 移到 module load
跨服务订阅（onQueueCardAdvanced → eventCompleted / onDayEnded → salary / onPhaseChanged → status clear）只能 wire 一次。从 useGameSession 移到 stores/ 模块顶层（已经的 run-store 等已部分 wire）。

### 集成测试
```typescript
// tests/integration/app-navigation.test.ts
test('完整 e2e: select → play → settle → replay', async () => {
  // mock uni.navigateTo
  const navigateMock = vi.fn()
  ;(globalThis as any).uni = { navigateTo: navigateMock, ... }
  
  // start: phase=JOB_SELECT
  // user picks programmer
  runStore.selectJob('programmer')
  // verify navigateTo('/pages/index/index')
  
  // simulate: complete the run
  // verify SETTLING phase → navigateTo settle
  
  // simulate: click 再来一局 → endRun + new run
  // verify navigateTo back to game-main
})
```

## Out of Scope

- **S3-1/2/3**: 各 page 自身实现
- **S3-9** 被动技能：不在导航集成
- **S3-10** 主菜单：不在 job-select → menu 链路
- 真机三端联调（→ S3-5 smoke）

## QA Test Cases

```
AC-1: 启动页
- Setup: 浏览器/模拟器加载 dist
- Verify: 首屏是 job-select 页面（含 5 职业卡）

AC-3: 选择导航
- Setup: tap programmer card on job-select
- Verify: spy uni.navigateTo 调用 with '/pages/index/index'

AC-4: SETTLING → settle 跳转
- Setup: game-main 上手动触发 runManager 进 SETTLING
- Verify: 1s 后 uni.navigateTo('/pages/settle/index') 调用

AC-5: 再来一局
- Setup: settle page，jobId='programmer'
- When: 点「再来一局」
- Verify: runManager.selectJob('programmer') + uni.navigateBack 或 navigateTo game-main

AC-6: 换份工
- When: 点「换份工」
- Verify: uni.navigateBack to job-select

AC-7: store 跨页面保留
- Setup: game-main 中改变 resources（applyEffects）
- When: 切换到 settle page
- Verify: resourceStore.resources 仍是改变后的值（singleton 持续）

AC-8: onUnload 持久化
- Setup: spy saveService.save
- When: 模拟 page onUnload (调用 onUnload 钩子函数)
- Verify: saveService.save 调用

AC-9: 关闭重启 profile
- Setup: 设置 profile.firstStatusShown=true + 累计 stats.totalRuns=3 → save
- When: 完全重启 (新建 saveService 实例 + load)
- Verify: profile 字段保留
```

## Test Evidence

**Story Type**: Integration
**Required**: `tests/integration/app-navigation.test.ts`（12 tests）+ 手测 e2e 在浏览器/微信工具（DEFERRED：用户未搭建小程序开发环境，留 S3-5 smoke 验证）
**Status**: [x] `tests/integration/app-navigation.test.ts` 已创建（12 tests）

## Dependencies

- 前置: S3-1 (progression-system) ✓ + S3-2 (job-select page) ✓ + S3-3 (settle page) ✓
- 阻塞: S3-5 (smoke check)

## Completion Notes (2026-05-19)

**Files modified**:
- `src/pages/job-select/index.vue` — 添加 onUnload → saveStore.save
- `src/pages/index/index.vue` — 添加 onUnload → saveStore.save
- `src/pages/settle/index.vue` — 添加 onUnload → saveStore.save
- `vitest.config.ts` — 加 setupFiles: ['./tests/setup.ts']

**Files created**:
- `tests/setup.ts` — vi.mock('@dcloudio/uni-app', ...) 全局 stub uni-app 页面 lifecycle hooks（onUnload 等在 happy-dom 不可用，会调 vue.injectHook 失败）
- `tests/integration/app-navigation.test.ts` — 12 集成测试覆盖：
  - JobSelect 点 → navigateTo + selectJob (AC-3)
  - JobSelect 锁定卡 → showToast 不 navigateTo (AC-7 防御)
  - Settle 再来一局 → selectJob + reLaunch (AC-5)
  - Settle 换份工 → reLaunch（不 selectJob）(AC-6)
  - 跨页面 resourceStore singleton 持续 (AC-7)
  - 跨页面 jobStore unlockedIds 持续 (AC-7)
  - SaveService.save 100ms 防抖落盘 (AC-8 实现验证)
  - SaveService.saveImmediate 同步落盘（onUnload 适用）(AC-8)
  - SaveService 实例间 round-trip：stats + jobUnlocks + firstStatusShown 保留 (AC-9)
  - 完整 win 流程：selectJob → endRun → progression.recordRun → checkUnlocks → 解锁 sales (AC-10)
  - 完整 die 流程：DYING → declineRevive → SETTLING → endRun → totalDeaths++ 不解锁 wins-gated (AC-10)
  - saveStore Pinia API 暴露完整 (AC-7)

**Design decisions / 偏离 spec**:
- **不拆分 useGameSession 为 3 个 composable**：spec 提议拆 useJobSelectSession + useGameMainSession + useSettleSession，但实际：
  - job-select 已在 S3-2 自含 onMounted（saveStore.load + jobStore.init + getRecommendations）
  - settle 不需要 session 初始化（lastRunResult 已在 runStore）
  - game-main 仍是唯一需要复杂 session wiring 的页面（loadJobEvents + bootstrap），保留 useGameSession 名义即可
  拆分会引入 3 个空壳函数，YAGNI。已在 S3-3 注释 useGameSession 改用 runManager.getCurrentJob() 而非硬编码 'programmer'。
- **uni.reLaunch 替代 navigateBack（S3-3 已采用）**：navigateBack 复用页面实例，game-main onMounted 不重跑导致 state 残留 bug。reLaunch 关闭所有页面、干净启动。
- **集成测试 unmount → mount 模拟 navigation**：因 uni-app navigateTo 在 vitest 不实际触发 page 渲染，集成测试用 unmount 模拟"离开"，再 mount 模拟"进入"，验证 Pinia store singleton 持续。

**Gates**:
- 338/338 tests pass（326 → 338，+12 集成测试）
- type-check clean
- mp-weixin build 356KB（3 页面，远低于 2MB 主包限制）

**Manual verification deferred**: 真机 e2e（启动 → 选职业 → 玩 → 死/赢 → 结算 → 再来一局/换份工）+ navigateTo / reLaunch 流畅度 + onUnload 真实触发 → 留 S3-5 smoke 在用户配置开发工具后验证。
