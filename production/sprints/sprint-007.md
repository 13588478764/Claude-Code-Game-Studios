# Sprint 7 -- 2026-05-15 to 2026-05-29 (Polish Week 1-2)

## Sprint Goal
进入 Polish 阶段第一周期。优先建立美术管线产能 + 完成第二三幕剧情大纲 + 主题系统统一 UI 视觉 + 修复 Alpha 遗留的 GDD 数值偏离与 class_name 冲突, 同时建立 Polish→Beta 必修 backlog (polish-fixlist-2026-05-25.md)。

## Capacity
- **Total days**: 14 (2026-05-15 ~ 2026-05-29)
- **Buffer (20%)**: 3 days
- **Available**: 11 days

---

## Tasks

### Must Have (已完成, Critical Path)

| ID | Task | Commit | Status | Acceptance Criteria |
|----|------|--------|--------|---------------------|
| s7-01 | Playtest 003 遗留 bug 修复 | 83240bc | DONE | NPC 对话/存档加载/UI 面板加载三类问题闭环 |
| s7-02 | AI 美术管线建设 + 五行图标首批 | c05598e | DONE | ComfyUI + FLUX 工作流跑通, 五行 5 张图标入库 |
| s7-03 | 主题系统 main_theme.tres + 主题生成器 | a305684 | DONE | 全局 Theme 资源就位, 生成器可批量化 UI 视觉 |
| s7-04 | 第二三幕剧情大纲 + Sprint 6 门检产出物 | ff20fd8 | DONE | 三幕完整剧情结构定稿; gate-production-to-polish 落档 |
| s7-05 | UI 场景/脚本批量调整 + 启动场景切主菜单 | 90b189d | DONE | 启动 → 主菜单 (而非测试场景); UI 命名/路径统一 |
| s7-06 | 测试用例修复 + 补齐 Godot 4.6 .uid 元数据 | 1be0d32 | DONE | 测试套件再次可跑; 4.6 自动生成的 .uid 全量入库 |
| s7-07 | 钩子脚本 mode 刷新 | d3756dc | DONE | 12 个 hook 脚本 mode 标记一致 |
| s7-08 | AI 51 张 UI 图标 + 1024 母版 + 清理境界占位 | 1df1d27 | DONE | 第一批 41 张验收 + 10 张境界图标入库 |
| s7-09 | AI 图标批量管线 (Python 生成器 + 8 工作流) | db925df | DONE | 工作流支持挂机批量; 回流脚本扩展到 4 类别 |
| s7-10 | 境界突破广播 player_realm_changed + HUD 适配 | 224e2aa | DONE | 突破后 HUD 境界图标自动刷新 (修复 P0 bug) |
| s7-11 | session-state 更新 — AI 图标管线第二批挂机就绪 | 62ca9d3 | DONE | session-state/active.md 记录第二批进度 |
| s7-12 | GDD 数值对齐 + class_name 冲突清除 | 7a96c95 | DONE | 暴击率公式/连击单位/熟练度上限对齐 GDD; 删 281 行 ui/damage_visualization_manager 空壳 |
| s7-13 | 第二批 AI 图标预期清单 + Polish 全方位审查必修清单 | ee0386f | DONE | ai-batch-2-expected.md (110 复选框) + polish-fixlist-2026-05-25.md (23 项) |

**Must Have Total**: 13 stories, 全部 DONE

### Should Have (Carryover from Gate-Check Concerns)

| ID | Task | Owner | Est. Days | Status | Acceptance Criteria |
|----|------|-------|-----------|--------|---------------------|
| s7-14 | 性能基线建立 (/perf-profile) | Performance Analyst | 1 | PENDING | 60 FPS / 16.6 ms 预算; 主菜单/探索/战斗三场景的帧时基线落档 |
| s7-15 | 修复 29 个失败测试 → 95%+ 通过率 | QA Tester | 2 | PENDING | tests/ 套件从 397/426 (93.2%) 提升到 ≥405/426 (95%) |
| s7-16 | 中期/难度曲线专项 Playtest | QA Lead | 1.5 | PENDING | 30 ~ 60 级段位的 1-2 场 Playtest 记录, 涵盖战斗节奏与升级曲线 |
| s7-17 | game-concept.md 补 Fun Hypothesis 章节 | Game Designer | 0.5 | PENDING | 显式定义"乐趣假设"段落, 含验证手段 |

**Should Have Total**: 5 days

### Nice to Have (Polish Fixlist P0 起步)

| ID | Task | Owner | Est. Days | Status | Acceptance Criteria |
|----|------|-------|-----------|--------|---------------------|
| s7-18 | HUD 10 个信号全面接通 (fixlist #1) | UI/Gameplay Programmer | 2 | PENDING | player_hp/qi/poise/level_up/exp + enemy_*/combat_action_queue 共 10 信号在源头 emit, HUD 实时刷新 |
| s7-19 | 境界 9/10 决策 + 跨系统统一 (fixlist #3) | Game Designer | 0.5 | PENDING | GDD 加"真仙"或代码改回 9; cross-check character_system + equipment_slot_manager + 图标资源 |
| s7-20 | 奇遇内容补齐 (gate-check Concern #1) | Writer + Systems Designer | 3 | PENDING | encounter-system 数据填充, ≥20 条可触发奇遇 |

**Nice to Have Total**: 5.5 days

---

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|--------------|
| 无 | Sprint 6 全部完成 (11/11), Alpha 里程碑达成 | — |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 美术管线 ComfyUI 挂机失败 (节点崩溃/磁盘满) | Medium | Low | 已建立 polish-fixlist + ai-batch-2-expected 复选框, 手动验收 |
| HUD 10 信号接通时引入新 bug | Medium | Medium | 与 s7-10 同型修复 (find 源头 → emit → 手动验证), 每个信号单独 commit |
| 29 个失败测试中含 Godot 4.6 API 变更 | Medium | Medium | godot-gdscript-specialist 评估; 必要时降级要求 |
| 中期 Playtest 需要存档导入工具 | Low | Medium | 利用现有 SaveSystem.create_test_save() |

## Dependencies on External Factors
- ComfyUI + FLUX 模型可用性 (本地, 已就位)
- Steam SDK 仅在 Release 阶段需要, 本 sprint 不依赖

## Definition of Done for this Sprint
- [x] All Must Have tasks completed (13/13 DONE)
- [ ] All Should Have tasks completed (0/4)
- [ ] All Nice to Have tasks evaluated (0/3)
- [ ] polish-fixlist-2026-05-25.md 至少处理 P0 #1 (HUD 信号) + #3 (境界 9/10)
- [ ] 性能基线落档
- [ ] 测试通过率 ≥95%
- [ ] session-state/active.md 同步收尾
- [ ] sprint-007 retrospective 落档
