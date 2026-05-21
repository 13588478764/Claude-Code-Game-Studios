# Sprint 4 — 2026-05-20 to 2026-06-02 (2 weeks)

## Sprint Goal

让游戏从"一周一局"扩到"4 周一职业生涯" + 引入**升职机制** + 让**金钱真正可花**（基础商店 / 消耗品）。
解决用户首次手测反馈的三个核心问题（重复事件 ✓ 已修 / 金钱负数 ✓ 已修 / 金钱无用 ← 本 sprint）。
为 Sprint 5 装备 + 房屋系统打地基。

## Capacity

- Total days: 10
- Buffer (20%): 2 days
- Available: 8 days

## Context

- **Sprint 3 完成 ✓**：10/10 stories（5 must + 3 should + 2 nice），394 tests，3 平台 build，Alpha gameplay loop + polish + passive stub + menu page
- **首次手测反馈** (2026-05-19)：用户跑通 H5 后报告 3 个游戏感问题
  - ✅ 重复事件 → S3-Hotfix RECENT_BUFFER_SIZE 5→12
  - ✅ 金钱负数 → S3-Hotfix DAY_SALARIES 70 → 175 total
  - ⏸ 金钱无用 → Sprint 4 本期解决（商店 + 消耗品）
- **设计大幅扩展** (2026-05-20)：用户给了完整产品愿景（升职/家族传承/多结局/房屋/月报 etc.），已映射到 Sprint 4-7
- **架构决策锁定**（5 项）：
  1. 职业长度统一 4 周
  2. 升职机制纯数值 careerScore
  3. health 作为第 4 资源（Sprint 6 实装）
  4. 代际传承：财富 + 天赋都传（Sprint 7 实装）
  5. 道具数据放主包共享 src/static/items.json
- **本期范围**：升职打分骨架 + 道具/商店 MVP（消耗品）。装备/房屋/multi-tier UI 留 Sprint 5。

## Tasks

### Must Have (Critical Path — 升职 + 经济闭环)

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|--------------|---------------------|
| S4-1 | 多周职业 — DayCycle + JobConfig 扩展 | gameplay-programmer | 1.0 | S3-1 | `WEEKS_PER_CAREER` 从 JobConfig 读（默认 4）；DayCycleSystem 引入 weekIndex；新 emitter onCareerCompleted；RunManager 监听该新 emitter 触发 SETTLING；DayBadge 显示"第 N 周 周X"；现有 day-cycle 测试更新 |
| S4-2 | CareerProgressionSystem — 升职打分骨架 | gameplay-programmer | 1.5 | S4-1 | 新 service `CareerProgressionSystem`；周末累计 careerScore（金钱 + 平均能量 + 平均心情 + 选择多样性的加权和）；阈值 100/250/500 触发升职 → emit onPromoted；careerLevel + careerScore 持久化进 SaveData.currentRun；后续工资 ×(1 + careerLevel×0.5)；100% 行覆盖 |
| S4-3 | 周末 review 事件机制 | gameplay-programmer | 0.5 | S4-2 | events.json 加 `weekend-review` tag；EventCardSystem 在 weekIndex 最后一天最后一个事件位强制抽该 tag；编 3 个 review 示例事件（拼一把 +careerScore / 平稳 / 摆烂 -careerScore）；EventDataEngine 加强制 tag 优先级 |
| S4-4 | ItemSystem service + 库存 | gameplay-programmer | 1.0 | S4-1 | 新 service `ItemSystem`：buyItem(id) / useItem(id) / getInventory()；消耗品 useItem 立即 apply effects 到 ResourceManager；扣钱通过 ResourceManager.applyEffects；装备/housing 留 slot stub；SaveData.currentRun.inventory[] 持久化；100% 行覆盖 |
| S4-5 | Shop page + game-main 入口 | ui-programmer | 1.0 | S4-4, S4-6 | `pages/shop/index.vue` 新页面 + pages.json 路由；按 category 分 tab；卡片显示 icon/name/cost/effects；当前 money < cost → 灰显 + 提示；购买 → ItemSystem.buyItem；game-main 加 🛒 入口（与 📖 图鉴并列） |
| S4-6 | items.json 初始道具表 | systems-designer | 0.5 | S4-4 | `src/static/items.json` 编 12-15 个道具：5-6 通用消耗品 + 3-4 程序员专属 + 2-3 实习生专属 + 1-2 销售专属；含 cost / effects / icon / category / jobId / description；schema lint 加 item validator |
| S4-7 | Sprint 4 收尾 smoke check | qa-tester | 0.5 | S4-1..S4-6 | full test suite + 3 平台 build；mp-alipay 仍超 500KB 则把 shop + menu 移入 subpackages；report 写入 `production/qa/smoke-sprint-4-[date].md` |

**Must Have 合计：6.0 days**

