# 成就系统 (Achievement System)

> **Status**: Designed (Retrofit 2026-05-25)
> **Author**: gameplay-programmer + user
> **Last Updated**: 2026-05-25
> **Implements Pillar**: 永远有新的 / 局外成长
> **Sprint**: S3-10 (stub) → Sprint 4+ (扩展)

## Overview

成就系统提供**跨局收集向反馈**。玩家累计 stats（局数 / 胜数 / 死亡 / 总金钱 / 各职业游玩数 / 尝试不同职业数）触发数据驱动解锁——满足条件即自动加入 `unlocked` set + emit `onAchievementUnlocked`，UI 弹小 toast / 在主菜单显示徽章。

成就**纯收集向 / 无 gameplay 奖励**——不像 PassiveSkill 给数值 mul，achievement 只是"看到这个图标 + 名字"的成就感。这种纯虚荣设计保留它的可有可无性，避免成就解锁影响 build。

本系统结构**几乎完全镜像 PassiveSkillSystem**（init / hasAchievement / checkUnlocks），区别只在：没有 applyToEffect（不参与数值管线）、condition 类型多了 jobsTried（玩过的不同职业数量）。

## Player Fantasy

**间接幻想**：玩家关掉游戏前看到主菜单"已解锁 5/17 成就"——"还有 12 个，下次拼一下试试探险家"。成就名字走口语化 / 段子向（社畜入门 / 早睡早起 / 月光族 / 凡人 / 全才 / 卷王 ...），保持调性一致。

不像 PassiveSkill 是"被动变强"的安心感，achievement 是"收集 / 探索"的甜点——玩腻 build 后转目标"我要拿全成就"。

## Detailed Rules

### Achievement 数据结构（src/types/achievement.ts）

```typescript
interface Achievement {
  id: string
  name: string
  description: string
  rarity: 'common' | 'rare' | 'legendary'
  condition: AchievementCondition
  icon?: string
}

type AchievementCondition =
  | { type: 'runs'; value: number }            // totalRuns ≥ N
  | { type: 'wins'; value: number }            // totalWins ≥ N
  | { type: 'deaths'; value: number }          // totalDeaths ≥ N
  | { type: 'totalMoney'; value: number }      // totalMoneyEarned ≥ N
  | { type: 'jobPlays'; jobId: string; value: number }  // 该 job 玩 ≥ N 次
  | { type: 'jobsTried'; value: number }       // 玩过 ≥ N 个不同 job
```

### Catalog 17 个成就（src/types/achievement.ts）

简化示例（实际 17 个）：

| ID | Name | Rarity | 条件 |
|----|------|--------|------|
| first-step | 社畜入门 | common | runs ≥ 1 |
| first-win | 初胜 | common | wins ≥ 1 |
| early-grave | 早死早超生 | common | deaths ≥ 1 |
| veteran | 老油条 | rare | runs ≥ 10 |
| true-survivor | 真正的幸存者 | rare | wins ≥ 5 |
| moonlighter | 月光族 | common | totalMoney ≥ 1000 |
| salary-tycoon | 工资大亨 | legendary | totalMoney ≥ 100000 |
| programmer-master | 程序员之魂 | rare | jobPlays programmer ≥ 5 |
| jack-of-trades | 全才 | rare | jobsTried ≥ 5 |
| job-hopper-supreme | 跳槽之王 | legendary | jobsTried ≥ 8 |
| ... (共 17 条) | | | |

### 解锁触发点

`AchievementSystem.checkUnlocks(stats)` 由 `ProgressionSystem.recordRun` 在每局结束累计 stats 后调用（同 PassiveSkillSystem）。新解锁的 achievement：
1. 加入 `this.unlocked` set
2. emit `onAchievementUnlocked({ achievementId })`（UI 弹 toast）
3. 不立即持久化——由 progressionSystem.recordRun 的 saveServiceUpdate 一次性写入（持久化集中点）

### 持久化 location

存放在 `SaveData.stats.achievements: string[]`（不是 SaveData.achievements 顶级字段）——因为 achievement 是 "GlobalStats 的一部分"（永久跨 run）。读：`init(stats.achievements ?? [])`。写：通过 ProgressionSystem.recordRun 的 stats spread 自动持久化。

### 与 PassiveSkill 的区别

| 特性 | PassiveSkill | Achievement |
|------|--------------|-------------|
| 奖励 | 数值 mul（影响 effect） | 纯 UI 徽章 |
| 参与管线 | 是（applyToEffect） | 否 |
| 解锁条件类型 | 5 种 | 6 种（多 jobsTried） |
| 持久化字段 | SaveData.passiveSkills | SaveData.stats.achievements |
| 影响 ending | 间接（mul 改变结局触发） | 无 |
| Catalog 长度 | 7（小） | 17（大） |

### condition 评估

