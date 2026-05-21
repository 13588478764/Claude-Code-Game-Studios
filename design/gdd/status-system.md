# 状态效果系统 (Status System)

> **Status**: In Design (v2 — major revision per design review 2026-05-19)
> **Author**: user + agents
> **Last Updated**: 2026-05-19
> **Implements Pillar**: 一局一笑（comedy beat 放大器）+ 三秒上手（最多一个胶囊，一眼可见）
> **Anti-Pillar Compliance**: 严格保留"NOT 深度策略"——本系统是**喜剧节拍放大器**，不是 buff 策略层
>
> **v2 Revision Note**: v1 把系统过设为"策略引擎"（8 status 叠乘 / 多 target / 长持续）违反 anti-pillar。v2 大幅砍向"comedy beat"——最多 2 槽 / strongest-wins / 2 天封顶。

---

## Overview

状态效果系统给玩家身上挂一两个**短效情绪标签**——不是数值策略，是叙事张力的视觉延续。"喝杯咖啡"上"亢奋"，**接下来一两张卡的精力损失被打折**；"被领导骂"上"emo"，**接下来一两张卡的心情损失被放大**。系统的意义在于让选择的喜剧效果**多撑一两个事件**，让玩家说"刚才那杯咖啡还在管用"——而不是让玩家计算如何叠 buff 通关。

**严格定位**：comedy beat 放大器，**不是**策略层。3 资源 + 二选一 + 5 天 是这游戏的全部决策维度——状态系统不增加新维度，只让现有维度的某些事件**晚一点结算**。

---

## Player Fantasy

**直接幻想**：选了"喝咖啡"，接下来那张"加班"卡精力少扣了 10 点——那个"诶？怎么这次没那么累"的瞬间是 fantasy 的核心。它是**已经发生选择的回响**，不是**未来选择的铺垫**。

**关键限定**（修正 v1 的过度承诺）：玩家不需要预判 buff 链路。Buff 的乐趣在于**回看时说"刚才喝咖啡管用了"**——这是"延迟笑点"机制，对齐**一局一笑**支柱。绝不要求玩家"为未来铺路"——那违反**三秒上手**。

服务支柱：**一局一笑**（emo 抖动 + 亢奋发光等情绪表演，比文案更直接）；**三秒上手**（最多 1-2 个 chip，无需理解叠乘）。

---

## Detailed Design

### Core Rules

1. **Status 数据结构**（精简版）：

```typescript
interface StatusEffect {
  id: string                           // 唯一标识，如 'caffeine'
  name: string                         // 显示名称，如 '亢奋'
  icon: string                         // emoji 或自绘图标 key
  type: 'buff' | 'debuff'              // 视觉色调；与计算无关（计算只看 mul）
  daysLeft: number                     // 剩余天数（含当天）
  energyMul?: number                   // 精力变化倍率（应用于负值 effect 时减弱/放大）
  moodMul?: number                     // 心情变化倍率
  source?: string                      // 来源 eventId（仅成就/统计用，不影响逻辑）
}
```

> ⚠️ **去掉 moneyMul**（v1 → v2）：金钱无 status 修正。金钱是 0 上限的简单累计资源，不参与 buff 系统，避免 dailySalary 的语义模糊（评审建议 #22）。

2. **槽位制添加规则**（替换 v1 的"无限同时存在"）：
   - 玩家最多同时持有 **1 个 buff + 1 个 debuff = 共 2 个 status**
   - 添加新 buff 时：若已有 buff → **替换**（不并存）。emit `onStatusReplaced({ old, new })`
   - 添加新 debuff 同理
   - 同 id status 再次添加：**新 mul 替换旧 mul + 新 days 替换旧 days**（不叠加任何字段）。emit `onStatusRefreshed`

3. **strongest-wins 修正规则**（替换 v1 的连乘）：
   - 同 target 不存在多 status——因为最多 1 buff + 1 debuff，且二者对同 target 的修正不会同时存在（数据约束：data designer 不在 buff 和 debuff 上对同一 target 都设 mul）
   - 因此 modifyDelta 退化为：**找到对该 target 设了 mul 的那 1 个 status**（如果有），应用其 mul
   - 没有 status 设了对应 mul → mul = 1.0（无修正）