### Should Have

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|--------------|---------------------|
| S4-8 | 升职通知 toast + 视觉反馈 | ui-programmer | 0.5 | S4-2 | onPromoted 时全屏 1.5s 升职 banner（🎉 升职 Lv N）；settle page rating 显示当前 careerLevel |
| S4-9 | "今日体力恢复"消耗品 | systems-designer + gameplay-programmer | 0.25 | S4-4 | 把"红牛"消耗品做成核心循环 — 体力低时强烈视觉提示玩家可购买 |

**Should Have 合计：0.75 days**

### Nice to Have

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|--------------|---------------------|
| S4-10 | salaryMul 实际生效（修旧 bug） | gameplay-programmer | 0.5 | S4-1 | DayCycleSystem 接收 jobConfig 注入；onDayEnded 输出 `salary × jobConfig.salaryMul`；销售 3.0x / 程序员 2.0x / 外卖 1.0x / 实习 0.5x 真实生效 |

**Nice to Have 合计：0.5 days**

---

**总计**：6.0 (must) + 0.75 (should) + 0.5 (nice) = **7.25 days** ✅ 在 8 available 内

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| 三端 manual smoke | 用户已在 H5 跑通；小程序 simulator 仍待 | 含在 S4-7 |
| 经济系统设计 | Sprint 3 仅诊断金钱无用，Sprint 4 给出解决方案 | 含在 S4-4/5/6 |

## Risks

| Risk | P | I | Mitigation |
|------|---|---|-----------|
| **20-day run 太长玩家中途流失** | M | H | S4-2 升职作为 "周末爽点"；H5 手测后可调 WEEKS_PER_CAREER 默认值（2-3 也可） |
| **CareerProgressionSystem 打分公式失衡** | M | M | 公式纯数值 + 配置化阈值；可在 systems-designer 推出 v1 后迭代 |
| **EventCardSystem 加强制 tag 优先级影响 S2-2 测试** | M | M | S4-3 改动局部；保留 fallback 行为；运行完整 sprint 2 测试集合 |
| **mp-alipay bundle 已 532KB，加 shop + items 大概率超 600KB** | H | M | S4-7 准备 subpackage 重构（menu + shop 都进 subpackage）；预计可拉回 <500KB |
| **库存 state 序列化进 SaveData 引入 schema 变更** | L | M | schema v1 保留 inventory? optional；存量存档无 inventory 字段视为空 |
| **设计扩展过大 — 用户后续可能再加更多** | M | L | Sprint 4 严格只做"升职+消耗品"；装备/房屋/健康/传承都写入 Sprint 5-7 roadmap |

## Dependencies on External Factors

- 微信小程序 AppID — 仍未需要（广告 SDK 进 Sprint 8+）
- 美术资源 — 无新增需求；emoji + CSS
- 音频资源 — useSoundEffect 仍 graceful no-op（资源未 drop in）
- 道具文案 — S4-6 由 systems-designer agent 写，不阻塞 user

## Out of Scope (Sprint 5+ 候选)

- **装备槽位 + 房屋系统**（永久 modifier，多 slot 互斥）— Sprint 5
- **健康资源**（第 4 资源，过劳死结局）— Sprint 6
- **多结局图鉴**（10+ 结局 + 收集 UI）— Sprint 6
- **代际传承 / 家族系统**（generation counter + 跨 run buff）— Sprint 7
- **中年危机 / 时间触发事件**（mortgage / 失业 / 父母生病）— Sprint 7
- **月报分享图**（canvas 渲染 + 小程序 shareImage）— Sprint 7
- **广告 SDK 接入**（revive ad / 收入翻倍 / 体力恢复）— Sprint 8
- **新职业事件包**（甲方乙方 / 摸鱼大师 / 赛博算命师）— 持续，依设计师产出
- **现实时间 cooldown**（HR 审核 / 体力恢复）— Beta

## Definition of Done for this Sprint

- [ ] 7/7 Must Have 任务完成
- [ ] QA plan exists (`production/qa/qa-plan-sprint-4.md`)
- [ ] 全部 Logic 故事 100% 行覆盖（service 层）
- [ ] Smoke check 通过（S4-7）
- [ ] 没有 S1-S3 级 bug regression（394+ tests 仍通过）
- [ ] 玩家能完成 e2e：选职业 → 4 周生涯 → 至少 1 次升职 → 用钱买消耗品续命 → 进 settle → rating 显示 careerLevel
- [ ] mp-alipay bundle ≤ 500KB（如不达需 subpackage 重构）
- [ ] 任何架构偏离已记录到 ADR 或 story Completion Notes

## Producer Feasibility Gate

> **PR-SPRINT skipped — Lean mode.** Sprint 3 已验证 8-day capacity 合理；Sprint 4 7.25 days 在容量内。
> 经济系统 + 升职是用户明确需求，且 Sprint 3 hotfix 已铺垫（金钱 balance）。

## Scope Check

> Sprint 4 must-have 完全在用户 2026-05-20 设计文档范围内（"升职加薪" + "金钱用处"）。
> nice-to-have S4-10 是 Sprint 3 遗留诊断的 salaryMul bug，与本期主题对齐。
