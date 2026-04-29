# QA 测试计划 - Sprint 1

**生成日期**: 2026-04-28  
**Sprint**: Sprint 1  
**时间范围**: 2026-04-28 至 2026-05-11  
**QA Lead**: QA Team  
**状态**: Ready for Execution

---

## 执行摘要

Sprint 1 的目标是验证核心游戏系统的实现质量，建立测试基准，为后续开发奠定质量基础。本测试计划覆盖 30 个故事，包括 18 个 Must Have、9 个 Should Have 和 9 个 Nice to Have 故事。

**关键指标**:
- 总故事数: 30
- 自动化测试故事: 24 (Logic + Integration)
- 手动 QA 故事: 6 (UI + Visual/Feel)
- 预计工作量: 3-5 天
- 冒烟检查: PASS WITH WARNINGS (需要创建冒烟测试)

---

## 1. 范围定义

### 1.1 包含的系统

| 系统 | 故事数 | 优先级 | 测试类型 |
|------|--------|--------|---------|
| 战斗系统 | 3 | Must Have | Logic |
| 角色成长系统 | 6 | Must Have | Logic + Integration + UI |
| 技能树系统 | 3 | Must Have | Logic + UI |
| 武学系统 | 4 | Must Have | Logic + Integration |
| 装备系统 | 3 | Must Have | Logic + Integration |
| 经济系统 | 3 | Should Have | Logic |
| 任务系统 | 3 | Should Have | Logic + Integration |
| 小地图系统 | 3 | Should Have | Logic + UI |
| 战斗 UI | 3 | Nice to Have | UI |
| 装备 UI | 3 | Nice to Have | UI |

### 1.2 不在范围内

- 性能优化测试 (将在 Polish 阶段进行)
- 网络多人游戏测试 (不在 MVP 范围内)
- 本地化测试 (将在 Release 阶段进行)
- 安全审计 (将在 Release 阶段进行)

---

## 2. 故事分类与测试策略

### 2.1 按类型分类

#### Logic 类型 (18 个故事) - 自动化测试

需要编写单元测试或集成测试，验证核心逻辑的正确性。

**故事列表**:
- combat-001: 战斗机制
- combat-002: 弱点系统
- combat-003: 战斗连携系统
- char-prog-001: 角色升级
- char-prog-002: 属性分配
- char-prog-003: 天赋网格
- skill-tree-001: 学习路径类型
- skill-tree-002: 解锁机制
- martial-arts-001: 武学获取
- martial-arts-002: 武学熟练度
- martial-arts-004: 武学连招
- equipment-001: 装备管理
- equipment-003: 装备属性计算
- economy-001: 货币管理
- economy-003: 价格平衡
- minimap-002: 已探索区域标记

**测试要求**:
- 每个故事必须有对应的测试文件在 `tests/unit/` 或 `tests/integration/`
- 测试覆盖所有接受标准
- 测试必须通过 (PASS)

#### Integration 类型 (6 个故事) - 自动化 + 手动

需要编写集成测试验证系统间的交互，同时需要手动 QA 验证整体流程。

**故事列表**:
- char-prog-004: 奇遇集成
- char-prog-005: 角色成长UI (实际是 UI 类型)
- martial-arts-003: 武学使用
- equipment-002: 装备穿戴
- quest-002: 任务追踪系统
- quest-003: 任务奖励分配

**测试要求**:
- 编写集成测试验证系统交互
- 手动 QA 验证整体流程和用户体验
- 测试必须通过 (PASS)

#### UI 类型 (4 个故事) - 手动 QA

需要手动验证 UI 界面的布局、交互和视觉效果。

**故事列表**:
- char-prog-005: 角色成长UI
- skill-tree-003: 可视化与交互
- minimap-001: 玩家位置显示
- minimap-003: 导航标记系统
- combat-ui-001: 战斗HUD显示
- combat-ui-002: 战斗菜单交互
- combat-ui-003: 战斗反馈系统
- equipment-ui-001: 装备界面布局
- equipment-ui-002: 装备交互
- equipment-ui-003: 视觉反馈和效果

**测试要求**:
- 手动验证 UI 布局和交互
- 验证所有接受标准
- 记录截图和测试结果

#### Visual/Feel 类型 (2 个故事) - 手动 QA

需要手动验证游戏的视觉效果和感受。

**故事列表**:
- char-prog-006: 奇遇UI
- status-effect-system-004: 状态UI视觉反馈 (如果在范围内)

**测试要求**:
- 手动验证视觉效果和游戏感受
- 验证所有接受标准
- 记录截图和测试结果

