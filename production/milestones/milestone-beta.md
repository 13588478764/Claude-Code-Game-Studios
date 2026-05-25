# Milestone: Beta — 内容完整版本

**Target Date**: 2026-07-15 (Polish 6 周后)
**Status**: IN PROGRESS (Polish Week 1-2 进行中)
**Stage**: Polish → Release Candidate

---

## 里程碑定义

Beta 版本要求: 所有游戏内容 (关卡/对话/任务/奇遇) 数据填充完成, 平衡数据经至少 3 轮 Playtest 调优, 性能在 60 FPS / 16.6 ms 预算内, 美术资产 100% 入库, 所有 P0/P1 bug 清零。玩家可以从开场到大结局完整体验游戏, 含三幕剧情、≥20 条奇遇、≥9 个境界突破。

## 进入 Beta 的硬性要求

| 类别 | 要求 | 当前状态 |
|------|------|----------|
| 内容 | 三幕剧情全部可玩 (含 Act 2/3 主线) | 大纲就位, 数据未填充 |
| 内容 | ≥20 条奇遇可触发 (encounter-system 数据) | 框架就位, 数据缺失 (Concern #1) |
| 内容 | NPC 对话覆盖率 ≥80% (主要 NPC 全覆盖) | 待评估 |
| 内容 | 所有 9 (或 10) 境界可玩, 突破流程完整 | 境界 9/10 决策 PENDING (fixlist #3) |
| 美术 | UI 图标 100% 入库 (含天赋/武学/系统) | 41/96 (第一批已收, 第二批夜间挂机) |
| 美术 | 主题资源全 UI 应用率 ≥90% | main_theme 已就位, 普及率待统计 |
| 平衡 | 暴击/连击/熟练度公式全部对齐 GDD | DONE (s7-12) |
| 平衡 | DamageCalculator 接通所有乘数 | PENDING (fixlist #2) |
| 性能 | 60 FPS 在主菜单/探索/战斗三场景达成 | 无基线数据 (s7-14 PENDING) |
| 性能 | 内存 < 8 GB | 无基线数据 |
| 测试 | 通过率 ≥95% | 93.2% (29 失败, s7-15 PENDING) |
| 测试 | P0/P1 bug 数 = 0 | polish-fixlist 4 P0 + 8 P1 待清 |
| QA | Beta Playtest 至少 3 场 (新玩家/中期/通关) | 0/3 |
| 工程 | 测试文件 100% 在 tests/ (无 src/ 残留) | 8 个测试文件混在 src/ (fixlist #19) |

## 计划 Sprint 范围 (Polish 阶段)

| Sprint | 周期 | 主题 | 关键交付 |
|--------|------|------|----------|
| Sprint 7 | 2026-05-15 ~ 05-29 | Polish Week 1-2: 美术管线 + 第二三幕 + GDD 数值对齐 | 见 sprint-007.md (13 DONE + 7 PENDING) |
| Sprint 8 | 2026-05-30 ~ 06-12 | Polish Week 3-4: HUD 信号闭环 + 奇遇内容 + 性能基线 | polish-fixlist P0 全清 + 奇遇 ≥20 条 + 性能基线 |
| Sprint 9 | 2026-06-13 ~ 06-26 | Polish Week 5-6: 装备系统决策 + 测试通过率 95%+ + Beta Playtest | 装备 GDD 9/15 槽决策 + 测试 ≥95% + Beta Playtest x2 |
| Sprint 10 | 2026-06-27 ~ 07-10 | Polish Week 7-8: Beta 候选打磨 + 平衡微调 | polish-fixlist P1 全清 + 平衡迭代 + Beta Playtest x1 |
| Beta Gate | 2026-07-15 | Polish → Release Candidate 门检 | gate-checks/polish-to-release-{date}.md |

## 核心系统优化重点

| 系统 | Polish 阶段任务 |
|------|------------------|
| 战斗 | DamageCalculator 接通乘数, HUD 战斗信号闭环, 平衡调优 |
| 角色成长 | 境界 9/10 决策, EXP 后期曲线 (GDD 1.8 vs 代码 2.5) 对齐, 福缘软上限实现 |
| 装备 | GDD 9 槽 vs 代码 15 槽决策, 强化/镶嵌/洗练/幻化 4 子系统决策 |
| 奇遇 | encounter-system 数据填充 ≥20 条, 触发概率 GDD 矛盾消除 (15% vs 20%) |
| 对话 | dialogue_data 条件判定真实化 (3 处 stub 清零), Act 2/3 主线对话填充 |
| HUD | 10 个未 emit 信号全部接通, 玩家可见 HP/内力/架势/经验/敌人弱点 |
| 美术 | 第二批 54 张图标验收, 武器图标 (Palm/Blade/Bow), 主题统一 |
| 工程 | 8 个 test 文件迁出 src/, class_name 冲突 (world_streaming_manager) 清零 |
| 性能 | /perf-profile 基线 + 优化到 60 FPS / 16.6 ms |

## 已知风险

1. **美术管线产能** — ComfyUI 挂机依赖本地稳定性, 第二批 54 张失败需要补跑
2. **奇遇内容工作量大** — Writer + Systems Designer 协作, ≥20 条需要 ~10 人日
3. **装备系统决策** — GDD 9 槽 vs 代码 15 槽分歧大, 决策影响 8 个子文件
4. **测试 4.6 兼容** — 29 个失败测试可能含 4.5/4.6 API 变更, godot-gdscript-specialist 评估必要

## 不进入 Beta 的项目 (顺延到 Release Candidate)

- live-ops 系统设计 (赛季/活动)
- 多语言本地化 (en/jp)
- Steam 成就/云存档/社区集成
- 控制器全适配 (gamepad partial 即可)
- 4K 适配优化 (1080p / 1440p 为优先级)

## 下一里程碑

**Release Candidate — 发行候选版本**: 锁内容, 锁平衡, Steam 集成完成, 多语言完成, 全平台兼容性测试通过。
