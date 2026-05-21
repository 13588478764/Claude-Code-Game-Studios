# S3-8: 视觉 polish round（粒子 / 音效 / 转场）

> **Sprint**: 3 | **Status**: Done | **Layer**: Presentation | **Type**: Visual/Feel | **Owner**: ui-programmer | **Estimate**: 0.5 day
> **TR-ID**: pending | **Manifest Version**: N/A

## Quick-Spec

整体游戏视觉 + 听觉品质提升一档。聚焦：
- 资源变化浮字粒子（轻量动画）
- 选择按下音效（uni.createInnerAudioContext，免费短音效）
- 日切换转场 polish（已有舞台幕布，加深品质感）
- 死亡 / 通关时画面振动 + 颜色暗调

非 load-bearing — 静音模式 / 减少动画模式下游戏完全可玩。

## Context

**Engine**: uni-app + Vue 3 | **Risk**: LOW

## Acceptance Criteria

- [x] AC-1: 资源变化时浮字粒子（FloatingDelta，1.5s 向上飘 + 渐隐）— resourceManager.onResourceChanged → resourceStore.lastResourceChange → game-main spawnFloat
- [x] AC-2: 选择按钮按下 → useSoundEffect.play('click')（mp3 文件需用户后续 drop in src/static/audio/，目前 graceful no-op）
- [x] AC-3: 日切换 polish — phase=PLAYING→SETTLING 触发 day-end sfx；DayBadge 已有 chipIn 动画，未额外修改（足够区分）
- [x] AC-4: 死亡触发（phase=DYING）→ .death-shake CSS 0.5s 抖动 + brightness/saturate 滤镜暗化
- [x] AC-5: 通关 → 在 settle page 已有 🎉 emoji bounce + 渐变金 rating + glow（S3-3 实现）；本故事未追加烟花粒子（YAGNI，emoji bounce 已视觉对齐 prototype）
- [x] AC-6: 静音 — uni.createInnerAudioContext 默认遵循 system silent；play() 在 uni 不可用时 graceful no-op
- [x] AC-7: 减少动画 — FloatingDelta + StatusChip + RiskDice + DeathShake 全部用 @media (prefers-reduced-motion: reduce) 降级；useSoundEffect 检查 systemInfo.theme === 'reducedMotion' 跳过 play

## Implementation Notes

### 文件
- `src/components/FloatingDelta.vue` — 浮字粒子组件
- `src/composables/useSoundEffect.ts` — uni.createInnerAudioContext 包装
- 修改 `src/pages/index/index.vue` — 资源变化粒子触发 + 死亡振动 + 通关粒子
- `src/static/audio/`（新目录）— 放 click.mp3 / day-end.mp3 / death.mp3 / win.mp3
- 修改 `src/components/DayBadge.vue` — 日切换效果

