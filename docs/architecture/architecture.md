# 打工轮回 — Master Architecture

## Document Status

- **Version**: 3
- **Last Updated**: 2026-05-25
- **Framework**: uni-app (Vue 3 + TypeScript)
- **Platform**: 微信/抖音/支付宝小程序 + H5
- **GDDs Covered**: save-system, event-data-engine, resource-management, day-cycle, job-rotation, event-card, choice-resolution, run-manager, game-main-ui, status-system, passive-skill-system, progression-system, career-progression-system, item-system, ending-system, achievement-system
- **ADRs Referenced**: ADR-001 ~ ADR-009

> **Note (v3 update 2026-05-25)**: 16 GDD 全部 retrofit 完成（增 6 个 service GDD），
> ADR 扩到 9 条（新增 ADR-008 EventCondition / ADR-009 Build Pipeline），事件总数 ~354 → 382，
> 测试 585 → 621。Sprint 4-7 architecture 详见底部 "Current Architecture" section。
> 早期的 Layer Map / Module Ownership / Data Flows section 是 Sprint 0 baseline —
> 历史准确但已非全貌。

---

## System Layer Map

```
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION (Vue 组件 + CSS 动画)                      │
│  GameMain.vue, JobSelect.vue, Settlement.vue             │
│  ResourceBar, EventCard, ChoiceButton, DayIndicator      │
├─────────────────────────────────────────────────────────┤
│  STATE (Pinia Stores — 响应式状态中枢)                    │
│  resourceStore, eventCardStore, dayCycleStore,           │
│  runStore, jobStore                                      │
├─────────────────────────────────────────────────────────┤
│  SERVICE (纯 TypeScript 逻辑 — 无 UI 依赖)               │
│  EventDataEngine, ResourceManager, DayCycleSystem,       │
│  JobRotationSystem, EventCardSystem,                     │
│  ChoiceResolutionEngine, RunManager                      │
├─────────────────────────────────────────────────────────┤
│  DATA (JSON 配置 + 本地存储读写)                          │
│  SaveService, EventLoader, JobConfigLoader               │
├─────────────────────────────────────────────────────────┤
│  PLATFORM (uni-app API 封装)                             │
│  StorageAdapter, AdAdapter, ShareAdapter, LifecycleHooks │
└─────────────────────────────────────────────────────────┘
```

### Layer Rules

- **向下依赖**: 上层可调用下层，不可反向
- **同层通信**: 通过 Pinia store 或 EventEmitter，不直接 import 同层模块
- **Platform 层封装所有平台差异**: Service/Data 层不直接调用 `uni.*` API
- **Presentation 层无业务逻辑**: 只读取 Store 状态 + emit 用户事件

---

## Module Ownership

| 模块 | 层 | 拥有数据 | 暴露接口 | 消费接口 |
|------|---|---------|---------|---------|
| **StorageAdapter** | Platform | uni.storage 封装 | `get/set/remove` | uni API |
| **AdAdapter** | Platform | 广告实例管理 | `showRewardedAd()`, `isAdReady()` | 平台广告SDK |
| **SaveService** | Data | localStorage 读写策略 | `load/save/clear Profile/RunState` | StorageAdapter |
| **EventLoader** | Data | JSON 文件缓存 | `loadJobEvents()`, `loadCommonEvents()` | 静态JSON import |
| **EventDataEngine** | Service | 当前事件池、冷却表 | `drawEvent()`, `getEventsPerDay()`, `loadJobEvents()` | EventLoader |
| **ResourceManager** | Service | 三维资源值、当前状态 | `applyEffects()`, `getResources()`, `getState()` | SaveService |
| **DayCycleSystem** | Service | 当前天数、事件进度 | `startDay()`, `eventCompleted()`, `getCurrentDay()` | EventDataEngine |
| **JobRotationSystem** | Service | 解锁列表、推荐权重 | `selectJob()`, `checkUnlocks()`, `getRecommendedJobs()` | SaveService |
| **EventCardSystem** | Service | 事件队列、卡片阶段 | `prepareDay()`, `selectChoice()`, `getCurrentCard()` | EventDataEngine, DayCycleSystem |
| **ChoiceResolutionEngine** | Service | 无持久状态(纯函数) | `resolveChoice()` | ResourceManager, SaveService |
| **RunManager** | Service | 局阶段、RunResult | `startNewRun()`, `resumeRun()`, `endRun()` | 所有Service + SaveService |
| **resourceStore** | State | resources 响应式包装 | Vue 组件绑定 | ResourceManager events |
| **eventCardStore** | State | currentCard 响应式 | Vue 组件绑定 | EventCardSystem events |
| **dayCycleStore** | State | currentDay 响应式 | Vue 组件绑定 | DayCycleSystem events |
| **runStore** | State | phase 响应式 | Vue 组件绑定 | RunManager events |
| **jobStore** | State | 职业列表响应式 | Vue 组件绑定 | JobRotationSystem |
| **GameMain.vue** | Presentation | 无 | 用户事件 emit | stores |

