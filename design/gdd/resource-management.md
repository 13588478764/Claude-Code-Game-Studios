# 资源管理系统 (Resource Management System)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-16
> **Implements Pillar**: 一局一笑（资源紧张是喜剧张力来源）+ 三秒上手（3条直观的进度条）

## Overview

资源管理系统管理玩家的三维资源状态：精力(energy)、心情(mood)、钱包(money)。它负责资源的初始化、增减计算、阈值检测、极端状态触发。每次事件选择的后果都通过这个系统体现——它是"选择有意义"的数学保障。

资源条是玩家唯一持续可见的游戏状态指示器。它们的变化节奏直接决定了游戏的紧张感曲线——太平缓则无聊，太陡峭则不公平。

## Player Fantasy

**直接幻想**：玩家每做一个选择，都能立即看到"我的选择产生了后果"——资源条的跳动是最直接的反馈。当精力条快见底时，那种"再撑一天就发工资了"的紧张感是核心乐趣。

这不是资源焦虑——是荒诞喜剧式的紧张。服务支柱：**一局一笑** — 资源告急时的选项变得更极端更搞笑。

## Detailed Design

### Core Rules

1. **三维资源定义**：

```typescript
interface Resources {
  energy: number   // 精力: 0-100, 归零=燃尽(游戏结束)
  mood: number     // 心情: 0-100, 低于20触发"摆烂模式"
  money: number    // 钱包: 0-无上限, 每天发薪/扣钱, 局结算时计入永久存款
}
```

2. **初始值**（每局开始时）：
   - energy: 80（不满，暗示已经有点累了）
   - mood: 60（中等，上班第一天心情一般）
   - money: 0（刚入职还没发工资）

3. **变化规则**：
   - 绝对值变化: `resource += effect.value`（如 energy -20）
   - 百分比变化: `resource += resource * effect.value / 100`（如 mood -30%）
   - 变化后立即 clamp: `Math.max(0, Math.min(MAX, value))`
   - energy 和 mood 上限100，money 无上限

4. **阈值触发**：

| 条件 | 触发效果 |
|------|---------|
| energy = 0 | 游戏结束：燃尽/猝死结局 |
| mood ≤ 20 | 进入"摆烂模式"：部分选项被替换为摆烂选项（高风险高回报） |
| mood = 0 | 游戏结束：暴走离职结局 |
| money < 0 | 触发"吃土事件"（强制插入一个额外事件） |
| energy ≤ 30 | UI警告（资源条变红+闪烁） |

5. **被动技能修正**：
   - 资源变化应用前检查被动技能修正器
   - 如"厚脸皮Lv2"：mood负面变化×0.5
   - 修正公式: `finalEffect = baseEffect × passiveModifier`

### States and Transitions

| 状态 | 含义 | 转换 |
|------|------|------|
| `NORMAL` | 所有资源在安全范围 | → `WARNING`: 任一资源 ≤ 30 |
| `WARNING` | 有资源接近危险值 | → `NORMAL`: 回升到 > 30 |
| `WARNING` | | → `CRISIS`: mood ≤ 20 |
| `CRISIS` | 摆烂模式激活 | → `WARNING`: mood > 20 |
| `CRISIS` | | → `DEAD`: energy=0 或 mood=0 |
| `DEAD` | 游戏结束 | → (交给局管理器处理) |

### Interactions with Other Systems

| 系统 | 方向 | 接口 |
|------|------|------|
| 存档系统 | ↔ 读写 | `loadRunState().resources` / `saveRunState()` |
| 选择结算引擎 | ← 接收变化 | `applyEffects(effects: ResourceEffect[])` |
| 被动技能系统 | ← 获取修正 | `getModifier(resource, direction): number` |
| 局管理器 | → 通知死亡 | emit `resourceDepleted(type)` |
| 游戏主界面 | → 提供状态 | `getResources(): Resources` + `onResourceChanged` event |
| 广告激励系统 | ← 接收恢复 | `applyEffects([{target:'energy', value:50, percent:true}])` |

## Formulas

### 资源变化计算

`finalValue = clamp(currentValue + baseEffect × passiveModifier, 0, MAX)`

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| currentValue | int | 0-100 | 当前资源值 |
| baseEffect | int | -100 to +100 | 事件选项定义的基础变化量 |
| passiveModifier | float | 0.1-2.0 | 被动技能修正倍率（默认1.0） |
| MAX | int | 100 (energy/mood), ∞ (money) | 资源上限 |