4. **修正应用位置**（修正 v1 架构，符合 ADR-001/003）：
   - **不修改 ResourceManager**——保持 Sprint 1 的纯 service
   - **由 ChoiceResolutionEngine 在 effect 入参时前置修正**：

```typescript
// ChoiceResolutionEngine.resolveChoice() 内部
const status = statusSystem
const modifiedEffects = choice.effects.map(fx => ({
  target: fx.target,
  value: status.applyToEffect(fx.target, fx.value)  // 返回新数值
}))
resourceManager.applyEffects(modifiedEffects)
```

> 这个调整把 v1 的 ResourceManager constructor injection 完全删除。Sprint 1 已实现的 ResourceManager 不动。修正发生在 service 链上游。

5. **修正数学**（fix Math.round bug + 反向 effect 死边界）：

```typescript
// Status applies only to effect.value, not result. Sign-aware floor.
function applyToEffect(target, rawValue: number): number {
  const mul = getMulForTarget(target)  // 1.0 if no status
  const product = rawValue * mul
  // sign-aware floor: 损失向 0 取整（玩家友好），收益向 0 取整（保守）
  return product >= 0 ? Math.floor(product) : Math.ceil(product)
}
```

> **Math.floor + Math.ceil 而非 round**（评审 #3、#9）：JS `Math.round` 是 "round half toward +∞"（ECMA-262 标准，非 banker's rounding），但在 .5 边界产生方向偏差（round(-19.5)=-19, round(19.5)=20——对正负方向不对称）。signFloor 始终向 0 取整，方向语义统一。
> 设计意图：负值取整向 0（玩家少损失 1）；正值取整向 0（玩家少收益 1）——一致地"对玩家保守"。

6. **天数倒数规则**：
   - DayCycleSystem 在每个 `onDayEnded` 时通知状态系统
   - 每个 status 的 daysLeft -= 1
   - daysLeft <= 0 移除 + emit `onStatusExpired`
   - **倒数发生在工资结算之后**——避免 status 影响 dailySalary 语义模糊

7. **持久化规则**：
   - status 列表写入 `runState.statuses: StatusEffect[]`（save schema 兼容，见 Save Migration）
   - 局结束清空（DEAD / WIN）

8. **UI 显示规则**：
   - **最多 2 个胶囊**（1 buff + 1 debuff）——不需要 +N 折叠
   - chip 触发时（添加 / 修正参与 / 过期）整体 pulse 一次
   - **无 tooltip，无长按**——chip 文字本身是充分说明

### States and Transitions

无全局状态机。单个 status 生命周期：

| 阶段 | 触发 | 行为 |
|------|------|------|
| `CREATED` | resolveChoice 含 buff 字段 | addStatus → emit onStatusAdded |
| `ACTIVE` | daysLeft > 0 | applyToEffect 时被查询 |
| `REPLACED` | 同槽位（buff/debuff）有新 status 加入 | 旧 status 移除 + emit onStatusReplaced |
| `REFRESHED` | 同 id status 重新添加 | mul + days 同时更新（不叠加）+ emit onStatusRefreshed |
| `EXPIRED` | daysLeft <= 0 | 移除 + emit onStatusExpired |
| `CLEARED` | StatusSystem 订阅 `RunManager.onPhaseChanged`，当 phase=`ENDED` 时触发（**不**在 DYING/SETTLING——保留续命场景的状态） | clearAll → emit onStatusesCleared |

### Interactions with Other Systems

| 系统 | 方向 | 接口 |
|------|------|------|
| 选择结算引擎 | ← 接收 buff 添加请求 | `addStatus(buff: StatusEffect)` |
| 选择结算引擎 | → 提供修正函数 | `applyToEffect(target, rawValue): number` |
| 日周期系统 | ← 监听 onDayEnded（晚于工资结算）| 触发 tickStatuses() |
| 存档系统 | ↔ 读写 | `runState.statuses` 数组 |
| 局管理器 | ← 接收清空 | RunManager.onPhaseChanged → ENDED 时调 clearAll() |
| 游戏主界面 | → 提供数据 | `getActiveStatuses()`（返回 0-2 个）+ `onStatusChanged` |

