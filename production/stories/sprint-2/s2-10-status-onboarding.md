# S2-10: 首次状态教学气泡 + chip pulse 动画

> **Sprint**: 2 | **Status**: Backlog（Should Have）| **Layer**: Presentation | **Type**: UI | **Owner**: ui-programmer | **Estimate**: 0.5 day
> **TR-ID**: pending | **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/status-system.md` v2.1 UI Requirements 段（评审 #29 onboarding + chip pulse 替换 v1 的 \* 标记）
**Requirement Summary**: 玩家**首次**（跨局永久）拿到任意 status 时显示 1.5s 教学气泡"新效果！持续 X 天"。Status 触发修正时该 chip 整体 pulse 一次（替代 v1 的 \* 标记）。

**Governing ADRs**: ADR-003（Service emit → Store subscribe）

**Engine**: uni-app + Vue 3 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-1: 全新存档（profile.firstStatusShown undefined）+ 第一次拿任意 status → 1.5s 气泡气泡浮出"新效果！持续 X 天"
- [ ] AC-2: 气泡消失后 profile.firstStatusShown 写入 true（saveService.save 调用）
- [ ] AC-3: 后续局再获取 status → **不再**显示气泡
- [ ] AC-4: 跨局重启 → profile.firstStatusShown 仍为 true → **不再**显示气泡
- [ ] AC-5: status 触发修正时（applyToEffect 返回值 ≠ rawValue）→ 对应 chip 同帧 pulse 一次（350ms 内）
- [ ] AC-6: chip pulse 动画：scale 1.0 → 1.1 → 1.0 + glow 一次
- [ ] AC-7: 减少动画偏好开启时：pulse 降级为静态高亮 350ms

---

## Implementation Notes

### 文件
- `src/components/StatusOnboardingTip.vue` — 教学气泡组件
- `src/components/StatusChip.vue`（已 S2-5 创建）— 添加 pulse class hook
- 修改 `src/stores/status-store.ts` — 暴露 `lastModifierTrigger: { statusId: string, timestamp: number } | null`
- 修改 `src/services/choice-resolution/choice-resolution-engine.ts`（S2-3）— 当 applyToEffect 修正生效时通过 store 标记
- `src/stores/save-store.ts`（S1-3 已有）— profile.firstStatusShown 读写

### 教学气泡触发逻辑

```typescript
// StatusChip.vue 内
const showTip = computed(() => {
  return !saveStore.data.profile.firstStatusShown && isMyTurnToShow.value
})

watch(showTip, (val) => {
  if (val) {
    setTimeout(() => {
      saveStore.update({ profile: { ...saveStore.data.profile, firstStatusShown: true } })
    }, 1500)
  }
})
```

### Chip pulse 触发

ChoiceResolutionEngine 在 status 修正生效时（modified !== raw）emit 信号：
```typescript
// 简化思路：S2-3 在 applyToEffect 后判断是否修正，记录到 status-store
statusStore.markModifierApplied(statusId, Date.now())
```

StatusChip 监听自身 status.id 是否最近被 mark：
```typescript
const isPulsing = computed(() =>
  statusStore.lastModifierTrigger?.statusId === props.status.id &&
  Date.now() - statusStore.lastModifierTrigger.timestamp < 400
)
```

### 关键实现要点
- 教学气泡只在**任意一个 status** 首次出现时触发（不是每个 status 都触发自己的教学）
- pulse 触发**精确到帧**：与浮字数字同帧出现，让玩家看到"咖啡 chip 闪了一下"和"-10*" 的对应关系
- profile.firstStatusShown 是 boolean，set true 后永不重置

---

## Out of Scope

- 浮字数字 \* 标记（v1 设计，v2 删除）
- 多状态分别的教学（仅首次）
- 教学动画的复杂表现（如箭头指向）— 简单气泡即可

---

## QA Test Cases

### Manual Verification + Logic Test

**AC-1: 首次教学气泡触发**
- Setup: 删除 storage（npm run reset 或手动 uni.removeStorageSync）→ 启动游戏
- When: 玩到第一个含 buff 的事件 → 选择
- Verify: chip 出现 + 1.5s 气泡浮出"新效果！持续 2 天"
- Verify: 气泡消失后查 storage → profile.firstStatusShown === true
- Pass: 视觉气泡 + 持久化都正确

**AC-3/4: 后续不再触发**
- Setup: profile.firstStatusShown=true（人为 set）
- When: 再次拿 status
- Verify: chip 出现，但**无**气泡

**AC-5/6: chip pulse**
- Setup: 持有 ☕亢奋(energyMul=0.5)
- When: 下张卡选择含 energy -20
- Verify: chip 整体放大 1.1x → 回到 1.0x，期间 glow 加强（参考 prototype v3）
- Pass: 视觉同帧（与浮字 -10 同时）

**AC-7: 减少动画**
- Setup: 模拟器开启"减少动画"
- When: status 修正生效
- Verify: chip 静态高亮 350ms（无 scale 变化）

### Logic Test（追加到 save-service.test.ts）

**AC-2: 持久化**
- Given: profile.firstStatusShown=false
- When: 模拟教学气泡完成 + saveStore.update
- Then: storage 中 profile.firstStatusShown === true

---

## Test Evidence

**Story Type**: UI
**Required**:
- `production/qa/evidence/s2-10-status-onboarding.md` — 截图 + 视频 + sign-off
- 追加测试到 `tests/unit/save-service.test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- 前置: S2-1（status-store）, S2-3（修正触发信号）, S2-5（StatusChip 组件）, S2-7（profile.firstStatusShown 字段类型）
- 阻塞: 无
