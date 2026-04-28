# Sprint 1 — 2026-04-28 to 2026-05-11

## Sprint Goal
验证核心游戏系统的实现质量,建立测试基准,为后续开发奠定质量基础

## Capacity
- **Total days**: 14
- **Buffer (20%)**: 3 days (reserved for unplanned work)
- **Available**: 11 days

---

## Tasks

### Must Have (Critical Path)

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|-------------------|
| 1.1 | 战斗系统测试验证 (3个故事) | QA Team | 2 | None | 所有单元测试通过,无S1/S2 bug |
| 1.2 | 角色成长系统测试验证 (6个故事) | QA Team | 3 | None | 所有单元测试通过,无S1/S2 bug |
| 1.3 | 技能树系统测试验证 (3个故事) | QA Team | 2 | None | 单元测试通过 + UI手动测试完成 |
| 1.4 | 武学系统测试验证 (4个故事) | QA Team | 2 | None | 所有单元测试通过,无S1/S2 bug |
| 1.5 | 装备系统测试验证 (3个故事) | QA Team | 1.5 | None | 所有单元测试通过,无S1/S2 bug |

**Total**: 10.5 days

### Should Have

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|-------------------|
| 2.1 | 经济系统测试验证 (3个故事) | QA Team | 1.5 | None | 单元测试通过 |
| 2.2 | 任务系统测试验证 (3个故事) | QA Team | 1.5 | None | 单元测试通过 |
| 2.3 | 小地图系统测试验证 (3个故事) | QA Team | 1 | None | 手动测试 + 截图证据 |

### Nice to Have

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|-------------------|
| 3.1 | 战斗UI测试验证 (3个故事) | QA Team | 1 | 1.1 | 手动测试 + 截图证据 |
| 3.2 | 装备UI测试验证 (3个故事) | QA Team | 1 | 1.5 | 手动测试 + 截图证据 |

---

## Carryover from Previous Sprint
(None — this is Sprint 1)

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 测试失败率高于预期 | Medium | High | 预留3天缓冲时间,优先修复Must Have故事的bug |
| UI测试耗时超出估算 | Medium | Medium | 将部分UI测试移至Should Have或下一个Sprint |
| 缺少测试数据或环境问题 | Low | Medium | 使用现有JSON数据文件,提前验证Godot 4.6环境 |
| 测试证据文档填写不完整 | Low | Low | 提供清晰的模板和示例 |

---

## Dependencies on External Factors
- Godot 4.6 编辑器已安装并配置
- GUT 测试框架已设置
- 所有109个故事的代码已实现

---

## Definition of Done for this Sprint

- [ ] 所有Must Have任务完成
- [ ] 所有任务通过验收标准
- [ ] QA计划存在 (`production/qa/qa-plan-sprint-001.md`)
- [ ] 所有Logic/Integration故事有通过的单元/集成测试
- [ ] Smoke check通过 (`/smoke-check sprint`)
- [ ] QA签署报告: APPROVED 或 APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] 交付功能中无S1或S2级别bug
- [ ] 任何偏差都已更新到设计文档
- [ ] 代码已审查并合并
- [ ] 所有测试证据文档已完成并签署
- [ ] Sprint回顾会议完成

---

## Testing Strategy

### Logic Stories (自动化测试)
- 运行GUT测试框架
- 验证所有单元测试通过
- 检查测试覆盖率 ≥ 70%
- 记录测试结果

### UI Stories (手动测试)
- 在Godot编辑器中运行场景
- 执行测试用例
- 收集截图/视频证据
- 填写测试证据文档并签署

### Integration Stories
- 运行集成测试
- 验证系统间交互
- 记录集成测试结果

---

## Notes

**Sprint Focus**: 这是第一个Sprint,专注于验证已实现的核心系统。所有109个故事已实现但处于Pending Test状态。本Sprint的目标是建立测试基准,验证核心系统质量,为后续开发奠定基础。

**Next Sprint Preview**: Sprint 2将专注于次要系统和UI系统的测试验证,以及修复Sprint 1中发现的任何问题。

---

**Created**: 2026-04-28
**Last Updated**: 2026-04-28