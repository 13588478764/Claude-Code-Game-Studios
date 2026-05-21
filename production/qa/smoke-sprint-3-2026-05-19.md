# Sprint 3 Smoke Check Report

**Date**: 2026-05-19
**Sprint**: 3 (Alpha gameplay loop)
**Tester**: gameplay-programmer + ui-programmer (autonomous run)
**Verdict**: **PASS (with deferred manual verification)**

---

## Summary

Sprint 3 introduces the full Alpha gameplay loop:
**job-select → play → settle → progress → re-select**.
All 5 must-have stories closed; all automation gates green; 3-platform builds
clean and well below size budgets. Manual three-platform live verification
remains **deferred** — same blocker as Sprint 2 (user has not configured
WeChat / Douyin / Alipay developer tools yet).

| Gate | Status | Detail |
|------|--------|--------|
| Vitest suite | ✅ PASS | 338 / 338 (16 files) |
| TypeScript strict | ✅ PASS | `vue-tsc --noEmit` clean |
| Event JSON validation | ✅ PASS | 4 files, 0 warnings |
| Build mp-weixin | ✅ PASS | **356 KB** main package (17.8% / 2 MB) |
| Build mp-toutiao | ✅ PASS | **360 KB** main package |
| Build mp-alipay | ✅ PASS | **444 KB** main package |
| Manual 3-platform smoke | ⏸ DEFERRED | User to run when env ready |
| Manual e2e (real device) | ⏸ DEFERRED | Same |

---

## 1. Sprint 3 Must-Have Stories

| ID | Title | Status | Tests added | Type |
|----|-------|--------|-------------|------|
| S3-1 | 永久进度系统 service + store | ✅ Done | 23 unit | Logic |
| S3-2 | 职业选择页（5 卡 + 推荐 + 解锁条件）| ✅ Done | 12 component | UI |
| S3-3 | 完整结算页面（替换 S2-5 占位 overlay）| ✅ Done | 12 component | UI + Logic |
| S3-4 | 应用启动 + 多页面导航 | ✅ Done | 12 integration | Integration |
| S3-5 | Sprint 3 收尾 smoke check | ✅ Done | this report | Integration |

**Burndown**: 6.0 / 6.0 must-have days = 100%.

Should-have / nice-to-have (S3-6 risk dice / S3-7 onboarding / S3-8 polish /
S3-9 passive skills stub / S3-10 main menu) remain in backlog — not blocking
Alpha exit.

---

## 2. Automated Gate Detail

### 2.1 Vitest

```
Test Files  16 passed (16)
     Tests  338 passed (338)
  Duration  ~1.4s
```

Cumulative breakdown:

| Sprint | Files | Tests |
|--------|-------|-------|
| Sprint 1 (S1-1 ~ S1-11) | 6 | 81 |
| Sprint 2 (S2-1 ~ S2-8) | 6 | 198 |
| Sprint 3 (S3-1 ~ S3-4) | 4 | 59 |
| **Cumulative total** | **16** | **338** |

Sprint 3 new files:
- `tests/unit/progression-system.test.ts` — 23 tests (stat accumulation /
  unlock orchestration / persistence / multi-run / fresh-install / event
  emission / getStats / cross-session preservation)
- `tests/component/job-card.test.ts` — 12 tests (3 render states /
  4 unlock-condition copy variants / tap routing / data hook)
- `tests/component/settle-page.test.ts` — 12 tests (rendering — rating /
  emoji / stats / D-rating monochrome — / unlock-toast / button routing)
- `tests/integration/app-navigation.test.ts` — 12 tests (JobSelect →
  navigateTo / locked-tap-toast / Settle 再来一局 / 换份工 / cross-page
  Pinia singleton persistence × 2 / save-debounce / saveImmediate /
  cross-instance round-trip / full-win lifecycle / die-decline lifecycle /
  saveStore API)

### 2.2 Coverage (Sprint 3 modules — isolated)

| Module | Lines | Branches | Functions |
|--------|-------|----------|-----------|
| progression-system.ts | **100%** | **100%** | **100%** |

(Other Sprint 3 work is UI / Vue components — visual + Pinia store integration
verified via component + integration tests; Vitest line-coverage on `.vue`
files is not enforced.)

### 2.3 Type Check

```bash
$ npm run type-check
# vue-tsc --noEmit → exit 0
```

Strict mode passes across 16 test files + ~38 source files. No `any` leaks.

### 2.4 Event JSON Schema Lint

```
[validate-events] Validating 4 event file(s)...
✓ Event validation passed (0 warnings)
```

Same 4 files as Sprint 2 (no new event packs added in Sprint 3 — Alpha
covers programmer / intern / sales which were authored in S1-11; designer
and runner remain placeholder).

### 2.5 Three-Platform Builds

All builds chain `validate:events && uni build`:

```
[validate-events] Validating 4 event file(s)...
✓ Event validation passed (0 warnings)
正在编译中...
DONE  Build complete.
```

