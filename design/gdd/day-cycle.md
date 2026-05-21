# 日周期系统 (Day Cycle System)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-16
> **Implements Pillar**: 随开随走（天是最小完整单元）+ 三秒上手（每天结构清晰可预期）

## Overview

日周期系统是游戏节奏的时钟。它管理"当前第几天"、"这天还有几个事件要处理"、"一天结束时发生什么"。一局游戏=一个工作周（5天），每天是一个完整的微循环：开始→处理事件→结算→下一天。它确保每天的节奏有起伏——第一天轻松（2事件），最后一天紧张（4事件）。

## Player Fantasy

**间接幻想**：玩家感受到的是"周一到周五，一天比一天难熬"的真实打工节奏。周一轻松划水，周五被ddl逼到极限——这个系统在背后控制着这种节奏感。做得好=玩家觉得"和现实一样，但更夸张"。

## Detailed Design

### Core Rules

1. **工作周结构**：

```typescript
interface DayConfig {
  dayNumber: number       // 第几天 (1-5)
  eventsCount: number     // 当天事件数量
  dayName: string         // 显示名: "周一"..."周五"
  dailySalary: number     // 当天结算发放的薪水
  specialRule?: string    // 特殊规则ID (如"周三加班日")
}
```

2. **默认工作周配置**：

| Day | dayName | eventsCount | dailySalary | 特殊规则 |
|-----|---------|-------------|-------------|---------|
| 1 | 周一 | 2 | 10 | — |
| 2 | 周二 | 3 | 10 | — |
| 3 | 周三 | 3 | 10 | 加班概率+50% |
| 4 | 周四 | 3 | 10 | — |
| 5 | 周五 | 4 | 20 | 发薪日（双倍） |

3. **日循环流程**：
   - `DAY_START`: 显示"周X"日期卡片(0.5s动画) → 通知事件卡系统准备当天事件
   - `IN_PROGRESS`: 逐个呈现事件卡，等待玩家选择
   - `DAY_END`: 所有事件处理完毕 → **(1) 发放日薪 (resourceManager.applyEffects)** → **(2) emit `onDayEnded`** → **(3) 显示日结算摘要**。这个三步顺序是**契约**——状态效果系统的 `tickStatuses()` 监听 `onDayEnded` 触发，因此必须保证日薪先于 status 倒数（避免 status 天数倒数后才发薪导致语义混淆）
   - `TRANSITION`: 过渡到下一天 / 如果是最后一天 → 通知局管理器"周结束"

4. **事件数量由事件数据引擎提供**：
   - 调用 `eventDataEngine.getEventsPerDay(day)` 获取当天事件数
   - 配置在JSON中，可按职业自定义（如"程序员"周五有5个事件因为上线日）

5. **日薪发放规则**：
   - 每天结束时自动发放 `dailySalary` 到money
   - 周五双倍是基础规则，某些职业可覆盖
   - 日薪通过资源管理系统的 `applyEffects` 发放
   - **顺序契约**：`applyEffects(salary)` → `emit onDayEnded` → 摘要显示。订阅 onDayEnded 的下游（如状态效果系统的 tickStatuses）保证看到的是已发薪的资源状态

### States and Transitions

| 状态 | 含义 | 转换 |
|------|------|------|
| `IDLE` | 等待局管理器启动新天 | → `DAY_START`: 收到startDay指令 |
| `DAY_START` | 播放日期过渡动画 | → `IN_PROGRESS`: 动画结束/事件准备好 |
| `IN_PROGRESS` | 事件进行中，等待玩家交互 | → `DAY_END`: 所有事件处理完毕 |
| `IN_PROGRESS` | | → `INTERRUPTED`: 玩家死亡(由资源系统触发) |
| `DAY_END` | 日结算（发薪、显示摘要） | → `IDLE`: 进入下一天 |
| `DAY_END` | | → `WEEK_COMPLETE`: 第5天结束 |
| `INTERRUPTED` | 中途死亡 | → (交给局管理器) |
| `WEEK_COMPLETE` | 工作周圆满结束 | → (交给局管理器) |

### Interactions with Other Systems

| 系统 | 方向 | 接口 |
|------|------|------|
| 事件数据引擎 | ← 获取配置 | `getEventsPerDay(day): number` |
| 事件卡系统 | → 通知出牌 | `dayStarted(day, eventsCount)` |
| 局管理器 | ↔ 控制 | ← `startDay(dayNumber)` / → `dayCompleted(day)` / → `weekCompleted()` |
| 资源管理系统 | → 发薪 | `applyEffects([{target:'money', value: dailySalary}])` |
| 状态效果系统 | → onDayEnded 触发倒数 | 监听 `onDayEnded`。**顺序契约**：`applyEffects(dailySalary)` 先执行，**然后**才 emit `onDayEnded`，listener 调用 `tickStatuses()`。这保证 status 看到的是发薪后的资源状态。详见 `design/gdd/status-system.md` 与本 GDD Core Rule #3 |
| 游戏主界面 | → 状态 | `getCurrentDay(): DayState` + `onDayChanged` event |

