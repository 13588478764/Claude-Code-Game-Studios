# Story 002: 查询与显示系统

> **Epic**: 奇遇历史记录系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: UI
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/encounter-history-record-system.md`
**Requirement**: `TR-enc-hist-rec-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的UI系统实现图鉴式界面，利用数据结构提供查询功能

**Control Manifest Rules (this layer)**:
- Required: UI查询响应时间不超过100ms
- Forbidden: 禁止在UI查询中阻塞主线程
- Guardrail: 界面渲染不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/encounter-history-record-system.md`, scoped to this story:*

- [x] 图鉴式UI界面正确显示（左侧列表+右侧详情）
- [x] 筛选和排序功能正常（类型筛选、时间排序）
- [x] 搜索功能正常（字符串匹配）
- [x] 视觉反馈正确（稀有度着色、新纪录标记）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用HistoryDisplayManager节点管理历史记录显示
- 实现show_history_interface()方法显示图鉴式UI
- 实现display_encounter_list(history_records)方法显示左侧列表
- 实现display_encounter_detail(selected_record)方法显示右侧详情
- 实现filter_by_type(filter_type)方法实现类型筛选
- 实现sort_by_timestamp(sort_order)方法实现时间排序
- 实现search_records(search_term)方法实现搜索功能
- 实现apply_visual_feedback(record_data)方法应用视觉反馈
- 实现history_displayed信号通知其他系统
- 与UISystem、HistoryLogger和EncounterDB系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 历史记录机制（处理记录生成逻辑）
- Story 003: 数据持久化与管理（处理存档和加载逻辑）
- 核心数据结构（由数据管理处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For UI stories — evidence specs]:**

- **AC-1**: 图鉴式UI界面正确显示
  - Given: 玩家打开奇遇历史记录界面
  - When: 界面加载完成
  - Then: 显示左侧列表+右侧详情的双面板布局
  - Edge cases: 不同分辨率、UI缩放、窗口模式

- **AC-2**: 筛选和排序功能正常
  - Given: 奇遇历史记录中有多种类型
  - When: 玩家选择"战斗"类型筛选
  - Then: 列表只显示战斗类型奇遇
  - Edge cases: 多种筛选条件、排序切换、空结果

- **AC-3**: 搜索功能正常
  - Given: 奇遇历史记录中有多个条目
  - When: 玩家输入搜索词"老者"
  - Then: 列表只显示标题包含"老者"的记录
  - Edge cases: 大小写敏感、特殊字符、模糊匹配

- **AC-4**: 视觉反馈正确
  - Given: 玩家触发了一个稀有奇遇
  - When: 在历史记录中查看
  - Then: 标题显示为金色并有"NEW"标签
  - Edge cases: 不同稀有度、标签消失、图标显示

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- Evidence: `production/qa/evidence/query-and-display-system-evidence.md` — must exist and pass

**Status**: [x] Completed

---

## Dependencies

- Depends on: Story 001 (历史记录机制)
- Unlocks: Story 003 (数据持久化与管理)