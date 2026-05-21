# S3-7: 教学气泡 + chip pulse（Sprint 2 carryover from S2-10）

> **Sprint**: 3 | **Status**: Done | **Layer**: Presentation | **Type**: UI | **Owner**: ui-programmer | **Estimate**: 0.5 day
> **TR-ID**: pending | **Manifest Version**: N/A

## Quick-Spec

玩家**首次**（跨局永久）拿到任意 status 时显示 1.5s 教学气泡。Status 触发修正时该 chip 整体 pulse 一次（替代 v1 的 \* 标记，参见 status-system.md v2.1 评审 #13）。

## Context

**ADR-003**（Service emit → Store subscribe）

**Engine**: uni-app + Vue 3 | **Risk**: LOW

## Acceptance Criteria

- [x] AC-1: 全新存档 + 首次 buff/debuff → 1.5s 气泡 "新效果！持续 X 天"（game-main watch activeStatus + saveStore.data.firstStatusShown）
- [x] AC-2: 气泡消失同帧 saveStore.update({ firstStatusShown: true }) 持久化
- [x] AC-3: firstStatusShown=true 时 watch 不触发气泡（早 return）
- [x] AC-4: SaveData.firstStatusShown 跨实例 round-trip（已由 S2-7 + S3-4 集成测试验证）
- [x] AC-5: choice-resolution-store 在 wasStatusModified delta 时 → markModifierTrigger(causingStatusId) → StatusChip 350ms pulse
- [x] AC-6: chip pulse 动画 scale 1.0 → 1.1 → 1.0 + filter brightness 1.15（@keyframes chipPulse）
- [x] AC-7: `@media (prefers-reduced-motion: reduce)` → animation:none + 静态 brightness 1.3

## Implementation Notes

### 文件
- `src/components/StatusOnboardingTip.vue` — 教学气泡组件
- 修改 `src/components/StatusChip.vue` — 添加 pulse class hook（监听 store）
- 修改 `src/stores/status-store.ts` — 暴露 `lastModifierTrigger: { statusId, timestamp } | null`
- 修改 `src/services/choice-resolution/choice-resolution-engine.ts`（S2-3）— 当 applyToEffect 修正生效时通过 store 标记
- 修改 `src/pages/index/index.vue` — 集成教学气泡

### 教学气泡触发
```typescript
// In game-main.vue（or use-game-main-session）
const showTip = computed(() =>
  !saveStore.data.firstStatusShown && (buff.value || debuff.value) && !tipShown.value
)

watch(showTip, (v) => {
  if (v) {
    tipShown.value = true
    setTimeout(() => {
      saveStore.update({ ...saveStore.data, firstStatusShown: true })
    }, 1500)
  }
})
```

### Chip pulse trigger
ChoiceResolutionEngine 在 status 修正生效时（modified !== raw）→ store 标记 statusId + timestamp。
StatusChip 自身监听该 ref 是否最近被 mark：
```typescript
const isPulsing = computed(() =>
  statusStore.lastModifierTrigger?.statusId === props.status.id &&
  Date.now() - statusStore.lastModifierTrigger.timestamp < 400
)
```

## Out of Scope

- 浮字数字 \* 标记（v2.1 已删除概念）
- 多 status 分别教学（仅首次任意 status）
- 复杂教学动画（箭头指向等）— 简单气泡即可

## QA Test Cases

```
Manual + Logic mixed:

AC-1: 首次教学气泡触发
- Setup: 删除 storage（npm run reset 或手动 uni.removeStorageSync）+ 启动游戏
- When: 玩到第一个含 buff 的事件 + 选择
- Verify: chip 出现 + 1.5s 气泡浮出"新效果！持续 2 天"
- Verify: 气泡消失后查 storage → profile.firstStatusShown === true

AC-3/4: 后续不再触发
- Setup: profile.firstStatusShown=true
- When: 再次拿 status
- Verify: chip 出现，但**无**气泡

AC-5/6: chip pulse
- Setup: 持有 ☕亢奋(energyMul=0.5)
- When: 下张卡选择含 energy -20
- Verify: chip 整体放大 1.1x → 回到 1.0x，期间 glow 加强（参考 prototype v3）
- Pass: 视觉同帧（与浮字 -10 同时）

AC-7: 减少动画
- Setup: 模拟器开启"减少动画"
- When: status 修正生效
- Verify: chip 静态高亮 350ms（无 scale 变化）

Logic test (save-service test 已含 firstStatusShown round-trip from S2-7)
```