---

## Formulas

### 单 status 修正应用

`modifiedValue = signFloor(rawValue × mul)`

```typescript
function signFloor(x: number): number {
  return x >= 0 ? Math.floor(x) : Math.ceil(x)
}
```

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| rawValue | v | int | -100 to +100 | choice.effect.value 原始值 |
| mul | μ | float | [BUFF_MUL_MIN, DEBUFF_MUL_MAX] | 单 status 倍率，见 Tuning Knobs |
| modifiedValue | v' | int | clamped to int 后传给 ResourceManager | 修正后的值 |

**Output Range:** v ∈ [-100, +100] × μ ∈ [0.5, 2.0] = v' ∈ [-200, +200]（仍由 ResourceManager 内部 clamp 到资源边界）

**Example A**（buff 减弱负面）：
- rawValue = -20（精力 -20）
- ☕亢奋 energyMul = 0.5
- modifiedValue = signFloor(-20 × 0.5) = signFloor(-10) = -10

**Example B**（debuff 放大负面）：
- rawValue = -10（心情 -10）
- 💔emo moodMul = 1.5
- modifiedValue = signFloor(-10 × 1.5) = signFloor(-15) = -15

**Example C**（边界 Math.floor 验证）：
- rawValue = -19, mul = 1.05
- product = -19.95
- signFloor(-19.95) = Math.ceil(-19.95) = -19（少损失 1，对玩家友好）
- 对比 v1 用 round(-19.5) → JS 实际是 -19（round half toward +∞），但与 round(19.5)=20 在符号方向不对称；v2 signFloor 明确"向 0 取整"

### 同时多 status 的处理

> **退化情况——不存在多 status 同 target 修正**。槽位制保证最多 1 buff + 1 debuff，data 设计约定 buff 不在 debuff 同 target 上 重复设 mul。
>
> ResourceManager 可写一行断言：`assert(activeMulCount(target) <= 1, 'mul collision')` 兜底。

---

## Edge Cases

- **If addStatus 的同槽位（buff 或 debuff）已有不同 id 的 status**：旧的被踢出，新的 take over。emit `onStatusReplaced({ slot, old: oldStatus, new: newStatus })`。设计意图：每杯新咖啡盖掉前一杯，这是"短效"语义。

- **If addStatus 的同 id status 已存在**：mul + days 一并替换为新值（不叠 days、不取 max mul）。emit `onStatusRefreshed`。设计意图：新 buff 是新事件触发，应当反映新事件的强度。

- **If addStatus 时 days <= 0 或 days > BUFF_MAX_DAYS**（数据配置错误）：拒绝添加，console.warn 含 status.id 和违规字段。

- **If 数据违约：buff 和 debuff 的 mul 都对同 target 起作用**（data designer 破坏 schema lint 约定）：`getMulForTarget` 返回**先到达 statusSystem 的那个**（即先 addStatus 的状态）的 mul；后到的 mul 该 target 字段被忽略，但 status 本身仍占槽位。开发期 assert 抛出 warn 提示数据违约——schema lint 应在 build 时拦截，不应到运行时。

- **If RunManager 进入 DYING（玩家死亡，等待续命）**：**不清空 statuses**。续命后 PLAYING 时玩家保留之前的 status（含 daysLeft）。设计意图：续命是"再撑一天"而非"重置"。

- **If RunManager 进入 ENDED（局正式结束）**：clearAll() 清空所有 status，emit `onStatusesCleared`。

- **If 玩家选择含 followUp 且 followUp 卡也在同一天**：followUp 卡在解析其 effect 时也会经过 status 修正（与普通卡完全一致）。修正不区分主卡和 followUp。