## Formulas

### 每日事件数量

`eventsCount = baseEvents + jobModifier + dayModifier`

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| baseEvents | int | 2-4 | 基础事件数（按天递增） |
| jobModifier | int | -1 to +2 | 职业特殊修正（程序员周五+1） |
| dayModifier | int | -1 to +1 | 随机波动（增加不确定性） |

**Output Range:** 最终事件数 clamp 在 [1, 6] — 最少1个事件，最多6个。

**Example:** 周四(baseEvents=3), 程序员(jobModifier=0), 随机(dayModifier=+1)
- eventsCount = 3 + 0 + 1 = 4个事件

### 日薪计算

`actualSalary = baseSalary × dayMultiplier × jobSalaryRate`

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| baseSalary | int | 10 | 基础日薪 |
| dayMultiplier | float | 1.0-2.0 | 周五=2.0, 其余=1.0 |
| jobSalaryRate | float | 0.5-3.0 | 职业薪资倍率（程序员高、实习生低） |

## Edge Cases

- **If 玩家在日结算前死亡**：不发放当天日薪。已完成的事件效果已实时生效（不回滚）。

- **If 事件数据引擎返回0个事件**（所有事件冷却中）：最少保证1个事件（使用通用事件池兜底）。

- **If 玩家在"日开始"动画时退出游戏**：存档记录当前天数和状态为`DAY_START`，回来时跳过动画直接进入事件。

- **If 工作周配置被职业覆盖为3天或7天**：系统支持可变天数，`WEEK_COMPLETE`由天数配置决定而非硬编码5。

- **If 日薪计算结果为小数**：向上取整（`Math.ceil`）— 打工人不能亏。

## Dependencies

### 上游

| 系统 | 依赖类型 | 接口 |
|------|---------|------|
| 事件数据引擎 | Hard | `getEventsPerDay(day)` 读取每日事件数配置 |

### 下游

| 系统 | 接口 |
|------|------|
| 事件卡系统 | `dayStarted(day, eventsCount)` 通知准备事件 |
| 局管理器 | `dayCompleted(day)`, `weekCompleted()` |
| 状态效果系统 | `onDayEnded` 监听（在工资结算后触发 tick）|

### 公共接口

```typescript
interface DayCycleSystem {
  startDay(dayNumber: number): void
  getCurrentDay(): DayState
  getRemainingEvents(): number
  eventCompleted(): void
  onDayStarted: EventEmitter<DayStartEvent>
  onDayEnded: EventEmitter<DayEndEvent>
  onWeekCompleted: EventEmitter<void>
}

interface DayState {
  dayNumber: number
  dayName: string
  totalEvents: number
  completedEvents: number
  phase: 'IDLE' | 'DAY_START' | 'IN_PROGRESS' | 'DAY_END' | 'WEEK_COMPLETE' | 'INTERRUPTED'
}

interface DayStartEvent {
  dayNumber: number
  eventsCount: number
  specialRule?: string
}

interface DayEndEvent {
  dayNumber: number
  salaryEarned: number
  isLastDay: boolean
}
```

## Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 说明 |
|--------|--------|---------|------|
| `DAYS_PER_WEEK` | 5 | 3-7 | 每局工作天数。影响局时长（天数×每天事件数×选择时间） |
| `BASE_SALARY` | 10 | 5-50 | 基础日薪。影响money曲线 |
| `FRIDAY_MULTIPLIER` | 2.0 | 1.5-3.0 | 最后一天薪资倍率 |
| `MIN_EVENTS_PER_DAY` | 1 | 1-2 | 每天最少事件数 |
| `MAX_EVENTS_PER_DAY` | 6 | 4-8 | 每天最多事件数 |
| `DAY_TRANSITION_MS` | 500 | 200-1000 | 日期过渡动画时长(ms) |

## Acceptance Criteria

- **GIVEN** 新局开始, **WHEN** startDay(1)调用, **THEN** 状态变为DAY_START，dayName="周一"，eventsCount=2。

- **GIVEN** 当天3个事件, **WHEN** eventCompleted()被调用3次, **THEN** 状态变为DAY_END，触发日薪发放。

- **GIVEN** 第5天(周五)结束, **WHEN** 日结算完成, **THEN** emit weekCompleted事件，薪水为baseSalary×2。

- **GIVEN** 玩家在第3天第2个事件时死亡, **WHEN** 资源系统emit resourceDepleted, **THEN** 状态变为INTERRUPTED，不发放日薪。

- **GIVEN** 事件数据引擎为"程序员"职业配置周五5个事件, **WHEN** startDay(5), **THEN** eventsCount=5。

- **GIVEN** 中途退出游戏, **WHEN** 重新打开, **THEN** 恢复到正确的天数和事件进度（从存档读取）。
