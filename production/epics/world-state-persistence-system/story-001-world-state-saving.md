# Story 001: 世界状态保存

> **Epic**: 世界状态持久化
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 8 hours
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/world-state-persistence-system.md`
**Requirement**: `TR-world-persist-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: 使用Godot 4.6引擎，Scene-Node架构模式，JSON格式本地存储，组件化设计。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Godot原生的FileAccess和JSON序列化功能适合数据持久化，异步I/O操作可避免主线程卡顿。

**Control Manifest Rules (this layer)**:
- Required: JSON format for local storage — human-readable, cross-platform compatible, supports version migration — source: ADR-001
- Required: Component-based design — implement functionality through script and node composition, not deep inheritance — source: ADR-001
- Forbidden: Never use string-based connect() — use typed signal connections for type safety and refactoring — source: Godot 4.6 best practices

---

## Acceptance Criteria

*From GDD `design/gdd/world-state-persistence-system.md`, scoped to this story:*

- [ ] 四类关键数据持久化：实现玩家核心状态、世界探索状态、任务与叙事进度、环境与实体状态的完整数据结构定义和序列化
- [ ] 结构化JSON格式：使用Godot的JSON序列化功能将游戏状态转换为结构化的JSON格式，确保人类可读性和跨平台兼容性
- [ ] 数据加密：对JSON内容进行Base64编码或XOR加密，防止玩家轻易修改存档作弊
- [ ] 异步I/O操作：使用Godot的后台线程或异步文件写入功能，避免在保存大量数据时造成主线程卡顿
- [ ] 差分存储支持：设计数据结构支持增量保存，只保存自上次保存以来发生变化的数据

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 创建WorldStateSaver类，负责处理所有四类数据的序列化和保存
- 实现SaveData结构体，包含PlayerCoreState、WorldExplorationState、QuestNarrativeProgress、EnvironmentEntityState四个子结构
- 使用Godot的JSON类进行序列化，确保输出格式符合GDD要求
- 实现简单的加密函数（Base64 + XOR），密钥可以从游戏版本或玩家ID派生
- 使用Thread或WorkerThreadPool实现异步文件写入，避免阻塞主线程
- 设计差分保存机制，通过比较当前状态和上次保存状态来确定需要保存的数据

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story 002]: 世界状态加载
- [Story 003]: 玩家进度管理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated unit/integration tests]:**

- **AC-1**: 四类关键数据持久化
  - Setup: 创建包含所有四类数据的测试场景
  - Verify: WorldStateSaver能够正确序列化所有数据类型
  - Pass condition: 所有数据字段都被正确包含在序列化输出中

- **AC-2**: 结构化JSON格式
  - Setup: 调用WorldStateSaver.save()方法
  - Verify: 输出的JSON字符串格式正确，可以通过JSON.parse()解析
  - Pass condition: JSON格式有效且结构清晰

- **AC-3**: 数据加密
  - Setup: 保存游戏状态到文件
  - Verify: 文件内容不是明文JSON，而是经过加密的字符串
  - Pass condition: 加密后的数据无法被直接阅读和修改

- **AC-4**: 异步I/O操作
  - Setup: 在主线程繁忙时调用保存功能
  - Verify: 游戏帧率不受影响，保存操作在后台完成
  - Pass condition: 主线程FPS保持稳定，保存完成后触发完成信号

- **AC-5**: 差分存储支持
  - Setup: 连续两次保存相同的游戏状态
  - Verify: 第二次保存的数据量显著小于第一次
  - Pass condition: 差分机制正确识别未变化的数据并跳过保存

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: Unit test file with 100% coverage (`tests/unit/world_state_saver_test.gd`)
- Integration: Integration test verifying save/load cycle (`tests/integration/world_persistence_integration_test.gd`)

**Status**: [x] Completed - world_state_saver.gd implemented and verified

---

## Dependencies

- Depends on: None
- Unlocks: [Story 002]