| Platform | Output Path | Main Package | <500KB AC | <2MB hard limit |
|----------|-------------|--------------|-----------|-----------------|
| mp-weixin | dist/build/mp-weixin | **356 KB** | ✅ 71% used | ✅ 17.8% used |
| mp-toutiao | dist/build/mp-toutiao | **360 KB** | ✅ 72% used | ✅ 18.0% used |
| mp-alipay | dist/build/mp-alipay | **444 KB** | ✅ 89% used | ✅ 22.2% used |

Sprint 3 added 2 new pages (job-select + settle) + 1 component (JobCard) +
1 service (ProgressionSystem) + 1 store (progressionStore). Bundle delta
vs Sprint 2 baseline (mp-weixin 292KB → 356KB) = **+64 KB** (+22%).

Build output structure verified:
```
dist/build/mp-weixin/pages/
├── index/        (game-main)
├── job-select/   (S3-2 entry page)
└── settle/       (S3-3 settle screen)
```

---

## 3. Architectural Coherence Verified (Sprint 3)

### 3.1 Permanent Progression Chain (S3-1)

`runManager.endRun → onRunEnded → progressionSystem.recordRun →
saveServiceUpdate(stats + jobUnlocks) → checkUnlocks emit onJobUnlocked →
progressionStore.recentlyUnlocked toast`

Verified in `tests/integration/app-navigation.test.ts > Full run lifecycle`.
Two-run cumulative test confirms:
- `totalRuns` increments correctly
- `jobsPlayed[jobId]` increments without overwriting other entries
- `jobUnlocks` appends (no duplicates) on second pass

### 3.2 Multi-Page Navigation (S3-4)

Pinia stores are module-singletons; cross-page `useResourceStore() /
useJobStore() / useRunStore()` calls return the same instance. Verified
via `mount(JobSelectPage) → mutate store → unmount → mount(SettlePage) →
verify store state persists`.

### 3.3 Save Round-Trip (S3-4)

`SaveService` + `StorageAdapter` decoupling allows process-restart
simulation via two adapter-sharing instances. Verified `stats /
jobUnlocks / firstStatusShown` all survive a fresh `SaveService` load.

### 3.4 Settling → Settle Page Hand-off (S3-3)

`game-main` watches `runStore.phase`; when `SETTLING`, schedules
`endRun(...)` after 800 ms then `uni.navigateTo('/pages/settle/index')`.
`endRun` synchronously emits `onRunEnded`, populating `runStore.lastRunResult`
**before** navigation, so settle page's `onMounted` reads a fully-populated
result.

### 3.5 Replay Flow (S3-3)

`uni.reLaunch` (not `navigateBack`) — page stack reset, game-main mounts
fresh, `useGameSession.onMounted` re-runs and re-bootstraps the run.
Without this, `onMounted` only fires once per page-instance lifetime
and the game never re-initializes.

---

## 4. End-to-End Flow Walkthrough (Logical)

The full e2e is executable in any browser preview. Below is the documented
walkthrough verified through integration tests:

```
1. Launch app
   → pages.json[0] = job-select → job-select renders
   → saveStore.load() → empty save → jobUnlocks=['intern','programmer']
   → stats={totalRuns:0, totalWins:0, ...}
   → header: "已通关 0 局 · 解锁 2 / 5 职业"

2. Tap programmer card
   → runStore.selectJob('programmer') → phase = INITIALIZING
   → uni.navigateTo('/pages/index/index')

3. game-main mounts
   → useGameSession bootstrap → loadJobEvents('programmer')
   → resourceManager.init() → runManager.startPlaying() → phase = PLAYING
   → dayCycleSystem.startDay(1)
   → Day 1 events render

4. Player resolves 3 events × 5 days
   → Day 5 last event resolves → onWeekCompleted → phase = SETTLING
   → game-main shows "正在结算…" overlay
   → 800 ms later: runManager.endRun(...) → won=true → onRunEnded
   → progressionStore.recordRun: stats.totalRuns=1, totalWins=1
   → jobSystem.checkUnlocks → 'sales' unlocked (wins ≥ 1) → onJobUnlocked
   → progressionStore.recentlyUnlocked = sales (toast)
   → uni.navigateTo('/pages/settle/index')

5. settle mounts
   → reads runStore.lastRunResult
   → renders rating (e.g. 'A 打工达人') + stats grid
   → unlock toast: "🎊 解锁了新职业：销售"

6. Tap 「再来一局」
   → runStore.selectJob('programmer') → phase = INITIALIZING
   → uni.reLaunch('/pages/index/index')
   → fresh game-main mounts → step 3 repeats

   OR Tap 「换份工」
   → uni.reLaunch('/pages/job-select/index')
   → job-select mounts fresh → header now: "已通关 1 局 · 解锁 3 / 5"
   → sales card unlocked + selectable
```

