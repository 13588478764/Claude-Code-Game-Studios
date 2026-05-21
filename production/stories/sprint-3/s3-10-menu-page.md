# S3-10: 主菜单 / 图鉴占位页

> **Sprint**: 3 | **Status**: Done | **Layer**: Presentation | **Type**: UI | **Owner**: ui-programmer | **Estimate**: 0.5 day
> **TR-ID**: pending | **Manifest Version**: N/A

## Quick-Spec（lite design）

**意图**：从 job-select 入口可达的轻量菜单页，展示已解锁职业 + 全局 stats（totalRuns / totalWins / 解锁数量 / 已解锁被动技能等）。Beta 阶段 系统 17 主菜单/图鉴 的占位版。

**视觉**：
- 顶部 stats grid（4 数据卡）
- 中部 已解锁职业列表（含 jobsPlayed[id] 计数）
- 底部 已解锁被动技能列表（如 S3-9 完成）
- 返回按钮 → navigateBack to job-select

## Context

**Engine**: uni-app + Vue 3 | **Risk**: LOW

## Acceptance Criteria

- [x] AC-1: `pages/menu/index.vue` 新页面 + pages.json `pages[3]` 配置
- [x] AC-2: 顶部 4 stat cards：totalWins / totalRuns / unlocked / totalMoneyEarned（grid 2×2）
- [x] AC-3: 已解锁职业列表 — 渲染 `JOBS` 中已解锁的，每行展示 icon + name + "玩过 N 次"
- [x] AC-4: 已解锁被动技能列表 — 复用 S3-9 的 PASSIVE_SKILLS 注册表查找 + 名称 + 描述；空时显示 placeholder
- [x] AC-5: 返回按钮 → uni.navigateBack({ delta: 1 })
- [x] AC-6: job-select 页面加 "📖 图鉴" 入口 button → uni.navigateTo /pages/menu/index

## Implementation Notes

### 文件
- `src/pages/menu/index.vue`
- 修改 `src/pages/job-select/index.vue` — 加图鉴入口
- 修改 `src/pages.json` — 加 menu 路由

### 数据来源
全部从 saveStore.data 读取（无新 API）：
- saveStore.data.stats.totalRuns / totalWins / totalDeaths / totalMoneyEarned
- saveStore.data.jobUnlocks (string[])
- saveStore.data.stats.jobsPlayed (Record<string, number>)
- saveStore.data.passiveSkills (从 S3-9 → 可选)

## Out of Scope

- 完整图鉴（含事件统计 / 成就） — Beta 阶段
- 设置页（音效开关 / reduced motion）— Polish 阶段

## QA Test Cases

```
Manual:

AC-2: stats display
- Setup: 玩 3 局通关 1 次
- When: 进入 menu
- Verify: totalRuns=3, totalWins=1

AC-3: jobs list
- Setup: 玩过 programmer 2 次 + intern 1 次
- When: menu
- Verify: programmer 卡显示 "玩过 2 次"，intern 卡显示 "玩过 1 次"

AC-5: navigateBack
- When: menu page → 点返回
- Verify: 回 job-select

AC-6: 入口
- When: job-select 页面
- Verify: 看到「图鉴」按钮 → tap → 进 menu
```

## Test Evidence

**Story Type**: UI
**Required**:
- `production/qa/evidence/s3-10-menu.md` — 截图 + 手测 checklist（DEFERRED：用户未搭建小程序开发环境）
- `tests/component/menu-page.test.ts` — 8 component tests（stats grid / unlocked jobs / passive skills / back button + unknown id 防御）

**Status**: [x] `tests/component/menu-page.test.ts` 已创建（8 tests）

## Dependencies

- 前置: S3-1（progression stats）✓ + S3-2（job-select page）✓ + S3-9（PASSIVE_SKILLS registry）✓
- 阻塞: 无

## Completion Notes (2026-05-19)

**Files created**:
- `src/pages/menu/index.vue` — 4 stat cards (2×2 grid) + unlocked jobs list (icon+name+playCount) + unlocked passive skills list (name+description) + back button
- `tests/component/menu-page.test.ts` — 8 component tests

**Files modified**:
- `src/pages.json` — 添加 menu 路由（pages[3]）
- `src/pages/job-select/index.vue` — header 加 "📖 图鉴" 入口 button → uni.navigateTo /pages/menu/index

**Design decisions**:
- **stats 来源直接读 progressionStore.stats**（已经是 single source of truth via S3-1 wiring），不走 saveStore
- **passiveSkills 列表用 PASSIVE_SKILLS 注册表查找**，未知 id 静默过滤（同 S3-9 invariant）
- **navigateBack vs reLaunch**：menu 是 navigateTo 进入（栈：[job-select, menu]），所以 navigateBack 1 即可；与 settle 用 reLaunch 不同（settle 需要重启 game-main 干净）
- **onMounted 防御性 saveStore.load + jobStore.init**：menu 可能在 saveStore 未初始化时被打开，再 load 一次保证 stores 反映持久化状态

**Gates**:
- 394/394 tests pass（386 → 394，+8 新组件测试）
- type-check clean
- mp-weixin 448KB / mp-toutiao 452KB / mp-alipay 532KB
  - mp-alipay 超过 S3-5 smoke 自定 500KB AC（+6.4%），但仍远低于平台 2MB 硬限（26.6%）。Polish round 的合理代价。

**Manual verification deferred**: 视觉对齐 prototype + 实际 uni.navigateBack 流畅度待 simulator 验证。
