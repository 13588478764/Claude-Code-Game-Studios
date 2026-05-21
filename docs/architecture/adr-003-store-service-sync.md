# ADR-003: Store-Service 同步模式

## Status

Accepted

## Context

架构要求 Service 层（纯 TypeScript 游戏逻辑）不依赖 Vue/Pinia，但 Vue 组件需要响应式地消费 Service 产出的状态变化。需要确定 Store 层如何桥接这两者。

约束：
- Service 层不可 import Vue/Pinia（保证可独立测试）
- Vue 组件必须响应式更新（ref/reactive）
- 存档时机由 Service 控制（不依赖 Vue 生命周期）
- 数据流必须单向、可追踪

## Decision

**Service emit → Store subscribe（事件驱动同步）**

模式：
1. Service 模块通过 TypedEventEmitter 发出状态变化事件
2. Pinia Store 在 `defineStore` 的 setup 函数中订阅这些事件
3. 收到事件后，Store 更新自身的 `ref` 值
4. Vue 组件通过 `storeToRefs()` 响应式消费

完整数据流：
```
用户操作 → Vue emit → Store action → 调用 Service method
  → Service 执行逻辑 → Service emit event
    → Store listener 更新 ref → Vue 响应式重渲染
```

Store 实现模式：
```typescript
export const useResourceStore = defineStore('resource', () => {
  // State: 响应式包装
  const resources = ref<Resources>(resourceManager.getResources())
  const state = ref<ResourceState>(resourceManager.getState())

  // Subscribe: 监听 Service 事件
  resourceManager.onResourceChanged.on(event => {
    resources.value = event.after
  })
  resourceManager.onStateChanged.on(event => {
    state.value = event.newState
  })

  // Actions: 代理 Service 调用
  function applyEffects(effects: ResourceEffect[]): ApplyResult {
    return resourceManager.applyEffects(effects)
  }

  return { resources, state, applyEffects }
})
```

存档同步：
- Service 完成状态变更后，自行调用 SaveService（不经过 Store）
- Store 只负责 UI 同步，不参与持久化决策
- 顺序保证：Service method → 1. emit event(Store更新) → 2. SaveService.save()

## Consequences

**正面：**
- Service 层完全不知道 Vue/Pinia 存在——100% 可用 Vitest 单独测试
- 单向数据流清晰可追踪，调试时只需看 Service emit 历史
- Store 代码极简（只是 ref + listener + action proxy）
- 天然支持多个 consumer（Store 只是 Service 事件的消费者之一）

**负面：**
- 需要手动管理订阅生命周期（避免内存泄漏）
- Service 状态和 Store ref 之间存在短暂不一致窗口（emit→listener 是同步的，所以实际无延迟）
- 每个 Store 的 setup 需要写订阅代码（模板化但不可省略）

**缓解：**
- App 级 Store 在小程序生命周期内不销毁（无需 unsubscribe）
- 如需页面级 Store，在 `onUnmounted` 中 `store.$dispose()` + `emitter.clear()`
- 可抽取 `createServiceStore(service, eventMap)` 工具函数减少模板代码

## Engine Compatibility

不适用——纯 Vue 3 + Pinia 架构模式，无平台依赖。

## GDD Requirements Addressed

- 游戏主界面: "通过Pinia store响应式获取 resourceStore.resources"
- 游戏主界面: "监听 onResourceChanged 更新资源条数值+动画"
- 所有 Service: EventEmitter 接口的消费者实现方式
- 架构原则: "Store 是桥梁不是大脑"