- **If 选择含 buff 字段但 buff.id 已存在 + buff 字段缺 mul**（仅 days 变化）：仍按"完全替换"处理，新 mul 为 undefined，相当于纯计时 buff 不影响数值。

- **If 局加载时 save 中的 statuses 含 daysLeft <= 0**（损坏存档）：loadSnapshot 过滤掉这些 entry，emit `onLoadCorrected({ dropped: [...] })`。

---

## Dependencies

### 上游

| 系统 | 依赖类型 | 接口 |
|------|---------|------|
| 选择结算引擎 | Hard | 调 `addStatus()` 添加，调 `applyToEffect()` 修正 |
| 日周期系统 | Hard | 监听 `onDayEnded` 触发 tickStatuses（在工资结算之后）|
| 存档系统 | Hard | runState.statuses 字段（schema v1 兼容）|
| 局管理器 | Hard | RunPhase ENDED 时 clearAll；DYING/SETTLING 不清空 |

### 下游

| 系统 | 接口 |
|------|------|
| 游戏主界面 | 渲染状态胶囊 + 监听 `onStatusChanged` |
| 选择结算引擎 | applyToEffect 是 status-system 的 public method，被结算引擎调用 |

### 公共接口

```typescript
// Public interface — exposed to ChoiceResolutionEngine, RunManager, DayCycleSystem,
// status-store. UI components import via store only.
interface StatusSystem {
  // ====== Mutation (Choice / Run / Day callers) ======
  addStatus(spec: StatusEffect): void
  clearAll(): void

  // ====== Query (slot-based, canonical for v2) ======
  getBuff(): StatusEffect | null        // 当前 buff 槽位
  getDebuff(): StatusEffect | null      // 当前 debuff 槽位
  hasStatus(id: string): boolean

  // ====== Modifier (called by ChoiceResolutionEngine ONLY) ======
  // Recommended: typed as readonly accessor on engine side to prevent misuse from
  // unrelated call sites. See evaluator note #12.
  applyToEffect(target: 'energy' | 'mood', rawValue: number): number

  // ====== Day tick (called by DayCycleSystem listener) ======
  tickStatuses(): void

  // ====== Persistence ======
  getSnapshot(): StatusEffect[]
  loadSnapshot(snapshot: StatusEffect[] | undefined): void  // undefined → empty

  // ====== Events ======
  onStatusAdded: TypedEventEmitter<StatusEffect>
  onStatusReplaced: TypedEventEmitter<{ slot: 'buff' | 'debuff'; old: StatusEffect; new: StatusEffect }>
  onStatusRefreshed: TypedEventEmitter<{ id: string; oldDays: number; newDays: number }>
  onStatusExpired: TypedEventEmitter<StatusEffect>
  onStatusesCleared: TypedEventEmitter<void>
  onLoadCorrected: TypedEventEmitter<{ dropped: StatusEffect[] }>  // 损坏存档过滤的 entry
  onStatusChanged: TypedEventEmitter<StatusEffect[]>  // UI 用合并通知
}

// Internal-only methods (NOT in public interface; used by status-system internals)
// - removeStatus(id): used by tickStatuses when daysLeft <= 0 and by clearAll
```

### Status Store（ADR-003 强制要求 Service → Store → Component）

```typescript
// src/stores/status-store.ts (Sprint 2 实现)
export const useStatusStore = defineStore('status', () => {
  const buff = ref<StatusEffect | null>(null)
  const debuff = ref<StatusEffect | null>(null)

  statusSystem.onStatusChanged.on((statuses) => {
    buff.value = statusSystem.getBuff()
    debuff.value = statusSystem.getDebuff()
  })

  // No actions exposed to UI — UI only reads. Mutations go through ChoiceResolutionEngine.
  return { buff, debuff }
})
```

> **架构约束**：Vue 组件**不得**直接 import `statusSystem`。仅通过 store 读取。

### Save Migration

> **Schema 兼容策略**（替换 v1 的"需要 schema bump"）：
>
> 两个新增字段，**均为可选**——schema v1 兼容，无需 version bump、无 migration shim。

