# 事件数据引擎 (Event Data Engine)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-16
> **Implements Pillar**: 永远有新的

## Overview

事件数据引擎是《打工轮回》的内容驱动核心。它负责从JSON配置中加载事件数据、按职业筛选事件池、根据权重随机抽取事件、管理去重逻辑防止重复感。

这是支柱"永远有新的"的技术实现——新增一个职业只需要添加一个JSON文件，不需要修改任何引擎代码。数据格式和加载逻辑完全解耦。

## Player Fantasy

**间接幻想**：玩家感受到的是"每次打开都有新的离谱事件"。他们不知道背后有一个数据引擎在工作——他们只知道游戏"内容好多"、"总有惊喜"。

如果这个系统做得好：玩家5局内不会看到重复事件。做得差：第3局就开始觉得"又是这个事件"，然后卸载。

## Detailed Design

### Core Rules

1. **事件数据结构**：

```typescript
interface EventCard {
  id: string              // 唯一标识: "programmer-001"
  jobId: string           // 所属职业: "programmer"
  text: string            // 事件描述文案
  choiceA: Choice         // 选项A
  choiceB: Choice         // 选项B
  weight: number          // 抽取权重 (1-10, 默认5)
  tags: string[]          // 标签: ["overtime", "boss", "crisis"]
  prereqs?: string[]      // 前置条件: 需要之前出现过的事件ID
  cooldown?: number       // 冷却: 被抽中后N天内不再出现
  dayRange?: [number, number]  // 仅在第X-Y天出现
}

interface Choice {
  text: string            // 选项文案
  effects: ResourceEffect[]  // 资源变化
  followUp?: string       // 触发后续事件ID (可选)
}

interface ResourceEffect {
  target: 'energy' | 'mood' | 'money'
  value: number           // 正=增加, 负=减少
  percent?: boolean       // true=百分比变化, false=绝对值
}
```

2. **事件池构建**：每局开始时，根据当前职业构建可用事件池：
   - 加载该职业的专属事件 + 通用事件(jobId = "common")
   - 过滤掉不满足 `prereqs` 的事件
   - 过滤掉不在 `dayRange` 范围内的事件
   - 过滤掉在 `cooldown` 中的事件

3. **权重抽取算法**：
   - 从可用池中按 `weight` 加权随机抽取
   - 已展示过的事件权重临时降为原始值的20%（降低重复但不完全排除）
   - 带 `crisis` 标签的事件在资源低于30%时权重×2（加剧紧张感）

4. **数据加载策略**：
   - 小程序启动时加载当前职业的事件JSON（按需加载，非全量）
   - 切换职业时卸载旧数据、加载新数据
   - JSON文件放在分包中，不占主包空间

### States and Transitions

| 状态 | 含义 | 转换 |
|------|------|------|
| `UNLOADED` | 未加载任何事件数据 | → `LOADING`: 请求加载某职业数据 |
| `LOADING` | 正在加载JSON | → `READY`: 加载成功 |
| `LOADING` | | → `ERROR`: 加载失败 |
| `READY` | 事件池可用，可以抽取 | → `UNLOADED`: 切换职业/局结束 |
| `ERROR` | 加载失败 | → `LOADING`: 重试 |

### Interactions with Other Systems

| 系统 | 方向 | 接口 |
|------|------|------|
| 事件卡系统 | → 提供事件 | `drawEvent(context): EventCard` |
| 日周期系统 | → 提供数量 | `getEventsPerDay(day): number` |
| 职业轮回系统 | ← 告知职业 | `loadJobEvents(jobId): void` |
| 存档系统 | ← 读取冷却 | `runState.eventCooldowns[]` |

## Formulas

### 权重抽取概率

