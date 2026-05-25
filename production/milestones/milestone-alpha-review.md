# Milestone Alpha 回顾 (Retrospective)

**Milestone**: Alpha — 核心可玩版本
**Achieved Date**: 2026-05-15
**Review Date**: 2026-05-25 (Polish Week 2 中段)
**Reviewer**: producer skill (本次会话 polish-fixlist 同期产出)

---

## 总览数据

| 指标 | 值 |
|------|-----|
| Sprint 数 | 6 (Sprint 1 ~ 6) |
| Total stories | 66 |
| 故事完成率 | 100% (66/66) |
| 工程产出 | 175 .gd / 35 .tscn / 106 _test.gd |
| GDD 数 | 55+ |
| ADR 数 | 7 |
| UX 规范 | 13 |
| QA 签收 | 6/6 (全 sprint 签收) |
| Playtest 场次 | 3 (2026-04-29 ×2 + 2026-05-15 ×1) |
| 周期总长 | 17 天 (2026-04-28 → 2026-05-15) |
| Velocity (avg) | ≈11 stories/sprint, ≈4 stories/天 (高度并行) |

## 各 Sprint 节奏

| Sprint | 周期 | 实际周期 | Stories | 主题 |
|--------|------|---------|---------|------|
| Sprint 1 | 2026-04-28 ~ 05-11 | ≈14 天 | 11 | 核心系统验证 |
| Sprint 2 | 2026-05-09 ~ 05-23 | 部分重叠 | 14 | UI 场景 8 个 |
| Sprint 3 | 2026-05-13 ~ 05-27 | 部分重叠 | 12 | UI 接入游戏循环 |
| Sprint 4 | 2026-05-14 ~ 05-28 | 部分重叠 | 11 | 战斗深化 + 探索 |
| Sprint 5 | 2026-05-14 ~ 05-28 | 部分重叠 | 10 | 角色关系 |
| Sprint 6 | 2026-05-15 ~ 05-29 | 部分重叠 | 11 (提前 14 天达成) | 端到端体验 |

> 关键观察: Sprint 2~6 周期高度重叠, 实际是并行多线推进而非串行。Alpha 比 sprint 名义截止日 (05-29) 提前 14 天达成。

## Velocity 分析

**优点**:
- 6 sprint 全部按计划范围完成, 0 carryover
- 故事达成率 100%, 无 stretch goal 落空
- 测试文件数 (106) > 源文件数 (175) × 60% 满足覆盖率目标
- QA 签收链路顺畅, 无 sprint 签收延迟

**异常信号**:
- Sprint 周期严重重叠 (Sprint 2~6 同时活跃) — 实际是多 agent 并行而非严格 sprint 模式
- 故事粒度估算偏粗 (单 story 1-2 天, 但实际工时含 AI agent 时间未量化)
- Sprint 6 名义截止 05-29, 实际 05-15 达成 (-14 天) — 估算保守或并行加速

## 范围变更 (Scope Changes)

### 范围内完成
- 全部 Alpha 硬性要求 (核心循环 / UI / 存档 / 战斗 / 对话 / 关系) ✅
- 6 项 "Needs Revision" GDD 已全部 Approved (2026-05-15 平衡审查批次)
- 旧版测试路径 (random_event) 修复 (2026-05-15)
- 平衡数据正式审查通过 (2026-05-15)

### 范围外但补救
- 性能数据基线缺失 → 延后到 Polish s7-14
- 中期/难度曲线 Playtest 缺失 → 延后到 Polish s7-16
- 乐趣假设未显式定义 → 延后到 Polish s7-17

### 真·遗留缺陷 (Polish 期发现)
- ❌ HUD 10 信号哑火 (player_hp/qi/poise/level_up/exp + enemy_*/combat_action_queue) — 玩家根本看不到 UI 反馈, Alpha 期未捕获
- ❌ DamageCalculator 全乘数未串接 (暴击/弱点/连击/随机浮动) — 战斗只是 atk-def, Alpha QA 未挖出
- ❌ GDD 数值偏离 (暴击率公式 / 连击单位 / 熟练度上限) — 已在 7a96c95 修复
- ❌ class_name 冲突 (damage_visualization / world_streaming_manager) — 已在本 Polish 阶段处理
- ❌ 境界 9 vs 10 跨系统不统一 — 决策 PENDING
- ❌ 装备 9 槽 vs 15 槽不统一 — 决策 PENDING

> Alpha 签收的 "11/11 stories DONE" 与实际 polish-fixlist 23 项必修存在落差。
> 根因: Sprint QA 集中在"接口可调用"+ "无崩溃", 未做"按 GDD 数值快照比对"。

---

## Lessons Learned