**字段 1：`runState.statuses?: StatusEffect[]`**（runtime 状态，局结束清空）
- 旧存档无此字段 → loadSnapshot 收到 undefined → 初始化为 []
- 局结束清空（与 runState 整体一致）

**字段 2：`profile.firstStatusShown?: boolean`**（permanent 标志，跨局保留）
- 旧存档无此字段 → 视为 false → 玩家本局首次拿到 status 时仍然显示教学气泡
- 玩家看完一次教学后置为 true，**局结束不清空，跨局保留**
- 这是 v2 评审 #1 的修正——v1 错放在 runState 导致每局重置

> 修改 `src/types/save.ts`：
> ```typescript
> export interface RunSnapshot {
>   ...existing fields...
>   statuses?: StatusEffect[]  // v2 新增可选字段
> }
>
> export interface ProfileData {
>   ...existing fields...
>   firstStatusShown?: boolean  // v2 新增可选字段（permanent）
> }
> ```

---

## Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 说明 |
|--------|--------|---------|------|
| `MAX_CONCURRENT_STATUSES` | 2 | 1-3 | 同时持有的 status 总数（1 buff + 1 debuff）|
| `BUFF_MAX_DAYS` | 2 | 1-3 | 单个 buff 最大天数（comedy beat，不跨整周） |
| `DEBUFF_MAX_DAYS` | 2 | 1-3 | 单个 debuff 最大天数 |
| `BUFF_MUL_MIN` | 0.5 | 0.4-0.7 | buff mul 下限（防止过强减伤）|
| `DEBUFF_MUL_MAX` | 2.0 | 1.3-2.5 | debuff mul 上限（防止单 debuff 即死）|
| `STATUS_TICK_TIMING` | 'dayEnd-after-salary' | 固定 | 倒数时机锁定为工资结算后 |
| `CHIP_VISUAL_HEIGHT_PX` | 26 | 24-32 | chip 视觉高度 |
| `CHIP_HIT_HEIGHT_PX` | 44 | 44-56 | chip 触控热区高度（透明 padding 撑大）|

> **Schema validation 规则**（评审 #10、#16）：data designer 写 buff 时，schema lint 应警告：
> - `type: 'buff' && energyMul > 1.0` → warn（buff 不应放大负面）
> - `type: 'debuff' && energyMul < 1.0` → warn（debuff 不应减弱负面）
> - `days > BUFF_MAX_DAYS` → warn
>
> **必须在 build time 运行**——配在 vite plugin 或 npm prebuild hook 里。坏数据不应能 ship 到生产环境。运行时 assert 仅作开发期兜底。

---

## Visual/Audio Requirements

### 状态胶囊（Status Chip）

- **位置**：顶部资源条下方，事件卡上方独立行
- **结构**：`[icon] [name] [xD]`
  - 视觉高度：26px（chip body）
  - 触控热区：44px（**透明 padding** 上下各 9px 撑出，与视觉解耦）
- **配色**：buff 绿底 / debuff 红底（hex 待 art-bible）
- **形状区分**（评审 #25 色盲友好）：buff = 圆角矩形；debuff = 圆角矩形 + 1px 红色破折线下划线
- **图标**：MVP 用 emoji；art-bible 阶段考虑替换为自绘 icon（评审 #24 跨平台 emoji 不稳定）

### Chip 动画

| 触发 | 动画 | 时长 |
|------|------|------|
| onStatusAdded | 弹入（scale 0.8 → 1.0）+ glow 一次 | 350ms |
| onStatusReplaced | 旧 chip 渐出 + 新 chip 弹入 | 400ms |
| onStatusRefreshed | 整体 pulse + 天数闪烁 | 250ms |
| onStatusExpired | 渐出 + 向左滑出 | 350ms |
| **applyToEffect 触发了修正** | 该 chip 短暂 pulse + glow | 400ms（替换 v1 的 * 角标，评审 #13）|

### 资源变化反馈（替换 v1 的 * 角标）

- **不**在浮动数字旁加 \* 角标——角标在 800ms 浮字上无法被 UX 利用
- **改为**：触发修正的 chip 在浮字出现的同一帧 pulse。"刚才那杯咖啡管用了"在视觉上是"咖啡 chip 闪了一下"，比 \* 直观

