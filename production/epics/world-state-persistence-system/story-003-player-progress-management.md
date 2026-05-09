# Story 003: 玩家进度管理

> **Epic**: 世界状态持久化
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 10 hours
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/world-state-persistence-system.md`
**Requirement**: `TR-world-persist-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: 使用Godot 4.6引擎，Scene-Node架构模式，JSON格式本地存储，组件化设计。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Godot原生的Steamworks插件支持云存档功能，信号系统适合实现保存状态通知。

**Control Manifest Rules (this layer)**:
- Required: JSON format for local storage — human-readable, cross-platform compatible, supports version migration — source: ADR-001
- Required: Component-based design — implement functionality through script and node composition, not deep inheritance — source: ADR-001
- Forbidden: Never use string-based connect() — use typed signal connections for type safety and refactoring — source: Godot 4.6 best practices

---

## Acceptance Criteria

*From GDD `design/gdd/world-state-persistence-system.md`, scoped to this story:*

- [ ] 自动保存机制：实现在进入新区域、完成任务/奇遇、定期间隔（每游戏内30分钟或现实时间10分钟）时自动触发保存
- [ ] 手动保存支持：实现玩家在菜单中点击"保存游戏"或在土地庙/驿站选择"休息并保存"时的手动保存功能，支持3-5个存档槽位
- [ ] 关键事件强制保存：实现在进入Boss战前、主线剧情关键转折点后等关键事件时的强制保存
- [ ] Steam Cloud集成：集成Steamworks API实现云端同步，在保存成功后自动上传存档文件至Steam云服务器
- [ ] 云冲突检测和解决：实现云冲突检测机制，当检测到本地和云端版本不一致时提示玩家选择"覆盖本地"或"下载云端"
- [ ] 保存状态UI：在屏幕右下角显示微小的"保存中..."图标，不打断游戏流程，并在主菜单显示云同步状态

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 创建ProgressManager类，负责协调所有保存触发条件和管理存档槽位
- 实现AutoSaveManager子系统，监听游戏事件（区域切换、任务完成等）并触发自动保存
- 实现ManualSaveManager子系统，处理玩家手动保存请求和存档槽位管理
- 集成Steamworks API，使用Steam.remote_storage_file_write()和Steam.remote_storage_file_read()进行云同步
- 实现CloudConflictResolver，处理版本冲突并提供用户界面选项
- 创建SaveStatusUI组件，显示保存状态和云同步状态，使用Godot的CanvasLayer和Control节点
- 与WorldStateSaver和WorldStateLoader集成，确保保存和加载操作的一致性

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story 001]: 世界状态保存
- [Story 002]: 世界状态加载

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated unit/integration tests]:**

- **AC-1**: 自动保存机制
  - Setup: 触发自动保存条件（进入新区域、完成任务等）
  - Verify: ProgressManager正确触发保存操作，调用WorldStateSaver.save()
  - Pass condition: 自动保存在正确时机触发，不影响游戏流程

- **AC-2**: 手动保存支持
  - Setup: 玩家在菜单中选择保存或在土地庙交互
  - Verify: ManualSaveManager正确处理保存请求，管理多个存档槽位
  - Pass condition: 玩家可以创建和管理3-5个独立的存档槽位

- **AC-3**: 关键事件强制保存
  - Setup: 进入Boss战或主线剧情关键点
  - Verify: 强制保存被触发，确保重要进度不丢失
  - Pass condition: 关键事件后立即执行保存操作

- **AC-4**: Steam Cloud集成
  - Setup: 在支持Steam的环境中保存游戏
  - Verify: 存档文件成功上传至Steam云服务器
  - Pass condition: 云同步成功完成，显示绿色对勾图标

- **AC-5**: 云冲突检测和解决
  - Setup: 模拟本地和云端存档版本不一致的情况
  - Verify: 系统检测到冲突并显示解决对话框
  - Pass condition: 玩家可以选择"覆盖本地"或"下载云端"来解决冲突

- **AC-6**: 保存状态UI
  - Setup: 触发保存操作
  - Verify: 屏幕右下角显示"保存中..."图标，主菜单显示云同步状态
  - Pass condition: UI元素正确显示且不干扰游戏体验

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: Unit test file with 100% coverage (`tests/unit/progress_manager_test.gd`)
- Integration: Integration test verifying complete save/load/cloud sync cycle (`tests/integration/progress_management_integration_test.gd`)
- Visual/Feel: Manual test evidence document with screenshots (`production/qa/evidence/progress_management_ui_evidence.md`)

**Status**: [x] Completed - progress_manager.gd implemented and verified

---

## Dependencies

- Depends on: [Story 001], [Story 002]
- Unlocks: None