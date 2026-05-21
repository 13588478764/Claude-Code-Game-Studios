# S1-2: TypedEventEmitter 实现

> **Sprint**: 1 | **Priority**: Must Have | **Owner**: gameplay-programmer | **Estimate**: 0.5 day
> **Status**: ready-for-dev

## Goal

实现 ADR-001 规定的 TypedEventEmitter，作为所有 Service 层通信的基础。零依赖，类型安全，~30 行代码即可。

## GDD Requirements Addressed

- 资源管理 GDD: `onResourceChanged`/`onStateChanged`/`onResourceDepleted` 事件接口
- 事件数据引擎 GDD: `onLoadComplete`/`onLoadFailed` 事件接口
- 日周期 GDD: `onDayStarted`/`onDayEnded`/`onWeekCompleted` 事件接口
- 职业轮回 GDD: `onJobUnlocked`/`onJobSelected` 事件接口
- 局管理器 GDD: `onPhaseChanged`/`onRunEnded` 事件接口

## Governing ADRs

- **ADR-001 事件通信机制** — 自实现 TypedEventEmitter（不引入 mitt 等第三方库）

## Technical Approach

### 文件

- `src/services/common/event-emitter.ts`
- `tests/unit/event-emitter.test.ts`

### 接口

```typescript
type Handler<T> = (payload: T) => void

export class TypedEventEmitter<T> {
  on(handler: Handler<T>): void
  off(handler: Handler<T>): void
  once(handler: Handler<T>): void
  emit(payload: T): void
  clear(): void
  get size(): number
}
```

### 关键实现要点

- 使用 `Set<Handler<T>>` 存储 handler
- `emit` 内 try/catch 每个 handler，失败不阻塞其他
- 复制 set 后再迭代，避免 emit 内 on/off 引发 ConcurrentModification
- once 用包装 handler 实现，包装 handler 调用一次后 off 自身

## Acceptance Criteria

- [ ] 100% 行覆盖率
- [ ] 100% 分支覆盖率
- [ ] 类型推断：`new TypedEventEmitter<{ before: number; after: number }>()` 的 `emit` 参数类型正确
- [ ] 所有 10 个测试用例通过（见 QA plan）

## Test Evidence

- **Type**: Logic
- **Path**: `tests/unit/event-emitter.test.ts`

## Dependencies

- 前置：S1-1（脚手架）
- 阻塞：S1-3, S1-4, S1-5, S1-9, S1-10