**Example:** 精力=45, 事件效果=-30, 拥有"咖啡因抗性Lv1"(负面精力×0.8)
- finalValue = clamp(45 + (-30 × 0.8), 0, 100) = clamp(45-24, 0, 100) = 21

## Edge Cases

- **If 多个effect同时作用于同一资源**：按数组顺序依次计算，每次计算后都clamp。不累加后一次性应用。

- **If 百分比变化计算出小数**：向下取整（`Math.floor`）。资源值始终为整数。

- **If 被动技能修正后effect变为0**：仍然触发资源变化事件（UI需要显示"+0"以表示"技能生效了"）。

- **If energy和mood同时归零**（一个选择同时扣光两者）：优先触发energy=0结局（燃尽），忽略mood=0。

- **If 广告续命恢复energy后，mood仍为0**：续命只恢复energy，mood=0仍触发暴走结局。续命广告应该在判定结局前触发。

- **If money为负数**（某些事件允许欠钱）：允许负值，触发"吃土事件"但不结束游戏。

## Dependencies

### 上游

| 系统 | 依赖类型 | 接口 |
|------|---------|------|
| 存档系统 | Hard | 读写资源状态 |

### 下游

| 系统 | 接口 |
|------|------|
| 选择结算引擎 | `applyEffects(effects)` |
| 局管理器 | `resourceDepleted` event |
| 游戏主界面 | `getResources()`, `onResourceChanged` |
| 被动技能系统 | `getModifier()` (反向: 技能系统提供修正给资源系统) |
| 状态效果系统 | `modifyDelta()` (反向: 状态系统在 applyEffects 内被调用提供修正)，详见 `design/gdd/status-system.md` |
| 广告激励系统 | `applyEffects()` (续命恢复) |

### 公共接口

```typescript
interface ResourceManager {
  init(saved?: Resources): void
  getResources(): Resources
  getState(): 'NORMAL' | 'WARNING' | 'CRISIS' | 'DEAD'
  applyEffects(effects: ResourceEffect[]): ApplyResult
  onResourceChanged: EventEmitter<ResourceChangeEvent>
  onStateChanged: EventEmitter<StateChangeEvent>
  onResourceDepleted: EventEmitter<'energy' | 'mood'>
}

interface ApplyResult {
  before: Resources
  after: Resources
  deltas: Record<string, number>  // 实际变化量(含修正后)
  triggered: string[]             // 触发的阈值事件
}
```

## Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 说明 |
|--------|--------|---------|------|
| `INITIAL_ENERGY` | 80 | 50-100 | 开局精力。太低=第一天就死，太高=无紧张感 |
| `INITIAL_MOOD` | 60 | 30-80 | 开局心情。影响前几天的"摆烂"触发频率 |
| `INITIAL_MONEY` | 0 | 0-100 | 开局金钱。0=必须打工才有钱 |
| `CRISIS_THRESHOLD` | 20 | 10-40 | mood低于此值进入摆烂模式 |
| `WARNING_THRESHOLD` | 30 | 20-50 | 低于此值UI变红警告 |
| `ENERGY_MAX` | 100 | 80-200 | 精力上限 |
| `MOOD_MAX` | 100 | 80-200 | 心情上限 |

## Acceptance Criteria

- **GIVEN** 新局开始, **WHEN** 资源初始化, **THEN** energy=80, mood=60, money=0。

- **GIVEN** energy=45, **WHEN** 收到effect {target:'energy', value:-30}, **THEN** energy变为15，触发WARNING状态，emit onResourceChanged。

- **GIVEN** energy=10, **WHEN** 收到effect {target:'energy', value:-15}, **THEN** energy=0，触发DEAD状态，emit onResourceDepleted('energy')。

- **GIVEN** mood=25, **WHEN** 收到effect {target:'mood', value:-10}, **THEN** mood=15, 状态从WARNING变为CRISIS。

- **GIVEN** 被动技能"厚脸皮Lv2"(modifier=0.5), **WHEN** mood收到-20效果, **THEN** 实际变化为-10。

- **GIVEN** energy=50, **WHEN** 收到effect {target:'energy', value:80}, **THEN** energy=100(clamp到上限)。

- **GIVEN** money=10, **WHEN** 收到effect {target:'money', value:-20}, **THEN** money=-10，触发"吃土事件"。

- **GIVEN** applyEffects执行完毕, **WHEN** 结果返回, **THEN** ApplyResult包含准确的before/after/deltas/triggered。