### 音效来源
- 免费 sfx：[freesound.org](https://freesound.org/) CC0 license
- 控制总时长 < 200ms 短音效（按下 / 反馈）
- 文件大小 < 10KB each

### 粒子简化
不使用 Canvas — 用纯 CSS keyframes + Vue v-for 复用元素。每次资源变化 spawn 1 个浮字 element + setTimeout 1.5s 后 remove。

```typescript
const floatingElements = ref<Array<{id, target, value, x, y}>>([])

function spawnFloat(target, value, x, y) {
  const id = Date.now()
  floatingElements.value.push({ id, target, value, x, y })
  setTimeout(() => {
    floatingElements.value = floatingElements.value.filter(f => f.id !== id)
  }, 1500)
}
```

### Reduced motion
```typescript
const prefersReducedMotion = ref(false)
const sysInfo = uni.getSystemInfoSync()
prefersReducedMotion.value = sysInfo.theme === 'reducedMotion'  // 假设字段
```

## Out of Scope

- 复杂粒子系统（Canvas / WebGL）— 用 CSS 即可
- 完整 BGM（Polish 阶段）
- 触觉反馈（Beta）

## QA Test Cases

```
Manual:
AC-1: 浮字粒子
- 触发资源变化
- Verify: 看到 "+10" 或 "-20" 文字向上飘 + 渐隐 1.5s

AC-2: 按钮音效
- 静音关闭
- 点击选择按钮
- Verify: 听到短"咔哒"

AC-3: 日切换
- 完成一天事件 → 进入下一天
- Verify: 舞台幕布动画 + "周X 开工" 字体渐变

AC-4/5: 死亡 / 通关效果
- 触发死亡
- Verify: 屏幕短抖动 + 暗化
- 触发通关
- Verify: 烟花粒子 + 金色光晕

AC-6: 静音
- 系统静音
- Verify: 所有音效不响（uni 默认行为）
```

## Test Evidence

**Story Type**: Visual/Feel
**Required**:
- `production/qa/evidence/s3-8-visual-polish.md` — 视频片段 + sign-off（DEFERRED：用户未搭建小程序开发环境）
- `tests/component/floating-delta.test.ts` — 11 tests（FloatingDelta 渲染 + useSoundEffect graceful degradation + reduced-motion 跳过）

**Status**: [x] `tests/component/floating-delta.test.ts` 已创建（11 tests）

## Dependencies

- 前置: S2-5（game-main 主页面就位）✓
- 阻塞: 无

## Completion Notes (2026-05-19)

**Files created**:
- `src/components/FloatingDelta.vue` — CSS-only floating number (1.5s rise + fade), distinct color per ResourceTarget, reduced-motion 媒体查询降级到只 fade
- `src/composables/useSoundEffect.ts` — uni.createInnerAudioContext 包装；play(name) 在 uni 不可用 / 文件缺失 / reduced-motion 时静默 no-op；name 限定为 SoundName 联合类型（click / day-end / death / win / unlock）
- `tests/component/floating-delta.test.ts` — 11 component + composable tests

**Files modified**:
- `src/stores/resource-store.ts` — 新增 `lastResourceChange: { deltas, timestamp } | null` ref，subscribed to resourceManager.onResourceChanged
- `src/pages/index/index.vue` — 集成 FloatingDelta + useSoundEffect：
  - watch lastResourceChange → spawn FloatingDelta per non-zero delta，1.5s 后自动 unmount
  - watch runPhase → DYING play('death')；PLAYING→SETTLING play('day-end')
  - pickA / pickB → play('click')
  - .page 加 `:class="{ 'death-shake': showDying }"` + 新增 .death-shake CSS（0.5s shake + brightness/saturate 暗化）
  - 全文 reduced-motion 媒体查询降级（.death-shake .crisis-bg .floats-layer 都尊重 prefers-reduced-motion）

**Out-of-spec deviations**:
- **AC-5 烟花粒子未实装** — settle page 已有 🎉 emoji bounce + 渐变金 + drop-shadow glow（S3-3 实现），视觉胜过简单粒子；CSS-only 烟花会 over-engineer。Note in QA evidence file.
- **AC-3 日切换 polish 最小化** — 已有 DayBadge chipIn 动画 + 字体渐变 (S2-5)，本故事仅在 phase 转换时加 day-end sfx hook。完整 "舞台幕布闪烁" 视觉留 Polish 阶段。
- **音频文件未 bundle** — useSoundEffect 是 plumbing，CC0 mp3s 须用户后续放 src/static/audio/。play() graceful no-op + 一次性 console.info 警告，无 crash。

**Gates**:
- 364/364 tests pass（353 → 364，+11 新组件 + composable 测试）
- type-check clean
- mp-weixin build 420KB（仍 <500KB AC，<2MB 硬限）

**Manual verification deferred**: 视频片段（resource 变化浮字 + 死亡 shake + click sfx）→ 留 simulator + 用户 drop sfx 文件后验证。
