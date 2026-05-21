# Sprint 2 — 2026-06-01 to 2026-06-14 (2 weeks)

## Sprint Goal

完成 Feature + Presentation 层（剩余 5 个 MVP 系统 + status-system v2.1 + 替换占位首页），让游戏首次具备完整可玩闭环：选择 → 资源变化 → 状态效果 → 日循环 → 死亡/胜利。

## Capacity

- Total days: 10
- Buffer (20%): 2 days
- Available: 8 days

## Context

- **Sprint 1 完成**：Foundation + Core 全部 service 完成，81/81 单元测试通过，type-check + build:mp-weixin 通过（164KB）
- **10/10 MVP GDDs 完成**（含 status-system v2.1 已通过设计评审）
- **3 ADRs 已锁定**：ADR-001 TypedEventEmitter / ADR-002 分包策略 / ADR-003 Service emit → Store subscribe
- **架构未变**：所有 Sprint 2 实现严格遵循 ADR-001/002/003

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S2-1 | 状态效果系统 service + store | gameplay-programmer | 1.0 | S1-2, S1-3, S1-9 | StatusSystem 实现 status-system.md v2.1 接口；slot-based（1 buff + 1 debuff 槽）；signFloor 修正；订阅 RunManager.onPhaseChanged 模式；100% 单元测试覆盖（addStatus 替换/刷新/strongest-wins/signFloor/tickStatuses 倒数/loadSnapshot 损坏过滤/clearAll/DYING 不清空）|
| S2-2 | 事件卡系统 service + store | gameplay-programmer | 1.5 | S1-2, S1-4, S1-9 | EventCardSystem 实现 event-card.md 接口；卡片状态机 6 阶段（ENTERING/READING/CHOOSING/RESOLVING/FOLLOW_UP/EXITING）；队列管理；followUp 链 ≤3 层；emit onCardShown/onChoiceMade/onDayEventsCompleted；100% 单元测试 |
| S2-3 | 选择结算引擎 service | gameplay-programmer | 1.0 | S1-2, S1-5, S2-1, S2-2 | ChoiceResolutionEngine 实现 choice-resolution.md 接口 + status 集成：选项 effects 先经 statusSystem.applyToEffect 修正 → resourceManager.applyEffects；risk 选项掷骰逻辑；ResolveResult 含 wasStatusModified；buff 字段触发 addStatus（**在** effect 应用之后）；100% 单元测试 |
| S2-4 | 局管理器 service + store | gameplay-programmer | 1.5 | S1-2, S1-3, S1-5, S1-9, S1-10, S2-1 | RunManager 实现 run-manager.md 接口；RunPhase 6 态状态机（JOB_SELECT/INITIALIZING/PLAYING/DYING/SETTLING/ENDED）；onResourceDepleted 触发 DYING；续命/拒绝/通关流程；ENDED 时通过 onPhaseChanged 通知 status 清空；100% 单元测试 |
| S2-5 | 游戏主界面 + 子组件 | ui-programmer | 2.5 | S1-6, S2-1, S2-2, S2-3, S2-4 | 替换占位首页：实现 EventCard.vue / ChoiceButton.vue / StatusChip.vue / DayBadge.vue / GameMain.vue；视觉品质对齐原型 v2（渐变/发光/状态化头像/舞台幕布/chip pulse）；触控热区 ≥44px；status chip 透明 padding 解触控；可访问性（色盲 buff/debuff 形状区分）|
| S2-6 | 事件 schema lint at build time | devops-engineer | 0.5 | S1-1, S1-4 | vite plugin 或 npm prebuild hook：扫描所有 events JSON，校验 schema 合法 + buff/debuff mul 方向 + days 范围；坏数据阻塞 build；输出友好报错位置 |
| S2-7 | Profile schema 扩展 + persistence | gameplay-programmer | 0.25 | S1-3 | `src/types/save.ts` ProfileData 添加 `firstStatusShown?: boolean` 可选字段；SaveService 不需改动（schema v1 兼容）；测试覆盖 load undefined → false |
| S2-8 | Sprint 2 收尾 smoke check | qa-tester | 0.5 | S2-1..S2-7 | 全链路联调：选择 → effect 修正 → 资源变化 → status 应用 → 日结算（顺序契约：salary → onDayEnded → tick）→ 下一天 → 死亡/胜利 → 局结束清空。至少微信开发者工具跑完整一局通关 |

