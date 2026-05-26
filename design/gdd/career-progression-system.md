# 升职机制 (Career Progression System)

> **Status**: Designed (Retrofit 2026-05-25)
> **Author**: gameplay-programmer + user
> **Last Updated**: 2026-05-25
> **Implements Pillar**: 一局一笑 / 局内成长
> **Sprint**: S4-2

## Overview

升职机制是**局内成长** ——每职业的多周生涯（4 周 = 28 天）中，玩家通过资源管理 / 选择多样性 / 周末 review 积累 careerScore，达到阈值 100 / 250 / 500 触发升职 Lv2 / Lv3 / Lv4，工资倍率随级别提升 1.0x → 1.5x → 2.25x → 3.5x。

设计动机：解决用户首次手测反馈的"金钱无用 / 周末无爽点"——给"撑过这一周"一个 tangible 的奖励。

## Player Fantasy

**直接幻想**：玩家感觉"我在变强 / 工资在涨 / 越往后越爽"。周末 review 事件是"小周目 boss"——选择是否拼一把决定 score delta（拼一把 +30 / 平稳 +0 / 摆烂 -30）。

第 1-2 周 → 升 Lv2，第 3-4 周可冲 Lv3，少数玩家达到 Lv4。卡顿处："为什么没升职？"应该来自玩家的选择失误（金钱没攒 / 心情透支 / 周末摆烂），而非系统设计模糊。

## Detailed Rules

### CareerLevel + Salary 表（src/types/career.ts）

```typescript
PROMOTION_THRESHOLDS = { 1:0, 2:100, 3:250, 4:500 }
SALARY_MULTIPLIER_PER_LEVEL = { 1:1.0, 2:1.5, 3:2.25, 4:3.5 }
LEVEL_TITLES = { 1:'初出茅庐', 2:'小有成就', 3:'资深骨干', 4:'行业翘楚' }
```

### Score 累计触发点

1. **每周结束** (`DayCycleSystem.onWeekCompleted` → RunManager → `recordWeek(inputs)`)：按公式计算 weekScore 加到 totalScore。
2. **周末 review 事件** (S4-3：玩家选 "拼一把" / "平稳" / "摆烂")：通过 `applyScoreDelta(delta)` 直接调整，作为 `reviewBonus` 输入下一次 recordWeek。当前实现是两条路径都可写 score（review 事件直接 emit choice，recordWeek 也有 reviewBonus 输入）——以代码为准。

### 升职检测

每次 score 变更后 `checkPromotion(before)`：
- `while (canPromote()) level += 1`（while 而非 if——保证一次 +500 也能跨多级）
- 若 level 变更 → emit `onPromoted({ fromLevel, toLevel, newSalaryMul })`
- 最高 Lv4 之后 `PROMOTION_THRESHOLDS[5] == null` → `canPromote()` 返回 false，停止。

### 工资计算位置

salary multiplier 由 `getSalaryMultiplier()` 返回，**调用方** (DayCycleSystem onDayEnded 或 RunManager 结算) 负责乘到 daily salary。本系统不主动 push 工资到 ResourceManager。

### Generic vs Per-Job Title

`getTitle()` 返回 generic 头衔（初出茅庐 / 小有成就 / ...）。UI 显示用 `getJobLevelTitle(job.careerTitles, level)`（来自 `types/career.ts`），优先取 jobConfig.careerTitles 数组，fallback 到 generic 表。**本系统保持 jobId-agnostic**——只管数字，presentation 知道 job。

### Reset / Resume

- `reset()` —— RunManager 启动新 run 时调用，回到 Lv1 / score 0 / weeksWorked 0。
- `loadSnapshot(snap)` —— Sprint 5+ resume 时恢复。**clamp 防御**：level 不在 1-4 → 强制 1；score / weeksWorked < 0 → clamp 到 0。

## Formulas

### Week Score 公式

```
weekScore =
    moneyComponent      ←  clamp(endMoney / 100, -1, 2) × 25       [-25 .. +50]
  + resourceComponent   ←  ((avgEnergy + avgMood) / 200) × 40      [0 .. +40]
  + varietyComponent    ←  min(uniqueEvents/max(choices,1), 1) × 20 [0 .. +20]
  + reviewBonus         ←  pass-through                             [-30 .. +30]
```

**Variables**:
| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| endOfWeekMoney | int | -∞..+∞ | 周末结算时的金钱（被 clamp 限制贡献） |
| avgEnergy | float | 0..100 | 该周日均体力 |
| avgMood | float | 0..100 | 该周日均心情 |
| uniqueEventsThisWeek | int | 0..choicesThisWeek | 周内见过的不同事件数 |
| choicesThisWeek | int | 0..N | 周内做的选择数（含重复事件） |
| reviewBonus | int | -30..+30 | 周末 review 选择产生的直接 score delta |

**Output Range**: 理论 -55..+140；可持续平均 50-80。

**Round**: `Math.round(total)` —— score 最终为 int。

**Example**: 程序员第 1 周末：金钱 200 / avg energy 60 / avg mood 70 / 5 unique 事件 / 5 choices / reviewBonus +30（拼一把）
- money = clamp(2, -1, 2) × 25 = 50
- resource = (60+70)/200 × 40 = 26
- variety = 5/5 × 20 = 20
- review = 30
- total = round(126) = 126 → 第 1 周末已可升 Lv2（threshold 100）

