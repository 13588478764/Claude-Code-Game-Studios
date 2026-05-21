# 事件卡系统 (Event Card System)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-16
> **Implements Pillar**: 三秒上手（二选一是最简交互）+ 一局一笑（卡片文案是搞笑的载体）

## Overview

事件卡系统是玩家与游戏交互的唯一界面——它负责将事件数据引擎提供的EventCard数据渲染为可交互的卡片UI，管理卡片的展示队列、玩家选择的捕获、选择后的结果动画、以及followUp事件链的触发。每张卡片=一个荒诞的职场情景+两个同样离谱的选项。这是支柱"三秒上手"的直接体现：看一段话，点一个按钮，就是全部操作。

## Player Fantasy

**直接幻想**：每张卡片就像一个"你会怎么做"的小剧场。玩家觉得自己是故事的主角，每个选择都在塑造"我的打工人生"。好的卡片让人读完先笑，然后纠结选哪个——因为两个选项都很搞笑但后果很不同。服务支柱：**一局一笑** — 文案直接承载幽默；**三秒上手** — 读+点=完成一次交互。

## Detailed Design

### Core Rules

1. **卡片生命周期**：

```typescript
type CardPhase = 
  | 'ENTERING'      // 卡片入场动画 (从下方滑入, 300ms)
  | 'READING'       // 展示事件文案, 等待玩家阅读
  | 'CHOOSING'      // 玩家可以点击选项A或B
  | 'RESOLVING'     // 选择后, 显示结果(资源变化动画)
  | 'FOLLOW_UP'     // 如果有后续事件, 短暂过渡后展示下一张
  | 'EXITING'       // 卡片退场动画 (向上飘出, 200ms)
```

2. **卡片展示规则**：
   - 一次只展示一张卡片（不堆叠、不预览下一张）
   - 事件文案在`READING`阶段全部可见，选项按钮在底部
   - 选项A在左/上，选项B在右/下（固定位置，不随机）
   - 文案超过3行时自动缩小字号（最小14px），超过5行截断并加"..."

3. **玩家交互方式**：
   - 主交互：点击选项A或选项B按钮
   - 无滑动手势（避免误操作，保持极简）
   - 选中后按钮高亮0.3s → 进入RESOLVING阶段
   - RESOLVING期间不可再次点击（防连点）

4. **结果展示**：
   - 选择后显示资源变化动画（"+20💰"、"-30⚡"飘字）
   - 资源变化动画持续1s，期间资源条同步动画
   - 如果触发了状态变化（WARNING/CRISIS），额外显示状态提示

5. **followUp事件链**：
   - 如果选项有`followUp`字段，结果展示后自动加载下一张卡
   - followUp卡不计入当日事件数量（是前一张的延续）
   - 最多支持3层嵌套followUp（防止无限链）

6. **事件队列管理**：
   - 每天开始时，从事件数据引擎抽取当天所有事件到队列
   - 按队列顺序逐张展示
   - 队列清空 → 通知日周期系统`eventCompleted()`（最后一个事件完成时）
   - 中间不可跳过（每张必须选择）

### States and Transitions

| 状态 | 含义 | 转换 |
|------|------|------|
| `IDLE` | 无卡片展示, 等待日周期系统通知 | → `LOADING`: 收到dayStarted |
| `LOADING` | 从事件数据引擎抽取事件到队列 | → `SHOWING`: 队列就绪 |
| `SHOWING` | 正在展示当前卡片(ENTERING→READING→CHOOSING) | → `RESOLVING`: 玩家做出选择 |
| `RESOLVING` | 播放结果动画 | → `SHOWING`: 队列中还有卡 / 有followUp |
| `RESOLVING` | | → `DAY_DONE`: 队列清空且无followUp |
| `DAY_DONE` | 今日事件全部完成 | → `IDLE`: 通知日周期系统后 |

### Interactions with Other Systems

| 系统 | 方向 | 接口 |
|------|------|------|
| 事件数据引擎 | ← 获取事件 | `drawEvent(context): EventCard`（调用N次填充队列） |
| 日周期系统 | ← 接收通知 | 监听 `onDayStarted` 事件 |
| 日周期系统 | → 完成通知 | 调用 `eventCompleted()` 每完成一个事件 |
| 选择结算引擎 | → 传递选择 | `resolveChoice(eventCard, choiceKey): ResolveResult` |
| 游戏主界面 | → 提供UI状态 | `getCurrentCard(): CardDisplayState` |
| 资源管理系统 | ← 间接(通过选择结算引擎) | 结果反映到资源条 |

## Formulas

### 卡片阅读时间估算（用于数据分析，非游戏逻辑）

