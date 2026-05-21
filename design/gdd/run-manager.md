# 局管理器 (Run Manager)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-16
> **Implements Pillar**: 随开随走（局是最大完整单元，可随时中断恢复）+ 一局一笑（结局是最后的笑点）

## Overview

局管理器是一局游戏的总控制器——它管理"一局"的完整生命周期：从职业选择→初始化→日循环驱动→死亡/通关判定→结算→存档清理→返回选择。它是游戏核心循环的最外层壳，协调日周期系统、资源管理系统、职业轮回系统的工作节奏。每一局都是一个独立的"微人生"。

## Player Fantasy

**间接幻想**：玩家感受到的是完整的"一段打工经历"——从入职到离职/猝死/暴走，是一个有始有终的故事弧。好的局管理器让每局结束时有"盖棺定论"的仪式感——"这次打了3天工，赚了50块，最后因为周三加班太多猝死了"。结束不是失败，是一次完整的体验。

## Detailed Design

### Core Rules

1. **局生命周期**：

```typescript
type RunPhase =
  | 'JOB_SELECT'    // 展示职业选择界面
  | 'INITIALIZING'  // 初始化资源、加载事件池
  | 'PLAYING'       // 日循环进行中（日周期系统驱动）
  | 'DYING'         // 死亡过渡（显示死因动画）
  | 'SETTLING'      // 结算页面（展示本局成果）
  | 'ENDED'         // 局结束，准备回到JOB_SELECT
```

2. **局初始化流程** (`JOB_SELECT → INITIALIZING → PLAYING`)：
   - 玩家选择职业 → `jobRotation.selectJob(jobId)`
   - 获取职业配置（薪资倍率、资源修正、工作天数）
   - 初始化资源：`resourceManager.init()` + 应用职业修正
   - 加载事件池：`eventDataEngine.loadJobEvents(jobId)`
   - 创建新的runState存档：`saveService.saveRunState(newRunState)`
   - 通知日周期系统开始第1天：`dayCycle.startDay(1)`

3. **局进行中** (`PLAYING`)：
   - 局管理器不直接参与日内逻辑（由日周期→事件卡→结算引擎驱动）
   - 监听两个结束条件：
     - `resourceManager.onResourceDepleted` → 进入DYING
     - `dayCycle.onWeekCompleted` → 进入SETTLING（通关）
   - 监听日结束：`dayCycle.onDayEnded` → 触发自动存档

4. **死亡处理** (`PLAYING → DYING → SETTLING`)：
   - 死因判定：energy=0 → "燃尽/猝死"，mood=0 → "暴走离职"
   - 显示死因动画/文案（1-2秒）
   - 广告续命检查点：展示"看广告续命？"（广告激励系统接口）
   - 如果续命成功 → 回到PLAYING（恢复energy到50%）
   - 如果拒绝/无广告 → 进入SETTLING

5. **结算流程** (`SETTLING`)：
   - 计算本局成果：存活天数、总收入、选择数量、死因
   - 结算工资：将money存入profile.totalSavings
   - 检查职业解锁：`jobRotation.checkUnlocks(runResult)`
   - 检查成就：（Alpha阶段，MVP跳过）
   - 展示结算页面
   - 清理runState：`saveService.clearRunState()`

6. **结算数据结构**：

```typescript
interface RunResult {
  jobId: string
  jobName: string
  survivalDays: number       // 存活天数 (1-7)
  totalMoney: number         // 本局总收入
  totalChoices: number       // 做了多少次选择
  deathType: 'burnout' | 'rage_quit' | 'survived' | 'fired'
  deathDay: number           // 死在第几天 (通关则=最后一天)
  highlights: string[]       // 本局高光时刻（触发的特殊事件）
  duration: number           // 实际游玩时长(秒)
}
```

### States and Transitions

| 状态 | 含义 | 转换 |
|------|------|------|
| `JOB_SELECT` | 等待玩家选择职业 | → `INITIALIZING`: 玩家确认选择 |
| `INITIALIZING` | 加载职业数据、初始化系统 | → `PLAYING`: 初始化完成 |
| `INITIALIZING` | | → `JOB_SELECT`: 加载失败(回退) |
| `PLAYING` | 日循环进行中 | → `DYING`: 资源归零 |
| `PLAYING` | | → `SETTLING`: 工作周全部完成(通关) |
| `DYING` | 显示死因/询问续命 | → `PLAYING`: 广告续命成功 |
| `DYING` | | → `SETTLING`: 拒绝续命/无广告 |
| `SETTLING` | 展示结算页面 | → `JOB_SELECT`: 玩家确认/关闭结算 |
| `ENDED` | 内部清理态 | → `JOB_SELECT`: 清理完成 |

### Interactions with Other Systems

