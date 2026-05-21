# S3-6: Risk dice 全屏动画（Sprint 2 carryover from S2-9）

> **Sprint**: 3 | **Status**: Done | **Layer**: Presentation | **Type**: Visual/Feel | **Owner**: ui-programmer | **Estimate**: 0.5 day
> **TR-ID**: pending | **Manifest Version**: N/A

## Quick-Spec

直接复用 prototype v3 `prototypes/core-loop/index.html` 的 `.risk-overlay` 样式：1s dice 旋转 + 大字 success/fail 结果，~2s 后消失。

## Context

**ADR-003**（Service emit → Store subscribe）

**Engine**: uni-app + Vue 3 | **Risk**: LOW

## Acceptance Criteria

- [x] AC-1: 玩家选 risk choice → 全屏 dice overlay 立即出现（game-main watch lastChoiceResult）
- [x] AC-2: dice 旋转 720° + scale 弹性，1 秒（@keyframes diceRoll: 0%→50%→100%）
- [x] AC-3: success → 绿色 #4CD964 "✨ 成功" + text-shadow 发光
- [x] AC-4: fail → 红色 #FF6B6B "💀 翻车" + text-shadow 发光
- [x] AC-5: outcome 文字 resolvePop 动画 0.4s @ 0.8s delay
- [x] AC-6: overlay 总时长 ~2s 后自动消失（RISK_DICE_DISMISS_MS = 2000）
- [x] AC-7: 通过 z-index: 35 + position fixed inset:0 阻挡其他点击（覆盖整个 viewport）

## Implementation Notes

### 文件
- `src/components/RiskDiceOverlay.vue` 新组件
- 修改 `src/pages/index/index.vue`（game-main） — 集成 overlay；监听 lastRiskRoll
- 扩展 `src/stores/choice-resolution-store.ts` — 暴露 lastRiskRoll ref（已有 lastResult）

### Trigger
ChoiceResolutionEngine.resolveChoice 内含 risk 时，store 暴露 `lastRiskRoll: { outcome, detail } | null`。Game-main watch 此 ref → 显示 overlay → 2s 后置 null。

### CSS 复用 prototype v3
对齐 `.risk-overlay` / `.dice` / `.risk-result-text` 样式。详见 `prototypes/core-loop/index.html`。

## Out of Scope

- Risk choice 按钮上的 🎲 percentage 标签（已 S2-5 实现）
- 复杂概率分支（多 outcome）— 当前只 success/fail 二元

## QA Test Cases

```
Manual:
- Setup: 微信工具 + 触发含 risk 的事件（programmer-events.json 多个含 risk）
- When: 选 risk choice
- Verify:
  [ ] dice overlay 立即出现（< 100ms）
  [ ] dice 旋转 720° 约 1 秒
  [ ] success/fail 结果显示带 glow
  [ ] 文字弹入动画 0.4s
  [ ] overlay 总时长约 2 秒
  [ ] 期间点击 game-main 无反应
- Pass: 视觉对齐 prototype v3 截图
```

## Test Evidence

**Story Type**: Visual/Feel
**Required**: `production/qa/evidence/s3-6-risk-dice.md` — 视频片段（gif） + sign-off（DEFERRED：用户未搭建小程序开发环境，逻辑层有 7 component tests 覆盖）
**Status**: [x] `tests/component/risk-dice-overlay.test.ts` 已创建（7 tests，覆盖 success/fail 渲染 + detail copy + a11y data attribute）

## Dependencies

- 前置: S2-3（ResolveResult.riskOutcome 字段）✓ + S2-5（主页面有 overlay 容器）✓
- 阻塞: 无

## Completion Notes (2026-05-19)

**Files created**:
- `src/components/RiskDiceOverlay.vue` — 1s diceRoll + 0.4s @ 0.8s delay resolvePop + 0.4s @ 1.0s detail fadeIn，对齐 prototype v3
- `tests/component/risk-dice-overlay.test.ts` — 7 component tests

**Files modified**:
- `src/pages/index/index.vue` — 引入 useChoiceResolutionStore + watch lastChoiceResult.value?.result.riskOutcome → 设置 riskOverlay ref → 2s setTimeout 清空

**Design decisions**:
- **不另建 lastRiskRoll ref**（spec 提议）— `lastResult.result.riskOutcome` 已经在 ChoiceResolutionEngine 输出里，game-main watch lastResult 即可触发。避免重复 store 字段。
- **AC-7 click 阻挡通过 z-index 35 + position fixed 而非 pointer-events**：overlay 全屏覆盖即天然阻挡所有底层 click，无需额外 css。
- **RISK_DICE_DISMISS_MS = 2000** 与 prototype v3 完全一致（1s dice + 0.4s pop + 0.6s lingering = 2s）

**Gates**:
- 345/345 tests pass（338 → 345，+7 新组件测试）
- type-check clean
- mp-weixin build 380KB（含 RiskDiceOverlay，仍 <500KB AC）

**Manual verification deferred**: 视频片段 gif + 实际小程序工具触发 risk choice → dice 旋转视觉对齐 prototype。
