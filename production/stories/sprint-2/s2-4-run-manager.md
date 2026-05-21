# S2-4: 局管理器 service + store（RunPhase 6 态状态机）

> **Sprint**: 2 | **Status**: Complete | **Layer**: Feature | **Type**: Integration | **Owner**: gameplay-programmer | **Estimate**: 1.5 days
> **Completed**: 2026-05-19
> **TR-ID**: pending | **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/run-manager.md`
**Requirement Summary**: 实现 RunManager 6 态状态机（JOB_SELECT/INITIALIZING/PLAYING/DYING/SETTLING/ENDED）；监听 onResourceDepleted 触发 DYING；续命/拒绝/通关流程；ENDED 时通过 onPhaseChanged 通知 statusSystem.clearAll；rating 计算映射 S/A/B/C/D。

**Governing ADRs**:
- **ADR-001 事件通信机制** — emit onPhaseChanged / onRunEnded（statusSystem 订阅 onPhaseChanged 实现 ENDED 清空）
- **ADR-003 Store-Service 同步模式** — run-store.ts 桥接到 UI

**Engine**: TypeScript strict | **Risk**: MEDIUM — 状态机复杂度 + 跨多 service 协调

---

## Acceptance Criteria

*From `design/gdd/run-manager.md` Acceptance Criteria 段:*

- [ ] AC-1: PLAYING + onResourceDepleted('energy') → DYING 状态，emit onPhaseChanged({from:'PLAYING',to:'DYING'})
- [ ] AC-2: DYING + 续命广告成功 → PLAYING，energy 恢复至 50
- [ ] AC-3: DYING + 拒绝续命 → SETTLING，准备结算数据
- [ ] AC-4: SETTLING 结算完毕 → ENDED，emit onRunEnded(RunResult)
- [ ] AC-5: PLAYING + onWeekCompleted（最后一天最后事件，未死亡）→ SETTLING（通关）
- [ ] AC-6: 死亡 + weekCompleted 同帧 → 优先判定 DYING（不算通关）
- [ ] AC-7: 监听 ENDED 的下游（statusSystem）收到 onPhaseChanged({to:'ENDED'}) → clearAll 调用（spy 验证）
- [ ] AC-8: rating 公式：survival×0.4 + money×0.3 + variety×0.3 → 映射 S(≥0.9)/A(≥0.7)/B(≥0.5)/C(≥0.3)/D(<0.3)
- [ ] AC-9: ENDED → JOB_SELECT 转移时 saveService.clearRunState 调用
- [ ] AC-10: 单局只允许 1 次续命（第二次死亡直接进 SETTLING，不再续命）
- [ ] AC-11: 续命广告失败 → 进入 SETTLING（不留在 DYING）
- [ ] AC-12: 集成测试覆盖 6 态全部转移路径

---

## Implementation Notes

### 文件
- `src/types/run-phase.ts` — `RunPhase` 联合类型 + `RunResult` 接口
- `src/services/run-manager/run-manager.ts`
- `src/stores/run-store.ts`
- `tests/integration/run-manager-flow.test.ts`

### 核心结构
```typescript
type RunPhase = 'JOB_SELECT' | 'INITIALIZING' | 'PLAYING' | 'DYING' | 'SETTLING' | 'ENDED'

class RunManager {
  private phase: RunPhase = 'JOB_SELECT'
  private revivedThisRun = false
  private runResult: RunResult | null = null

  readonly onPhaseChanged = new TypedEventEmitter<{from: RunPhase, to: RunPhase}>()
  readonly onRunEnded = new TypedEventEmitter<RunResult>()

  // 订阅资源系统
  constructor() {
    resourceManager.onResourceDepleted.on(({which}) => {
      if (this.phase === 'PLAYING') this.transitionTo('DYING')
    })
    dayCycleSystem.onWeekCompleted.on(() => {
      if (this.phase === 'PLAYING') this.transitionTo('SETTLING')
    })
  }

  selectJob(jobId): void  // JOB_SELECT → INITIALIZING
  startNewRun(jobId): Promise<void>  // INITIALIZING → PLAYING
  requestRevive(): Promise<boolean>  // DYING + 广告 → PLAYING / SETTLING
  declineRevive(): void  // DYING → SETTLING
  endRun(): void  // SETTLING → ENDED → JOB_SELECT

