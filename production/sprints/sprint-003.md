# Sprint 3 — 2026-05-13 to 2026-05-27

## Sprint Goal
将已实现的UI面板接入游戏循环，添加战斗操作UI替代自动战斗，接通存档系统，使游戏体验从"可跑通"进化为"可玩"

## Capacity
- **Total days**: 14
- **Buffer (20%)**: 3 days (reserved for unplanned work)
- **Available**: 11 days

---

## Tasks

### Must Have (Critical Path)

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|-------------------|
| 3-01 | 探索面板接入快捷键面板系统 | Gameplay Programmer | 1 | None | 探索状态下按 I 打开背包、E 打开装备、ESC 打开暂停菜单、M 打开大地图、F1 打开帮助，面板互斥（同时只开一个），再按关闭 |
| 3-02 | 暂停菜单接入游戏循环 | UI Programmer | 0.5 | 3-01 | ESC 弹出暂停菜单，"继续游戏"关闭面板，"设置"打开设置面板，"返回主菜单"回到主菜单，暂停时游戏逻辑暂停 |
| 3-03 | 背包面板数据绑定 | Gameplay Programmer | 1 | 3-01 | 打开背包可查看已获得物品，物品从奇遇/战斗奖励进入背包，显示物品名称/数量/描述 |
| 3-04 | 装备面板数据绑定 | Gameplay Programmer | 1 | 3-03 | 从背包装备物品到槽位，装备后属性变化反映到角色面板，卸下装备回到背包 |
| 3-05 | 战斗操作UI | UI Programmer | 1.5 | None | 战斗时显示操作面板（攻击/技能/防御），玩家选择行动后执行，敌人仍为自动AI，显示双方HP条 |
| 3-06 | 存档/读档系统接入 | Gameplay Programmer | 1.5 | None | "开始新游戏"创建新存档，探索中可在暂停菜单保存，主菜单"加载游戏"恢复进度（等级/经验/银两/区域） |

**Total**: 6.5 days

### Should Have

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|-------------------|
| 3-07 | 角色面板接入（探索时可查看） | UI Programmer | 0.5 | 3-01 | 按 C 打开角色面板，显示属性/境界/经验，可分配属性点 |
| 3-08 | 大地图数据绑定 | Gameplay Programmer | 1 | 3-01 | 大地图显示4个区域，点击区域可切换（替代探索面板的按钮列表），已解锁区域高亮 |
| 3-09 | 设置面板持久化 | UI Programmer | 0.5 | 3-02 | 音量/分辨率/全屏设置修改后保存到配置文件，重启游戏生效 |

**Total**: 2 days

### Nice to Have

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|-------------------|
| 3-10 | 战斗日志面板 | UI Programmer | 0.5 | 3-05 | 战斗中显示滚动日志（谁攻击谁、伤害值、状态变化） |
| 3-11 | ADR-006 奇遇架构审核 | Architecture | 0.5 | None | (Sprint 2 延迟) |
| 3-12 | ADR-007 对话架构审核 | Architecture | 0.5 | None | (Sprint 2 延迟) |

**Total**: 1.5 days

---

## Carryover from Sprint 2

| Task | Reason | New Estimate |
|------|--------|-------------|
| S2-13 ADR-006奇遇架构审核 | 延迟 | 0.5 days |
| S2-14 ADR-007对话架构审核 | 延迟 | 0.5 days |

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| UI面板接入需要修改多个系统 | Medium | Medium | 通过统一的面板管理器集中控制，减少散落的信号连接 |
| 战斗UI与CombatManager适配复杂 | Medium | High | 利用已有的execute_action() API，只需替换自动战斗的调用方为UI按钮 |
| 存档数据结构跨系统依赖 | Medium | Medium | MVP只存关键数据（等级/经验/银两/区域），不存完整状态 |

---

## Dependencies on External Factors
- Sprint 2 所有 UI 场景已实现
- MVP 核心循环已串联（Sprint 2 额外完成）
- CombatManager.execute_action() API 已验证可用

---

## Definition of Done for this Sprint
- [ ] 所有 Must Have 任务完成
- [ ] 所有任务通过验收标准
- [ ] 相关集成测试通过
- [ ] 无 S1 或 S2 级别 bug
- [ ] 代码已审查并合并

---

> ⚠️ **No QA Plan**: This sprint was started without a QA plan. Run `/qa-plan sprint`
> before the last story is implemented. The Production → Polish gate requires a QA
> sign-off report, which requires a QA plan.

---

**Created**: 2026-05-12
**Last Updated**: 2026-05-12
