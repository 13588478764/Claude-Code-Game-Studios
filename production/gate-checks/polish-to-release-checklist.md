# Gate Checklist: Polish → Release Candidate

**Purpose**: Beta 达成时执行的门检模板。在 milestone-beta.md 达成预定日期前 1-2 周触发本检查。
**Target Trigger Date**: 2026-07-15 (milestone-beta 目标日)
**Status**: TEMPLATE (待 Beta 达成时实际执行)

---

## 必要产出物 (Required Artifacts)

### 内容完整性
- [ ] 三幕剧情全部可玩 (Act 1 + Act 2 + Act 3 主线对话/任务/场景数据填充完成)
- [ ] 奇遇内容 ≥20 条入库, encounter-system 数据驱动 (`design/narrative/encounters/*.md` 或 `assets/data/encounters/`)
- [ ] 所有 9 或 10 境界突破流程可玩 (含突破特效/对话/奖励)
- [ ] NPC 对话覆盖率 ≥80%, 主要 NPC (≥10) 100% 覆盖
- [ ] 主线任务首尾完整, 至少 5 条支线任务可完成
- [ ] dialogue_data 条件判定 0 处 `return true` stub (fixlist #7)

### 美术资产
- [ ] UI 图标 100% 入库 (战斗/buff/debuff/境界/天赋/武学/系统 全类别)
- [ ] 主题资源全 UI 应用率 ≥90% (main_theme.tres 覆盖全部 Control 节点)
- [ ] 角色立绘/CG 至少覆盖 5 个主要 NPC
- [ ] 武器图标 Palm / Blade / Bow 决策落实 (fixlist #10)
- [ ] 1024 母版资源全部归档到 `assets/ui/_masters/`

### 平衡与系统
- [ ] DamageCalculator 全乘数接通 (暴击/弱点/连击/随机浮动) — fixlist #2
- [ ] 境界 9/10 跨系统统一 — fixlist #3
- [ ] EXP 后期指数对齐 (GDD 1.8 vs 代码 2.5) — fixlist #9
- [ ] 福缘软上限实现 (>100 点边际递减) — fixlist #12
- [ ] 装备 9 槽 vs 15 槽 决策落实, 4 子系统 (强化/镶嵌/洗练/幻化) 决策完成 — fixlist #8
- [ ] 奇遇触发概率 GDD 统一 (15% vs 20%) — fixlist #11

### 性能
- [ ] 60 FPS 在主菜单/探索/战斗/对话 4 场景全部达成
- [ ] 帧时 < 16.6 ms (无掉帧尖峰 > 33 ms)
- [ ] 内存峰值 < 8 GB
- [ ] 加载时间: 主菜单→存档 < 5s; 场景切换 < 3s
- [ ] /perf-profile 基线 + 优化前后对比报告落档

### 测试
- [ ] 自动化测试通过率 ≥95% (≥405/426)
- [ ] 关键系统 (战斗/角色成长/对话/存档) 单元测试覆盖率 ≥70%
- [ ] Beta Playtest ≥3 场, 含新玩家/中期/通关三个段位
- [ ] P0 bug 数 = 0; P1 bug 数 ≤ 5 且有缓解策略
- [ ] 8 个 test 文件全部从 src/ 迁出 (fixlist #19)

### 工程卫生
- [ ] class_name 冲突 0 处 (world_streaming_manager 决策完成) — fixlist #5
- [ ] character_system.gd 核心 Autoload 全文静态类型 — fixlist #6
- [ ] 25 处 "暂时" stub 处理或注释加 `// 预留, 待 vX.Y` (fixlist #20)
- [ ] 30+ 预留信号清理或注释 (fixlist #21)
- [ ] src/scripts/documentation/ 三空壳决策 (删/补) — fixlist #22
- [ ] 0 个失败的 CI build

### 文档
- [ ] 所有 GDD 状态 = Approved (无 Needs Revision 或 Draft)
- [ ] milestone-alpha-review.md 落档 (fixlist #23)
- [ ] milestone-beta-review.md 落档 (本次门检的回顾)
- [ ] release-notes-beta.md 落档 (Beta 发布说明)
- [ ] 所有 ADR 与代码现状一致

---

## 质量检查 (Quality Checks)

### Director Panel Assessment (必跑 4 人)
- [ ] **Creative Director**: 三幕剧情节奏 + 玩家情感曲线评估
- [ ] **Technical Director**: 性能基线 + 架构稳定性 + 4.6 兼容性
- [ ] **Producer**: 进度 + 风险 + 团队产能评估
- [ ] **Art Director**: 美术统一性 + 主题应用率 + 资产质量

### Playtest 验收 (≥3 场)
- [ ] 新玩家场: ≥3 名未接触过游戏的测试者, 完成开场 → Act 1 末
- [ ] 中期场: ≥2 名测试者, 30-60 级段位深度体验
- [ ] 通关场: ≥1 名测试者, 完整通关 Act 3 大结局
- [ ] 所有 Playtest 反馈分类: 阻塞 / 体验 / 平衡 / 视觉 / 音频

### 平台兼容性
- [ ] Windows 10/11: 1080p / 1440p / 4K 全分辨率测试通过
- [ ] 键鼠 + Gamepad partial 输入测试通过
- [ ] 全屏 / 窗口模式切换无崩溃

---

## Chain-of-Verification (5 个挑战问题)

1. "是否有 CONCERN 应升级为 BLOCKER?" — 评估 P1 bug 是否实际阻断主路径
2. "Beta 阶段的所有 concerns 能否在 Release Candidate 阶段消化?" — 评估 RC 阶段产能是否足够
3. "是否软化了任何 FAIL 为 CONCERN?" — 性能/测试通过率不达标必须 FAIL
4. "是否有未检查的产出物类别?" — Steam 集成预备工作?
5. "所有 CONCERNS 加起来是否构成阻塞问题?" — 评估累积风险

---

## Verdict 标准

| 等级 | 标准 |
|------|------|
| **PASS** | 全部 Required Artifacts 复选; 0 P0 bug; Playtest 全部通过; Director Panel 4/4 通过 |
| **CONCERNS** | ≤5 项 Required Artifacts 未达成且可在 RC 阶段消化; Playtest 通过但有改进点 |
| **FAIL** | >5 项 Required Artifacts 未达成 OR 任意 P0 bug OR 任意 Director Panel 否决 |

**PASS** → 进入 Release Candidate 阶段, 启动 release-manager 流程
**CONCERNS** → 在 RC 阶段优先处理未达项, 不阻塞推进
**FAIL** → 延期 1-2 周, 创建 sprint-NNN.md 集中处理失败项, 重跑门检

---

## 维护责任

- **触发**: milestone-beta 目标日前 2 周, 由 producer 启动
- **执行**: gate-check skill + 4 director panel agents
- **归档**: `production/gate-checks/polish-to-release-{YYYY-MM-DD}.md`
- **后续**: 通过则创建 milestone-release-candidate.md; 否则更新 sprint backlog
