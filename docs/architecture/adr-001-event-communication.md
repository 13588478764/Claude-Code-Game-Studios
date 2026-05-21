# ADR-001: 事件通信机制

## Status

Accepted

## Context

Service 层模块需要互相通知状态变化（如 ResourceManager 通知 RunManager 资源归零），但按架构原则 Service 层不应依赖 Vue/Pinia。需要一个轻量的进程内事件通信方案。

涉及的通信路径：
- ResourceManager → RunManager (resourceDepleted)
- ResourceManager → resourceStore (resourceChanged, stateChanged)
- DayCycleSystem → EventCardSystem (dayStarted)
- DayCycleSystem → RunManager (weekCompleted)
- EventCardSystem → DayCycleSystem (dayEventsCompleted)
- JobRotationSystem → UI (jobUnlocked)
- RunManager → UI (phaseChanged, runEnded)

## Decision

**自实现 TypedEventEmitter（~30行）**

实现一个类型安全的最小事件发射器，作为 Service 层所有模块的通信基础设施。

```typescript
// src/services/typed-event-emitter.ts
type Handler<T> = (data: T) => void

export class TypedEventEmitter<T> {
  private handlers: Set<Handler<T>> = new Set()

  on(handler: Handler<T>): void {
    this.handlers.add(handler)
  }

  off(handler: Handler<T>): void {
    this.handlers.delete(handler)
  }

  emit(data: T): void {
    this.handlers.forEach(handler => handler(data))
  }

  once(handler: Handler<T>): void {
    const wrapper: Handler<T> = (data) => {
      this.off(wrapper)
      handler(data)
    }
    this.on(wrapper)
  }

  clear(): void {
    this.handlers.clear()
  }
}
```

使用方式：
```typescript
class ResourceManager {
  onResourceChanged = new TypedEventEmitter<ResourceChangeEvent>()
  onResourceDepleted = new TypedEventEmitter<'energy' | 'mood'>()
}
```

## Consequences

**正面：**
- Service 层零外部依赖，纯 TypeScript 可在任何环境运行
- 完全类型安全——订阅者得到正确的泛型类型推断
- 可独立单元测试（无需 mock Vue/Pinia）
- 代码极少，无维护负担

**负面：**
- 缺少 mitt 的一些便利功能（通配符订阅、调试工具）
- 无自动内存泄漏检测（需手动 off 或 clear）
- Store 层需要在 setup 中手动订阅

**缓解：**
- Store 的 `$dispose` 或 `onUnmounted` 时调用 `clear()`
- 事件数量有限（<15个），手动管理完全可控

## Engine Compatibility

不适用——本项目使用 uni-app 框架，非游戏引擎。TypedEventEmitter 为纯 TypeScript 实现，无平台依赖。

## GDD Requirements Addressed

- 所有 GDD 中定义的 `onXxx: EventEmitter<T>` 接口均通过此实现覆盖
- 资源管理系统: onResourceChanged, onStateChanged, onResourceDepleted
- 日周期系统: onDayStarted, onDayEnded, onWeekCompleted
- 事件卡系统: onCardShown, onChoiceMade, onDayEventsCompleted
- 职业轮回系统: onJobUnlocked
- 局管理器: onPhaseChanged, onRunEnded