**Must Have 合计：8.75 days** ✅ 在 8 available + 2 buffer 范围内

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S2-9 | Risk dice 动画 + 视觉反馈 | ui-programmer | 0.5 | S2-3, S2-5 | Risk choice 触发时全屏骰子动画 + 大字成功/翻车结果；对齐原型 v3 视觉 |
| S2-10 | 首次状态教学气泡 + chip pulse | ui-programmer | 0.5 | S2-1, S2-5 | 玩家首次拿 status 时 1.5s 教学气泡（profile.firstStatusShown 标志）；status 修正触发同帧 chip pulse |

**Should Have 合计：1.0 day**

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S2-11 | 简版结算页（GameOver / Win） | ui-programmer | 0.5 | S2-4, S2-5 | 死亡/通关后 overlay 显示天数/金钱/选择次数/评级；点击"再来一局"回到首页 |

**Nice to Have 合计：0.5 day**

---

**总计：8.75 (must) + 1.0 (should) + 0.5 (nice) = 10.25 days**

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| 微信开发者工具 smoke check（Sprint 1 占位首页）| 用户尚未搭好微信开发环境，已推迟到 Sprint 2 末尾合并验收 | 含在 S2-8 |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **状态系统集成复杂度被低估** | M | M | status v2.1 已通过 design review；S2-3 显式包含 status integration AC |
| **5 个 service 集成时事件订阅顺序错乱** | M | H | S2-8 整合 smoke 包含全链路联调；写完 S2-4 后立即跑一次端到端 |
| **UI 主界面工作量被低估**（5 组件 + 整合 + 视觉对齐 prototype） | H | M | S2-5 是最大块（2.5d），写之前先看 prototype/core-loop/index.html v3 复用 CSS |
| **schema lint vite plugin 配置时间超预期** | L | L | 如超时直接降级为 npm prebuild script（脚本级校验） |
| **微信开发者工具环境搭建延迟** | M | L | Sprint 2 大部分工作在浏览器端 vitest + happy-dom 即可；最后联调阶段才需要工具 |
| **状态修正集成可能影响 Sprint 1 ResourceManager 测试** | L | H | 不改 ResourceManager（架构决策——modifier 在 ChoiceResolutionEngine 上游应用）；S2-3 实现时复跑 Sprint 1 全部测试 |
| **followUp 链与 RunPhase 状态机的边界条件** | L | M | event-card.md 已定义 ≤3 层 + S2-2 AC 覆盖；S2-4 测试覆盖 followUp 期间死亡的转移路径 |

## Dependencies on External Factors

- 微信小程序 AppID（S2-8 三端联调时需要测试号；可用通用测试号）
- art-bible 视觉规范（未启动）— S2-5 视觉对齐 prototype v2 即可，正式 art-bible 不阻塞 Sprint 2

## Out of Scope (Sprint 3+ 候选)

- 职业选择页（S2 用 hardcoded programmer 启动新局）
- 完整结算页（S2-11 是 nice-to-have 简版）
- 三端联调全覆盖（Sprint 3 真机测试）
- 性能优化 / 真机 profile（Polish 阶段）
- 永久进度系统 / 成就 / 广告（Alpha 阶段）

## Definition of Done for this Sprint

- [ ] 所有 Must Have 任务完成
- [ ] 所有任务通过 Acceptance Criteria
- [ ] QA plan 存在（`production/qa/qa-plan-sprint-2.md`）
- [ ] 全部 Logic 故事单元测试 100% 行覆盖（service 层）
- [ ] 全链路 smoke check 通过（`/smoke-check sprint`）
- [ ] 没有 S1/S2 级 bug
- [ ] 任何架构偏离已写入 ADR
- [ ] 玩家能在浏览器（vitest happy-dom 或本地 dev）跑通完整一局：选职业 → 5 天 → 死亡或通关
- [ ] 状态系统 chip 在主界面正确显示 + 修正触发 pulse
- [ ] 代码 review 通过并合并到 main 分支

## Producer Feasibility Gate

> **PR-SPRINT skipped — Lean mode.**
> 单人开发 + 已通过 prototype 验证机制可行性。
> 如需正式 producer 评审：`/sprint-plan new --review full`。

## Scope Check

> 本 Sprint 的所有故事均映射到 systems-index 的 MVP 范围。状态效果系统（S2-1）原本不在 9 个 GDD 中，已通过 v2.1 GDD 评审 + systems-index 更新合法化为 MVP（编号 18）。
> 实施开始前可运行 `/scope-check epic-feature` 二次检查。

---

**QA Plan**: `production/qa/qa-plan-sprint-2.md` ✓（2026-05-19 创建）
