# Sprint 6 -- 2026-05-15 to 2026-05-29

> **日期注**: 名义周期 14 天 (与 Sprint 1-5 一致), 但 Alpha milestone 在周期 day 0 (2026-05-15) 即达成。
> 实际是 Sprint 3-6 并行多线推进 (见 milestone-alpha-review.md velocity 分析), 不是 sprint 14 天延迟达成。
> 提前 14 天达成的真实含义: 6 sprint 名义截止 05-29, 11 个 stories 在 05-15 全部 DONE。

## Sprint Goal
接通设置面板实际功能、补全新游戏/加载流程、接入NPC对话触发、实现音频总线控制，使游戏具备完整的"启动→设置→开始→探索→NPC对话→战斗→存档"端到端体验

## Capacity
- **Total days**: 14
- **Buffer (20%)**: 3 days (reserved for unplanned work)
- **Available**: 11 days

---

## Tasks

### Must Have (Critical Path)

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|-------------------|
| s6-01 | 设置面板功能接通 | UI Programmer | 1.5 | None | 音量滑块控制AudioServer总线（音乐/音效/语音）；分辨率切换实际生效；设置持久化到user://settings.cfg并启动时加载 |
| s6-02 | 新游戏开场流程 | Gameplay Programmer | 1.5 | None | 点击"开始新游戏"→初始化CharacterSystem/RelationshipManager→加载intro_yunzhonghe对话→进入探索面板；有明确的状态转换而非直接跳转 |
| s6-03 | 加载游戏流程 | Gameplay Programmer | 1 | None | "加载游戏"按钮调用SaveSystem.has_save()检测；无存档时禁用按钮；有存档时加载并恢复到探索状态；加载失败有错误提示 |
| s6-04 | NPC对话触发接入 | Gameplay Programmer | 2 | s6-02 | 探索面板中可与已注册NPC交谈（按钮/列表）；调用DialogueManager.start_dialogue_with_npc()；至少5个NPC的日常对话可触发 |
| s6-05 | 音频总线控制 | Gameplay Programmer | 1 | s6-01 | AudioServer.set_bus_volume_db()响应设置面板；静音/取消静音功能；音量变化实时生效无需重启 |

**Must Have Total**: 7 days

### Should Have

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|-------------------|
| s6-06 | 支线任务触发验证 | QA/Programmer | 1.5 | s6-04 | quest_trigger_manager中已注册的3个支线（柳如烟/慕容雪/萧寒夜）可在关系值达标时触发对话；触发后任务系统记录进度 |
| s6-07 | 暂停菜单功能完善 | UI Programmer | 1 | s6-01 | 暂停菜单"返回主菜单"实际加载主菜单场景；"继续游戏"正确恢复；设置入口可打开设置面板 |
| s6-08 | 主菜单制作人员/帮助入口 | UI Programmer | 0.5 | None | 制作人员按钮打开滚动字幕面板；帮助按钮打开帮助面板；无崩溃 |

**Should Have Total**: 3 days

### Nice to Have

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|-------------------|
| s6-09 | 装备面板孔洞数据接通 | Gameplay Programmer | 0.5 | None | 装备面板的"孔洞: 0/3"占位替换为实际数据读取 |
| s6-10 | HotbarSlot tooltip实现 | UI Programmer | 0.5 | None | Hotbar槽位悬浮时显示简要信息tooltip |
| s6-11 | 集成测试补充 | QA/Programmer | 1 | s6-02, s6-04 | 新游戏流程/NPC对话触发/设置持久化的集成测试，覆盖端到端链路 |

**Nice to Have Total**: 2 days

---

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| 无 | Sprint 5 全部完成(10/10) | — |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| AudioServer总线名称与设置面板不匹配 | Medium | Low | 先确认project.godot中AudioBus配置 |
| intro_yunzhonghe.json格式与DialogueManager不兼容 | Low | Medium | 启动时验证JSON加载 |
| 设置持久化ConfigFile在不同OS路径差异 | Low | Low | 使用user://前缀，Godot自动处理 |

## Dependencies on External Factors
- 无外部依赖（所有数据文件已就位）

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-6.md`)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
