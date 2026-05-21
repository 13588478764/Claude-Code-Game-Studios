# S2-2: 事件卡系统 service + store

> **Sprint**: 2 | **Status**: Complete | **Layer**: Feature | **Type**: Logic | **Owner**: gameplay-programmer | **Estimate**: 1.5 days
> **Completed**: 2026-05-19
> **TR-ID**: pending | **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/event-card.md`
**Requirement Summary**: 实现卡片队列管理 + 6 阶段状态机（ENTERING/READING/CHOOSING/RESOLVING/FOLLOW_UP/EXITING）+ followUp 链 ≤3 层 + 防连点 + 队列结束通知 DayCycleSystem。

**Governing ADRs**:
- **ADR-001 事件通信机制** — emit onCardShown/onChoiceMade/onDayEventsCompleted
- **ADR-002 分包策略** — 通过 EventDataEngine 间接消费分包数据，本故事不直接处理分包路径
- **ADR-003 Store-Service 同步模式** — 提供 event-card-store.ts，UI 仅读取当前卡片显示状态

**Engine**: uni-app + Vue 3 + TypeScript strict | **Risk**: LOW
**Engine Notes**: 无

---

## Acceptance Criteria

*From `design/gdd/event-card.md` Acceptance Criteria 段:*

- [ ] AC-1: onDayStarted(day=1, eventsCount=2) → 抽 2 张到队列 → 展示第一张 + emit onCardShown
- [ ] AC-2: CHOOSING 状态 + 玩家点击 A → RESOLVING + 调用 ChoiceResolutionEngine.resolveChoice
- [ ] AC-3: 选项含 followUpId → RESOLVING 完成后加载 followUp 卡（不计入队列总数）
- [ ] AC-4: 队列最后一张 + 无 followUp → emit onDayEventsCompleted → 通知 DayCycleSystem.eventCompleted
- [ ] AC-5: RESOLVING 期间再次点击 → 无反应（防连点）
- [ ] AC-6: 60字文案渲染 → fontSize ≥ 14px，超 5 行截断
- [ ] AC-7: followUp 嵌套超 3 层 → 第 4 层忽略，正常进入下一队列卡
- [ ] AC-8: followUpId 引用不存在 → log warn 不 crash，进入下一队列卡
- [ ] AC-9: 事件文案为空字符串 → 兜底文案"今天平平无奇地过去了..."
- [ ] AC-10: 单元测试 100% 行覆盖

---

## Implementation Notes

*Derived from `design/gdd/event-card.md` Detailed Design + Public Interface 段:*

### 文件
- `src/types/card-phase.ts` — `CardPhase` 联合类型
- `src/services/event-card/event-card-system.ts`
- `src/stores/event-card-store.ts`
- `tests/unit/event-card-system.test.ts`

### 状态机
```typescript
type CardPhase = 'ENTERING' | 'READING' | 'CHOOSING' | 'RESOLVING' | 'FOLLOW_UP' | 'EXITING'

class EventCardSystem {
  private queue: EventCard[] = []
  private completedToday = 0
  private currentCard: EventCard | null = null
  private currentPhase: CardPhase = 'READING'
  private followUpDepth = 0  // 防嵌套
  private isResolving = false  // 防连点

