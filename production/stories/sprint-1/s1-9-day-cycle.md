# S1-9: 日周期系统

> **Sprint**: 1 | **Priority**: Should Have | **Owner**: gameplay-programmer | **Estimate**: 1.0 day
> **Status**: backlog

## Goal

实现日周期系统：管理 5 天工作周节奏，每天事件数 [2, 3, 3, 4, 4]，emit 事件给局管理器和 UI。

## GDD Requirements Addressed

- day-cycle GDD 全部接口
- 局管理器依赖 onWeekCompleted 进入结算
- 事件卡系统依赖 eventCompleted 计数

## Technical Approach

### 文件

- `src/types/day-cycle.ts`
- `src/services/day-cycle/day-cycle-system.ts`
- `tests/unit/day-cycle-system.test.ts`

### 接口

```typescript
export class DayCycleSystem {
  startDay(day: number): void
  eventCompleted(): void
  getCurrentDay(): number
  getEventsToday(): { done: number; total: number }
  reset(): void

  readonly onDayStarted: TypedEventEmitter<{ day: number; total: number }>
  readonly onEventCompleted: TypedEventEmitter<{ done: number; total: number }>
  readonly onDayEnded: TypedEventEmitter<{ day: number }>
  readonly onWeekCompleted: TypedEventEmitter<{}>
}
```

### 关键实现要点

- `EVENTS_PER_DAY = [2, 3, 3, 4, 4]` 来自 day-cycle GDD
- 事件计数到当日总数时 emit `onDayEnded`（除非是第 5 天最后一个事件，emit `onWeekCompleted`）
- 不直接管资源/工资 — 由局管理器在 `onDayEnded` 监听后处理

## Acceptance Criteria

- [ ] 6 个 test case 通过
- [ ] 100% 行覆盖率

## Test Evidence

- **Type**: Logic
- **Path**: `tests/unit/day-cycle-system.test.ts`

## Dependencies

- 前置：S1-2, S1-4
- 阻塞：Sprint 2 局管理器
