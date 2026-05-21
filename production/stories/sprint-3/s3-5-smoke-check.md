# S3-5: Sprint 3 收尾 smoke check

> **Sprint**: 3 | **Status**: Done | **Layer**: Cross-cutting | **Type**: Integration | **Owner**: qa-tester | **Estimate**: 0.5 day
> **TR-ID**: pending | **Manifest Version**: N/A

## Quick-Spec

**意图**：Sprint 3 全链路 smoke：完整 Alpha gameplay loop（含解锁 + 多次 run）+ 3 平台 build + Sprint 1+2+3 全测试不退化。

## Context

Sprint 3 收尾。包括 Sprint 2 三端 manual smoke 的 carryover（如用户已设置工具）。

## Acceptance Criteria

- [x] AC-1: `npm test` 全 suite 通过（338/338 — Sprint 1=81 + Sprint 2=198 + Sprint 3=59）
- [x] AC-2: `npm run type-check` 通过（vue-tsc clean）
- [x] AC-3: `npm run validate:events` 通过（4 files, 0 warnings）
- [x] AC-4: mp-weixin = **356 KB** main package ✅ <500KB
- [x] AC-5: mp-toutiao = **360 KB** main package ✅ <500KB
- [x] AC-6: mp-alipay = **444 KB** main package ✅ <500KB
- [⏸] AC-7: e2e flow 在工具跑完整一遍 — DEFERRED（用户工具未设置；逻辑路径已通过集成测试 + smoke report Section 4 walkthrough 覆盖）
- [x] AC-8: 多次 run 累计正确 — `tests/integration/app-navigation.test.ts > Full run lifecycle` 双 run 验证
- [x] AC-9: 满足条件解锁新职业 — `Full run lifecycle` 测试 win → 解锁 sales 验证
- [x] AC-10: 关闭重启 profile 保留 — `App navigation > Save round-trip across instances` 验证 stats + jobUnlocks + firstStatusShown 跨 SaveService 实例保留；endRun 同时设置 `currentRun: null`
- [x] AC-11: smoke 报告写入 `production/qa/smoke-sprint-3-2026-05-19.md`

## Implementation Notes

### 测试矩阵

```
1. 自动化层
   - npm test (全 suite)
   - npm run type-check
   - npm run validate:events
   - npm run build:mp-weixin / toutiao / alipay

2. 集成 e2e（在浏览器或微信工具）
   - 启动 → job-select 显示
   - 选 programmer → 玩 → 死亡 → settle
   - settle 显示 rating
   - 「换份工」→ 回 job-select
   - 选 programmer → 玩 → 通关（可能需要刻意通关，或多次尝试）
   - 解锁条件满足后 → 看到 sales 已解锁
   - 选 sales → 玩到事件包是 sales-events.json

3. 持久化
   - 关闭浏览器/工具 → 重新打开
   - profile.totalRuns / Wins 保留
   - 解锁列表保留
```

### 报告 format

```markdown
# Sprint 3 Smoke Check Report
**Date**: ...
**Verdict**: PASS / PASS WITH NOTES / FAIL

## Automated Gates
| Gate | Status |
|------|--------|
| npm test | ✅ pass (XXX/XXX) |
| ...

## E2E flow verification
| Step | Status |
|------|--------|

## Cross-sprint regression
- Sprint 1: 81/81
- Sprint 2: 198/198
- Sprint 3: NEW
- Total: ...

## Known deferred
- 三端 live test (user 工具未设置)
- ...
```

## Out of Scope

- 真机三端测试（用户工具未设置时延后）
- 性能 profile（Polish 阶段）

## QA Test Cases

参见 `production/qa/qa-plan-sprint-3.md` Smoke Test Scope 段。

## Test Evidence

**Story Type**: Integration
**Required**: `production/qa/smoke-sprint-3-2026-05-19.md` 完整报告
**Status**: [x] Created — verdict PASS (with deferred manual verification)

## Dependencies

- 前置: S3-1 ~ S3-4 全部完成 ✓
- 阻塞: Sprint 3 sign-off — 解除（除手动 e2e 三端联调外）

## Completion Notes (2026-05-19)

**File created**:
- `production/qa/smoke-sprint-3-2026-05-19.md` — 完整 smoke report (10 sections)

**Gates verified**:
- Vitest: 338/338 (16 test files) ✅
- vue-tsc strict: clean ✅
- validate:events: 4 files / 0 warnings ✅
- mp-weixin / mp-toutiao / mp-alipay: 356 / 360 / 444 KB ✅ all <500KB AC-4/5/6

**Sprint 3 cumulative**:
- New tests added: 59 (23 unit + 24 component + 12 integration)
- Bundle delta vs Sprint 2: mp-weixin 292 → 356 KB (+22%)
- 3 new pages built into output: `pages/job-select`, `pages/index`, `pages/settle`

**Verdict**: Sprint 3 PASS. Manual three-platform live verification deferred
to user-driven workflow when developer tools are configured.
