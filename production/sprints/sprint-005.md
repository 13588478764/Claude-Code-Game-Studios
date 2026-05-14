# Sprint 5 — 2026-05-14 to 2026-05-28

## Sprint Goal
实现角色关系系统的完整游戏循环：礼物系统、对话集成、事件触发、关系UI，使玩家能通过对话/礼物/任务与NPC建立关系并体验内容解锁

## Capacity
- **Total days**: 14
- **Buffer (20%)**: 3 days (reserved for unplanned work)
- **Available**: 11 days

---

## Tasks

### Must Have (Critical Path)

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|-------------------|
| S5-01 | NPC数据配置 | Game Designer | 1 | None | 创建至少5个核心NPC定义（id/名称/立场/礼物偏好/对话节点引用），存储为JSON，RelationshipManager可加载使用 |
| S5-02 | 礼物系统实现 | Gameplay Programmer | 2 | S5-01 | 玩家可向NPC赠送物品；喜好度分4档（最爱/喜欢/普通/讨厌）影响关系值变化；重复赠送新鲜度衰减（0.17/次，最低0.5）；每NPC每日限赠1次 |
| S5-03 | 对话系统集成 | Gameplay Programmer | 1.5 | None | 对话效果系统调用modify_relationship/modify_dao_heart；对话选项根据关系等级/道心值条件显示或隐藏；至少3段对话演示关系变化 |
| S5-04 | 存档系统集成 | Gameplay Programmer | 0.5 | None | SaveManager.save_game()和load_game()包含关系数据；存档/读档后关系值、道心值、已触发事件正确恢复 |
| S5-05 | 关系系统单元测试 | QA/Programmer | 1.5 | S5-02, S5-03 | 覆盖：关系值增减/等级转换/道心值计算/礼物新鲜度/态度修正/保存加载/边界值，通过率100% |

**Total**: 6.5 days

### Should Have

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|-------------------|
| S5-06 | 关系事件触发系统 | Gameplay Programmer | 2 | S5-01, S5-03 | 关系值达到阈值（10/50/80）时自动检查并触发事件（对话/任务/技能传授）；维护已触发事件列表防止重复；支持多条件组合（关系值+主线进度+境界） |
| S5-07 | 关系UI面板 | UI Programmer | 1.5 | S5-01 | 快捷键(R)打开关系面板；显示所有已交互NPC的关系值（进度条）/等级/道心指示器；关系等级变化时HUD弹出通知 |

**Total**: 3.5 days

### Nice to Have

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|-------------------|
| S5-08 | 结局判定系统 | Systems Designer | 1 | S5-01, S5-06 | 根据道心值+核心NPC关系值+主线进度判定4种结局类型；按优先级（隐世>逍遥>正道>魔道>默认）选择；提供check_ending_conditions() API |
| S5-09 | 战斗系统GDD同步 | Architecture | 0.5 | None | 更新combat-system.md为"Approved"状态，反映当前代码实现（连招系统、内力UI、结算面板） |
| S5-10 | 角色成长系统GDD同步 | Architecture | 0.5 | None | 更新character-progression-system.md为"Approved"状态，反映当前代码实现 |

**Total**: 2 days

---

## Carryover from Sprint 4

| Task | Reason | New Estimate |
|------|--------|-------------|
| 无 | Sprint 4 全部完成(11/11) | — |

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| NPC数据结构设计影响多个下游系统 | Medium | High | S5-01优先完成并评审，确定JSON schema后再开发S5-02/S5-06 |
| 对话系统集成需修改DialogueManager效果处理 | Medium | Medium | 现有dialogue effects已支持item_give/quest_trigger，扩展relationship_change类似 |
| 关系事件触发条件复杂（多条件组合） | Low | Medium | MVP限制为单条件（仅关系值阈值），多条件组合降级为Nice to Have |
| 礼物系统需要扩展items.json | Low | Low | 在现有42个物品基础上标记gift_preferences，不改变物品结构 |

---

## Dependencies on External Factors
- RelationshipManager + RelationshipData 代码已存在且功能完整
- DialogueManager 效果系统已就位（dialogue_effects）
- SaveManager 已实现保存/加载框架
- items.json 已有42个物品定义

---

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-5.md`)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged

---

**Created**: 2026-05-14
**Last Updated**: 2026-05-14
