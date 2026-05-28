# 项目阶段分析报告

**日期**: 2026-05-28
**阶段**: **Polish**
**阶段置信度**: PASS — `production/stage.txt` 标记为 Polish, Production→Polish 门检已通过
**上次更新**: 2026-05-23 → 本次 (第 5 天增量更新)

---

## 完整度概览

| 维度 | 完成度 | 详情 |
|------|--------|------|
| **设计文档** | 95% | 55 个 GDD + 13 个 UX spec + 3 幕叙事大纲 + 44 对话 JSON + 30 奇遇 JSON; 缺 game-concept.md / systems-index.md 顶层文件 |
| **源代码** | 85% | 165 个 .gd 文件, ~48,254 行, 24 个 Autoload, 93 个场景 |
| **美术资源** | 70% | 236 张游戏用图标 (不含 236 张 _masters 母版), 12 主角 + 16 敌人立绘, 15 背景 |
| **架构** | 75% | 12 个 ADR; 缺架构总览索引文档 |
| **生产管理** | 90% | 7 sprints, 3 milestones, 44 epics, 3 playtests, risk-register, polish-fixlist |
| **测试** | 80% | 152 个测试文件, ~31,075 行; unit/integration/smoke/performance 四层覆盖 |
| **代码健康** | 95% | 10 个 TODO(beta), 0 个 FIXME; polish-fixlist 27 项中 21 项已关闭 |

---

## 与上次报告 (05-23) 的变化

| 维度 | 05-23 | 05-28 | 变化 |
|------|-------|-------|------|
| 源代码 | ~45K 行 | ~48K 行 | +3K (UI 接入 + 乘数管线 + 信号桥) |
| 美术资源 | 41 张 | 236 张 (游戏用) | +195 张 (3 批 AI 出图入库) |
| polish-fixlist | 5/27 完成 | 21/27 完成 | +16 项闭环 |
| TODO/FIXME | 39 / 0 | 10 / 0 | -29 (stub 标准化 + 清理) |
| Sprints | 6 | 7 | +sprint-007 (Polish Week 1-2) |
| Risk register | 不存在 | 6 风险 | 新建 |

---

## 系统实现覆盖率

### 主要系统 (按目录)

| 系统 | 文件数 | 状态 | 备注 |
|------|--------|------|------|
| UI 系统 | 48 | ✅ DONE | buff/item/talent/skill 图标已接入 |
| 战斗系统 | 17 | ✅ DONE | 完整乘数链 (暴击×连击×弱点×破防×状态×浮动) |
| 奇遇系统 | 13 | ⚠️ 框架完成 | 触发/条件/奖励/历史全部就位, 缺内容数据 |
| HUD 系统 | 10 | ✅ DONE | 10 个信号全部接通 |
| 敌人缩放 | 9 | ✅ DONE | — |
| 装备系统 | 8 | ✅ DONE | 9 槽统一, 8 文件实现 |
| 角色系统 | 8 | ✅ DONE | 静态类型化, 暴击/经验/福缘公式全部对齐 GDD |
| 性能框架 | 7 | ✅ DONE | 对象池 + 批量更新 + LOD 调度 |
| 数据层 | 6 | ✅ DONE | martial_art/item/equipment/consumable/quest_item 数据类 |
| 对话系统 | 5 | ✅ DONE | 6 种条件判定已实现 |
| 世界系统 | 4 | ✅ DONE | 流式加载 + POI + 移动控制 + 探索追踪 |
| 关系系统 | 4 | ✅ DONE | — |
| 任务系统 | 4 | ✅ DONE | — |
| 经济系统 | 4 | ✅ DONE | — |

### Autoload 注册 (24 个)

GameEvents, CharacterSystem, CombatSystem, EncounterSystem, EncounterRecordManager,
EncounterRewardManager, HistoryLogger, HistoryPersistenceManager, AudioSystem,
QuestSystem, QuestTriggerManager, RelationshipManager, DialogueManager, DialogueLoader,
DialogueCombatBridge, ActManager, PauseMenuManager, CurrencyManager, GameLoopManager,
InventorySystem, SaveSystem, MartialArtsSystem, EncounterDataLoader + main_theme.tres

---

## 美术资源清单

| 类别 | 数量 | 代码接入 | 备注 |
|------|------|----------|------|
| 五行元素图标 | 5 | ✅ weakness_icon_display.gd | — |
| 境界图标 | 10 | ✅ player_status_panel.gd | — |
| 战斗状态图标 | 5 | ✅ status_icon.gd (→status_icons/) | — |
| Buff/Debuff 图标 | 36 | ✅ status_icon.gd (→buff_icons/) | 16 个 EffectType 已映射 |
| 物品图标 | 65 | ✅ inventory_panel.gd + items.json | 69 物品路径已更新 |
| 技能图标 | 16 | ✅ combat_action_panel.gd | 按 id→weapon_type 回退 |
| 天赋图标 | 16 | ✅ character_growth_ui_script.gd | 4×4 网格按位置映射 |
| 系统图标 | 23 | ❌ 未接入 | 待地图/任务 UI 使用 |
| 边框装饰 | 17 | ⚠️ 部分 | frame_dialogue.png 已接入; 品阶边框/按钮纹理待 Theme |
| 主角立绘 | 12 | ❌ 待接入 | 第四批产出, 对话框/队伍面板 |
| 敌人立绘 | 16 | ❌ 待接入 | 第四批产出, 战斗 UI 敌人信息面板 |
| 背景 | 15 | ❌ 待接入 | 第四批产出, 加载画面/主菜单 |
| 主角队伍头像 | 0 | ❌ 待出图 | party_portraits/ 空 |

