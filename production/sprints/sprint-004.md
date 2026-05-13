# Sprint 4 — 2026-05-14 to 2026-05-28

## Sprint Goal
深化战斗系统（接入武学/内力/连招），丰富探索内容（奇遇事件/对话触发），补齐任务日志和多存档槽位UI，修复测试回归

## Capacity
- **Total days**: 14
- **Buffer (20%)**: 3 days (reserved for unplanned work)
- **Available**: 11 days

---

## Tasks

### Must Have (Critical Path)

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|-------------------|
| S4-01 | 武学技能接入战斗 | Gameplay Programmer | 2 | None | 战斗中"技能"按钮打开已习得武学列表，选择后消耗内力执行，替代当前硬编码"气剑术"；至少3种不同武学可用（MVP范围：技能选择+释放，不含熟练度/元素效果） |
| S4-02 | 奇遇事件接入探索循环 | Gameplay Programmer | 1.5 | None | 探索时除战斗外随机触发非战斗奇遇（藏宝/NPC/修炼机缘），奇遇结果影响背包/经验/货币 |
| S4-03 | 任务日志UI面板 | UI Programmer | 1 | None | 快捷键(J)打开任务日志，显示进行中/已完成任务及目标，接入QuestManager真实数据 |
| S4-04 | 多存档槽位UI | UI Programmer | 1 | None | 暂停菜单"保存/加载"弹出3槽位列表，显示时间戳/等级/区域，支持覆盖保存和删除确认 |
| S4-05 | 测试回归修复 | QA/Programmer | 1 | None | 运行全部测试，修复Sprint 3引入的编译/运行错误，通过率恢复≥95% |

**Total**: 6.5 days

### Should Have

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|-------------------|
| S4-06 | 战斗结算面板 | UI Programmer | 0.5 | S4-01 | 战斗结束后弹出结算面板（经验/银两/物品掉落），点击"继续"返回探索 |
| S4-07 | 内力/气系统接入战斗UI | Gameplay Programmer | 1 | S4-01 | 战斗HP条下方显示内力条，技能消耗内力，内力不足时技能按钮置灰，每回合自然恢复 |
| S4-08 | 对话系统接入探索 | Gameplay Programmer | 1 | S4-02 | 奇遇中的NPC类型触发DialogueManager对话，对话选项影响结果（获得物品/经验/关系值） |

**Total**: 2.5 days

### Nice to Have

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|-------------------|
| S4-09 | ADR-006 奇遇架构审核 | Architecture | 0.5 | None | (Sprint 2/3/4 延迟) |
| S4-10 | ADR-007 对话架构审核 | Architecture | 0.5 | None | (Sprint 2/3/4 延迟) |
| S4-11 | 战斗连招系统接入 | Gameplay Programmer | 1.5 | S4-01, S4-07 | 连续使用特定武学组合触发连招加成，显示连招计数和加成效果 |

**Total**: 2.5 days

---

## Carryover from Sprint 3

| Task | Reason | New Estimate |
|------|--------|-------------|
| S3-11 ADR-006 奇遇架构审核 | 连续延迟(Sprint 2→3→4) | 0.5 days |
| S3-12 ADR-007 对话架构审核 | 连续延迟(Sprint 2→3→4) | 0.5 days |

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 武学系统API与战斗系统适配复杂 | Medium | High | MVP范围限定为技能选择+释放，不含熟练度/元素效果；martial_arts_system.gd已有完整API |
| 奇遇事件数据不足 | Medium | Medium | 优先使用现有encounter数据结构，至少3种模板可触发 |
| 测试回归量大（Sprint 3改动7个核心文件） | Medium | Medium | 优先修复编译错误，运行时错误按影响优先级排序 |
| 连续3个Sprint延迟ADR审核 | Low | Low | 纳入Nice to Have，技术债可控 |

---

## Dependencies on External Factors
- Sprint 3 所有系统已验证通过
- MartialArtsSystem、QiManager、EncounterSystem 代码已存在
- QuestManager、DialogueManager Autoload 已注册

---

## PR-SPRINT Feasibility Assessment
**Verdict**: REALISTIC with CONCERNS
- 总体可行：Must Have 6.5d / 可用 11d = 59%
- 关注点：S4-01 应严格控制 MVP 范围（仅技能选择+释放）；S4-05 测试修复如超 1 天可能挤压 Should Have
- Producer agent 不可用（API 授权错误），评估内联完成

---

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-4.md`)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged

---

**Created**: 2026-05-13
**Last Updated**: 2026-05-13
