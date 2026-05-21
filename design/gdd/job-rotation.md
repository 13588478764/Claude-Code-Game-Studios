# 职业轮回系统 (Job Rotation System)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-16
> **Implements Pillar**: 永远有新的（新职业=全新事件池+全新体验）+ 一局一笑（每个职业有独特荒诞点）

## Overview

职业轮回系统是《打工轮回》的Roguelike核心——"轮回"体现在每次游戏结束后切换到新职业。它管理职业的解锁条件、可选列表、随机推荐、以及每个职业的元数据（薪资倍率、特殊规则、事件池绑定）。这是支柱"永远有新的"的最直接载体：新职业=完全不同的事件内容+不同的数值手感。

## Player Fantasy

**直接幻想**："这辈子打了一百份工，每份都是离谱的。"——玩家在每次"死亡"后不是沮丧地重来，而是兴奋地看看"这次又要干什么奇葩工作"。解锁新职业的快感等同于Roguelike解锁新角色。服务支柱：**永远有新的** — 新职业意味着全新的事件文案、全新的专属梗、全新的体验。

## Detailed Design

### Core Rules

1. **职业数据结构**：

```typescript
interface JobConfig {
  id: string              // 唯一标识: "programmer", "doctor", "chef"
  name: string            // 显示名: "996程序员", "ICU医生", "深夜食堂厨师"
  description: string     // 一句话描述: "每天都是deadline eve"
  icon: string            // 职业图标资源路径
  unlockCondition: UnlockCondition  // 解锁条件
  salaryRate: number      // 薪资倍率 (相对BASE_SALARY)
  energyModifier: number  // 初始精力修正 (如程序员-10, 体力劳动者+10)
  moodModifier: number    // 初始心情修正
  specialRules?: string[] // 特殊规则ID列表
  daysPerWeek?: number    // 覆盖默认工作天数 (如自由职业者=3)
  tags: string[]          // 标签: ["tech", "service", "creative", "physical"]
}

interface UnlockCondition {
  type: 'default' | 'runs' | 'achievement' | 'specific_death'
  value?: number          // runs: 完成N局后解锁
  achievementId?: string  // 达成特定成就解锁
  deathType?: string      // 以特定方式死亡解锁 (如"被炒"解锁"摆摊老板")
}
```

2. **初始解锁职业**（MVP开箱即用）：

| 职业ID | 名称 | 解锁条件 | 薪资倍率 | 特色 |
|--------|------|---------|---------|------|
| intern | 卑微实习生 | default (初始解锁) | 0.5 | 钱少事多，入门教学职业 |
| programmer | 996程序员 | default (初始解锁) | 2.0 | 高薪但精力消耗大 |
| sales | 街头推销员 | 完成1局 | 1.0 | 心情波动大，看客户脸色 |

3. **职业选择机制**：
   - 每局开始前，展示3个可选职业（从已解锁职业中随机抽取）
   - 玩家选择一个开始本局
   - 如果已解锁职业≤3个，则全部展示（无随机）
   - 可通过看广告刷新选项（广告激励系统接口）

4. **职业解锁规则**：
   - 完成指定局数后自动解锁新职业
   - 特定死法触发隐藏职业解锁（如连续3局被炒→解锁"职业碰瓷者"）
   - 解锁时全屏通知 + 存入profile.unlockedJobs[]
   - 新解锁的职业在下次选择时100%出现在选项中

5. **职业影响范围**：
   - 绑定专属事件池（事件数据引擎按jobId加载）
   - 覆盖初始资源值（energy=80+energyModifier, mood=60+moodModifier）
   - 覆盖薪资计算（BASE_SALARY × salaryRate）
   - 可覆盖工作天数（自由职业者3天/医生7天值班）

### States and Transitions

| 状态 | 含义 | 转换 |
|------|------|------|
| `LOCKED` | 职业未解锁 | → `UNLOCKED`: 满足解锁条件 |
| `UNLOCKED` | 职业可选但未使用 | → `ACTIVE`: 玩家选择该职业开始新局 |
| `ACTIVE` | 当前局正在使用的职业 | → `UNLOCKED`: 局结束 |

### Interactions with Other Systems

| 系统 | 方向 | 接口 |
|------|------|------|
| 存档系统 | ↔ 读写 | `profile.unlockedJobs[]`, `profile.jobHistory[]` |
| 事件数据引擎 | → 告知职业 | `loadJobEvents(jobId)` |
| 局管理器 | ← 选择职业 | `selectJob(jobId): JobConfig` |
| 局管理器 | → 局结束 | `recordRunResult(jobId, result)` → 检查解锁条件 |
| 资源管理系统 | → 提供修正 | `getJobModifiers(): {energy, mood, salaryRate}` |
| 职业选择页 | → 提供数据 | `getAvailableJobs(): JobConfig[]`, `getLockedJobs(): LockedJobInfo[]` |