---

## Polish-Fixlist 状态

**来源**: `production/qa/polish-fixlist-2026-05-25.md`

### 已关闭 (21/27)

| # | 项目 | 关闭日期 |
|---|------|----------|
| 1 | HUD 10 信号哑火 | 05-28 (确认已有 emit) |
| 2 | DamageCalculator 乘数 | 05-28 (确认完整实现) |
| 3 | 境界 9/10 统一 | 05-26 |
| 4 | 暴击/连击/熟练度 + 回归测试 | 05-28 (确认测试存在) |
| 5 | class_name 冲突 | 05-28 |
| 6 | character_system 静态类型 | 05-26 |
| 7 | 对话条件判定 | 05-28 (确认 6 子类实现) |
| 8 | 装备 9 槽统一 | 05-28 |
| 9 | EXP 分段指数 | 05-26 |
| 10 | 武器类型补齐 (GDD) | 05-26 |
| 11 | 奇遇概率统一 | 05-26 |
| 12 | 福缘软上限 | 05-26 |
| 13 | sprint-007 | 05-28 (确认已创建) |
| 14 | milestone-beta | 05-28 (确认已创建) |
| 15 | epics/index 修复 | 05-28 |
| 18 | risk-register | 05-28 |
| 19 | 测试文件迁出 src/ | 05-26 |
| 20 | stub 标准化 | 05-27 |
| 22 | documentation/ 空壳删除 | 05-27 |
| 23 | milestone-alpha-review | 05-28 (确认已创建) |

### 剩余 (6/27)

| # | 项目 | 原因 |
|---|------|------|
| 16 | project-stage-report 过时 | ✅ 本报告即修复 |
| 17 | session-state 完工记录 | 历史回溯, 低优先 |
| 21 | 死信号清理 | 评估后风险>收益 |
| 24 | 品阶边框接入 | 需自定义 ItemSlot 场景 |
| 25 | 进度条/按钮 Theme | 需 Godot 编辑器 |
| 26 | system_icons 接入 | 需地图/任务 UI 完善 |
| 27 | 装饰纹理接入 | 纳入 #25 Theme 一并处理 |

---

## Beta 门检距离

| 门检要求 | 状态 | 备注 |
|----------|------|------|
| 三幕剧情全部可玩 | ✅ 大纲 + 数据已填充 | Act1 6 + Act2 11 + Act3 11 = 28 个主线事件 JSON |
| ≥20 条奇遇可触发 | ✅ 30 条奇遇数据 | data/encounters/ 30 个 JSON, 超过门检要求 |
| 10 境界可玩 | ✅ | — |
| UI 图标 100% 入库 | ⚠️ ~65% | 再出 1-2 批 |
| 暴击/连击/乘数对齐 | ✅ | + 回归测试 |
| HUD 信号接通 | ✅ 10/10 | — |
| 60 FPS 基线 | ❌ 无数据 | sprint-008 安排 perf-profile |
| 测试通过率 ≥95% | ⚠️ 93.2% | 修复 ~10 个失败用例 |
| P0 bug = 0 | ✅ | 全清 |
| P1 bug = 0 | ⚠️ | #10 武器类型补齐 (Blade/Exotic/Bow 待 Beta 数据) |
| Beta Playtest ≥3 | ❌ 0/3 | 内容 50%+ 后开始 |
| 测试文件不在 src/ | ✅ | — |

---

## 活跃风险 (详见 production/risk-register/active.md)

| ID | 风险 | 等级 |
|----|------|------|
| R-001 | ~~内容填充进度~~ | CLOSED (28 事件 + 30 奇遇已就位) |
| R-002 | 美术资源覆盖率 (~65%) | MEDIUM |
| R-003 | ComfyUI 工作流稳定性 | LOW |
| R-004 | 测试通过率 93.2% < 95% | MEDIUM |
| R-005 | 性能基线缺失 | MEDIUM |
| R-006 | Beta Playtest 组织 | LOW |

---

## 建议下一步 (优先级排序)

1. **性能基线** — 主菜单/探索/战斗三场景 profiling, Beta 门检硬性要求 (sprint-008)
2. **测试修复** — 通过率 93.2% → 95%+, 修复 ~10 个失败用例
3. **第四批回流** — ComfyUI 完成后 `import_ai_assets.sh --commit`, 立绘+背景接入代码
4. **UI Theme 统一** — game_theme.tres 接入按钮/进度条/边框纹理 (fixlist #24-#27)
5. **Beta Playtest** — 内容已就位, 可开始安排第一轮 Playtest
6. **顶层设计文件** — 补 game-concept.md + systems-index.md

---

> 本报告由 `/project-stage-detect` 生成, 取代 2026-05-23 版本。
> 下次更新建议: sprint-007 结束时 (2026-05-29) 或 sprint-008 中期。