  computeRating(): 'S' | 'A' | 'B' | 'C' | 'D'
}
```

### 关键实现要点
- **同帧死亡 + weekCompleted**：emit 顺序由资源系统先（applyEffects 内部 emit onResourceDepleted），DayCycleSystem 后（onDayEnded 触发后链路）。RunManager 在 PLAYING 状态先收到 onResourceDepleted → 进入 DYING → 后续 onWeekCompleted 时 phase 已不是 PLAYING，忽略
- **revivedThisRun 标志**：续命成功后置为 true，第二次 onResourceDepleted 直接 transitionTo('SETTLING')
- **statusSystem 订阅 ENDED 模式**：本故事仅触发 emit，不直接调 statusSystem.clearAll（避免跨 service 直接耦合）
- ENDED → JOB_SELECT 转移在 endRun 末尾，作为清理步骤

---

## Out of Scope

- **S2-1** 状态清空：statusSystem 自己订阅 onPhaseChanged
- **S2-2** 事件卡：日循环驱动由 DayCycleSystem 负责
- **S2-11** Settle screen 渲染：UI 层
- **广告 SDK 真实集成**：本故事用 mock showReviveAd，真实集成在 Alpha 阶段

---

## QA Test Cases

### Integration Tests

**AC-1: 死亡进入 DYING**
- Given: phase=PLAYING，spy on onPhaseChanged
- When: resourceManager emit onResourceDepleted({which:'energy'})
- Then: phase=DYING，emit onPhaseChanged({from:'PLAYING',to:'DYING'})

**AC-2: 续命恢复**
- Given: phase=DYING，mock showReviveAd resolve(true)
- When: requestRevive() await
- Then: phase=PLAYING，resourceManager.energy === 50（applyEffects 调用 spy 验证），revivedThisRun=true

**AC-3: 拒绝续命**
- Given: phase=DYING
- When: declineRevive()
- Then: phase=SETTLING

**AC-4: 结算完成**
- Given: phase=SETTLING，runResult 已构造
- When: endRun()
- Then: phase=ENDED，emit onRunEnded(runResult)
- Then: 接着 phase=JOB_SELECT，saveService.clearRunState 调用

**AC-5: 通关进入 SETTLING**
- Given: phase=PLAYING（最后一天最后事件结算后未死亡）
- When: dayCycleSystem emit onWeekCompleted
- Then: phase=SETTLING

**AC-6: 死亡优先于通关**
- Given: phase=PLAYING
- When: 同帧 emit onResourceDepleted 和 onWeekCompleted（按代码顺序 resource 先）
- Then: phase=DYING（不是 SETTLING）

**AC-7: ENDED 触发 status 清空**
- Given: statusSystem 订阅 onPhaseChanged，spy on statusSystem.clearAll
- When: phase 进入 ENDED（emit onPhaseChanged）
- Then: clearAll 调用 1 次

**AC-8: rating 计算**
- Given: survival=5/5, money=80/100, variety=15/20
- When: computeRating()
- Then: rating = 5/5×0.4 + 80/100×0.3 + 15/20×0.3 = 0.4+0.24+0.225 = 0.865 → 'A'
- Edge: 全 0 → 'D'，全 1.0 → 'S'

**AC-10: 单局 1 次续命**
- Given: revivedThisRun=true（已续命过）
- When: 第二次 onResourceDepleted
- Then: phase=DYING → 自动 declineRevive → phase=SETTLING（不再 prompt 广告）

**AC-11: 续命广告失败**
- Given: phase=DYING，mock showReviveAd resolve(false)
- When: requestRevive() await
- Then: phase=SETTLING（不留 DYING）

---

## Test Evidence

**Story Type**: Integration
**Required**: `tests/integration/run-manager-flow.test.ts` — 100% 覆盖全部 6 态转移
**Status**: [x] Created 2026-05-19 — 37 integration tests，100% lines / 96.36% branches / 100% functions on run-manager.ts

## Completion Notes

**Files created**:
- `src/types/run-phase.ts` — 扩展含 RunRating / RunResult / RatingContext / DepletionSource / JobInfo
- `src/services/run-manager/run-manager.ts` — 6 态状态机 + 订阅模式（200+ 行）
- `src/stores/run-store.ts` — Pinia store + 自动 wire status/resource subscriptions
- `tests/integration/run-manager-flow.test.ts` — 37 集成测试（含 6 态全转移 + 完整死亡/通关 lifecycle）

**Verification**:
- npm test: 220/220 pass
- npm run type-check: pass
- coverage（run-manager.ts isolated）: 100% lines / 96.36% branches / 100% functions

**Key flows tested**:
1. 6 态全转移（完整 lifecycle 死亡路径 + 通关路径）
2. AC-2: revive ad success → energy +50（spy 验证 applyResourceEffects）
3. AC-6: 同帧死亡 + week-completed → DYING 优先（after death, week emit ignored）
4. AC-7: ENDED 触发 statusSystem.clearAll（subscribeToRunPhase 集成验证）
5. AC-8: rating 公式精确验证 5 grade 边界（S=0.9+, A=0.7+, B=0.5+, C=0.3+, D<0.3）
6. AC-10: revivedThisRun 阻断第二次续命（auto-decline 不再 show ad）
7. AC-11: 续命失败 → SETTLING

**Deviations**: None

Ready for: `/code-review` → `/story-done`

---

## Dependencies

- 前置: S1-2, S1-3, S1-5, S1-9, S1-10, S2-1（statusSystem 订阅 onPhaseChanged 是另一侧的事，由 statusSystem 自己实现）
- 阻塞: S2-5, S2-8, S2-11（UI 渲染 + smoke + settle screen 都依赖 RunPhase 状态）
