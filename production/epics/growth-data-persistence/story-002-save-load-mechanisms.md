# Story 002: 保存加载机制

> **Epic**: 成长数据保存
> **Status**: Pending Test
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/growth-data-persistence.md`
**Requirement**: `TR-grow-data-pers-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的FileAccess类实现数据的保存和加载，利用JSON格式存储数据

**Control Manifest Rules (this layer)**:
- Required: 保存加载机制必须确保数据完整性
- Forbidden: 禁止在保存过程中阻塞主线程
- Guardrail: 保存加载操作必须有超时和错误处理机制

---

## Acceptance Criteria

*From GDD `design/gdd/growth-data-persistence.md`, scoped to this story:*

- [x] 实现自动保存机制（角色升级、境界突破、属性分配等时机）
- [x] 实现手动保存功能（玩家主动保存）
- [x] 实现周期保存功能（每5分钟自动保存）
- [x] 实现数据加载功能（启动游戏和读取存档）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用SaveLoadManager节点管理保存加载逻辑
- 实现saveGrowthData(character: Character)方法保存角色成长数据
- 实现loadGrowthData(saveSlot: Integer)方法加载指定存档槽的成长数据
- 实现getAvailableSaves()方法获取可用存档列表
- 实现deleteSave(saveSlot: Integer)方法删除指定存档
- 与CharacterProgressionSystem、EquipmentSystem、MartialArtsSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 数据结构与存储（处理数据结构定义）
- Story 003: 数据完整性与安全（处理数据验证和加密）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现自动保存机制
  - Given: 玩家角色升级
  - When: 触发自动保存时机
  - Then: 成长数据被自动保存到存档文件
  - Edge cases: 快速连续升级、保存失败、磁盘空间不足

- **AC-2**: 实现手动保存功能
  - Given: 玩家选择手动保存
  - When: 点击保存按钮
  - Then: 当前成长数据被保存到指定存档槽
  - Edge cases: 存档槽已满、文件写入失败、权限问题

- **AC-3**: 实现周期保存功能
  - Given: 游戏运行超过5分钟
  - When: 周期保存计时器触发
  - Then: 自动执行一次数据保存
  - Edge cases: 游戏暂停、后台运行、计时器重置

- **AC-4**: 实现数据加载功能
  - Given: 存在有效的存档文件
  - When: 玩家选择读取存档
  - Then: 成长数据被正确加载并应用到角色
  - Edge cases: 存档损坏、版本不兼容、加载失败

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/persistence/save_load_mechanisms_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (数据结构与存储)
- Unlocks: Story 003 (数据完整性与安全)