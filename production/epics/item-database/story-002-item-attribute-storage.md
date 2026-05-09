# Story 002: 物品属性存储

> **Epic**: 物品数据库
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/item-database.md`
**Requirement**: `TR-item-db-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的Resource系统和.tres文件进行数据持久化

**Control Manifest Rules (this layer)**:
- Required: 物品数据存储必须遵循GDD中定义的结构
- Forbidden: 禁止在存储过程中修改数据结构
- Guardrail: 存储系统必须支持版本控制和向后兼容

---

## Acceptance Criteria

*From GDD `design/gdd/item-database.md`, scoped to this story:*

- [x] 实现物品数据的.tres文件存储
- [x] 实现物品数据的JSON序列化（Web优化）
- [x] 实现数据分片与懒加载机制
- [x] 实现物品数据的验证与错误处理

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用Godot的ResourceSaver.save()方法保存物品数据
- 实现ItemDataManager单例管理物品数据
- 实现load_item_data()方法加载物品数据
- 实现save_item_data()方法保存物品数据
- 实现validate_item_data()方法验证数据完整性
- 与UI系统、装备系统、武学系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 物品数据结构定义（处理数据结构定义）
- Story 003: 数据访问接口（处理数据查询和检索）
- UI显示（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 实现物品数据的.tres文件存储
  - Given: 定义了一个物品数据实例
  - When: 保存物品数据到.tres文件
  - Then: 正确保存到指定路径且数据完整
  - Edge cases: 文件路径不存在、权限不足、磁盘空间不足

- **AC-2**: 实现物品数据的JSON序列化
  - Given: 物品数据需要在Web平台使用
  - When: 将.tres数据转换为JSON格式
  - Then: 生成压缩的JSON文件且数据结构保持不变
  - Edge cases: 数据过大、特殊字符、嵌套层级过深

- **AC-3**: 实现数据分片与懒加载机制
  - Given: 游戏启动时内存有限
  - When: 加载物品数据
  - Then: 按需加载相关数据，基础物品优先加载
  - Edge cases: 分片文件缺失、加载超时、内存不足

- **AC-4**: 实现物品数据的验证与错误处理
  - Given: 物品数据文件可能损坏或缺失
  - When: 加载物品数据时
  - Then: 使用默认数据确保游戏可玩并记录错误日志
  - Edge cases: 文件格式错误、属性值超出范围、引用资源丢失

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/data/item_attribute_storage_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (物品数据结构定义)
- Unlocks: Story 003 (数据访问接口)