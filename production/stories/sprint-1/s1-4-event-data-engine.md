# S1-4: 事件数据引擎

> **Sprint**: 1 | **Priority**: Must Have | **Owner**: gameplay-programmer | **Estimate**: 1.0 day
> **Status**: ready-for-dev

## Goal

实现事件数据引擎，加载 JSON 配置、schema 校验、按权重抽取、避免短期重复、失败兜底。

## GDD Requirements Addressed

- event-data-engine GDD 全部接口
- 事件卡系统依赖此引擎获取下一张事件
- 职业轮回依赖此引擎切换事件包

## Governing ADRs

- **ADR-001** — 暴露事件 emitter
- **ADR-002 分包策略** — `loadJobEvents(jobId)` 从分包路径加载，common-events 在主包

## Technical Approach

### 文件

- `src/types/event.ts` — `EventCard`, `Choice`, `Effect`, `BuffSpec`, `RiskOutcome` 等
- `src/services/event-data/event-data-engine.ts`
- `src/services/event-data/event-schema.ts` — schema 校验函数
- `src/services/event-data/fallback-events.ts` — 5 个硬编码兜底事件
- `tests/unit/event-data-engine.test.ts`

### 接口

```typescript
export class EventDataEngine {
  loadCommon(): Promise<void>
  loadJobEvents(jobId: string): Promise<void>
  unload(): void
  drawEvent(filter?: EventFilter): EventCard
  getEventById(id: string): EventCard | null
  readonly onLoadComplete: TypedEventEmitter<{ jobId: string; count: number }>
  readonly onLoadFailed: TypedEventEmitter<{ jobId: string; reason: string }>
}
```

### 关键实现要点

- 主包路径：`/static/events/common-events.json`
- 分包路径：`/subpackages/events/${jobId}-events.json`
- 抽取算法：
  1. 过滤 `tags` 满足 filter
  2. 排除最近 5 张已用事件（recent buffer）
  3. 按 `weight` 加权随机
- 兜底：网络/IO 失败重试 3 次，仍失败时返回硬编码兜底事件池
- schema 校验：每个 EventCard 必须有 `id`, `text`, `choiceA`, `choiceB`，否则忽略并 warn

## Acceptance Criteria

- [ ] 全部 10 个 test case 通过
- [ ] 100% 行覆盖率（含失败/兜底路径）
- [ ] 加权抽取分布正确（n=10000 时方差在期望范围内）
- [ ] schema 校验拒绝畸形事件而不是 throw

## Test Evidence

- **Type**: Logic
- **Path**: `tests/unit/event-data-engine.test.ts`

## Dependencies

- 前置：S1-1, S1-2
- 阻塞：S1-9（日周期需要事件计数）, Sprint 2 事件卡系统
