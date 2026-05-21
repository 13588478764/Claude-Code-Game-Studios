# S2-1: 状态效果系统 service + store

> **Sprint**: 2 | **Status**: Complete | **Layer**: Feature | **Type**: Logic | **Owner**: gameplay-programmer | **Estimate**: 1.0 day
> **Completed**: 2026-05-19
> **TR-ID**: pending（tr-registry.yaml 待 `/architecture-review` 填充）
> **Manifest Version**: N/A — control-manifest.md 待 `/create-control-manifest` 创建

## Context

**GDD**: `design/gdd/status-system.md` v2.1（已通过设计评审 NEEDS REVISION → minor fixes resolved）
**Requirement Summary**: 实现槽位制状态系统：1 buff + 1 debuff 槽，strongest-wins 修正（无叠乘），signFloor 数学，订阅 RunManager.onPhaseChanged 模式清空，schema v1 兼容持久化。

**Governing ADRs**:
- **ADR-001 事件通信机制** — 状态系统通过 TypedEventEmitter 暴露 onStatusAdded/Replaced/Refreshed/Expired/Cleared/LoadCorrected/Changed
- **ADR-003 Store-Service 同步模式** — 提供独立 status-store.ts，UI 仅通过 store 读取，不直接 import statusSystem

**Engine**: uni-app + Vue 3 + TypeScript strict | **Risk**: LOW — 无外部依赖，纯 TS 逻辑
**Engine Notes**: 无（uni-app/Vue 3 在 LLM 训练数据范围内）

---

## Acceptance Criteria

*From `design/gdd/status-system.md` v2.1 Acceptance Criteria 段（Logic ACs，blocking）:*

- [ ] AC-1: addStatus 含 buff 字段 → getBuff() 返回该 status；getDebuff() 仍 null
- [ ] AC-2: applyToEffect('energy', -20) 持有 ☕亢奋(energyMul=0.5) → 返回 -10
- [ ] AC-3: tickStatuses 在 daysLeft=1 后 → 移除 + emit onStatusExpired
- [ ] AC-4: 同 id 再次 addStatus → days+mul 同时全替换 + emit onStatusRefreshed（不叠加）
- [ ] AC-5: 同槽位（buff）添加不同 id → 旧被替换 + emit onStatusReplaced；debuff 槽不动
- [ ] AC-6: buff(energyMul=0.5) + debuff(moodMul=1.5) 共存 → energy effect 仅受 buff、mood effect 仅受 debuff
- [ ] AC-7: signFloor(-19.95) === -19；signFloor(19.95) === 19；signFloor(0) === 0
- [ ] AC-8: 监听 RunManager.onPhaseChanged emit DYING → clearAll 未被调用，statuses 仍在
- [ ] AC-9: 监听 emit ENDED → clearAll 调用 + emit onStatusesCleared
- [ ] AC-10: loadSnapshot(undefined) → statuses=[]，无报错
- [ ] AC-11: loadSnapshot(含 daysLeft=0 的 entry) → 过滤 + emit onLoadCorrected
- [ ] AC-12: addStatus({days:0,...}) → 拒绝 + console.warn 含 status.id
- [ ] AC-13: 单元测试 100% 行覆盖（含全部分支：替换/刷新/strongest-wins/signFloor/tick/load corrupted/clearAll/DYING 不清空）

---

## Implementation Notes

*Derived from `design/gdd/status-system.md` v2.1 Detailed Design + Public Interface 段:*

### 文件
- `src/types/status.ts` — `StatusEffect`, `StatusSlot` 类型
- `src/services/status/status-system.ts` — 主类
- `src/stores/status-store.ts` — Pinia store（仅暴露 `buff`, `debuff` ref；UI 不调 mutation）
- `tests/unit/status-system.test.ts`

### 核心结构
```typescript
class StatusSystem {
  private buffSlot: StatusEffect | null = null
  private debuffSlot: StatusEffect | null = null

  addStatus(spec: StatusEffect): void {
    // schema 验证：days > 0 否则拒绝
    // 同 id 刷新：days + mul 全替换
    // 同槽位不同 id：替换并 emit onStatusReplaced
  }

  applyToEffect(target, rawValue): number {
    // strongest-wins：找对该 target 设了 mul 的那一个 status
    // signFloor 处理：负数 ceil + 正数 floor
  }

  tickStatuses(): void {
    // 每个槽位 daysLeft -= 1，0 时移除并 emit
  }
}

function signFloor(x: number): number {
  return x >= 0 ? Math.floor(x) : Math.ceil(x)
}
```

### 关键实现要点
- **不修改 ResourceManager**——v2.1 设计决策保护 Sprint 1 已实现的 ResourceManager 与 81 个测试
- 修正应用发生在 ChoiceResolutionEngine（S2-3）的上游，不在此故事范围
- 订阅 RunManager.onPhaseChanged 在 setup 时绑定，DYING/SETTLING 不响应，仅 ENDED 触发 clearAll
- `removeStatus(id)` 是内部方法（不暴露 public interface）
- emit `onStatusChanged` 作为合并通知供 UI 高效订阅

---

## Out of Scope

*由其他 sprint-2 故事处理，不在本故事范围:*

- **S2-3** 选择结算引擎：调用 `addStatus(spec)` 和 `applyToEffect(target, raw)` 的入口
- **S2-4** 局管理器：触发 `onPhaseChanged(ENDED)` 让 statusSystem clearAll
- **S2-5** 游戏主界面：消费 `status-store.ts` 的 buff/debuff ref 渲染胶囊
- **S2-7** Profile schema 扩展：firstStatusShown 字段（permanent slot）
- **S2-10** 教学气泡 + chip pulse：UI-side 视觉反馈