### 做得好 (Continue)
1. **6 sprint 全部按时签收** — QA + Producer + Sprint Owner 三方签收节奏稳
2. **测试驱动开发** — 106 测试文件提供回归保护, 修复 7a96c95 时改 1 行代码可立即跑回归
3. **GDD 优先** — 大部分系统先有 GDD 再有代码, 避免"代码先行 / GDD 倒推"陷阱
4. **AI 美术管线 Polish 阶段补建** — Alpha 不强求美术 100%, 战略上正确, 把美术工作量挪到 Polish
5. **session-state 文件机制** — 跨会话/跨压缩稳定恢复, 避免重复探索

### 需要改进 (Change)
1. **Sprint QA 缺数值快照比对** — 应该在 sprint 签收前对 GDD 关键数值跑 "公式快照测试", 而不仅仅是 "无崩溃 + 接口可用"
   - 修复建议: Polish 阶段为每个 P1+ 数值系统建立 `tests/unit/{system}/{system}_formula_snapshot_test.gd`
   - 本 Polish 已落实: critical_rate_formula_test / combo_damage_increment_test / martial_arts_proficiency_cap_test
2. **HUD 信号链未做端到端验证** — Alpha 期 connect 验证了, 但 emit 验证缺失
   - 修复建议: 加 integration test 验证 "状态变化 → GameEvents.emit → HUD 收到"
3. **Sprint 周期严重重叠** — 名义 sprint 边界已失去意义, 实际是 "并行多线"
   - 修复建议: Polish 阶段改用 epic-driven backlog, sprint 仅作为节奏锚点 (2 周一次同步)
4. **class_name 命名空间未统一管理** — 出现 2 次冲突 (damage_visualization / world_streaming_manager)
   - 修复建议: 建立 `docs/architecture/class-name-registry.md` 集中登记所有全局类
5. **session-state 完工记录不全** — Polish 期发现 AI 管线/主题系统/启动场景切换/境界 bug 等 4 项无 completion 文件
   - 修复建议: 每个 commit 后强制更新 active.md 或建 completed.md

### 停止做 (Stop)
1. **"暂时" stub 注释** — Polish 阶段发现 25 处, 容易遗忘
   - 改用: `// TODO(@owner, milestone-X.Y): 实现 ...` 格式, 明确归属和截止
2. **预留信号定义但不 emit** — Polish 阶段发现 30+ 处, 误导后人
   - 改用: 实际需要时再加, 加时同步在 GDD 标记
3. **同名常量跨系统** — combat_system 的 COMBO_DAMAGE_INCREMENT (0.05 战斗连击) vs link_system 的 COMBO_DAMAGE_INCREMENT (0.10 连携槽) — 已被本 polish-fixlist 标记
   - 改用: 加前缀区分, 如 LINK_COMBO_DAMAGE_INCREMENT

---

## 对 Beta 的 Action Items

| # | Action | Owner | Target Sprint | 关联 |
|---|--------|-------|---------------|------|
| 1 | HUD 10 信号端到端接通 + integration test | UI Programmer + QA | Sprint 7-8 | polish-fixlist #1 |
| 2 | DamageCalculator 乘数全接通 + 公式快照测试 | Combat Programmer + Game Designer | Sprint 8 | polish-fixlist #2 |
| 3 | 境界 9/10 决策 + 跨系统对齐 | Game Designer | Sprint 7 | polish-fixlist #3 |
| 4 | 装备 9/15 槽决策 + 4 子系统决策 | Systems Designer | Sprint 9 | polish-fixlist #8 |
| 5 | sprint-007 ~ 010 backlog 引入 polish-fixlist 全部 23 项 | Producer | Sprint 7 起 | polish-fixlist 全 |
| 6 | 建立 class-name-registry.md | Lead Programmer | Sprint 8 | lessons #4 |
| 7 | 每个数值系统建立 formula_snapshot_test | QA Lead | Sprint 8-9 | lessons #1 |
| 8 | session-state 完工记录强制化 (hook + 模板) | Producer + DevOps | Sprint 7 | lessons #5 |

---

## 总结

**Alpha 阶段评级**: PASS (CONCERNS)

- ✅ 范围 100% 达成
- ✅ 工程产出健康
- ✅ QA 流程顺畅
- ⚠️ Polish 期发现 23 项必修 (4 P0 + 8 P1 + 6 状态体系缺口 + 5 卫生)
- ⚠️ Sprint QA 缺数值快照, Alpha 签收存在"接口可用即过"的盲区

**关键洞察**: Alpha 的 "100% DONE" 是 sprint-scope 内的真; 但跨 sprint 的"端到端玩家体验完整"评估缺失。Polish 阶段需补这一层验证。

**对 Beta 的核心信号**: 不要重复 Alpha 的"接口可用即过"模式, Polish 期所有 P0/P1 修复必须以 "公式快照测试 + 端到端 Playtest 通过" 为出口标准。
