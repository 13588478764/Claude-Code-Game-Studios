# Sprint 1 — 2026-05-18 to 2026-05-31 (2 weeks)

## Sprint Goal

完成 Foundation + Core 层（5 个 MVP 系统）：让项目跑起来，资源管理和事件数据引擎可独立测试，为后续 Feature 层（事件卡、结算引擎、局管理器）打地基。

## Capacity

- Total days: 10（10 个工作日）
- Buffer (20%): 2 days（预留给意外问题、调试小程序工具链兼容）
- Available: 8 days

## Context

- **Prototype 验证完毕**：核心循环 PROCEED，4 个机制层全部 work（见 `prototypes/core-loop/REPORT.md`）
- **9/9 MVP GDDs 已完成**（见 `design/gdd/systems-index.md`）
- **3 个 ADR 已签署**：001 事件通信 / 002 分包策略 / 003 Store-Service 同步
- **Master Architecture 已完成**：5 层架构（Presentation → State → Service → Data → Platform）
- **此为正式开发起点**：Prototype 代码完全丢弃，按架构从零重写

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S1-1 | 项目脚手架搭建 | devops-engineer | 1.0 | — | uni-app + Vue 3 + TypeScript strict + Pinia + Vitest 全部跑通；`npm run dev:mp-weixin` 能在微信开发者工具运行；`npm test` 能跑测试 |
| S1-2 | TypedEventEmitter 实现 | gameplay-programmer | 0.5 | S1-1 | `src/services/common/event-emitter.ts` 实现 ADR-001 接口；100% 单元测试覆盖 on/off/emit/once/clear |
| S1-3 | 存档系统 service + store | gameplay-programmer | 1.0 | S1-1, S1-2 | `SaveService` 实现 GDD 接口；封装 `uni.setStorageSync/getStorageSync`；schema 版本化；100% 单元测试覆盖 save/load/migrate/clear |
| S1-4 | 事件数据引擎（加载器 + 解析器 + 缓存） | gameplay-programmer | 1.0 | S1-1, S1-2 | `EventDataEngine` 实现 GDD 接口；JSON loader 支持主包 common-events.json；schema 校验；3 次重试 + 5 个备用事件兜底；100% 单元测试覆盖 |
| S1-5 | 资源管理系统 service + store | gameplay-programmer | 1.0 | S1-2, S1-3 | `ResourceManager` 实现 GDD 接口；energy/mood/money 三资源；状态机（NORMAL/WARNING/CRISIS/DEAD）；emit `onResourceChanged`/`onStateChanged`/`onResourceDepleted`；100% 单元测试覆盖 applyEffects 边界值 |
| S1-6 | 资源条 UI 组件（ResourceBar.vue） | ui-programmer | 0.5 | S1-5 | 单组件接收 `value`/`max`/`color`/`label`，使用 storeToRefs 订阅资源变化；颜色按阈值自动切换（绿/黄/红）；过渡动画 600ms |
| S1-7 | 占位首页（联调用） | ui-programmer | 0.5 | S1-1, S1-5, S1-6 | `pages/index/index.vue` 显示三条资源条 + 一个测试按钮（applyEffects 模拟）；用于验证 Service → Store → Vue 的响应式链路 |
| S1-8 | Sprint 1 收尾测试 + smoke check | qa-tester | 0.5 | S1-2..S1-7 | Vitest 覆盖率核心逻辑 100%；smoke test 覆盖：app 启动、资源初始化、应用一组 effects 后资源/UI 同步、刷新后存档恢复 |

**Must Have 合计：6.0 days**

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S1-9 | 日周期系统 service | gameplay-programmer | 1.0 | S1-2, S1-4 | `DayCycleSystem` 实现 GDD 接口；管理 5 天循环；emit `onDayStarted`/`onDayEnded`/`onWeekCompleted`；100% 单元测试 |
| S1-10 | 职业轮回系统 service | gameplay-programmer | 1.0 | S1-2, S1-3 | `JobRotationSystem` 实现 GDD 接口；初始解锁 intern + programmer；推荐算法（最近玩 ×0.1、新职业 ×5.0）；100% 单元测试 |

**Should Have 合计：2.0 days**

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S1-11 | 占位事件配置 (common-events.json) | systems-designer | 0.5 | — | 10 个通用事件作为联调材料（不是正式内容），供 Sprint 2 调用 |

**Nice to Have 合计：0.5 days**

---

**总计**：6.0 (must) + 2.0 (should) + 0.5 (nice) = 8.5 days，在 8 days available + 2 days buffer 范围内。

## Carryover from Previous Sprint

无 — 这是首个开发 Sprint。Pre-production 阶段产出（GDDs / ADRs / Architecture / Prototype）已全部完成。

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 微信开发者工具与 uni-app 编译兼容性问题 | M | M | 项目脚手架阶段（S1-1）就在三端模拟器跑 hello world，提前暴露问题 |
| Pinia + uni.setStorageSync 持久化时序问题 | L | M | 存档系统（S1-3）专门写时序测试：service emit → save 顺序保证 |
| TypedEventEmitter 在小程序环境不能正确清理引用导致内存泄漏 | L | H | App 级 emitter 在小程序生命周期内不销毁；如需页面级，明确文档 unsubscribe 模式 |
| 估算不准（首次为该项目估时） | M | M | 留 2 天 buffer；Should Have 任务可按需降级到 Sprint 2 |

## Dependencies on External Factors

- 微信小程序 AppID（开发期可用测试号）
- 抖音/支付宝小程序 AppID（Sprint 1 不需要，Sprint 2-3 才用）
- HBuilderX 或 CLI 模式（任选，Sprint 1 用 CLI 即可）

## Definition of Done for this Sprint

- [ ] 所有 Must Have 任务完成
- [ ] 所有任务通过 Acceptance Criteria
- [ ] QA plan 存在 (`production/qa/qa-plan-sprint-1.md`)
- [ ] 所有 Logic 类故事有可通过的 Vitest 单元测试（核心 service 100% 覆盖率）
- [ ] Smoke check 通过 (`/smoke-check sprint`)
- [ ] QA sign-off：APPROVED 或 APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] 没有 S1/S2 级 bug 存留
- [ ] 任何架构偏离都更新到对应 ADR
- [ ] 代码 review 通过并合并到 main 分支
- [ ] 占位首页能在微信开发者工具中运行，资源条响应式更新

## Out of Scope (Sprint 2 候选)

以下系统在 Sprint 2 实施（Feature → Presentation 层）：
- 事件卡系统（依赖 S1-4 + S1-9 + S1-10）
- 选择结算引擎（依赖 S1-5 + 事件卡）
- 局管理器（依赖 S1-9 + S1-5 + S1-10）
- 游戏主界面（依赖事件卡 + 资源管理 + 结算引擎）
- **新增**：Buff/Debuff 状态系统 GDD（原型验证发现的新需求，未在 9 个 MVP GDD 中）

## Producer Feasibility Gate

> **PR-SPRINT skipped — Lean mode.**
> 单人开发场景，可由开发者自行评估。
> 如需正式 producer 评审，运行 `--review full`。

## Scope Check

> 本 Sprint 严格遵循 systems-index.md 的 MVP 范围 + 推荐设计顺序。
> 如后续添加超出 9 个 MVP 系统的故事，运行 `/scope-check epic-foundation` 检测范围蔓延。

---

> ⚠️ **No QA Plan**: 本 Sprint 启动时尚未创建 QA plan。请在第一个 Must Have 故事开始实现前运行 `/qa-plan sprint`。Production → Polish gate 需要 QA sign-off 报告，而 sign-off 报告依赖 QA plan。
