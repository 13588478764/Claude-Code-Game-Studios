# S2-5: 游戏主界面 + 5 个子组件（替换占位首页）

> **Sprint**: 2 | **Status**: Complete | **Layer**: Presentation | **Type**: UI（次 Visual/Feel） | **Owner**: ui-programmer | **Estimate**: 2.5 days
> **Completed**: 2026-05-19
> **TR-ID**: pending | **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/game-main-ui.md` + `design/gdd/status-system.md` Visual/UI Requirements
**Requirement Summary**: 替换 Sprint 1 占位首页，实现完整游戏主界面：DayBadge / ResourceBar（已有）/ StatusChip / EventCard / ChoiceButton / GameMain.vue。视觉品质对齐 prototype v2-v3：渐变 / 发光 / 状态化头像 / 舞台幕布 / chip pulse。

**Governing ADRs**:
- **ADR-003 Store-Service 同步模式** — 组件用 storeToRefs 订阅 store ref，**不**直接 import service

**Engine**: uni-app + Vue 3 + TypeScript strict | **Risk**: HIGH（评审 sprint plan 标注） — 5 组件 + 视觉对齐 + 三端兼容
**Engine Notes**: rpx 单位 + uni 组件 `<view>/<text>/<button>` 用法见 uni-app 文档

---

## Acceptance Criteria

*From `design/gdd/game-main-ui.md` AC + `design/gdd/status-system.md` Visual ACs:*

- [ ] AC-1: 启动 → 替换占位首页，显示 GameMain（含资源条 + 状态栏 + 事件卡 + 选项按钮 + 日期 badge）
- [ ] AC-2: ResourceBar 颜色阈值切换：energy 80→绿，45→黄，20→红；mood 70→橙，25→灰，15→紫
- [ ] AC-3: StatusChip 视觉 26px + 透明 padding 撑出 → wrapper getBoundingClientRect().height ≥ 44px
- [ ] AC-4: EventCard 字号自适应：lineCount=3 → fontSize=32rpx；lineCount=5 → fontSize=24rpx
- [ ] AC-5: ChoiceButton 触控防连点：100ms 内 3 次点击 → selectChoice 仅触发 1 次（debounce 300ms）
- [ ] AC-6: DayBadge 显示"周三 · 第3天"格式
- [ ] AC-7: 状态栏空时 collapse 高度 0（不占空间）；有 chip 时高度约 50rpx
- [ ] AC-8: 资源动画过渡 600ms（cubic-bezier 0.4,0,0.2,1）
- [ ] AC-9: 资源动画未播完时新变化 → 中断 + 跳到最终值
- [ ] AC-10: 屏幕宽 < 320px → 选项按钮上下堆叠（非左右）
- [ ] AC-11: 三端模拟器（至少微信）跑通完整一局
- [ ] AC-12: 死亡 → DYING phase 显示死亡 overlay；通关 → SETTLING 显示胜利 overlay
- [ ] AC-13: buff/debuff 形状区分（debuff 加破折线下划线），不依赖颜色独立可辨

---

## Implementation Notes

### 文件
- `src/components/DayBadge.vue` — 日期 badge（已有简单实现，扩展为 game-concept 一致样式）
- `src/components/ResourceBar.vue` — 已存在（Sprint 1 S1-6），如有不足处补充
- `src/components/StatusChip.vue` — buff/debuff 胶囊
- `src/components/EventCard.vue` — 卡片渲染 + 字号自适应
- `src/components/ChoiceButton.vue` — 选项按钮 + risk 标签 + debounce
- `src/pages/index/index.vue` — 替换为 GameMain：组合上述组件
- `tests/component/game-main.test.ts` — programmatic component tests（@vue/test-utils）

### 视觉细节（对齐 prototype）

| 元素 | 关键样式 |
|------|---------|
| 背景 | 紫黑径向渐变 `radial-gradient(ellipse at top, #2d1b4e 0%, #1a0f2e 50%, #0a0518 100%)` |
| 卡片 | 米黄羊皮纸 `linear-gradient(160deg, #fdf6e8 0%, #f5e8c8 100%)` + 12px 阴影 |
| 资源条 | 内嵌阴影 + 50% 高光层 + glow（box-shadow currentColor）|
| StatusChip buff | 绿底 `rgba(76,217,100,0.15)` + 绿描边 |
| StatusChip debuff | 红底 + 1px 红色破折线下划线（色盲友好） |
| ChoiceButton | 渐变 + 6px 立体阴影 + active 下沉 2px |

### 关键实现要点
- 全部组件用 `storeToRefs(useXxxStore())` 订阅；**不**直接 `import { statusSystem } from '@/services/...'`
- StatusChip 容器布局：`padding: 9px 0;`（撑出 hit area）+ 内嵌视觉 26px 高 chip
- EventCard 字号公式：`fontSize = max(MIN_FONT, BASE_FONT - (lineCount - 3) × 2)`，BASE=32 / MIN=24
- ChoiceButton debounce：可用 lodash debounce 或自实现 `useDebouncedClick`
- chip pulse 动画：监听 `statusSystem.onStatusModifierApplied`（S2-3 提供新 emitter，或扩展 onStatusChanged）→ 触发该 chip 的 CSS class 一次
- 减少动画偏好：监听 `prefers-reduced-motion`（小程序通过 uni.getSystemInfoSync().theme 判断）

---

## Out of Scope

- **S2-9** Risk dice 动画：本故事仅占位（点击 risk 按钮触发结算），全屏 dice overlay 由 S2-9 完成
- **S2-10** 教学气泡 + chip pulse 动画：本故事提供 chip 渲染 + class hook，气泡和 pulse 由 S2-10 实现
- **S2-11** Settle screen：本故事预留 overlay slot，渲染由 S2-11
- **art-bible 视觉规范**：本故事对齐 prototype v2-v3 即可

---

## QA Test Cases

### Component Tests（programmatic）

**AC-2: ResourceBar 阈值切换**
- Setup: 渲染 `<ResourceBar type="energy" :value="80" />`
- Verify: fill 元素 background-color === '#4CD964'（绿）
- Verify: value=45 → '#FFCC00'，value=20 → '#FF6B6B'
- Pass: 三个阈值切换正确

**AC-3: StatusChip hit-area**
- Setup: 渲染 `<StatusChip :status="caffeine" />`
- Verify: wrapper.getBoundingClientRect().height ≥ 44
- Verify: chip-body 视觉高度 26px
- Pass: hit area >= 44，视觉 = 26

**AC-4: EventCard 字号**
- Setup: 渲染 EventCard 含不同长度文案
- Verify: lineCount=3 → fontSize=32rpx，lineCount=5 → 24rpx
- Pass: 字号公式正确

**AC-5: ChoiceButton debounce**
- Setup: 渲染 ChoiceButton + spy on @click handler
- When: 触发 3 次 click 在 100ms 内
- Then: handler 仅调用 1 次

### Manual Verification（三端 + 视觉）

**AC-1, 11, 12: 整体集成**

Setup: `npm run dev:mp-weixin` + 微信开发者工具

Checklist:
- [ ] 启动 → 替换占位首页（不再有"测试 +energy"按钮）
- [ ] 资源条 3 条颜色按值切换
- [ ] DayBadge 文案正确
- [ ] 选择卡片 → resolve → 资源条动画 600ms
- [ ] 上 buff 卡 → status chip 出现，下张卡 effect 受修正
- [ ] 死亡触发 → DYING overlay 出现
- [ ] 通关触发 → Win overlay 出现

Pass: 微信工具完整一局通关，无 console error

**AC-13: 色盲友好**

Setup: 模拟器 + 截图

Checklist:
- [ ] buff chip 圆角矩形（无下划线）
- [ ] debuff chip 圆角矩形 + 1px 红色破折线下划线
- [ ] 灰度截图（PS 去色）下仍可区分两者

---

## Test Evidence

**Story Type**: UI（次 Visual/Feel）
**Required**:
- `tests/component/game-main.test.ts` — programmatic component tests
- `production/qa/evidence/s2-5-game-main-ui.md` — 三端截图 + 手测 checklist + ui-programmer + lead-programmer sign-off

**Status**: [x] Component tests created 2026-05-19 — 23 tests pass; manual three-platform smoke deferred to S2-8

## Completion Notes

**Files created**:
- `src/components/DayBadge.vue` — 日期 badge + 5 dots progress
- `src/components/StatusChip.vue` — buff/debuff chip 含 44px hit-area + 色盲友好形状区分
- `src/components/EventCard.vue` — 卡片 + 字号自适应 + followUp 紫色变体
- `src/components/ChoiceButton.vue` — A/B 按钮 + risk 标签 + 300ms debounce
- `src/stores/day-cycle-store.ts` — DayCycleSystem 单例 + Pinia bridge
- `src/composables/useGameSession.ts` — 跨 service wiring 协调器（顺序契约：salary 先于 status tick）
- `src/pages/index/index.vue` — 替换占位首页为 GameMain
- `src/services/event-card/event-card-system.ts` — 加 `onQueueCardAdvanced` emitter（小幅 S2-2 扩展）
- `tests/component/game-main.test.ts` — 23 component tests
- `vitest.config.ts` — 添加 @vitejs/plugin-vue（支持 .vue 测试）
- `package.json` — 添加 @vitejs/plugin-vue@5

**Verification**:
- npm test: **243/243 pass**（全 Sprint 1 + Sprint 2 测试通过）
- npm run type-check: pass
- npm run build:mp-weixin: pass，主包 **292KB**（远低于 2MB 限制）

**Component test 覆盖**：
- DayBadge: 4 测试（dayName / 5 dots / progress states / out-of-range）
- StatusChip: 5 测试（renders / 44px hit-area / buff vs debuff classes / 色盲区分）
- EventCard: 6 测试（null / 文本 / 字号 base+min / followUp class / EVENT label）
- ChoiceButton: 8 测试（icon fallback / pick emit / disabled / debounce / risk badge / variant classes）

**Day-end 顺序契约实施**：useGameSession 顺序注册：
1. dayCycleSystem.onDayEnded 监听器#1：apply salary
2. statusSystem.subscribeToDayEnded：tick statuses（注册顺序后于上面）
3. dayCycleSystem.onDayEnded 监听器#3：next day setTimeout

TypedEventEmitter 用 Set 保留插入顺序，保证 salary 应用先于 status tick。

**Deviations**:
- 加 `onQueueCardAdvanced` 事件到 EventCardSystem（S2-2 之外的小幅扩展）— 文档化为生产 wiring 必需的 per-event 信号
- 安装 `@vitejs/plugin-vue@^5`（v6 ESM-only 与 CJS vitest config 冲突）
- 死亡 / 胜利 overlay 在 S2-5 中实现基础版（S2-11 polish 进一步优化）

Ready for: `/code-review` → `/story-done`

---

## Dependencies

- 前置: S1-6（ResourceBar.vue 已存在），S2-1（status-store ref）, S2-2（event-card-store currentCard ref）, S2-3（resolveChoice 触发链）, S2-4（run-store phase ref 决定 overlay）
- 阻塞: S2-8（smoke 需要主界面跑通）, S2-9, S2-10, S2-11（视觉 polish 在主界面之上）
