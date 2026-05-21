# S2-3: 选择结算引擎 service（含 status 集成 + risk 掷骰）

> **Sprint**: 2 | **Status**: Complete | **Layer**: Feature | **Type**: Integration | **Owner**: gameplay-programmer | **Estimate**: 1.0 day
> **Completed**: 2026-05-19
> **TR-ID**: pending | **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/choice-resolution.md` + `design/gdd/status-system.md` v2.1（status 集成）
**Requirement Summary**: 选项 effects 先经 statusSystem.applyToEffect 修正 → resourceManager.applyEffects；含 risk 字段时掷骰决定 success/fail outcome；含 buff 字段时在 effect 应用之后 addStatus；返回 ResolveResult 含 wasStatusModified 标记。

**Governing ADRs**:
- **ADR-001 事件通信机制** — 不直接 emit 事件，作为流程协调器调度其他 service
- **ADR-003 Store-Service 同步模式** — 引擎是无状态纯函数式服务

**Engine**: TypeScript strict | **Risk**: MEDIUM — 跨 4 个 service 协调（status / resource / save / event-card）

---

## Acceptance Criteria

*From `design/gdd/choice-resolution.md` Acceptance Criteria + `status-system.md` Logic AC #14:*

- [ ] AC-1: choice.effects=[{target:'energy',value:-20},{target:'money',value:+10}] → ResolveResult.deltas 正确反映两项变化
- [ ] AC-2: 持有 ☕亢奋(energyMul=0.5) + choice.effects=[{target:'energy',value:-20}] → 实际 energy 变化 -10，ResolveResult.deltas[0].wasStatusModified === true
- [ ] AC-3: choice 含 risk={chance:0.7, success, fail} → mock Math.random 强制 < 0.7 → 应用 success.effects；强制 ≥ 0.7 → 应用 fail.effects；ResolveResult.riskOutcome === 'success'/'fail'
- [ ] AC-4: choice 含 buff={...} → effect 应用之后 addStatus 调用（spy 验证调用顺序：applyToEffect → resourceManager.applyEffects → addStatus）
- [ ] AC-5: 资源管理 emit 'DEAD' → ResolveResult.stateChange === 'DEAD'
- [ ] AC-6: 选项含 followUpId → ResolveResult.followUpId 透传
- [ ] AC-7: choice.effects=[] → 正常返回 deltas=[]，仍调用 saveService.recordChoice
- [ ] AC-8: 任何选择被做出 → saveService.recordChoice 调用（spy）
- [ ] AC-9: Sprint 1 全部 81 个测试仍然通过（回归）
- [ ] AC-10: 集成测试 100% 行覆盖

---

## Implementation Notes

### 文件
- `src/services/choice-resolution/choice-resolution-engine.ts`
- `tests/integration/choice-resolution-flow.test.ts`

### 核心算法
```typescript
function resolveChoice(card: EventCard, key: 'A' | 'B'): ResolveResult {
  const choice = key === 'A' ? card.choiceA : card.choiceB

  // 1. 风险骰子（如有）→ 决定最终 effects
  let appliedEffects = choice.effects
  let riskOutcome: 'success' | 'fail' | undefined
  if (choice.risk) {
    const roll = Math.random()
    riskOutcome = roll < choice.risk.chance ? 'success' : 'fail'
    appliedEffects = choice.risk[riskOutcome].effects
  }

  // 2. status 修正（每个 effect 单独修正）
  const modifiedEffects = appliedEffects.map(fx => ({
    target: fx.target,
    value: statusSystem.applyToEffect(fx.target, fx.value)
  }))
  const wasModifiedFlags = appliedEffects.map((fx, i) =>
    modifiedEffects[i].value !== fx.value
  )

  // 3. ResourceManager 应用 modified effects
  const applyResult = resourceManager.applyEffects(modifiedEffects)

  // 4. **EFFECT 应用之后** addStatus（防止当前选择 effect 被刚加 buff 影响）
  if (choice.buff) {
    statusSystem.addStatus(choice.buff)
  }

  // 5. 存档记录
  saveService.recordChoice(card.id, key)

  // 6. 构造 ResolveResult
  return buildResolveResult(choice, applyResult, wasModifiedFlags, riskOutcome)
}
```

### 关键实现要点
- **顺序契约（关键 invariant）**：applyToEffect → applyEffects → addStatus，**不可乱序**
- 每个 modified effect 单独标记 wasStatusModified（不是整体一个 flag）
- risk 选项的 success/fail 也可包含自身的 buff 字段（递归同样的应用顺序）
- followUpId 仅透传，不在本故事处理 followUp 加载（S2-2 负责）

---

## Out of Scope

- **S2-1** 状态系统：本故事调用 statusSystem.applyToEffect 和 addStatus，但不实现它们
- **S2-2** 事件卡：本故事不管理卡片队列
- **S2-9** Risk dice 动画：UI 视觉反馈
- 被动技能 modifier（Alpha 阶段）：保留 hooks 但不实现

---

## QA Test Cases

### Integration Tests

**AC-1/2: status 修正完整流程**
- Given: statusSystem 持有 ☕亢奋(energyMul=0.5)，resourceManager.energy=80
- When: resolveChoice(card, 'A')，card.choiceA.effects=[{target:'energy',value:-20}]
- Then: 调用顺序 applyToEffect('energy',-20) → 返回 -10 → applyEffects([{value:-10}]) → resourceManager.energy=70
- Then: ResolveResult.deltas[0].wasStatusModified === true，delta=-10，rawDelta=-20

**AC-3: risk 掷骰**
- Given: vi.spyOn(Math, 'random')，card.choiceA.risk={chance:0.7, success:{effects:[{target:'mood',value:+30}]}, fail:{effects:[{target:'mood',value:-20}]}}
- When: random.mockReturnValue(0.5) → resolveChoice
- Then: ResolveResult.riskOutcome === 'success'，mood 应用 +30
- When: random.mockReturnValue(0.8) → resolveChoice
- Then: ResolveResult.riskOutcome === 'fail'，mood 应用 -20
- Edge: risk + status 同时（risk outcome.effects 也经 status 修正）

**AC-4: 顺序契约（关键）**
- Given: spy on statusSystem.applyToEffect, resourceManager.applyEffects, statusSystem.addStatus
- When: resolveChoice 含 buff={id:'newBuff',...} 且 effects=[{target:'energy',value:-10}]
- Then: 调用顺序断言（vi.spy.calls）：(1) applyToEffect → (2) applyEffects → (3) addStatus
- Verify: 当前 effect.value 在 applyEffects 时 = applyToEffect 的返回值（**不**受 newBuff 影响）

**AC-5: 死亡触发透传**
- Given: resourceManager mock applyEffects 返回 ApplyResult.triggered=['DEAD']
- When: resolveChoice
- Then: ResolveResult.stateChange === 'DEAD'

**AC-6: followUp 透传**
- Given: choice.followUpId='follow-bonus'
- When: resolveChoice
- Then: ResolveResult.followUpId === 'follow-bonus'

**AC-7: 空 effects**
- Given: choice.effects=[]
- When: resolveChoice
- Then: ResolveResult.deltas=[]，saveService.recordChoice 仍调用，resourceManager.applyEffects([]) 不报错

**AC-8: 存档调用**
- Given: spy on saveService.recordChoice
- When: 任意 resolveChoice
- Then: recordChoice(card.id, key) 调用 1 次

**AC-9: 回归**
- When: `npm test`（全套，包含 sprint-1 81 测试 + sprint-2 新测试）
- Then: 全部通过

---

## Test Evidence

**Story Type**: Integration
**Required**: `tests/integration/choice-resolution-flow.test.ts` — pass + sprint-1 全套回归通过
**Status**: [x] Created 2026-05-19 — 26 integration tests，100% lines / 100% branches / 100% functions on choice-resolution-engine.ts

## Completion Notes

**Files created**:
- `src/types/resolve.ts` — ResolveDelta（含 wasClamped + wasStatusModified 两个独立字段）+ ResolveResult
- `src/services/choice-resolution/choice-resolution-engine.ts` — 主引擎（170+ 行）
- `src/stores/choice-resolution-store.ts` — Pinia store + EventCardSystem.setResolveHandler 自动 wiring
- `tests/integration/choice-resolution-flow.test.ts` — 26 集成测试

**Verification**:
- npm test: 183/183 pass（含 sprint 1 81 + S2-1 46 + S2-2 30 + S2-3 26）
- npm run type-check: pass
- coverage（choice-resolution-engine.ts isolated）: 100% lines / 100% branches / 100% functions

**关键 invariant 验证**：
专门写了 spy 测试验证调用顺序 `applyToEffect → applyEffects → addStatus`：
1. "addStatus is called AFTER resourceApplyEffects (call order verification)" — vi.spy 确认顺序
2. "current choice effect is NOT modified by the buff that this choice adds" — 实际场景验证 invariant
3. "subsequent choice IS modified by the previously-added buff" — 反向验证 buff 在下张卡才生效

**Deviations**:
- ResolveDelta 拆分 `wasClamped`（Sprint 1 原 wasModified 含义）+ `wasStatusModified`（status 修正含义），解决 v2.1 评审 #9 的命名冲突

Ready for: `/code-review` → `/story-done`

---

## Dependencies

- 前置: S1-2, S1-3, S1-5, S2-1（statusSystem.applyToEffect/addStatus）, S2-2（card 数据结构 + EventDataEngine.getEventById for followUp）
- 阻塞: S2-4（局管理器需要 ResolveResult 判断死亡触发 DYING）
