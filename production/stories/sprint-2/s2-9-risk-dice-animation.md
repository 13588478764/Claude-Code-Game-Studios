# S2-9: Risk dice 动画 + 视觉反馈

> **Sprint**: 2 | **Status**: Backlog（Should Have）| **Layer**: Presentation | **Type**: Visual/Feel | **Owner**: ui-programmer | **Estimate**: 0.5 day
> **TR-ID**: pending | **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/event-card.md` Visual/Audio Requirements + `prototypes/core-loop/index.html` v3 视觉参考
**Requirement Summary**: Risk choice 触发时全屏 overlay 显示 dice 旋转 + 大字成功/翻车结果，对齐原型 v3 视觉。

**Governing ADRs**: ADR-003（Service emit → Store subscribe）

**Engine**: uni-app + Vue 3 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-1: 玩家选择 risk choice → 全屏 dice overlay 出现
- [ ] AC-2: dice 旋转动画约 1 秒（rotate 720deg + scale 0.5→1.3→1.0）
- [ ] AC-3: success → 显示绿色"✨ 成功"+ 发光描边
- [ ] AC-4: fail → 显示红色"💀 翻车"+ 发光描边
- [ ] AC-5: outcome 显示后保留 1 秒，整体 overlay 持续约 2 秒后自动消失
- [ ] AC-6: dice 期间禁用其他点击（pointer-events: none on game-main）
- [ ] AC-7: 视觉对齐 prototype v3（参考 prototypes/core-loop/index.html `.risk-overlay` 样式）

---

## Implementation Notes

### 文件
- `src/components/RiskDiceOverlay.vue` — 新组件
- 修改 `src/pages/index/index.vue` 集成 overlay
- 监听 `useChoiceResolutionStore()` 的 lastResult.riskOutcome（或新增 onRiskRoll emit）

### 视觉规范（对齐 prototype v3）
```css
.risk-overlay {
  position: absolute; inset: 0;
  background: rgba(0,0,0,0.85);
  display: flex; flex-direction: column;
  align-items: center; justify-content: center;
  z-index: 35;
}
.dice {
  font-size: 100px; animation: diceRoll 1s ease-out;
}
.risk-result-text {
  margin-top: 20px; font-size: 22px; font-weight: 800;
  animation: resolvePop 0.4s 0.8s both;
}
.risk-success { color: #4CD964; text-shadow: 0 0 20px rgba(76,217,100,0.6); }
.risk-fail { color: #FF6B6B; text-shadow: 0 0 20px rgba(255,107,107,0.6); }

@keyframes diceRoll {
  0% { transform: rotate(0) scale(0.5); opacity: 0; }
  50% { transform: rotate(360deg) scale(1.3); opacity: 1; }
  100% { transform: rotate(720deg) scale(1); opacity: 1; }
}
```

### 关键实现要点
- ChoiceResolutionEngine.resolveChoice 处理 risk 时，store 暴露 `lastRiskRoll: { outcome: 'success'|'fail', detail: string } | null`
- 监听 lastRiskRoll 变化触发 RiskDiceOverlay 显示 + 2s 后置 null
- 减少动画偏好：降级为静态 dice + 文字（无旋转）

---

## Out of Scope

- 风险概率展示（按钮上的 🎲 70% 标签）— 已在 S2-5 ChoiceButton 实现
- 多 dice / 复杂概率结构 — Beta 阶段

---

## QA Test Cases

### Manual Verification

**AC-1 ~ AC-7: 完整 risk 流程**
- Setup: 微信工具 + hardcoded 选择有 risk 字段的事件
- When: 玩家选择 risk choice
- Verify:
  - [ ] dice overlay 立即出现（< 100ms）
  - [ ] dice 旋转 720° 约 1 秒
  - [ ] success 显示绿色 ✨ 成功 / fail 显示红色 💀 翻车
  - [ ] 文字带 glow 效果
  - [ ] overlay 总时长约 2 秒
  - [ ] 期间点击 game-main 无反应
- Pass: 视觉对齐 prototype v3 截图

---

## Test Evidence

**Story Type**: Visual/Feel
**Required**:
- `production/qa/evidence/s2-9-risk-dice.md` — 视频片段（gif 或 mp4）+ 对比 prototype v3 截图 + ui-programmer sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- 前置: S2-3（lastRiskRoll store 字段）, S2-5（主界面有 overlay 容器）
- 阻塞: 无（visual polish，不影响其他故事）