---

## Data Flow

### Flow 1: 一次完整的事件选择

```
用户点击选项B
  → GameMain.vue emits choiceSelected('B')
    → eventCardStore.selectChoice('B')
      → EventCardSystem.selectChoice('B')
        → ChoiceResolutionEngine.resolveChoice(card, 'B')
          → ResourceManager.applyEffects(choice.effects)
            → resourceStore 响应式更新 (via event listener)
              → ResourceBar.vue 自动重渲染 + 动画
          → SaveService.saveRunState(updatedState)
        → return ResolveResult
      → eventCardStore.phase = 'RESOLVING'
        → GameMain.vue 显示结果动画 (watch phase)
      → (1s后) eventCardStore.nextCard() 或 dayEventsCompleted
```

### Flow 2: 一天结束

```
EventCardSystem: 队列清空, emit onDayEventsCompleted
  → DayCycleSystem.eventCompleted() (由 Store action 调用)
    → DayCycleSystem: state → DAY_END
      → ResourceManager.applyEffects([{target:'money', value:dailySalary}])
      → dayCycleStore 更新 → GameMain.vue 日期过渡动画
      → SaveService.saveRunState()
    → 0.5s后: DayCycleSystem.startDay(nextDay)
      或 emit onWeekCompleted → RunManager 接管结算
```

### Flow 3: 应用启动

```
App.onLaunch()
  → SaveService.hasActiveRun()?
    → YES: RunManager.resumeRun()
      → 从 SaveService 恢复所有 Service 状态
      → stores 初始化
      → uni.navigateTo('/pages/game/index')
    → NO: uni.navigateTo('/pages/job-select/index')
      → 用户选择职业
      → RunManager.startNewRun(jobId)
        → JobRotationSystem.selectJob(jobId)
        → EventDataEngine.loadJobEvents(jobId)
        → ResourceManager.init(withJobModifiers)
        → DayCycleSystem.startDay(1)
        → SaveService.saveRunState(newState)
        → uni.navigateTo('/pages/game/index')
```

### Flow 4: 死亡 → 续命 → 结算

```
ResourceManager emits onResourceDepleted('energy')
  → RunManager: phase → DYING
    → runStore 更新 → GameMain.vue 显示死亡遮罩
    → 用户点击"看广告续命"
      → AdAdapter.showRewardedAd('revive')
        → 成功: ResourceManager.applyEffects([{target:'energy', value:50, percent:true}])
                RunManager: phase → PLAYING
        → 失败/拒绝: RunManager: phase → SETTLING
          → 计算 RunResult
          → SaveService.clearRunState()
          → JobRotationSystem.checkUnlocks(result)
          → SaveService.saveProfile(updatedProfile)
          → uni.navigateTo('/pages/settlement/index')
```

### Initialization Order

