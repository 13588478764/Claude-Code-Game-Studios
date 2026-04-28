# Story 001: 装备管理功能

> **Epic**: 装备系统
> **Status**: Pending Test
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/equipment-system.md`
**Requirement**: `TR-equipment-003`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的数据序列化功能管理装备状态，利用内置数据结构存储装备信息

**Control Manifest Rules (this layer)**:
- Required: 装备记录必须持久化，确保跨会话一致性
- Forbidden: 禁止在内存中存储关键装备状态
- Guardrail: 装备查询不应影响游戏性能

---

## Acceptance Criteria

*From GDD `design/gdd/equipment-system.md`, scoped to this story:*

- [x] 装备获取和存储功能正常（背包管理）
- [x] 装备筛选和排序机制正确（品阶、类型、属性）
- [x] 装备拆解和回收功能正常（资源返还）
- [x] 装备绑定机制正常（可交易/不可交易）

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用EquipmentManager节点管理所有装备逻辑
- 实现add_equipment(equipment_data)方法添加装备到背包
- 实现remove_equipment(equipment_id)方法从背包移除装备
- 实现get_equipment_by_filter(filter_params)方法筛选装备
- 实现sort_equipment(sort_params)方法排序装备
- 实现disassemble_equipment(equipment_id)方法拆解装备
- 实现bind_equipment(equipment_id)方法处理装备绑定
- 实现equipment_changed信号通知UI更新装备列表
- 与ItemDatabase和EconomyManager系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 装备穿戴系统（处理装备穿戴逻辑）
- Story 003: 装备属性计算（处理装备属性计算）
- UI界面（由UI团队处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 装备获取和存储功能正常
  - Given: 玩家获得一件上品剑（攻击力50-70）
  - When: 装备添加到背包
  - Then: 背包中显示该装备，数量正确
  - Edge cases: 背包满、重复装备叠加、装备损坏

- **AC-2**: 装备筛选和排序机制正确
  - Given: 背包中有多种品阶和类型的装备
  - When: 玩家选择按品阶筛选和攻击力排序
  - Then: 显示符合条件的装备，按攻击力降序排列
  - Edge cases: 筛选条件为空、排序字段不存在、大量装备

- **AC-3**: 装备拆解和回收功能正常
  - Given: 玩家选择一件多余装备
  - When: 执行拆解操作
  - Then: 获得相应数量的强化石、打孔钻和银两，装备从背包移除
  - Edge cases: 拆解绑定装备、拆解唯一装备、背包空间不足

- **AC-4**: 装备绑定机制正常
  - Given: 玩家获得任务奖励装备
  - When: 装备添加到背包
  - Then: 装备标记为绑定状态（不可交易）
  - Edge cases: 制造装备非绑定、手动绑定/解绑、交易行上架

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/equipment/equipment_management_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (装备穿戴系统), Story 003 (装备属性计算)