### 音效（Audio integration subsection，评审 #26）

| 事件 | 类别 | 优先级 | 复音 | 强度 |
|------|------|--------|------|------|
| onStatusAdded | sfx_ui | 低（在 card-flip 之下）| 1 个/300ms | -18 LUFS（轻声）|
| onStatusReplaced | sfx_ui | 低 | 同上 | -18 LUFS |
| onStatusRefreshed | sfx_ui | 低 | 同上 | -20 LUFS（更轻）|
| onStatusExpired | sfx_ui | 极低 | 1 个/500ms | -22 LUFS（极轻）|

> **明确声明**：状态系统的所有音效**非 load-bearing**——静音模式下游戏完全可玩，状态变化由视觉承担全部信息。

> 📌 **Asset Spec** — 视觉/音频规范定义完毕。art-bible 通过后运行 `/asset-spec system:status-system` 产出每个 status icon 的视觉描述 + 生成 prompt + 音效 spec。

---

## UI Requirements

📌 **UX Flag — status-system**: 此系统在游戏主界面有持久 UI 元素。Sprint 2 实施前必须运行 `/ux-design` 为 game-main 屏幕产出 UX spec，含：

### 必须的 UI 元素

1. **状态栏（Status Bar）**——顶部资源条下方，事件卡上方
   - 高度：触控热区 44px（视觉 26px + 透明 padding）
   - 内容：横向最多 2 个 chip（左 buff，右 debuff），无折叠逻辑（永远 ≤2）
   - 空状态：collapse 高度为 0（不占空间），淡入淡出过渡

2. **首次出现教学**（评审 #29 onboarding）
   - 玩家**首次**（跨局永久）拿到任意 status 时，chip 旁出现 1.5s 的小提示气泡："新效果！持续 X 天"
   - 标记 `profile.firstStatusShown: boolean`（**permanent slot**——存于 profile 而非 runState；runState 在局结束时清空，profile 跨局保留）
   - 后续局再获取 status 不再触发该提示

3. **可访问性**
   - 触控热区 44×44px（透明 padding 实现，与视觉无关）
   - 配色 + 形状双重区分 buff/debuff（不仅依赖颜色）
   - 文字最小字号 14px（与 game-main UI 一致）
   - 动效尊重"减少动画"系统设置：脉冲降级为静态高亮

### 与事件卡区域的空间关系（评审 #14）

- 状态栏占用顶部 ~50rpx 空间——已纳入 game-main UI 整体布局预算
- 不与事件卡（400rpx 高度）冲突——事件卡仍占主屏中部

---

## Acceptance Criteria

### Logic ACs（自动化测试，blocking）

- **GIVEN** 玩家选择含 buff `{id:'caffeine', name:'亢奋', icon:'☕', type:'buff', daysLeft:2, energyMul:0.5}`, **WHEN** ChoiceResolutionEngine.resolveChoice 触发 statusSystem.addStatus, **THEN** statusSystem.getBuff() 返回该 status，statusSystem.getDebuff() 返回 null。

- **GIVEN** statusSystem 持有 ☕亢奋（energyMul=0.5）, **WHEN** ChoiceResolutionEngine 处理 effect=`{target:'energy', value:-20}`, **THEN** statusSystem.applyToEffect('energy', -20) 返回 -10，传给 ResourceManager 的 effect.value 是 -10。

- **GIVEN** 玩家持有 ☕亢奋（daysLeft=1）, **WHEN** DayCycleSystem.onDayEnded 触发, **THEN** statusSystem.tickStatuses 后 ☕亢奋 daysLeft=0 → 移除 → emit onStatusExpired。

- **GIVEN** 玩家持有 ☕亢奋（daysLeft=2）, **WHEN** 选择再次添加 ☕亢奋（同 id, daysLeft=1, energyMul=0.7）, **THEN** 旧的被替换：daysLeft=1, energyMul=0.7。emit onStatusRefreshed。

