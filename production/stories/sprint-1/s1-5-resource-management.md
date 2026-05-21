# S1-5: 资源管理系统

> **Sprint**: 1 | **Priority**: Must Have | **Owner**: gameplay-programmer | **Estimate**: 1.0 day
> **Status**: ready-for-dev

## Goal

实现资源管理 service：energy/mood/money 三资源、状态机（NORMAL/WARNING/CRISIS/DEAD）、事件 emit 给 store、应用 effects 时正确 clamp。

## GDD Requirements Addressed

- resource-management GDD 全部接口
- 选择结算引擎依赖 `applyEffects`
- 局管理器依赖状态变化事件判定死亡

## Governing ADRs

- **ADR-001** — emit `onResourceChanged`/`onStateChanged`/`onResourceDepleted`
- **ADR-003** — Service 不依赖 Pinia，store 订阅其事件

## Technical Approach

### 文件

- `src/types/resource.ts` — `Resources`, `ResourceState`, `Effect`, `ApplyResult`
- `src/services/resource/resource-manager.ts`
- `src/stores/resource-store.ts`
- `tests/unit/resource-manager.test.ts`

### 接口

```typescript
export interface Resources {
  energy: number  // 0-100
  mood: number    // 0-100
  money: number   // 可负
}

export type ResourceState = 'NORMAL' | 'WARNING' | 'CRISIS' | 'DEAD'

export class ResourceManager {
  init(initial: Resources): void
  getResources(): Readonly<Resources>
  getState(): ResourceState
  applyEffects(effects: Effect[]): ApplyResult
  reset(): void

  readonly onResourceChanged: TypedEventEmitter<{ before: Resources; after: Resources; deltas: ResourceDelta[] }>
  readonly onStateChanged: TypedEventEmitter<{ from: ResourceState; to: ResourceState }>
  readonly onResourceDepleted: TypedEventEmitter<{ which: 'energy' | 'mood' }>
}
```

### 状态机

```
state = computed:
  if energy <= 0 || mood <= 0: DEAD
  else if mood <= 20: CRISIS
  else if energy <= 30 || mood <= 30: WARNING
  else: NORMAL
```

### 关键实现要点

- `applyEffects` 单调原子：所有 effect 应用完毕后一次性 emit `onResourceChanged`
- state 变化只在前后值不同的时候 emit
- `applyResult` 包含每个资源的 before/after/delta，含 wasModified 标记
- store 订阅事件后更新 ref，UI 通过 storeToRefs 响应式消费

## Acceptance Criteria

- [ ] 全部 15 个 test case 通过（见 QA plan）
- [ ] 100% 行覆盖率（含状态机所有边界）
- [ ] 边界值：energy = 0/1/30/31/50/99/100 全部状态正确
- [ ] mood 同上
- [ ] money 可负、不 clamp
- [ ] applyEffects 多 effect 时 emit 顺序：先全部应用 → 再 emit changed → 再 emit state（如有变化）→ 再 emit depleted（如有）

## Test Evidence

- **Type**: Logic
- **Path**: `tests/unit/resource-manager.test.ts`

## Dependencies

- 前置：S1-2, S1-3
- 阻塞：S1-6, S1-7, Sprint 2 选择结算引擎