`estimatedReadTime = (textLength / READ_SPEED) + CHOICE_THINK_TIME`

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| textLength | int | 10-100 | 事件文案+两个选项的总字数 |
| READ_SPEED | float | 5.0 | 中文阅读速度(字/秒) |
| CHOICE_THINK_TIME | float | 2.0s | 平均决策思考时间 |

**Output Range:** 4-22秒/张卡片。用于验证"一局1-3分钟"的设计目标。

**Example:** 事件文案30字 + 选项A 10字 + 选项B 10字 = 50字
- estimatedReadTime = 50/5 + 2 = 12秒

### 单局时长验证

`sessionTime = sum(eventsPerDay) × avgCardTime + dayTransitions × DAY_TRANSITION_MS`

5天默认配置: (2+3+3+3+4)=15事件 × 12秒 + 5×0.5秒 = 182.5秒 ≈ 3分钟 ✓

## Edge Cases

- **If 事件数据引擎返回的事件少于请求数**（池枯竭）：用实际返回数量，不补齐。当天可能只有1-2个事件。

- **If followUp引用的事件ID不存在**：跳过followUp，正常进入下一张队列卡。log警告但不crash。

- **If followUp嵌套超过3层**：第4层followUp被忽略，当前卡正常结束。

- **If 玩家在RESOLVING动画期间退出**：选择已生效（资源已变化），存档标记该事件已完成。回来时直接展示下一张。

- **If 事件文案为空字符串**：显示兜底文案"今天平平无奇地过去了..."，两个选项都是"+0所有资源"。

- **If 两个选项的效果完全相同**：允许——这是设计意图（有时选项只是文案不同，制造幽默效果）。

## Dependencies

### 上游

| 系统 | 依赖类型 | 接口 |
|------|---------|------|
| 事件数据引擎 | Hard | `drawEvent(context)` 获取事件数据 |
| 日周期系统 | Hard | `onDayStarted` 触发每天开始 |
| 职业轮回系统 | Soft | 当前职业决定事件池（通过事件数据引擎间接） |

### 下游

| 系统 | 接口 |
|------|------|
| 选择结算引擎 | `resolveChoice(card, choice)` |
| 游戏主界面 | UI渲染当前卡片状态 |

### 公共接口

```typescript
interface EventCardSystem {
  prepareDay(dayNumber: number, eventsCount: number): void
  getCurrentCard(): CardDisplayState | null
  selectChoice(choiceKey: 'A' | 'B'): void
  getQueueStatus(): { total: number; completed: number; remaining: number }
  onCardShown: EventEmitter<EventCard>
  onChoiceMade: EventEmitter<{ card: EventCard; choice: 'A' | 'B' }>
  onDayEventsCompleted: EventEmitter<void>
}

interface CardDisplayState {
  card: EventCard
  phase: CardPhase
  resolveResult?: ResolveResult
}
```

## Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 说明 |
|--------|--------|---------|------|
| `CARD_ENTER_MS` | 300 | 150-500 | 卡片入场动画时长 |
| `CARD_EXIT_MS` | 200 | 100-400 | 卡片退场动画时长 |
| `RESOLVE_DISPLAY_MS` | 1000 | 500-2000 | 结果展示时长 |
| `FOLLOW_UP_DELAY_MS` | 500 | 200-1000 | followUp卡过渡延迟 |
| `MAX_FOLLOW_UP_DEPTH` | 3 | 1-5 | followUp最大嵌套层数 |
| `MIN_FONT_SIZE_PX` | 14 | 12-16 | 文案最小字号 |
| `MAX_TEXT_LINES` | 5 | 3-8 | 文案最大行数(超出截断) |

## Acceptance Criteria

- **GIVEN** 日周期系统emit dayStarted(day=1, eventsCount=2), **WHEN** 事件卡系统收到, **THEN** 从事件数据引擎抽取2个事件到队列，展示第一张。

- **GIVEN** 当前展示一张卡片, **WHEN** 玩家点击选项A, **THEN** 进入RESOLVING状态，调用选择结算引擎，显示资源变化动画。

- **GIVEN** 选项A有followUp="event-bonus", **WHEN** RESOLVING完成, **THEN** 加载event-bonus作为下一张卡片展示（不计入队列数量）。

- **GIVEN** 队列中最后一张卡片被选择并resolve完毕, **WHEN** 无followUp, **THEN** emit onDayEventsCompleted，通知日周期系统eventCompleted。

- **GIVEN** RESOLVING动画期间, **WHEN** 玩家再次点击屏幕, **THEN** 无反应（防连点）。

- **GIVEN** 卡片文案60字, **WHEN** 渲染, **THEN** 字号不小于14px，超过5行部分截断显示。