- **GIVEN** 玩家持有 ☕亢奋（buff 槽）, **WHEN** 选择添加 💪奋斗（id 不同，type='buff'）, **THEN** ☕亢奋 被替换为 💪奋斗。emit onStatusReplaced。debuff 槽不受影响。

- **GIVEN** statusSystem 同时持有 ☕亢奋（energyMul=0.5, buff 槽）和 💔emo（moodMul=1.5, debuff 槽）, **WHEN** effect=`{target:'energy', value:-20}`, **THEN** applyToEffect 返回 -10（仅 buff 影响 energy）。effect=`{target:'mood', value:-10}` → 返回 -15（仅 debuff 影响 mood）。

- **GIVEN** rawValue=-19, mul=1.05, **WHEN** applyToEffect 计算, **THEN** signFloor(-19.95) = -19。（验证 Math.ceil 在负数取整向 0）

- **GIVEN** RunManager.onPhaseChanged emit DYING（玩家死亡等续命）, **WHEN** statusSystem 收到, **THEN** clearAll **未被调用**，statuses 保留。

- **GIVEN** RunManager.onPhaseChanged emit ENDED, **WHEN** statusSystem 收到, **THEN** clearAll 被调用，emit onStatusesCleared。

- **GIVEN** 存档 runState 不含 statuses 字段（旧存档）, **WHEN** statusSystem.loadSnapshot(undefined) 调用, **THEN** statuses 初始化为 []，无报错。

- **GIVEN** 存档 runState.statuses 含 `{id:'old', daysLeft:0, ...}`, **WHEN** loadSnapshot, **THEN** 该 entry 被过滤，最终 statuses 不含它，emit onLoadCorrected。

- **GIVEN** addStatus 调用时 days = 0, **WHEN** schema 校验, **THEN** 拒绝添加，console.warn 含 status.id。

- **GIVEN** statusSystem 单元测试套件, **WHEN** `npm test`, **THEN** 命名测试覆盖：addStatus 替换 / 同 id 刷新 / strongest-wins 单 mul / signFloor 边界 / tickStatuses 倒数 / loadSnapshot 损坏过滤 / clearAll 触发时机 / DYING 不清空 全部分支。
  > 覆盖率 100%（行）和 100%（分支）作为 vitest threshold；不作为 AC 文本。

- **GIVEN** ChoiceResolutionEngine 处理含 buff 字段的 choice, **WHEN** resolveChoice, **THEN** addStatus 在 effects 应用**之后**触发（即当前选择的 effect 不被刚加的 buff 影响）。

- **GIVEN** 玩家持有 buff 与 debuff 各 1, **WHEN** 玩家死亡（DEAD 状态）, **THEN** RunManager 进入 DYING（status 仍在）→ 玩家不续命 → 进入 ENDED → statuses 清空。**全程无 race condition**：clearAll 在 ENDED 单次触发。

### Visual ACs（手测，advisory）

- **GIVEN** chip 渲染（视觉 26px）, **WHEN** Vue 组件单元测试断言 wrapper 元素 `getBoundingClientRect().height`, **THEN** ≥ 44px（透明 padding 实现）。**测试方式**：programmatic via `@vue/test-utils` 的 component test，断言 chip 包装容器的 computed style + bounding box——避免依赖小程序 DevTools（微信/抖音/支付宝 各有不同），保证跨平台测试。

- **GIVEN** applyToEffect 返回值 ≠ rawValue（修正起作用了）, **WHEN** 资源变化浮字出现, **THEN** 对应 chip 同帧 pulse 一次（350ms 内）。

- **GIVEN** 玩家本局首次获得任意 status, **WHEN** chip 出现, **THEN** 1.5s 教学气泡浮出"新效果！持续 X 天"。后续不再触发。

---

## Open Questions

