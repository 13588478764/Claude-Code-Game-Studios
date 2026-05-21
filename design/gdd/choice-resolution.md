# 选择结算引擎 (Choice Resolution Engine)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-16
> **Implements Pillar**: 一局一笑（结算反馈是幽默的最后一击）+ 三秒上手（结果立即可见）

## Overview

选择结算引擎是事件卡系统和资源管理系统之间的桥梁——玩家点击选项后，由它负责解析选项的effects、应用被动技能修正、调用资源管理系统执行变化、生成结果摘要供UI展示。它是"选择→后果"这条因果链的中间处理器。

## Player Fantasy

**间接幻想**：玩家感受到的是"我的选择立刻产生了明确的后果"。好的结算引擎让每次选择都有清晰的因果反馈——选了"偷偷摸鱼"，立刻看到精力+20但心情-10和"被发现概率"。不好的结算引擎让玩家困惑"我的选择到底有什么影响"。

## Detailed Design

### Core Rules

1. **结算流程**：

```typescript
function resolveChoice(card: EventCard, choiceKey: 'A' | 'B'): ResolveResult {
  // 1. 获取选中的选项
  const choice = choiceKey === 'A' ? card.choiceA : card.choiceB
  
  // 2. 获取被动技能修正（从被动技能系统，MVP阶段返回默认值）
  const modifiers = passiveSkillSystem.getModifiers()
  
  // 3. 应用效果到资源管理系统
  const applyResult = resourceManager.applyEffects(choice.effects)
  
  // 4. 记录选择到存档（用于去重、成就、解锁判定）
  saveService.recordChoice(card.id, choiceKey)
  
  // 5. 生成结果摘要
  return buildResolveResult(choice, applyResult)
}
```

2. **效果处理顺序**：
   - 同一选项的多个effect按数组顺序依次执行
   - 每个effect独立计算修正，独立clamp
   - 不做批量计算（保证中间状态触发阈值检测）

3. **结果摘要生成**：

```typescript
interface ResolveResult {
  choiceText: string           // 选项文案（展示"你选了..."）
  resourceChanges: ResourceDelta[]  // 每项资源的变化详情
  stateChange?: string         // 如果触发了状态变化: "WARNING", "CRISIS", "DEAD"
  followUpId?: string          // 如果有后续事件
  flavorText?: string          // 结果附加文案（可选，增加趣味）
}

interface ResourceDelta {
  resource: 'energy' | 'mood' | 'money'
  before: number
  after: number
  delta: number              // 实际变化量（含修正）
  rawDelta: number           // 原始变化量（修正前）
  wasModified: boolean       // 是否被被动技能修正过
}
```

4. **被动技能修正集成**（MVP阶段简化）：
   - MVP阶段：被动技能系统未实现，所有modifier返回1.0
   - 接口预留：`getModifier(resource, direction)` 已定义在资源管理系统
   - Alpha阶段接入被动技能系统后自动生效

5. **存档记录**：
   - 每次选择记录到 `runState.choiceHistory[]`
   - 记录内容: `{ eventId, choiceKey, day, timestamp }`
   - 用途：事件去重（已做过的事件权重降低）、成就判定、数据分析

### States and Transitions

选择结算引擎是无状态的纯计算模块——它不持有自己的状态机，被调用时执行计算并返回结果。

| 触发条件 | 行为 |
|---------|------|
| 事件卡系统调用 `resolveChoice()` | 执行完整结算流程，返回 `ResolveResult` |
| 资源管理系统返回 `DEAD` 状态 | 在 `ResolveResult.stateChange` 中标记 |

### Interactions with Other Systems

| 系统 | 方向 | 接口 |
|------|------|------|
| 事件卡系统 | ← 接收请求 | `resolveChoice(card, choiceKey): ResolveResult` |
| 资源管理系统 | → 执行变化 | `applyEffects(effects): ApplyResult` |
| 状态效果系统 | → 添加 buff | `addStatus(buff)` 当 choice 含 `buff` 字段时调用，详见 `design/gdd/status-system.md` |
| 被动技能系统 | ← 获取修正 | `getModifiers(): ModifierSet` (MVP阶段默认1.0) |
| 存档系统 | → 记录选择 | `saveService.recordChoice(eventId, choiceKey)` |

## Formulas

### 单项效果计算