---

## QA Test Cases

*Source: `production/qa/qa-plan-sprint-2.md` "S2-1 状态系统" 段。开发者按这些用例实现，不另行造测试。*

### Logic Tests（自动化）

**AC-1: slot 添加**
- Given: 全新 statusSystem 无任何 status
- When: addStatus({id:'caffeine', name:'亢奋', icon:'☕', type:'buff', daysLeft:2, energyMul:0.5})
- Then: getBuff() 返回该 status，getDebuff() 返回 null，emit onStatusAdded
- Edge: addStatus 同时含 type='debuff' 同 id → 同槽位逻辑

**AC-2: applyToEffect 修正**
- Given: 持有 ☕亢奋(energyMul=0.5)
- When: applyToEffect('energy', -20)
- Then: 返回 -10
- Edge: applyToEffect('mood', -20) → 返回 -20（亢奋无 moodMul）

**AC-3: tickStatuses 倒数**
- Given: 持有 ☕亢奋(daysLeft=1)
- When: tickStatuses()
- Then: getBuff() === null，emit onStatusExpired({...亢奋})
- Edge: daysLeft=2 → tick → 1（仍 active）

**AC-4: 同 id 刷新**
- Given: 持有 💔emo(daysLeft=2, moodMul=1.5)
- When: addStatus({id:'emo', daysLeft:1, moodMul:1.3, ...})
- Then: getDebuff().daysLeft === 1, getDebuff().moodMul === 1.3，emit onStatusRefreshed({id:'emo', oldDays:2, newDays:1})
- Edge: 新 mul 缺失 → 仍 take new（mul=undefined，applyToEffect 时 mul=1.0）

**AC-5: 同槽位替换**
- Given: 持有 ☕亢奋（buff 槽）
- When: addStatus({id:'energetic', type:'buff', ...})
- Then: getBuff().id === 'energetic'（旧的 ☕被踢），emit onStatusReplaced({slot:'buff', old:'caffeine', new:'energetic'})；getDebuff() 不变
- Edge: 添加 type='debuff' → buff 槽不动

**AC-6: 跨槽位独立**
- Given: 同时持有 ☕亢奋(energyMul=0.5) 和 💔emo(moodMul=1.5)
- When: applyToEffect('energy', -20) 和 applyToEffect('mood', -10)
- Then: energy 返回 -10（仅 buff），mood 返回 -15（仅 debuff）

**AC-7: signFloor 边界**
- Given: signFloor 函数
- When: 输入 -19.95 / 19.95 / 0 / -10 / 10
- Then: 输出 -19 / 19 / 0 / -10 / 10（向 0 取整）

**AC-8: DYING 不清空**
- Given: 持有 1 buff + 1 debuff，订阅了 mock RunManager.onPhaseChanged
- When: emit phase=DYING
- Then: clearAll 未被调用（spy）；getBuff/getDebuff 仍返回原 status

**AC-9: ENDED 清空**
- Given: 同上
- When: emit phase=ENDED
- Then: clearAll 调用，getBuff()===null && getDebuff()===null，emit onStatusesCleared

**AC-10/11: loadSnapshot 兼容**
- Given: statusSystem 实例
- When: loadSnapshot(undefined) / loadSnapshot([{daysLeft:0,...}])
- Then: undefined → []，无报错；含 daysLeft=0 → 过滤 + emit onLoadCorrected({dropped:[...]})

**AC-12: schema 验证**
- Given: statusSystem 实例
- When: addStatus({days:0,...})
- Then: status 未添加，console.warn 调用且消息含 status.id

---

## Test Evidence

**Story Type**: Logic
**Required**: `tests/unit/status-system.test.ts` — must exist + pass + 100% 行覆盖
**Status**: [x] Created 2026-05-19 — 46 测试，100% lines / 100% branches / 100% functions on `src/services/status/status-system.ts`

## Completion Notes

**Files created**:
- `src/types/run-phase.ts` — RunPhase 联合类型 + PhaseChangedPayload（S2-4 将扩展）
- `src/types/status.ts` — StatusEffect / StatusSlot / 事件 payload 类型
- `src/services/status/status-system.ts` — 主类（246 行）
- `src/stores/status-store.ts` — Pinia store（buff/debuff refs）
- `tests/unit/status-system.test.ts` — 46 测试

**Verification**:
- npm test: 127/127 pass（Sprint 1 81 + Sprint 2 S2-1 46）
- npm run type-check: pass
- coverage（status-system.ts isolated）: 100% lines / 100% branches / 100% functions

**Code Review**: APPROVED WITH SUGGESTIONS（2026-05-19）
- 0 BLOCKING / 0 CHANGES REQUIRED
- 3 SUGGESTION（非阻塞）：getBuff/getDebuff 返回 Readonly 类型 / removeStatus 内联省略 INFO / accessor doc 风格统一——记入技术债清单

**Deviations**:
- Sprint 1 deps（S1-2/S1-3/S1-9）形式状态为 review，按用户授权 [A] 进行——功能上 81 测试通过证明 deps 就绪
- removeStatus 方法内联到 tickStatuses 和 clearAll 中（DRY 不违反，简化代码；GDD 注释中标记的内部方法）

**Manual Suggestion 1 followup**: getBuff/getDebuff 返回内部引用而非副本，未来若 S2-5 UI 出现意外 mutation 再处理

---

## Dependencies

- 前置: S1-2（TypedEventEmitter）, S1-3（SaveService 用于 loadSnapshot 测试 mock）, S1-9（DayCycleSystem 提供 onDayEnded 订阅契约——本故事仅订阅，不实际触发）
- 阻塞: S2-3, S2-4, S2-5（所有下游集成都依赖 statusSystem）