1. **Platform adapters** (StorageAdapter, AdAdapter)
2. **SaveService** (reads storage, determines initial state)
3. **All Service modules** (created but not initialized)
4. **Pinia stores** (created, subscribe to service events)
5. **Router decision** (hasActiveRun → game page / no run → job select)
6. **Service initialization** (RunManager.resumeRun or wait for user)

---

## API Boundaries

```typescript
// ===== PLATFORM LAYER =====

interface StorageAdapter {
  get<T>(key: string): T | null
  set<T>(key: string, value: T): void
  remove(key: string): void
}

interface AdAdapter {
  showRewardedAd(type: 'revive' | 'double' | 'unlock'): Promise<boolean>
  isAdReady(): boolean
}

interface ShareAdapter {
  shareResult(runResult: RunResult): Promise<boolean>
}

// ===== DATA LAYER =====

interface SaveService {
  loadProfile(): Profile
  saveProfile(data: Profile): void
  loadRunState(): RunState | null
  saveRunState(data: RunState): void
  clearRunState(): void
  hasActiveRun(): boolean
  getDataVersion(): number
}

interface EventLoader {
  loadJobEvents(jobId: string): Promise<EventCard[]>
  loadCommonEvents(): Promise<EventCard[]>
}

interface JobConfigLoader {
  loadAllJobs(): JobConfig[]
  loadJobById(jobId: string): JobConfig | null
}

// ===== SERVICE LAYER =====

interface EventDataEngine {
  loadJobEvents(jobId: string): Promise<void>
  drawEvent(context: DrawContext): EventCard
  getEventsPerDay(day: number): number
  getPoolSize(): number
  unload(): void
}

interface ResourceManager {
  init(saved?: Resources): void
  getResources(): Resources
  getState(): 'NORMAL' | 'WARNING' | 'CRISIS' | 'DEAD'
  applyEffects(effects: ResourceEffect[]): ApplyResult
  onResourceChanged: EventEmitter<ResourceChangeEvent>
  onStateChanged: EventEmitter<StateChangeEvent>
  onResourceDepleted: EventEmitter<'energy' | 'mood'>
}

interface DayCycleSystem {
  startDay(dayNumber: number): void
  getCurrentDay(): DayState
  getRemainingEvents(): number
  eventCompleted(): void
  onDayStarted: EventEmitter<DayStartEvent>
  onDayEnded: EventEmitter<DayEndEvent>
  onWeekCompleted: EventEmitter<void>
}

interface JobRotationSystem {
  getAvailableJobs(): JobConfig[]
  getLockedJobs(): LockedJobInfo[]
  getRecommendedJobs(count: number): JobConfig[]
  selectJob(jobId: string): JobConfig
  checkUnlocks(runResult: RunResult): UnlockEvent[]
  getJobStats(jobId: string): JobStats
  onJobUnlocked: EventEmitter<JobConfig>
}

interface EventCardSystem {
  prepareDay(dayNumber: number, eventsCount: number): void
  getCurrentCard(): CardDisplayState | null
  selectChoice(choiceKey: 'A' | 'B'): void
  getQueueStatus(): { total: number; completed: number; remaining: number }
  onCardShown: EventEmitter<EventCard>
  onChoiceMade: EventEmitter<{ card: EventCard; choice: 'A' | 'B' }>
  onDayEventsCompleted: EventEmitter<void>
}

interface ChoiceResolutionEngine {
  resolveChoice(card: EventCard, choiceKey: 'A' | 'B'): ResolveResult
}

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

// ===== STATE LAYER (Pinia Store interfaces) =====

// Stores wrap Service state as reactive refs and expose actions
// that delegate to the Service layer. They do NOT contain logic.
// Pattern:
//   const store = defineStore('resource', () => {
//     const resources = ref<Resources>(resourceManager.getResources())
//     resourceManager.onResourceChanged.on(e => { resources.value = e.after })
//     return { resources }
//   })
```

---

## Architecture Principles