---

## 5. Cross-Sprint Regression Check

Sprint 1 (81 tests) + Sprint 2 (198) + Sprint 3 (59) = **338 tests, 100% pass**.

No Sprint 1 / Sprint 2 test was modified for Sprint 3 changes. Backward
compatibility confirmed:
- `useGameSession` change (hardcoded `'programmer'` → `runManager.getCurrentJob() ?? 'programmer'`)
  preserves the test fallback
- `pages.json` reorder (job-select moved to `pages[0]`) does not affect
  any unit or component test (tests do not depend on page launch order)
- `SETTLING` overlay removal in `pages/index/index.vue` did not regress
  the 23 `game-main.test.ts` component tests (they target individual
  child components, not the overlay)

---

## 6. Deferred Manual Verification

Same as Sprint 2 — gated on user setting up the developer tool environments:

| AC | Requirement | Auto-equivalent | Manual step |
|----|-------------|----------------|-------------|
| AC-7 | Browser/工具 e2e flow runnable | logical walkthrough above + integration tests | actually load `dist/build/mp-weixin/` in WeChat devtools and click through |
| AC-8 | profile 累计 cross-session 真机验证 | covered by `app-navigation.test.ts > Save round-trip` and `> Full run lifecycle` | live device: 玩 3 局，关工具，重开，查 profile |
| AC-9 | 解锁后 sales 在 job-select 显示已解锁 | covered logically + `Full run lifecycle` test | live device: 通关 1 次后回 job-select 看 sales 卡 |
| AC-10 | 关闭重启 currentRun 清空 | logically covered (endRun sets currentRun: null in SaveData patch) | live device: 通关后强制关工具，重开看 job-select 而不是 game-main |

**Recommendation**: when WeChat / Douyin / Alipay tools are set up, import
`dist/build/mp-{platform}/` and run the 6-step walkthrough in section 4.
The build artifacts are ready.

---

## 7. Sprint 3 Definition of Done — Status

| Criterion | Status |
|-----------|--------|
| 5/5 Must Have tasks completed | ✅ S3-1 through S3-5 |
| QA plan exists | ✅ `production/qa/qa-plan-sprint-3.md` |
| Logic / Integration stories have passing tests | ✅ 5/5 |
| Smoke check passed | ✅ this report |
| Service-layer 100% line coverage | ✅ progression-system 100% |
| 0 S1 / S2 bugs surfaced | ✅ none |
| 全部 Sprint 1 + 2 测试不退化 (279 → still 279 passing within total 338) | ✅ confirmed |
| systems-index Implemented status updated | ⏸ deferred (no systems-index file in this project; Sprint 1+2 model used per-sprint stories instead) |
| E2E playable: select → play → settle → re-select | ✅ logically + integration-test verified; live deferred |

---

## 8. Should-Have / Nice-to-Have Status (Backlog)

Not part of Sprint 3 sign-off:

| ID | Title | Days | Status | Notes |
|----|-------|------|--------|-------|
| S3-6 | Risk dice 全屏动画 | 0.5 | backlog | visual polish; Sprint 4 candidate |
| S3-7 | 教学气泡 + chip pulse | 0.5 | backlog | onboarding UX |
| S3-8 | 视觉 polish round | 0.5 | backlog | particles / sfx / transition |
| S3-9 | 被动技能 stub | 1.0 | backlog | feeds Sprint 4 |
| S3-10 | 主菜单 / 图鉴占位页 | 0.5 | backlog | Beta scope |

---

## 9. Sprint 3 Final Stats

```
Sprint 3 must-have completion:    5/5 (100%)
Sprint 3 burndown:                6.0/6.0 days (100%)
Tests added in Sprint 3:          59 (23 unit + 24 component + 12 integration)
Cumulative project tests:         338
Cumulative passing:               338 (100%)
Build artifacts:                  3/3 platforms successful
Largest build:                    mp-alipay 444 KB / 500 KB AC budget (89%)
                                  mp-alipay 444 KB / 2 MB hard limit (22.2%)
Bundle growth (S2 → S3):          mp-weixin 292 → 356 KB (+22%)
```

**Verdict**: Sprint 3 PASSES smoke check. All Must Have stories closed.
Manual three-platform live-test gating is the **only** remaining item before
full Alpha sign-off, blocked solely on user environment setup. Alpha
gameplay loop (job-select → play → settle → progress → re-select) is
implemented and verified through automation.

---

## 10. Recommended Next Steps

1. (User) Set up WeChat / Douyin / Alipay developer tools when ready
2. Import `dist/build/mp-{platform}/` and run the section 4 walkthrough
3. If issues surface → file bugs → polish round (S3-6/7/8 may also be
   pulled in here)
4. If clean → Sprint 3 fully closed → declare Alpha milestone reached →
   plan Sprint 4 (broadly: ad SDK integration / passive skills full
   implementation / designer + runner event packs / achievement system)
