# Sprint 3 — 2026-06-15 to 2026-06-28 (2 weeks)

## Sprint Goal

进入 Alpha 阶段：实现完整 Alpha gameplay loop（job-select → play → settle → progress → re-select），让玩家能多次循环游玩、解锁新职业、积累跨局进度。

## Capacity

- Total days: 10
- Buffer (20%): 2 days
- Available: 8 days

## Context

- **Sprint 2 完成 ✓**：8/8 must-have，279 tests，3 平台 build 全过
- **MVP 闭环就位**：单职业（programmer）完整可玩
- **数据基线完备**：163 events（30 common + 82 programmer + 25 intern + 25 sales），3 个职业元数据已配置
- **Alpha 范围**：3 jobs × 20+ events ✓ + 职业解锁 ✓ + 广告（→ Sprint 4 延后，因平台 SDK 未设置）
- **设计模式**：Alpha 系统采用 **lite design embedded in story**（每个故事文件含 quick-spec 段），跳过完整 GDD 周期以保证 sprint 不被设计消耗

## Tasks

### Must Have (Critical Path — 完整 Alpha gameplay loop)

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|--------------|---------------------|
| S3-1 | 永久进度系统 service + store（跨局经验值 + 解锁触发）| gameplay-programmer | 1.5 | S1-3 | ProgressionSystem 累计 stats 到 SaveData.stats（已有 GlobalStats 字段）；endRun 时根据 RunResult 更新 totalRuns/Wins/Deaths/Money/jobsPlayed；调用 jobRotationSystem.checkUnlocks → emit onJobUnlocked；100% 行覆盖 |
| S3-2 | 职业选择页（5 职业卡 + 推荐高亮 + 解锁条件展示）| ui-programmer | 1.5 | S1-10, S3-1 | `pages/job-select/index.vue` 新页面 + JobCard.vue 子组件；调 jobStore.getRecommendations(2) 高亮显示；锁定职业灰显示 unlockCondition 文案；tap 一个职业 → runManager.selectJob → uni.navigateTo 到 game-main |
| S3-3 | 完整结算页面（替换 S2-5 占位 overlay）| ui-programmer | 1.5 | S2-4, S3-1 | `pages/settle/index.vue`：rating 大字 + RunResult 全部 stats + 解锁通知 toast（如有）+ "再来一局"/"换份工" 双按钮；进入时触发 progressionSystem.recordRun；从 game-main 移除 overlay 代码；GameOver/Win 状态进入此页 |
| S3-4 | 应用启动流程 + 多页面导航 | ui-programmer | 1.0 | S3-2, S3-3 | pages.json 添加 job-select + settle 路由；App.vue 启动直接进 job-select；useGameSession 拆为 useJobSelectSession + useGameMainSession；onUnload 处理 store 持久化；e2e: 选职业 → 玩 → 死/赢 → settle → 回 job-select |
| S3-5 | Sprint 3 收尾 smoke check | qa-tester | 0.5 | S3-1..S3-4 | full test suite + 3 平台 build；e2e flow（多次 run + 解锁）；report 写入 `production/qa/smoke-sprint-3-[date].md` |

**Must Have 合计：6.0 days**

### Should Have (Sprint 2 polish carryover)

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|--------------|---------------------|
| S3-6 | S2-9 Risk dice 全屏动画 | ui-programmer | 0.5 | S2-3, S2-5 | `RiskDiceOverlay.vue` 1s 旋转 + success/fail 大字结果，对齐 prototype v3；触发时机 ChoiceResolutionEngine.lastRiskRoll |
| S3-7 | S2-10 教学气泡 + chip pulse | ui-programmer | 0.5 | S2-1, S2-5, S2-7 | 玩家首次拿 status → 1.5s 气泡（profile.firstStatusShown 持久化）；status 修正时 chip pulse；profile 跨局保留验证 |
| S3-8 | 视觉 polish round（粒子/音效/转场）| ui-programmer | 0.5 | S2-5 | 资源变化浮字 + 选择按下音效（uni.createInnerAudioContext）+ 日切换转场 polish；非 load-bearing |

**Should Have 合计：1.5 days**