## Test Evidence

**Story Type**: UI
**Required**:
- `production/qa/evidence/s3-7-status-onboarding.md` — 截图 + 视频 + sign-off（DEFERRED：用户未搭建小程序开发环境）
- `tests/component/status-onboarding-tip.test.ts` — 8 component tests（tip 渲染 + chip pulse 行为 + statusStore.markModifierTrigger API）
- S2-7 save-service.test.ts firstStatusShown round-trip ✓
- S3-4 集成测试 cross-instance round-trip 验证 ✓

**Status**: [x] `tests/component/status-onboarding-tip.test.ts` 已创建（8 tests）

## Dependencies

- 前置: S2-1（status-store）✓ + S2-3（wasStatusModified 字段）✓ + S2-5（StatusChip 组件）✓ + S2-7（profile.firstStatusShown 字段）✓
- 阻塞: 无

## Completion Notes (2026-05-19)

**Files created**:
- `src/components/StatusOnboardingTip.vue` — tooltip with bounce-in + 1.2s 延迟 fade-out（CSS 动画 0.4s + 0.3s tipFadeOut delay 1.2s = 1.5s total）
- `tests/component/status-onboarding-tip.test.ts` — 8 component tests

**Files modified**:
- `src/stores/status-store.ts` — 新增 `lastModifierTrigger` ref + `markModifierTrigger(statusId)` API
- `src/stores/choice-resolution-store.ts` — resolve 后扫描 `result.deltas[].wasStatusModified`，按 target → buff/debuff `${target}Mul` 字段归因 → markModifierTrigger
- `src/components/StatusChip.vue` — 加 useStatusStore + watch lastModifierTrigger → chip-pulsing class 350ms + reduced-motion 媒体查询降级
- `src/pages/index/index.vue` — 引入 StatusOnboardingTip + watch activeStatus（buff ?? debuff）→ 1.5s 气泡 + saveStore.update({firstStatusShown:true}); .status-bar 加 position:relative 容纳 absolute 定位的 tip
- `tests/component/game-main.test.ts` — 加 `setActivePinia(createPinia())` beforeEach（StatusChip 现需要 Pinia store）

**Design decisions**:
- **chip pulse 归因策略**：data invariant（schema lint S2-6 enforced）保证同一 target 只能有一个 Mul（buff 或 debuff），所以 `delta.target === 'energy' && wasStatusModified` 唯一对应有 `energyMul` 的那个 chip。无歧义。
- **markModifierTrigger 写在 store action 而非 service**：保持 service 层 pure（无 Pinia 依赖）；store-level 是消费 service 输出 + UI 触发的合理位置。
- **CSS-only fadeOut for tip**：parent control visibility via v-if + setTimeout 1.5s，CSS 自身处理 0.3s @ 1.2s fade-out 动画。tip 总寿命 = 1.5s 与 setTimeout 一致。
- **reduced-motion 通过 CSS @media 而非 uni.getSystemInfoSync**：CSS native 实现更跨平台，小程序如果运行在 webview 内会被支持；uni API 检查反而增加 platform-specific 代码。

**Gates**:
- 353/353 tests pass（345 → 353，+8 新组件测试）
- type-check clean
- mp-weixin build 396KB（仍 <500KB AC 阈值）

**Manual verification deferred**: 真机首次拿 status 看气泡 + chip pulse 视觉对齐 prototype v3 → 留 simulator 验证。