| 问题 | 影响 | 决议时机 |
|------|------|---------|
| **risks 不被 status 修正——v2 最终设计意图**（评审 #11 确认）。Beta+ 才考虑扩展。当前 risk 概率字段仅由 choice 数据本身决定，与 status 无关 | 锁定不引入 | 已确认，不重开 |
| 自绘 icon vs emoji 的成本权衡 | 视觉一致性 vs 美术工作量 | art-bible Phase 2 |
| 被动技能（Alpha）系统加入后，是否覆盖 status 的 mul？建议：被动 = 永久 modifier，外层；status = 临时 modifier，内层。两者顺序乘 | Alpha 设计 | 被动技能 GDD |
| 状态条空间是否值得让出给"今日小贴士"等 UX 元素 | UI 信息密度 | UX spec 阶段 |

---

## v1 → v2 Major Revisions Summary

针对设计评审报告的 30 项 findings：

| 评审编号 | v1 问题 | v2 解决 |
|----------|---------|---------|
| #1 | 8-status × 3-target 违反 anti-pillar | 砍到最多 2（1 buff + 1 debuff）|
| #2 | finalMul 范围 [0.01, 9.0] 数学错误 | strongest-wins 退化为单 mul，范围 [BUFF_MUL_MIN, DEBUFF_MUL_MAX] |
| #3 | Math.round(-19.5) === -19 不是 -20 | signFloor（负数 ceil + 正数 floor）|
| #4 | mul ∈ [0.1, 3.0] 不可能反向 | 删除该 edge case |
| #5 | modifyDelta 签名 3 处不一致 | 改名 applyToEffect，统一签名返回单 number |
| #6 | 显示上限 4 vs 5 矛盾 | 标准化为 2（永远不需要折叠）|
| #7 | MAX_STATUS_INSTANCES eviction 未定义 | 槽位制（buff/debuff 各 1 槽）替换上限概念 |
| #8 | 注入 modifier 违反 ADR-001/003 | Choice 引擎前置修正，ResourceManager 不动 |
| #9 | wasModified 与 Sprint 1 的"clamped" 撞名 | 不引入 wasModified——视觉用 chip pulse 替代 |
| #10 | 无 save migration | runState.statuses 设为可选字段，schema 兼容无需 bump |
| #11 | 26px 视觉 vs 44×44px 触控冲突 | 透明 padding 解耦：视觉 26 / 触控 44 |
| #12 | 800ms 浮字上长按死交互 | 删除 tooltip / 长按；改 chip pulse |
| #13 | * 标记无 UX 含义 | 删除——chip pulse 替代 |
| #14 | 状态栏与事件卡空间冲突 | 50rpx 高度纳入主 UI 预算，不挤事件卡 |
| #15 | "为未来铺路" 无法实现 | 改为"延迟笑点 / past choice pays off"|
| #16 | 数据约束靠自律 | schema lint 警告（buff/debuff 方向）|
| #17 | 罕见用法 mul>1 正面 | 删除——v2 中 buff/debuff 均按方向语义校验 |
| #18 | 缺 status-store.ts | 已添加 status-store 接口规范 |
| #19 | clearAll 时机未定 | 锁定为 RunPhase=ENDED；DYING 不清空 |
| #20-22 | AC 混合逻辑+视觉、覆盖率非行为、缺关键 AC | AC 拆分为 Logic（blocking）+ Visual（advisory），添加 DYING / loadSnapshot 损坏 / refresh / 槽位替换 等 |
| #23 | refresh 语义未定 | 明确 mul + days 同时全替换 |
| #24 | 跨平台 emoji 不稳定 | art-bible 阶段考虑自绘 icon |
| #25 | 色盲不友好 | buff/debuff 形状区分（debuff 加破折线下划线）|
| #26 | 音效未规范化 | 添加 dB/LUFS / 复音 cap / 优先级 / 非 load-bearing 声明 |
| #27 | 双向依赖缺口 | （写完 v2 后单独更新 day-cycle / save / run-manager / game-main-ui）|
| #28 | source 字段未用 | 保留用于成就/统计，明确 "不影响逻辑" |
| #29 | 无首次教学 | 添加 firstStatusShown 一次性气泡 |
| #30 | 动画雪崩 | 状态栏动画为最低优先级，与卡退场冲突时让位 |