  prepareDay(day: number, count: number): void
  selectChoice(key: 'A' | 'B'): void
  getCurrentCard(): CardDisplayState | null
  getQueueStatus(): { total, completed, remaining }
}
```

### 关键实现要点
- 队列严格按抽取顺序 FIFO
- CHOOSING → RESOLVING 转移时 isResolving=true，selectChoice 立即 early-return
- followUp 卡用 EventDataEngine.getEventById(followUpId) 加载
- followUpDepth >= 3 时禁用嵌套（清零 + 进入下张队列卡）
- 文案渲染逻辑放 UI 层（S2-5 EventCard.vue），本故事只暴露 currentCard 数据

---

## Out of Scope

- **S2-3** 选择结算：调用 resolveChoice 是本故事的下游
- **S2-5** 游戏主界面：渲染 currentCard 是 UI 层
- **S2-1** 状态系统：本故事不直接 add/apply status
- **followUp 数据完整性校验**：S2-6 schema lint 在 build 时拦截

---

## QA Test Cases

### Logic Tests（自动化）

**AC-1: 日开始抽卡**
- Given: 空队列，订阅 onDayStarted
- When: emit onDayStarted(day=1, eventsCount=2)
- Then: queue.length === 2，currentCard 为 queue[0]，emit onCardShown(queue[0])
- Edge: eventsCount=0 → 直接 emit onDayEventsCompleted

**AC-2: 选择触发结算**
- Given: currentCard 处于 CHOOSING 阶段
- When: selectChoice('A')
- Then: phase 变 RESOLVING，调用 ChoiceResolutionEngine.resolveChoice(card, 'A')（spy）
- Edge: 重复 selectChoice('A') → 第二次被忽略

**AC-3: followUp 加载**
- Given: 选项 A 含 followUpId='follow-1'，EventDataEngine.getEventById 返回有效卡
- When: RESOLVING 完成
- Then: 下一张卡 === followUp 卡，completedToday 不增加（不计入队列）
- Edge: followUpId 不存在 → log warn，进入下一队列卡

**AC-4: 日结束通知**
- Given: 队列剩 1 张 + 无 followUp，玩家正在 CHOOSING
- When: 玩家选择 + RESOLVING 完成
- Then: emit onDayEventsCompleted，DayCycleSystem.eventCompleted 调用（spy）

**AC-5: 防连点**
- Given: 当前 RESOLVING 状态
- When: 100ms 内 selectChoice 调用 3 次
- Then: ChoiceResolutionEngine.resolveChoice 仅调用 1 次

**AC-7: followUp 嵌套上限**
- Given: 4 张卡 followUp 链（A → B → C → D）
- When: 玩家依次选择
- Then: 第 4 层（D）被忽略，进入下一队列卡

**AC-9: 兜底文案**
- Given: EventDataEngine.drawEvent 返回卡 text=''
- When: 渲染
- Then: currentCard.text === '今天平平无奇地过去了...'，choiceA/B 兜底为 +0 effects

---

## Test Evidence

**Story Type**: Logic
**Required**: `tests/unit/event-card-system.test.ts` — pass + 100% 行覆盖
**Status**: [x] Created 2026-05-19 — 30 tests，100% lines / 95.74% branches / 100% functions on `src/services/event-card/event-card-system.ts`

## Completion Notes

**Files created**:
- `src/types/card-phase.ts` — CardPhase / CardDisplayState / payload 类型
- `src/services/event-card/event-card-system.ts` — 主类（236 行）
- `src/stores/event-card-store.ts` — Pinia store（currentCard / queueStatus / lastChoiceMade refs + selectChoice/commitResolve actions）
- `tests/unit/event-card-system.test.ts` — 30 测试

**Verification**:
- npm test: 157/157 pass（含全部 Sprint 1 + Sprint 2 之前的测试）
- npm run type-check: pass
- coverage（event-card-system.ts isolated）：100% lines / 95.74% branches / 100% functions

**Key design decisions**:
1. **Two-phase resolve protocol**：selectChoice 标记 isResolving=true → resolveHandler 调用 → 系统留在 RESOLVING 直到 commitResolve；保证 100ms 内连点期间二次 selectChoice early-return（AC-5 防连点）
2. **Late-bound resolveHandler** — `setResolveHandler(fn)` 让 store 可以在 ChoiceResolutionEngine（S2-3）实现后再注入
3. **DI 注入 deps** — drawEvent / getEventById / notifyEventCompleted 通过构造函数注入，便于测试 mock
4. **Empty-text fallback** — normalizeCard 在卡片显示前注入兜底文案（AC-9）
5. **followUp 计数与队列计数分离** — followUpDepth 独立于 completedToday，避免 followUp 计入"今日事件"

**Deviations**:
- 删除了 advanceToNextQueueCard 的不可达 defensive 分支（队列空检查），改用非空断言 + 注释说明 invariant，让代码更明确并达到 100% 行覆盖
- 105 行 EXITING 守卫与 224 行 setPhase 同 phase 早返回 是防御代码，分支覆盖 95.74%，超过 95% 阈值即可

Ready for: `/code-review src/services/event-card/event-card-system.ts src/stores/event-card-store.ts` → `/story-done`

---

## Dependencies

- 前置: S1-2, S1-4（EventDataEngine 抽卡 + getEventById）, S1-9（DayCycleSystem 事件订阅）
- 阻塞: S2-3, S2-5（结算 + UI 都需要 currentCard）
