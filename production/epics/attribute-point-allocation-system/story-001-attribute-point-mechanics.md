# Story 001: 属性点机制

> **Epic**: 属性点分配系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/attribute-point-allocation-system.md`
**Requirement**: `TR-char-progression-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的信号系统处理属性变更事件，利用内置数据结构管理属性点

**Control Manifest Rules (this layer)**:
- Required: 属性点分配必须验证可用点数，确保不超过限制
- Forbidden: 禁止在内存中存储关键属性状态
- Guardrail: 属性分配不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/attribute-point-allocation-system.md`, scoped to this story:*

- [x] 属性点获取机制正常（升级获得属性点）
- [x] 属性点分配规则正确（每升1级获得5点）
- [x] 属性体系实现（六维属性：力道、身法、根骨、悟性、定力、福缘）
- [x] 属性点数据结构正确（存储和管理）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用AttributePointManager节点管理属性点逻辑
- 实现allocate_point(attribute_type)方法分配属性点
- 实现get_available_points()方法获取可用属性点数
- 实现get_attribute_value(attribute_type)方法获取属性值
- 实现attribute_allocated信号通知其他系统
- 与CharacterProgressionSystem和BattleManager系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 属性点分配（处理UI界面和用户交互）
- Story 003: 属性点验证（处理分配验证和重置机制）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 属性点获取机制正常
  - Given: 玩家角色升级到第2级
  - When: 系统处理升级事件
  - Then: 玩家获得5点自由属性点
  - Edge cases: 不同等级、境界突破、批量升级

- **AC-2**: 属性点分配规则正确
  - Given: 玩家拥有5点可用属性点
  - When: 分配1点到力道属性
  - Then: 力道属性值增加1，可用点数减少1
  - Edge cases: 超出上限、负数分配、零分配

- **AC-3**: 属性体系实现
  - Given: 玩家角色具有六维属性
  - When: 查询任意属性值
  - Then: 返回正确的属性值（力道、身法、根骨、悟性、定力、福缘）
  - Edge cases: 属性值为0、属性值达到上限、属性值负数

- **AC-4**: 属性点数据结构正确
  - Given: 玩家角色拥有属性点数据
  - When: 保存和加载游戏
  - Then: 属性点数据正确保存和恢复
  - Edge cases: 数据损坏、版本迁移、存档格式

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/character/attribute_point_mechanics_test.gd` — must exist and pass

**Status**: [x] Completed

---

## Dependencies

- Unlocks: Story 002 (属性点分配), Story 003 (属性点验证)