### Nice to Have

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|--------------|---------------------|
| S3-9 | 被动技能系统 stub | gameplay-programmer | 1.0 | S1-5, S3-1 | PassiveSkillSystem 占位类 + 1 个示例技能"厚脸皮 Lv1"（mood 损失 ×0.8 modifier 注入 ChoiceResolutionEngine 上游）；为 Sprint 4 完整版做准备 |
| S3-10 | 主菜单 / 图鉴占位页 | ui-programmer | 0.5 | S3-2 | `pages/menu/index.vue` 显示已解锁职业 + 全局 stats（totalRuns/totalWins）；从 job-select 入口可达 |

**Nice to Have 合计：1.5 days**

---

**总计**：6.0 (must) + 1.5 (should) + 1.5 (nice) = **9.0 days** ✅ 在 8 available + 2 buffer 内

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| Sprint 2 manual three-platform smoke | 用户未设置 WeChat 开发工具 | 含在 S3-5（用户搭好后一次性验证 Sprint 2+3）|
| S2-9 risk dice → S3-6 | Sprint 2 should，重新分布 | 0.5 |
| S2-10 onboarding tip → S3-7 | Sprint 2 should，重新分布 | 0.5 |
| S2-11 settle screen polish | 内容并入 S3-3 完整结算页面 | 含在 S3-3 |

## Risks

| Risk | P | I | Mitigation |
|------|---|---|-----------|
| **Alpha 系统无 GDD 直接编码可能埋坑** | M | M | 每个 must-have story 内嵌 quick-spec section（lite design），沿用 Sprint 2 模式 |
| **uni-app 多页面导航与 Pinia store 持久化交互** | M | M | S3-4 显式测试页面切换 store 不丢；onUnload 触发 saveStore.save |
| **结算页面替换 S2-5 占位 overlay 引入 regression** | L | M | S3-3 完成后跑 full e2e；保留 overlay 代码（feature flag）直到 S3-3 验证 |
| **Sprint 3 含 lite design + 实现，估算偏紧** | M | M | nice-to-have 可降级；S3-9 / S3-10 不阻塞 Alpha 主目标 |
| **被动技能系统（S3-9）需改 ChoiceResolutionEngine pipeline** | L | M | nice-to-have；如冲突直接 defer 到 Sprint 4 |
| **多页面 navigateTo 在小程序与浏览器预览行为差异** | M | L | 优先在浏览器跑；微信工具实测时 S3-5 会暴露问题 |

## Dependencies on External Factors

- 微信小程序 AppID — 仍未需要（Sprint 4 才接广告 SDK）
- 美术资源 — 无新增需求；继续 emoji + CSS
- art-bible 视觉规范 — 延后；S3-2/3 视觉对齐 prototype v2-v3
- 音频资源（S3-8 需要）— 用免费短音效，或留 hook 到 Sprint 4 接入

## Out of Scope (Sprint 4+ 候选)

- **广告激励系统**（需要平台 SDK + AppID 设置完成）
- **完整成就系统**（依赖永久进度，S3 nice-to-have S3-10 是基础占位）
- **被动技能完整系统**（S3-9 是 stub，完整版 Sprint 4）
- **多职业事件包扩充**（designer/runner 暂未有 events JSON）
- **多端真机 + 性能 profile**（Polish 阶段）
- **复杂分享功能**（Beta 阶段）

## Definition of Done for this Sprint

- [ ] 5/5 Must Have 任务完成
- [ ] QA plan exists (`production/qa/qa-plan-sprint-3.md`)
- [ ] 全部 Logic 故事 100% 行覆盖（service 层）
- [ ] Smoke check 通过（S3-5）
- [ ] 没有 S1/S2 级 bug
- [ ] systems-index.md 更新永久进度（4）/ 职业选择页（15）/ 结算页面（16）状态为 Implemented
- [ ] 玩家能完成 e2e：选职业 → 完成 5 天 → 结算 → 解锁新职业（如条件满足）→ 重新选职业（含新解锁）
- [ ] 任何架构偏离已记录到 ADR 或 story Completion Notes
- [ ] 代码 review 通过（lean 模式可自审）

## Producer Feasibility Gate

> **PR-SPRINT skipped — Lean mode.** 单人开发场景，sprint 大小符合 Sprint 1-2 已验证容量。
> 如需正式评审：`/sprint-plan new --review full`。

## Scope Check

> Sprint 3 的 must-have 完全在 systems-index Alpha 优先级范围内。
> nice-to-have S3-9 是 Alpha 范围；S3-10 是 Beta 占位（可降到 nice 接受）。
> 实施开始前可运行 `/scope-check epic-alpha` 二次检查。