1. **Service 层无 UI 依赖** — 所有游戏逻辑可独立于 Vue 组件运行和测试（Vitest 直接测试 Service）
2. **Store 是桥梁不是大脑** — Store 只做 Service→Vue 的响应式桥接，不含业务逻辑
3. **Platform 封装隔离平台差异** — 切换微信/抖音/支付宝只需替换 Adapter 实现，业务代码零改动
4. **数据驱动扩展** — 新增职业/事件只加 JSON 文件到 config/events/，不改代码逻辑
5. **单向数据流** — 用户操作 → Store action → Service 计算 → Store 状态更新 → View 渲染

---

## Required ADRs

### P0 — 必须在编码开始前决定

| # | ADR 标题 | 决策内容 | 影响范围 |
|---|---------|---------|---------|
| 1 | 事件通信机制 | EventEmitter 自实现 vs mitt vs Pinia action 直调 | Service 层所有模块间通信 |
| 2 | 分包策略 | 事件 JSON 按职业分包 vs 全量加载 vs 懒加载 | 主包<2MB 约束 |
| 3 | Store-Service 同步模式 | Service emit → Store listen vs Store 轮询 vs Service 直接写 Store | 数据一致性 + 存档时机 |

### P1 — 对应系统开发前决定

| # | ADR 标题 | 决策内容 | 影响范围 |
|---|---------|---------|---------|
| 4 | 广告 SDK 封装 | 各平台广告 API 差异处理 + 降级策略 | AdAdapter 实现 |
| 5 | 存档数据迁移 | 版本号管理 + 迁移函数链 + 回退策略 | SaveService |

### P2 — 可推迟到实现时决定

| # | ADR 标题 | 决策内容 | 影响范围 |
|---|---------|---------|---------|
| 6 | 动画方案 | CSS transition vs uni.createAnimation vs 第三方库 | Presentation 层 |
| 7 | 多平台条件编译策略 | #ifdef 粒度 + 平台差异处理文件组织 | 全局 |

---

## Project File Structure

```
src/
├── platform/              # PLATFORM 层
│   ├── storage-adapter.ts
│   ├── ad-adapter.ts
│   └── share-adapter.ts
├── data/                  # DATA 层
│   ├── save-service.ts
│   ├── event-loader.ts
│   └── job-config-loader.ts
├── services/              # SERVICE 层
│   ├── event-data-engine.ts
│   ├── resource-manager.ts
│   ├── day-cycle-system.ts
│   ├── job-rotation-system.ts
│   ├── event-card-system.ts
│   ├── choice-resolution-engine.ts
│   └── run-manager.ts
├── stores/                # STATE 层
│   ├── resource-store.ts
│   ├── event-card-store.ts
│   ├── day-cycle-store.ts
│   ├── run-store.ts
│   └── job-store.ts
├── pages/                 # PRESENTATION 层
│   ├── game/
│   │   └── index.vue      # 游戏主界面
│   ├── job-select/
│   │   └── index.vue      # 职业选择页
│   └── settlement/
│       └── index.vue      # 结算页
├── components/            # 共用 UI 组件
│   ├── ResourceBar.vue
│   ├── EventCard.vue
│   ├── ChoiceButton.vue
│   └── DayIndicator.vue
└── config/                # 静态配置 + 类型
    ├── constants.ts       # 所有 Tuning Knobs
    ├── types.ts           # 共享类型定义
    └── events/            # 事件 JSON 数据 (分包)
        ├── common-events.json
        ├── programmer-events.json
        └── intern-events.json
```

---

## Open Questions