### 工资缩放

```
actualDailySalary = baseSalary × jobConfig.salaryMul × careerSalaryMultiplier[level]
```

注：调用方负责乘法，本系统只提供 `getSalaryMultiplier()`。

## Edge Cases

- **score 减为负数** → `applyScoreDelta` 使用 `Math.max(0, this.score + delta)` clamp 到 0。但 `recordWeek` 内部 `this.score += delta` **不 clamp** —— 因 weekScore 公式输出已有理论下限 -55，total score 实际可能短暂为负。**已知 SMELL**：两个写入路径处理不一致；当前测试未覆盖，等用户首次反馈再决定要不要统一。
- **choicesThisWeek === 0**（理论上不可能） → varietyRatio = 0（除零保护）。
- **avgEnergy / avgMood 越界**（< 0 或 > 100）→ 公式不防御，依赖调用方（DayCycleSystem）传干净数据。
- **一次 delta 跨多级**（如初始 score=0 + delta=600）→ while 循环连续升 → emit 一次 onPromoted，payload 直接显示 fromLevel:1 toLevel:4（不是 3 次单级升）。**故意如此**——避免连续弹 toast，UI 一次性显示"连升三级"。
- **loadSnapshot 收到非法 level**（如 99）→ filter `[1,2,3,4].includes(snap.level)` 失败 → 强制 1。data 防御。
- **Lv4 之后 scoreToNextLevel**() → 返回 `Infinity` 让 UI 知道封顶。

## Dependencies

### 上游
| 系统 | 用途 |
|------|------|
| DayCycleSystem | `onWeekCompleted` 触发 recordWeek |
| RunManager | reset / loadSnapshot / 启停管理 |

### 下游
| 系统 | 接口 |
|------|------|
| Vue Store (careerStore) | 订阅 onPromoted / onScoreChanged 推 UI |
| DayCycleSystem (回调) | 读 `getSalaryMultiplier()` 缩放每日工资 |
| EndingSystem (G-3) | 读 `getLevel()` 作为 ending resolve 输入 |

### 公共接口

```typescript
class CareerProgressionSystem {
  reset(): void
  loadSnapshot(snap: CareerState): void
  recordWeek(inputs: WeekScoreInputs): void
  applyScoreDelta(delta: number): void
  getLevel(): CareerLevel
  getScore(): number
  getWeeksWorked(): number
  getSnapshot(): CareerState
  getSalaryMultiplier(): number
  getTitle(): string                    // generic; UI 用 getJobLevelTitle
  scoreToNextLevel(): number            // Infinity at Lv4
  readonly onPromoted: TypedEventEmitter<PromotedEvent>
  readonly onScoreChanged: TypedEventEmitter<ScoreChangedEvent>
}

interface WeekScoreInputs {
  endOfWeekMoney: number
  avgEnergy: number
  avgMood: number
  uniqueEventsThisWeek: number
  choicesThisWeek: number
  reviewBonus: number   // 0 if no review event this week
}
```

## Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 说明 |
|--------|--------|---------|------|
| PROMOTION_THRESHOLDS | {1:0, 2:100, 3:250, 4:500} | 50-1000 | 升职门槛——降低让升职更易，升高让 Lv3/4 成稀有目标 |
| SALARY_MULTIPLIER_PER_LEVEL | {1.0, 1.5, 2.25, 3.5} | 1.0-5.0 | 工资倍率——影响 health resource 引入后的经济曲线 |
| moneyComponent 系数 | × 25, clamp(-1, 2) | 10-50 | money 对 score 的影响权重 |
| resourceComponent 系数 | × 40 | 20-60 | 资源管理对 score 的影响权重 |
| varietyComponent 系数 | × 20 | 10-30 | 事件多样性奖励——鼓励玩家不要每天点同一个选项 |
| reviewBonus 范围 | -30..+30 | -50..+50 | 周末 review 事件单次 delta（S4-3 在 weekend events JSON 配置） |

## Acceptance Criteria

- **GIVEN** 新 run, **WHEN** `reset()`, **THEN** `getLevel() === 1`、`getScore() === 0`、`getWeeksWorked() === 0`。
- **GIVEN** Lv1, **WHEN** `recordWeek({endMoney:200, avg E/M:60/70, unique:5, choices:5, review:0})`, **THEN** score 约 96，未升级。
- **GIVEN** Lv1 score=80, **WHEN** `applyScoreDelta(+30)`, **THEN** score=110, level=2, emit onPromoted({1, 2, 1.5})。
- **GIVEN** Lv1 score=0, **WHEN** `applyScoreDelta(+600)`, **THEN** level=4，**仅 emit 一次** onPromoted({1, 4, 3.5})。
- **GIVEN** Lv4, **WHEN** `scoreToNextLevel()`, **THEN** 返回 Infinity。
- **GIVEN** save snapshot {level: 99, score: -50}, **WHEN** `loadSnapshot`, **THEN** level=1, score=0（防御性 clamp）。
- **GIVEN** Lv2, **WHEN** `getSalaryMultiplier()`, **THEN** 返回 1.5。
- **GIVEN** Lv3, **WHEN** `getTitle()`, **THEN** 返回 `'资深骨干'`（generic, 不是 per-job）。