`P(event_i) = adjustedWeight_i / sum(allAdjustedWeights)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| baseWeight | w | int | 1-10 | 事件配置中的原始权重 |
| repeatPenalty | rp | float | 0.2 or 1.0 | 本局已展示过=0.2，未展示=1.0 |
| crisisMod | cm | float | 1.0 or 2.0 | 带crisis标签且资源<30%时=2.0，否则=1.0 |
| adjustedWeight | aw | float | 0.2-20 | = baseWeight × repeatPenalty × crisisMod |

**Output Range:** 概率范围 0.01-0.95（取决于池大小和权重分布）

**Example:** 池中3个事件(权重5,5,5)，事件A已展示过，玩家精力<30%且事件C有crisis标签：
- A: 5×0.2×1 = 1
- B: 5×1×1 = 5
- C: 5×1×2 = 10
- P(A)=1/16=6.25%, P(B)=5/16=31.25%, P(C)=10/16=62.5%

## Edge Cases

- **If 可用事件池为空**（所有事件都在冷却中）：重置所有冷却计数器，重新构建池。

- **If JSON加载失败**（网络问题/文件损坏）：重试3次，仍失败则使用内置的5个紧急备用事件（硬编码在代码中），保证游戏不中断。

- **If 事件的prereqs引用了不存在的事件ID**：忽略该prereq条件，正常将事件加入池。

- **If 同一天需要抽5个事件但池中只剩3个不同事件**：允许重复抽取（repeatPenalty已降低但不禁止）。

- **If 事件的effects会导致资源超出范围**：由资源管理系统负责clamp，事件数据引擎不做校验。

## Dependencies

### 上游

无游戏系统依赖。仅依赖JSON数据文件和小程序文件加载API。

### 下游

| 系统 | 接口 |
|------|------|
| 事件卡系统 | `drawEvent(context: DrawContext): EventCard` |
| 日周期系统 | `getEventsPerDay(day: number): number`（从配置读取） |

### 公共接口

```typescript
interface EventDataEngine {
  loadJobEvents(jobId: string): Promise<void>
  drawEvent(context: DrawContext): EventCard
  getEventsPerDay(day: number): number
  getPoolSize(): number
  unload(): void
}

interface DrawContext {
  currentDay: number
  shownEventIds: string[]
  resources: { energy: number; mood: number; money: number }
  eventCooldowns: Record<string, number>
}
```

## Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 说明 |
|--------|--------|---------|------|
| `REPEAT_PENALTY` | 0.2 | 0-1 | 已展示事件的权重倍率。0=绝不重复，1=无惩罚 |
| `CRISIS_WEIGHT_MOD` | 2.0 | 1-5 | 危机事件在低资源时的权重倍率 |
| `CRISIS_THRESHOLD` | 0.3 | 0.1-0.5 | 资源低于多少触发危机加权 |
| `DEFAULT_COOLDOWN` | 3 | 1-10 | 默认冷却天数（事件未指定时） |
| `FALLBACK_RETRY_COUNT` | 3 | 1-5 | JSON加载失败重试次数 |

## Acceptance Criteria

- **GIVEN** 职业为"程序员"且JSON中有20个事件, **WHEN** 调用 `loadJobEvents("programmer")`, **THEN** `getPoolSize()` 返回20+通用事件数。

- **GIVEN** 事件池中10个事件, **WHEN** 连续抽取5个, **THEN** 已抽过的事件在后续抽取中出现概率降至原来的20%。

- **GIVEN** 玩家精力<30%且池中有crisis标签事件, **WHEN** 抽取, **THEN** crisis事件出现概率为正常的2倍。

- **GIVEN** 事件A的prereqs为["event-B"], **WHEN** event-B未在本局出现过, **THEN** 事件A不在可用池中。

- **GIVEN** JSON加载失败, **WHEN** 重试3次仍失败, **THEN** 系统使用备用事件集，游戏继续运行。

- **GIVEN** 新增职业JSON文件"doctor-events.json", **WHEN** 代码未做任何修改, **THEN** 该职业的事件可被正常加载和抽取（数据驱动验证）。
