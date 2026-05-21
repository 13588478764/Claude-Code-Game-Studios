# S2-11: 简版结算页（GameOver / Win overlay）

> **Sprint**: 2 | **Status**: Backlog（Nice to Have）| **Layer**: Presentation | **Type**: UI | **Owner**: ui-programmer | **Estimate**: 0.5 day
> **TR-ID**: pending | **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/run-manager.md` Acceptance Criteria（rating 计算 + RunResult 数据）
**Requirement Summary**: 死亡或通关时显示 overlay 含天数 / 金钱 / 选择次数 / 评级（S/A/B/C/D），点击"再来一局"回到 JOB_SELECT。简版（无复杂动画 / 无分享按钮 / 无成就解锁）。

**Governing ADRs**: ADR-003（Service emit → Store subscribe）

**Engine**: uni-app + Vue 3 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-1: phase=DYING（拒绝续命）→ SETTLING → 显示 GameOver overlay
- [ ] AC-2: GameOver overlay 内容：死因（燃尽/暴走）+ 存活天数 + 总金钱 + 选择次数 + 评级
- [ ] AC-3: phase=PLAYING + onWeekCompleted（5 天通关）→ SETTLING → 显示 Win overlay
- [ ] AC-4: Win overlay 内容：总收入 + 选择次数 + 评级 + 评级文案（"卷王"/"打工达人" 等）
- [ ] AC-5: "再来一局"按钮触控区域 ≥ 44×44px
- [ ] AC-6: 点击"再来一局" → endRun() → ENDED → JOB_SELECT，存档清空
- [ ] AC-7: overlay 出现动画 0.5s fadeIn
- [ ] AC-8: rating 显示与 RunManager.computeRating 返回值一致

---

## Implementation Notes

### 文件
- `src/components/GameOverOverlay.vue`
- `src/components/WinOverlay.vue`
- 修改 `src/pages/index/index.vue`（GameMain）— 根据 run-store.phase 渲染对应 overlay

### overlay 触发逻辑

```typescript
// pages/index/index.vue
const runStore = useRunStore()
const { phase, runResult } = storeToRefs(runStore)

const showGameOver = computed(() => phase.value === 'SETTLING' && !runResult.value?.won)
const showWin = computed(() => phase.value === 'SETTLING' && runResult.value?.won)
```

### GameOver Overlay 内容
```
┌────────────────────────┐
│      💀 燃尽了         │
│  你的身体终于扛不住了  │
│                        │
│  存活：3 天            │
│  赚了：30 元           │
│  选择：12 次           │
│  评级：C 摸鱼被抓      │
│                        │
│  [ 再 来 一 局 ]       │
└────────────────────────┘
```

### Win Overlay 内容
```
┌────────────────────────┐
│   🎉 撑过了一周        │
│  恭喜打工人！发工资了  │
│                        │
│  总收入：120 元        │
│  选择：18 次           │
│  评级：A 打工达人      │
│                        │
│  [ 换 份 工 再 来 ]    │
└────────────────────────┘
```

### 关键实现要点
- 视觉对齐 prototype v2-v3（参考 `prototypes/core-loop/index.html` `.death-overlay` / `.win-overlay`）
- "再来一局"按钮调 runManager.endRun()，触发 ENDED → JOB_SELECT
- rating 文案表参考 run-manager.md：S 卷王 / A 打工达人 / B 勉强混过 / C 摸鱼被抓 / D 第一天就寄了

---

## Out of Scope

- 分享功能（Beta 阶段）
- 成就解锁动画（Beta）
- 详细统计（Alpha 阶段——本故事仅显示基础数据）
- 广告续命按钮（在 DYING phase 显示，不在 SETTLING）

---

## QA Test Cases

### Manual Verification

**AC-1, 2: GameOver 触发**
- Setup: 玩到资源归零 → DYING 拒绝续命
- Verify:
  - [ ] phase 变 SETTLING 同时 GameOver overlay 出现
  - [ ] 标题 "💀 燃尽了" 或 "🤬 暴走离职"（取决于 energy 还是 mood 归零）
  - [ ] 显示 4 项数据：天数 / 金钱 / 选择 / 评级
  - [ ] overlay 渐入动画 0.5s

**AC-3, 4: Win 触发**
- Setup: 撑过 5 天最后事件 + 不死亡
- Verify:
  - [ ] phase 变 SETTLING + Win overlay 出现
  - [ ] 标题 "🎉 撑过了一周"
  - [ ] 显示 3 项数据 + 评级文案

**AC-5: 触控区域**
- DevTools 或代码审计 "再来一局" 按钮 wrapper getBoundingClientRect().height ≥ 44

**AC-6: 重启逻辑**
- When: 点击"再来一局"
- Verify:
  - [ ] overlay 渐出
  - [ ] 回到 JOB_SELECT 页（MVP 默认 hardcoded programmer 直接进入新局）
  - [ ] 资源条 + status 栏 全部重置
  - [ ] storage runState 已清空（profile 仍保留）

**AC-8: rating 一致**
- Setup: 强制 RunResult 数据 → 计算预期 rating
- Verify: overlay 显示等级与 computeRating 返回一致

---

## Test Evidence

**Story Type**: UI
**Required**:
- `production/qa/evidence/s2-11-settle-screen.md` — 截图 GameOver + Win 各一组 + 手测 checklist + ui-programmer sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- 前置: S2-4（RunManager phase + runResult + computeRating + endRun）, S2-5（GameMain 容器 + overlay slot）
- 阻塞: 无