## Formulas

### 职业推荐抽取

`candidates = weightedRandom(unlockedJobs, 3, weights)`

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| unlockedJobs | JobConfig[] | 2-20+ | 已解锁的全部职业 |
| recentPenalty | float | 0.1 | 最近3局玩过的职业权重降至10% |
| newBonus | float | 5.0 | 新解锁(未玩过)职业权重×5 |
| baseWeight | float | 1.0 | 默认权重 |

**Output:** 3个不重复的推荐职业

**Example:** 5个已解锁职业, 上局玩了programmer, doctor刚解锁(未玩过)
- programmer: 1.0×0.1 = 0.1
- intern: 1.0
- sales: 1.0
- chef: 1.0
- doctor: 1.0×5.0 = 5.0 (几乎必出)

### 解锁进度

`unlockProgress = completedRuns / requiredRuns`

显示为百分比进度条。隐藏解锁条件不显示进度（只显示"???"）。

## Edge Cases

- **If 已解锁职业<3个**：全部展示，不做随机抽取。

- **If 玩家连续选同一个职业**：允许。不限制选择自由，靠权重降低推荐频率即可。

- **If 解锁条件引用了不存在的achievementId**：忽略该条件，该职业永远锁定（不静默解锁）。

- **If 新增职业JSON但不重新发版**：热更新支持——新职业配置随事件数据加载，解锁条件在客户端检查。

- **If 玩家已解锁全部职业**：显示"全职业解锁"成就，推荐算法正常工作（去除newBonus）。

- **If daysPerWeek被职业覆盖为超出范围的值**：clamp到[3,7]。

## Dependencies

### 上游

| 系统 | 依赖类型 | 接口 |
|------|---------|------|
| 存档系统 | Hard | 读写解锁状态和历史记录 |

### 下游

| 系统 | 接口 |
|------|------|
| 事件数据引擎 | `loadJobEvents(jobId)` |
| 局管理器 | `selectJob(jobId)`, `recordRunResult()` |
| 资源管理系统 | 初始资源修正 |
| 职业选择页 | `getAvailableJobs()`, `getLockedJobs()` |
| 主菜单/图鉴 | `getAllJobs()`, `getJobStats(jobId)` |

### 公共接口

```typescript
interface JobRotationSystem {
  getAvailableJobs(): JobConfig[]
  getLockedJobs(): LockedJobInfo[]
  getRecommendedJobs(count: number): JobConfig[]
  selectJob(jobId: string): JobConfig
  checkUnlocks(runResult: RunResult): UnlockEvent[]
  getJobStats(jobId: string): JobStats
  onJobUnlocked: EventEmitter<JobConfig>
}

interface LockedJobInfo {
  id: string
  name: string          // 显示"???"还是真实名字取决于unlockHint
  unlockHint: string    // "再完成2局即可解锁" 或 "???"(隐藏条件)
  progress: number      // 0-1, 隐藏条件显示为-1
}

interface JobStats {
  timesPlayed: number
  bestMoney: number
  bestSurvivalDays: number
  deathTypes: Record<string, number>
}
```

## Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 说明 |
|--------|--------|---------|------|
| `RECOMMEND_COUNT` | 3 | 2-5 | 每局展示的推荐职业数量 |
| `RECENT_PENALTY` | 0.1 | 0-0.5 | 最近玩过的职业推荐权重 |
| `NEW_JOB_BONUS` | 5.0 | 2.0-10.0 | 新解锁职业的推荐权重倍率 |
| `RECENT_WINDOW` | 3 | 1-5 | "最近"的定义=最近N局 |
| `INITIAL_UNLOCKED` | 2 | 1-3 | 初始解锁职业数量 |

## Acceptance Criteria

- **GIVEN** 新玩家首次进入, **WHEN** 请求职业列表, **THEN** 返回2个初始解锁职业（实习生+程序员）。

- **GIVEN** 完成1局, **WHEN** checkUnlocks调用, **THEN** 解锁"街头推销员"，emit onJobUnlocked。

- **GIVEN** 5个已解锁职业，上局玩了programmer, **WHEN** getRecommendedJobs(3), **THEN** programmer出现概率显著低于其他职业。

- **GIVEN** 选择programmer, **WHEN** selectJob("programmer"), **THEN** 返回完整JobConfig含salaryRate=2.0和energyModifier。

- **GIVEN** 职业"doctor"配置daysPerWeek=7, **WHEN** 开始该职业的局, **THEN** 日周期系统使用7天而非默认5天。

- **GIVEN** 新职业doctor刚解锁未玩过, **WHEN** getRecommendedJobs(3), **THEN** doctor必定出现在推荐列表中。