1. **EventEmitter 实现选择** — 自己写一个最小 EventEmitter(<50行) 还是用 mitt 库？(ADR #1 决定)
2. **Store 初始化顺序** — Pinia store 在 app 级别创建还是按需创建？
3. **热更新机制** — 事件 JSON 是否支持远程更新（不发版添加新事件）？MVP 可能暂不需要。

---

# Current Architecture (Sprint 4-7+) — as of 2026-05-25

## 新增 ADRs

| # | 标题 | 简述 |
|---|---|---|
| **ADR-004** | 多周职业架构 | 1 run = N 周（N from JobConfig.weeksPerCareer），onCareerCompleted 替代 onWeekCompleted 触发 SETTLING |
| **ADR-005** | 4 层 Modifier Pipeline | raw → passive → equipment → status → resource |
| **ADR-006** | 多结局 First-Match Catalog | 10 endings，按声明顺序优先级，必有 fallback |
| **ADR-007** | Save Resume Day-Boundary Checkpoint | 每天结束 checkpoint，resume 跳到 next day |
| **ADR-008** | EventCondition Pipeline | JSON 驱动 12-type 谓词链 + 纯函数 evaluateCondition，作为 buildPool filter chain 末位 |
| **ADR-009** | Build Pipeline Subpackage Plugin | Vite plugin `copy-subpackage-data` 双 hook（configureServer + closeBundle）覆盖 dev:h5 + 4 build target |

## Services（13 个，原 7 个 → 现 13 个）

新增（Sprint 2-7）：
- **StatusSystem** (Sprint 2) — buff/debuff 槽 + applyToEffect modifier
- **PassiveSkillSystem** (Sprint 3) — 跨 run 永久 modifier
- **ProgressionSystem** (Sprint 3) — 跨 run stats 累加 + unlock 触发
- **CareerProgressionSystem** (Sprint 4) — career level + score + 升职
- **ItemSystem** (Sprint 4) — 道具购买/使用 + equipment modifier
- **EndingSystem** (Sprint 7 G-3) — 多结局 catalog + 持久化解锁
- **AchievementSystem** (Sprint 6 C-2) — 成就解锁

完整 Service 列表：
```
EventDataEngine / ResourceManager / DayCycleSystem / JobRotationSystem /
EventCardSystem / ChoiceResolutionEngine / RunManager
+ StatusSystem / PassiveSkillSystem / ProgressionSystem
+ CareerProgressionSystem / ItemSystem / EndingSystem / AchievementSystem
```

## Stores（11 个）

```
resourceStore / eventCardStore / dayCycleStore / runStore / jobStore /
saveStore / statusStore / choiceResolutionStore / progressionStore /
passiveSkillStore / itemStore / careerStore / endingStore / achievementStore
```

## Resources（3 → 4 个）

`Resources = { energy, mood, money, health }`
- health 在 Sprint 7 G-2 引入
- CRISIS 状态每日 -5 health
- health=0 → 过劳死 ending（不可 revive）

## Job Catalog（5 → 8 职业）

intern / programmer / sales / designer / runner +
**researcher / slacker / fortune**（Sprint 6 D-1）

每职业有 `weeksPerCareer`、`careerTitles[4]`、`salaryMul`、`unlockCondition`。

## Event Catalog（4 → 9 files）

```
common-events.json (72)
+ intern-events (35) / programmer-events (89) / sales-events (35) /
  designer-events (31) / runner-events (30) /
  researcher-events (21) / slacker-events (21) / fortune-events (20)
```

总 **382 events**（2026-05-25 M-续 后；含 M-2 8 个 common-条件事件 + M-续 19 个 job-specific 条件事件）。

事件 gating 由 ADR-008 EventCondition pipeline 控制：JSON 加 `conditions?: EventCondition[]`，
buildPool filter chain 末位评估，AND 满足才入池。12 个 type cover resource / day / weekday /
career-level / has-item / has-equipment / status-active / event-seen 等场景。

## Item Catalog（0 → 50 items）

`src/static/items.json` — 6 通用消耗品 + 8 职业各 ~5 个 + 2 equipment + 2 housing。

## Pages（1 → 5 pages）

- `pages/job-select` — Sprint 3 入口
- `pages/index` — game-main（runtime）
- `pages/settle` — 结算 + ending
- `subpackages/ui/menu` — 图鉴（含结局 X/N 收集）
- `subpackages/ui/shop` — 商店

## Modifier Pipeline（ADR-005）

```
choice.effect.value
  → PassiveSkillSystem.applyToEffect    (永久跨 run)
  → ItemSystem.applyToEffect            (per-run 装备)
  → StatusSystem.applyToEffect          (per-run buff/debuff)
  → ResourceManager.applyEffects        (clamp + state machine)
```

## Bundle 现状（mp-alipay 是关键约束）

**测量日期**: 2026-05-21（K-1 + K-2 优化后）

| Platform | Main | Subpackages | Total | vs 500KB AC | vs 2MB hard |
|---|---|---|---|---|---|
| h5 | 336KB | 224KB | 560KB | — | — |
| mp-weixin | 520KB | 256KB | 776KB | +4% | 26% |
| mp-toutiao | 524KB | 256KB | 780KB | +5% | 26% |
| mp-alipay | 612KB | 260KB | 872KB | +22% | 30% |

**K-1 优化（2026-05-21）**: `common-events.json`(41KB) main → subpackages
- 同时修复 build pipeline：之前 src/subpackages/*.json 不会被复制到 dist（dev mode vite serve 兜底跑通，但 build 后 job events 全部丢失，靠 FALLBACK_EVENTS 兜底未被发现）
- 新增 vite plugin `copy-subpackage-data` 自动复制 src/subpackages/**/*.json
- 主包减 ~44KB 平均，所有 9 个 event JSONs 正确出现在 dist

**K-2 优化（2026-05-21）**: `items.json`(15KB) 去重
- items.json 之前在 main 出现两次：`static/items.json`(raw 16KB) + `config/items.js`(编译时 inline 12KB)
- 移出 `src/static/` 到 `src/config/`，uni-app 不再自动 copy，items.ts 的 static import 不变
- 主包减 16KB

**Main bundle 拆解**（mp-alipay 612KB）：
- common/vendor.js — 144KB (Vue 3 + uni runtime 硬底)
- components/ — 192KB (16 个 Vue 组件 × 4 个平台文件，文件系统 block 占用)
- services/ — 80KB
- pages/ — 68KB
- stores/ — 56KB
- 其他 (types/config/utils/composables) — 76KB

**剩余 over-budget**: mp-alipay 还超 AC 112KB。结构性瓶颈：
- vendor.js (Vue runtime) 是硬底，无法压缩
- components 文件系统 block padding 是平台特性
- 进一步优化需重构（async items API / 拆 settle 到 subpackage / 评估 prebuilt Vue 选项），ROI 边际递减

## Test 现状

**621 tests across 32+ files**（2026-05-25）。
100% coverage on services: career-progression / item / ending / achievement / passive-skill / status / resource / progression / event-condition-evaluator.

## Build Pipeline 修复（2026-05-25, commit b1c1021）

`vite.config.ts` 中的 `copy-subpackage-data` plugin 之前**遗漏了 `configureServer` hook**——
仅 `closeBundle` 在 production build 时 copy JSON 到 dist，但 dev:h5 模式下 vite dev server
不知道 src/subpackages/ 的存在，浏览器 fetch `/subpackages/events/*.json` 全部 404，
uni-event-loader fallback 到 5 个硬编码 events → bug 症状 "每天都是相同 5 个事件"。

修复加入 middleware hook：拦截 `/subpackages/**/*.json` 请求，从 src/ 实时读取并返回。
现在 dev:h5 实测可拉取完整 9 个职业 JSON / 382 events。详见 ADR-009。

## 设计文档与代码同步状态（2026-05-25 audit）

| Layer | Status |
|-------|--------|
| **GDD coverage** | 16/21 systems designed（含 6 个 Sprint 4-7 retrofit） |
| **Service-level GDD** | passive-skill / progression / career-progression / item / ending / achievement 全部补齐 |
| **event-data-engine.md** | 加 `conditions?` 字段 + EventCondition 谓词章节 |
| **ADR coverage** | 9 条（ADR-001 ~ ADR-009），ADR-008 EventCondition / ADR-009 Build Pipeline 为 retrofit |
| **未补 GDD** | 广告激励 / 分享 / 职业选择页 / 结算页 / 主菜单图鉴 — Beta+ tier，待实现时补 |