| 系统 | 方向 | 接口 |
|------|------|------|
| 职业轮回系统 | ← 选择职业 | `selectJob(jobId)`, `checkUnlocks(result)` |
| 日周期系统 | → 驱动日循环 | `startDay(1)`, 监听 `onDayEnded`/`onWeekCompleted` |
| 资源管理系统 | → 初始化/监听 | `init()`, 监听 `onResourceDepleted` |
| 事件数据引擎 | → 加载事件 | `loadJobEvents(jobId)` |
| 存档系统 | ↔ 读写 | `saveRunState()`, `clearRunState()`, `saveProfile()` |
| 广告激励系统 | → 续命请求 | `showReviveAd(): Promise<boolean>` |
| 状态效果系统 | → 订阅 onPhaseChanged | 状态效果系统订阅 `RunManager.onPhaseChanged`：当 phase=`ENDED` 时调用 `statusSystem.clearAll()`；`DYING`/`SETTLING` 阶段**不**清空（保留续命场景的 status）。订阅形式而非直接调用——避免 RunManager 直接依赖 statusSystem。详见 `design/gdd/status-system.md` |
| 结算页面 | → 提供数据 | `getRunResult(): RunResult` |

## Formulas

### 结算评价

`rating = (survivalDays / totalDays) × 0.4 + (money / expectedMoney) × 0.3 + (choicesVariety / totalChoices) × 0.3`

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| survivalDays | int | 1-7 | 实际存活天数 |
| totalDays | int | 3-7 | 该职业工作天数 |
| money | int | 0-∞ | 本局总收入 |
| expectedMoney | int | - | 如果全活=预期日薪总和 |
| choicesVariety | int | 0-N | 不同事件的选择数（去重后） |

**Output:** 0-1之间的评分，映射为评价等级：
- ≥0.9: S级 "卷王"
- ≥0.7: A级 "打工达人"
- ≥0.5: B级 "勉强混过"
- ≥0.3: C级 "摸鱼被抓"
- <0.3: D级 "第一天就寄了"

## Edge Cases

- **If 玩家在INITIALIZING阶段退出**：无runState产生，下次进入直接到JOB_SELECT。

- **If 玩家在PLAYING阶段退出（中途离开）**：runState已存档。下次进入时检测hasActiveRun() → 恢复到中断的那天/那个事件。

- **If 续命广告加载超时(>5秒)**：自动视为"无广告"，进入SETTLING。不让玩家等。

- **If 续命后再次立即死亡（同一天内）**：同一局只允许续命1次。第二次死亡直接进入SETTLING。

- **If 通关(SURVIVED)且money<0**：仍算通关，但结算评价中money项为0分。负债记入profile。

- **If 同时触发weekCompleted和resourceDepleted**（最后一天最后一个事件导致死亡）：优先判定为死亡（DYING），不算通关。

## Dependencies

### 上游

| 系统 | 依赖类型 | 接口 |
|------|---------|------|
| 日周期系统 | Hard | 驱动日循环 |
| 资源管理系统 | Hard | 初始化+死亡监听 |
| 职业轮回系统 | Hard | 职业选择和解锁检查 |

### 下游

| 系统 | 接口 |
|------|------|
| 永久进度系统 | `runResult` 用于经验/解锁计算 |
| 成就系统 | `runResult` 用于成就判定 |
| 广告激励系统 | `showReviveAd()` 续命广告 |
| 状态效果系统 | 局进入 ENDED 时 `clearAll()` |
| 结算页面 | `getRunResult()` 渲染结算 |
| 分享系统 | `getRunResult()` 生成分享图 |

### 公共接口

```typescript
interface RunManager {
  startNewRun(jobId: string): Promise<void>
  resumeRun(): Promise<void>
  getCurrentPhase(): RunPhase
  getRunResult(): RunResult | null
  hasActiveRun(): boolean
  requestRevive(): Promise<boolean>
  endRun(): void
  onPhaseChanged: EventEmitter<RunPhase>
  onRunEnded: EventEmitter<RunResult>
}
```

## Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 说明 |
|--------|--------|---------|------|
| `MAX_REVIVES_PER_RUN` | 1 | 0-3 | 每局最多续命次数 |
| `REVIVE_ENERGY_PERCENT` | 50 | 20-80 | 续命后恢复精力百分比 |
| `REVIVE_AD_TIMEOUT_MS` | 5000 | 3000-10000 | 续命广告加载超时 |
| `DEATH_ANIMATION_MS` | 1500 | 800-3000 | 死因动画时长 |
| `AUTO_SAVE_INTERVAL` | 'per_day' | per_day/per_event | 自动存档频率 |

## Acceptance Criteria

- **GIVEN** 玩家选择"程序员", **WHEN** startNewRun("programmer"), **THEN** 资源初始化为energy=70(80-10修正), mood=60, money=0；事件池加载programmer事件；第1天开始。

- **GIVEN** 正在PLAYING, **WHEN** resourceManager emit resourceDepleted('energy'), **THEN** 进入DYING状态，显示"燃尽"动画。

- **GIVEN** DYING状态, **WHEN** 玩家点击续命且广告播放成功, **THEN** 回到PLAYING状态，energy恢复到50。

- **GIVEN** DYING状态且已续命1次, **WHEN** 再次死亡, **THEN** 直接进入SETTLING，不再询问续命。

- **GIVEN** 工作周5天全部完成, **WHEN** dayCycle emit weekCompleted, **THEN** 进入SETTLING，deathType='survived'。

- **GIVEN** 结算完成, **WHEN** endRun(), **THEN** clearRunState, money存入profile.totalSavings, 检查职业解锁, 回到JOB_SELECT。

- **GIVEN** 玩家中途退出后重新打开, **WHEN** hasActiveRun()=true, **THEN** resumeRun恢复到正确的天数和状态。