`evaluateAchievementCondition(cond, stats)` 在 types/achievement.ts 内：
- runs/wins/deaths/totalMoney/jobPlays：直接读 stats 对应字段
- jobsTried：`Object.keys(stats.jobsPlayed).filter(j => stats.jobsPlayed[j] > 0).length`

## Formulas

本系统**无数值公式**——纯谓词链：

```
for each Achievement a in ACHIEVEMENTS:
  if !unlocked.has(a.id) && evaluateAchievementCondition(a.condition, stats):
    unlock(a.id)
    newly.push(a.id)
return newly
```

不变量：unlocked set 只增不减；同 id 不重复解锁（evaluateAchievementCondition 单调递增 + has 去重）。

## Edge Cases

- **若 save 中有未知 id**（旧版本删除的 achievement）→ `init` 阶段 filter `getAchievementById(id) != null` 静默丢弃。**与 EndingSystem 不一致**：ending 不 filter，achievement filter——历史遗留，统一时优先 achievement 模式。
- **同时解锁多个 achievement**（一局结束导致 3 个条件同时达到）→ checkUnlocks 返回 newly 列表 [a, b, c]，emit 3 次 onAchievementUnlocked。**UI 应排队弹 toast**——payload 是单个 id，UI 自己管理队列。
- **未来添加的新 condition 类型**（前向兼容）→ `evaluateAchievementCondition` 走 default 返回 false（保守不解锁）。旧 build 加载新 save 不会误解锁。
- **jobsPlayed 含 jobId 但 count=0**（理论不可能）→ jobsTried filter `count > 0` 排除——0 不算"玩过"。
- **stats 字段 undefined**（save 损坏 / 旧版本）→ ProgressionSystem 端 `stats ?? emptyStats()` 已防御。本系统假设 stats 完整。

## Dependencies

### 上游
| 系统 | 用途 |
|------|------|
| 存档系统 | `SaveData.stats.achievements: string[]` 读 |
| ProgressionSystem | 每局结束调用 `checkUnlocks(stats)` |

### 下游
| 系统 | 接口 |
|------|------|
| Vue Store (achievementStore) | 订阅 `onAchievementUnlocked` 推 UI toast / 图鉴页 |
| 主菜单 UI | 读 `getUnlocked()` 显示进度 "5/17" |

### 公共接口

```typescript
class AchievementSystem {
  init(unlockedIds: string[]): void
  hasAchievement(id: string): boolean
  getUnlocked(): string[]
  getUnlockedAchievements(): Achievement[]
  unlockAchievement(id: string): boolean
  checkUnlocks(stats: GlobalStats): string[]    // 返回 newly unlocked
  readonly onAchievementUnlocked: TypedEventEmitter<{ achievementId: string }>
}
```

## Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 说明 |
|--------|--------|---------|------|
| ACHIEVEMENTS catalog | 17 entries | — | 加 achievement 只需 push entry，无代码改动 |
| achievement.condition.value | 1-100 | 1-1000 | 解锁门槛——过低让成就太普遍，过高让玩家放弃 |
| achievement.rarity | common/rare/legendary | — | 影响 UI 弹窗动效 + 图鉴排序 |
| jobsTried 门槛 | 5 / 8 | 3-10 | 鼓励多职业体验；总职业数 8 → 8 是"全开" |

## Acceptance Criteria

- **GIVEN** 新玩家（stats 全 0）, **WHEN** `getUnlocked()`, **THEN** 返回 `[]`。
- **GIVEN** stats.totalRuns=1, **WHEN** `checkUnlocks(stats)`, **THEN** 返回 `['first-step']`, emit onAchievementUnlocked 1 次。
- **GIVEN** stats.totalRuns=1 / unlocked 已含 first-step, **WHEN** `checkUnlocks(stats)`, **THEN** 返回 `[]`, 不 emit（去重）。
- **GIVEN** stats {totalRuns:10, totalWins:5, totalMoneyEarned:1000}, **WHEN** checkUnlocks, **THEN** newly 含 veteran + true-survivor + moonlighter（一次解锁多个），emit 3 次。
- **GIVEN** stats.jobsPlayed={programmer:3, sales:2, designer:1, runner:1, researcher:1}（5 jobs）, **WHEN** checkUnlocks, **THEN** newly 含 jack-of-trades。
- **GIVEN** stats.jobsPlayed={programmer:3, sales:0}（sales count=0）, **WHEN** jobsTried 评估, **THEN** count=1（不算 sales）。
- **GIVEN** save 含未知 id "future-achievement", **WHEN** `init(['future-achievement', 'first-step'])`, **THEN** `getUnlocked()` 仅含 'first-step'。
- **GIVEN** ProgressionSystem.recordRun 调用, **WHEN** 检查 saveServiceUpdate, **THEN** stats.achievements 含新解锁的 id（统一持久化点）。