### 2.2 优先级分布

| 优先级 | 故事数 | 测试策略 |
|--------|--------|---------|
| Must Have | 18 | 必须全部通过 (PASS) |
| Should Have | 9 | 应该全部通过，允许 PASS WITH NOTES |
| Nice to Have | 3 | 可以 PASS 或 SKIP |

---

## 3. 自动化测试需求

### 3.1 测试文件位置

所有自动化测试文件应位于以下目录：

```
tests/
├── unit/
│   ├── combat/
│   ├── character/
│   ├── equipment/
│   ├── economy/
│   ├── quest/
│   └── ...
└── integration/
    ├── combat/
    ├── character/
    ├── equipment/
    └── ...
```

### 3.2 测试框架

- **框架**: GUT (Godot Unit Test)
- **配置**: `addons/gut/` (已配置)
- **运行方式**: 
  - 编辑器内运行: `Tools > GUT > Run Tests`
  - 命令行运行: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests`

### 3.3 测试覆盖率目标

- **Logic 故事**: 100% 接受标准覆盖
- **Integration 故事**: 100% 接受标准覆盖
- **整体目标**: ≥ 70% 代码覆盖率

---

## 4. 手动 QA 范围

### 4.1 手动 QA 故事

以下 6 个故事需要手动 QA：

| 故事 ID | 故事名称 | 类型 | 验证内容 |
|---------|---------|------|---------|
| char-prog-005 | 角色成长UI | UI | UI 布局、交互、数据显示 |
| char-prog-006 | 奇遇UI | Visual/Feel | 视觉效果、动画、反馈 |
| skill-tree-003 | 可视化与交互 | UI | 技能树显示、交互、解锁效果 |
| minimap-001 | 玩家位置显示 | UI | 小地图显示、玩家位置、更新 |
| minimap-003 | 导航标记系统 | UI | 标记显示、交互、清除 |
| combat-ui-* | 战斗 UI (3 个) | UI | HUD 显示、菜单交互、反馈效果 |

### 4.2 手动 QA 流程

1. **准备阶段**:
   - 启动游戏
   - 进入相应的游戏场景
   - 准备测试数据

2. **执行阶段**:
   - 按照测试用例执行操作
   - 记录实际结果
   - 拍摄截图（如需要）

3. **验证阶段**:
   - 验证所有接受标准
   - 检查边界情况
   - 记录任何异常

4. **报告阶段**:
   - 标记为 PASS / FAIL / PASS WITH NOTES
   - 如果 FAIL，创建 bug 报告

---

## 5. 入场标准 (Entry Criteria)

QA 开始前，必须满足以下条件：

- [ ] 所有代码已提交到版本控制
- [ ] 项目可以成功编译和运行
- [ ] 所有 Must Have 故事的代码已实现
- [ ] 冒烟测试通过 (或创建冒烟测试)
- [ ] 测试环境已准备好 (GUT 框架已配置)
- [ ] QA 团队已获得所有必要的文档和访问权限

---

## 6. 出场标准 (Exit Criteria)

QA 完成的条件：

- [ ] 所有 Must Have 故事的自动化测试通过 (PASS)
- [ ] 所有 Must Have 故事的手动 QA 完成 (PASS 或 PASS WITH NOTES)
- [ ] 所有 Should Have 故事的测试完成 (PASS 或 PASS WITH NOTES)
- [ ] 所有 S1/S2 级别的 bug 已修复或有明确的解决方案
- [ ] QA 签署报告已生成并获得批准
- [ ] 测试证据已收集并存档

---

## 7. 测试执行计划

### 7.1 时间表

| 阶段 | 日期 | 工作内容 | 负责人 |
|------|------|---------|--------|
| 准备 | 2026-04-28 | 创建冒烟测试，准备测试环境 | QA Lead |
| 自动化测试 | 2026-04-29 至 2026-05-01 | 运行自动化测试，修复失败的测试 | QA Tester |
| 手动 QA | 2026-05-02 至 2026-05-05 | 执行手动 QA，记录结果 | QA Tester |
| Bug 修复 | 2026-05-06 至 2026-05-08 | 修复发现的 bug | Dev Team |
| 回归测试 | 2026-05-09 至 2026-05-10 | 验证 bug 修复 | QA Tester |
| 签署 | 2026-05-11 | 生成 QA 签署报告 | QA Lead |

### 7.2 资源分配

- **QA Lead**: 1 人 (策略、计划、签署)
- **QA Tester**: 2 人 (测试执行、bug 报告)
- **Dev Team**: 根据需要 (bug 修复)

---

## 8. 风险与缓解措施

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|---------|
| 自动化测试失败率高 | 延迟 QA 进度 | 中 | 提前创建冒烟测试，识别关键问题 |
| 手动 QA 工作量超出预期 | 延迟完成时间 | 中 | 优先测试 Must Have 故事 |
| 发现大量 S1/S2 bug | 需要返工 | 低 | 在 QA 前进行代码审查 |
| 测试环境不稳定 | 影响测试执行 | 低 | 准备备用测试环境 |

---

## 9. 报告与沟通

### 9.1 日报

每天下午 5 点生成日报，包括：
- 当天完成的测试数量
- 发现的 bug 数量和严重级别
- 阻塞问题
- 明天的计划

### 9.2 周报

每周五生成周报，包括：
- 周完成的测试数量
- 总体进度
- 关键发现
- 下周计划

### 9.3 最终报告

QA 完成后生成最终的 QA 签署报告，包括：
- 测试覆盖率
- Bug 统计
- 最终建议 (APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED)

---

## 10. 附录：故事详细列表

### Must Have 故事 (18 个)

#### 战斗系统 (3 个)
1. **combat-001**: 战斗机制 - Logic - 自动化测试
2. **combat-002**: 弱点系统 - Logic - 自动化测试
3. **combat-003**: 战斗连携系统 - Logic - 自动化测试

#### 角色成长系统 (6 个)
4. **char-prog-001**: 角色升级 - Logic - 自动化测试
5. **char-prog-002**: 属性分配 - Logic - 自动化测试
6. **char-prog-003**: 天赋网格 - Logic - 自动化测试
7. **char-prog-004**: 奇遇集成 - Integration - 自动化 + 手动
8. **char-prog-005**: 角色成长UI - UI - 手动 QA
9. **char-prog-006**: 奇遇UI - Visual/Feel - 手动 QA

#### 技能树系统 (3 个)
10. **skill-tree-001**: 学习路径类型 - Logic - 自动化测试
11. **skill-tree-002**: 解锁机制 - Logic - 自动化测试
12. **skill-tree-003**: 可视化与交互 - UI - 手动 QA

#### 武学系统 (4 个)
13. **martial-arts-001**: 武学获取 - Logic - 自动化测试
14. **martial-arts-002**: 武学熟练度 - Logic - 自动化测试
15. **martial-arts-003**: 武学使用 - Integration - 自动化 + 手动
16. **martial-arts-004**: 武学连招 - Logic - 自动化测试

#### 装备系统 (3 个)
17. **equipment-001**: 装备管理 - Logic - 自动化测试
18. **equipment-002**: 装备穿戴 - Integration - 自动化 + 手动
19. **equipment-003**: 装备属性计算 - Logic - 自动化测试

### Should Have 故事 (9 个)

#### 经济系统 (3 个)
20. **economy-001**: 货币管理 - Logic - 自动化测试
21. **economy-002**: 交易系统 - Integration - 自动化 + 手动
22. **economy-003**: 价格平衡 - Logic - 自动化测试

#### 任务系统 (3 个)
23. **quest-001**: 任务状态管理 - Logic - 自动化测试
24. **quest-002**: 任务追踪系统 - Integration - 自动化 + 手动
25. **quest-003**: 任务奖励分配 - Integration - 自动化 + 手动

#### 小地图系统 (3 个)
26. **minimap-001**: 玩家位置显示 - UI - 手动 QA
27. **minimap-002**: 已探索区域标记 - Logic - 自动化测试
28. **minimap-003**: 导航标记系统 - UI - 手动 QA

### Nice to Have 故事 (3 个)

#### 战斗 UI (3 个)
29. **combat-ui-001**: 战斗HUD显示 - UI - 手动 QA
30. **combat-ui-002**: 战斗菜单交互 - UI - 手动 QA
31. **combat-ui-003**: 战斗反馈系统 - UI - 手动 QA

#### 装备 UI (3 个)
32. **equipment-ui-001**: 装备界面布局 - UI - 手动 QA
33. **equipment-ui-002**: 装备交互 - UI - 手动 QA
34. **equipment-ui-003**: 视觉反馈和效果 - UI - 手动 QA

---

## 11. 批准与签署

| 角色 | 名称 | 签署 | 日期 |
|------|------|------|------|
| QA Lead | — | [ ] | — |
| Project Manager | — | [ ] | — |

---

**文档版本**: 1.0  
**最后更新**: 2026-04-28  
**下一次审查**: 2026-05-11