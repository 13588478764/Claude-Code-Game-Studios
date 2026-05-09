# Story 002: 世界状态加载

> **Epic**: 世界状态持久化
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 6 hours
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/world-state-persistence-system.md`
**Requirement**: `TR-world-persist-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: 使用Godot 4.6引擎，Scene-Node架构模式，JSON格式本地存储，组件化设计。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Godot原生的FileAccess和JSON反序列化功能适合数据加载，错误处理机制可确保存档损坏时的安全恢复。

**Control Manifest Rules (this layer)**:
- Required: JSON format for local storage — human-readable, cross-platform compatible, supports version migration — source: ADR-001
- Required: Component-based design — implement functionality through script and node composition, not deep inheritance — source: ADR-001
- Forbidden: Never use string-based connect() — use typed signal connections for type safety and refactoring — source: Godot 4.6 best practices

---

## Acceptance Criteria

*From GDD `design/gdd/world-state-persistence-system.md`, scoped to this story:*

- [ ] 存档文件读取和解析：实现从本地存储读取加密的存档文件，并正确解密和解析JSON内容
- [ ] JSON格式验证：在加载过程中验证JSON格式的有效性，确保数据完整性
- [ ] 损坏检测和恢复：实现存档损坏检测机制，当主存档损坏时自动尝试从最近3个备份文件中恢复
- [ ] 版本兼容性处理：支持不同游戏版本的存档加载，处理字段缺失或格式变化的情况
- [ ] 异步加载：使用异步I/O操作避免加载大存档时的主线程卡顿

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 创建WorldStateLoader类，负责处理存档文件的读取、解密和反序列化
- 实现存档验证函数，检查JSON格式和必需字段的存在性
- 设计备份恢复机制，在主存档损坏时按时间顺序尝试加载备份文件
- 实现版本兼容性层，处理不同游戏版本间的存档格式差异
- 使用Thread或WorkerThreadPool实现异步文件读取，避免阻塞主线程
- 与WorldStateSaver类配合，确保保存和加载的数据结构完全匹配

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story 001]: 世界状态保存
- [Story 003]: 玩家进度管理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated unit/integration tests]:**

- **AC-1**: 存档文件读取和解析
  - Setup: 创建有效的加密存档文件
  - Verify: WorldStateLoader能够正确读取、解密和解析存档内容
  - Pass condition: 所有数据字段都被正确还原到内存中

- **AC-2**: JSON格式验证
  - Setup: 创建格式无效的存档文件（缺少必需字段或语法错误）
  - Verify: 加载器能够检测到格式错误并返回适当的错误代码
  - Pass condition: 无效存档被正确识别，不会导致程序崩溃

- **AC-3**: 损坏检测和恢复
  - Setup: 损坏主存档文件，但保留有效的备份文件
  - Verify: 加载器自动检测主存档损坏并成功从备份文件恢复
  - Pass condition: 游戏状态从备份文件正确加载，玩家进度得到保护

- **AC-4**: 版本兼容性处理
  - Setup: 创建旧版本格式的存档文件
  - Verify: 加载器能够正确处理字段缺失或格式变化
  - Pass condition: 旧版本存档成功加载，缺失字段使用默认值填充

- **AC-5**: 异步加载
  - Setup: 在主线程繁忙时调用加载功能
  - Verify: 游戏帧率不受影响，加载操作在后台完成
  - Pass condition: 主线程FPS保持稳定，加载完成后触发完成信号

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: Unit test file with 100% coverage (`tests/unit/world_state_loader_test.gd`)
- Integration: Integration test verifying save/load cycle (`tests/integration/world_persistence_integration_test.gd`)

**Status**: [x] Completed - world_state_loader.gd implemented and verified

---

## Dependencies

- Depends on: [Story 001]
- Unlocks: [Story 003]