`actualDelta = rawEffect × passiveModifier`

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| rawEffect | int | -100 to +100 | 事件配置中的effect.value |
| passiveModifier | float | 0.1-2.0 | 被动技能修正（MVP=1.0） |
| actualDelta | float→int | -200 to +200 | 实际变化量（Math.floor） |

结果传递给资源管理系统，由其负责clamp和阈值检测。

### 百分比效果计算

`actualDelta = Math.floor(currentValue × rawEffect / 100 × passiveModifier)`

**Example:** mood=60, effect={target:'mood', value:-30, percent:true}, modifier=0.8
- actualDelta = Math.floor(60 × (-30/100) × 0.8) = Math.floor(-14.4) = -15

## Edge Cases

- **If choice.effects为空数组**：合法，结果为"无资源变化"。仍记录选择到存档。

- **If 结算过程中资源触发DEAD**：结算正常完成并返回完整ResolveResult，由事件卡系统读取stateChange后通知上层。

- **If 被动技能修正导致正效果变为负效果**（modifier>1.0应用到负效果）：允许。修正是乘法不是翻转方向。

- **If 同一个effect对象被引用到多张卡**（数据复用）：每次结算读取当时的资源值，互不影响。

- **If 百分比效果对money（可能为负数）操作**：以当前值的绝对值计算百分比变化。money=-10, effect=-30% → delta=Math.floor(-10×(-30/100))=+3（欠钱时扣钱=还钱...允许这个行为，但数据设计应避免）。

- **If recordChoice在存档写入时失败**：结算结果仍然有效（资源已变化）。选择记录标记为pending，下次成功时补写。

## Dependencies

### 上游

| 系统 | 依赖类型 | 接口 |
|------|---------|------|
| 资源管理系统 | Hard | `applyEffects()` 执行资源变化 |
| 事件卡系统 | Hard | 被事件卡系统调用 |
| 被动技能系统 | Soft | MVP阶段可缺省(默认modifier=1.0) |
| 存档系统 | Soft | 记录选择历史（失败不阻塞结算） |

### 下游

| 系统 | 接口 |
|------|------|
| 游戏主界面 | 通过事件卡系统间接提供结果展示数据 |

### 公共接口

```typescript
interface ChoiceResolutionEngine {
  resolveChoice(card: EventCard, choiceKey: 'A' | 'B'): ResolveResult
}

interface ResolveResult {
  choiceText: string
  resourceChanges: ResourceDelta[]
  stateChange?: 'WARNING' | 'CRISIS' | 'DEAD'
  followUpId?: string
  flavorText?: string
}

interface ResourceDelta {
  resource: 'energy' | 'mood' | 'money'
  before: number
  after: number
  delta: number
  rawDelta: number
  wasModified: boolean
}
```

## Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 说明 |
|--------|--------|---------|------|
| `GLOBAL_EFFECT_MULTIPLIER` | 1.0 | 0.5-2.0 | 全局效果倍率（用于难度调节：简单模式0.7，困难模式1.3） |
| `POSITIVE_EFFECT_CAP` | 50 | 20-100 | 单次正面效果最大值（防止单次选择回满） |
| `NEGATIVE_EFFECT_CAP` | -60 | -100 to -20 | 单次负面效果最大值（防止一选即死） |

## Acceptance Criteria

- **GIVEN** 事件卡选项A有effects [{target:'energy', value:-20}, {target:'money', value:+10}], **WHEN** resolveChoice调用, **THEN** 返回的resourceChanges正确反映两项变化。

- **GIVEN** 被动技能modifier=0.5用于mood负面, **WHEN** mood effect为-20, **THEN** ResourceDelta.delta=-10, wasModified=true。

- **GIVEN** 资源管理系统applyEffects返回triggered含'DEAD', **WHEN** 结算完成, **THEN** ResolveResult.stateChange='DEAD'。

- **GIVEN** 选项有followUp="event-aftermath", **WHEN** resolveChoice完成, **THEN** ResolveResult.followUpId="event-aftermath"。

- **GIVEN** choice.effects=[], **WHEN** resolveChoice调用, **THEN** 正常返回resourceChanges为空数组，不报错。

- **GIVEN** 任何选择被做出, **WHEN** resolveChoice调用, **THEN** choiceHistory中新增一条记录。
