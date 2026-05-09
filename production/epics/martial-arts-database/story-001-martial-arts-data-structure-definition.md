# Story 001: 武学数据结构定义

> **Epic**: 武学数据库
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/martial-arts-database.md`
**Requirement**: `TR-martial-arts-db-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的Resource系统定义武学数据结构

**Control Manifest Rules (this layer)**:
- Required: 武学数据结构必须遵循GDD中定义的核心属性和分类规则
- Forbidden: 禁止在数据结构中使用硬编码的数值
- Guardrail: 数据结构应支持扩展而不破坏向后兼容性

---

## Acceptance Criteria

*From GDD `design/gdd/martial-arts-database.md`, scoped to this story:*

- [x] 定义武学核心属性（基础信息、消耗与限制、战斗参数、时序控制、视觉与听觉）
- [x] 实现武学分类系统（主要类型、武器类型、门派/流派、品阶）
- [x] 创建MartialArtData基类
- [x] 实现数据验证机制

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用Godot的Resource系统创建MartialArtData类
- 实现武学核心属性的定义（id, name, description, icon等）
- 实现消耗与限制属性（cost_stamina, cost_mana, cooldown等）
- 实现战斗参数（damage_base, damage_scale, hit_count等）
- 实现时序控制属性（startup_frames, active_frames, recovery_frames等）
- 实现视觉与听觉资源引用（vfx_prefab, sfx_hit, sfx_cast等）
- 创建枚举类型定义武学分类

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 武学属性存储：由Story 002处理
- 数据访问接口：由Story 003处理
- UI显示：由UI故事处理

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 定义武学核心属性
  - Given: 创建一个新的武学数据实例
  - When: 设置所有核心属性
  - Then: 所有属性都能正确存储和访问
  - Edge cases: 检查边界值和无效输入

- **AC-2**: 实现武学分类系统
  - Given: 武学分类枚举定义
  - When: 为武学分配分类标签
  - Then: 正确应用主要类型、武器类型、门派/流派、品阶
  - Edge cases: 检查无效分类值

- **AC-3**: 创建MartialArtData基类
  - Given: Godot Resource系统
  - When: 定义MartialArtData类
  - Then: 类继承自Resource并包含所有必需属性
  - Edge cases: 检查继承和序列化功能

- **AC-4**: 实现数据验证机制
  - Given: 武学数据实例
  - When: 验证数据完整性
  - Then: 检测并标记无效或缺失的数据
  - Edge cases: 检查各种无效数据组合

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Unit: `tests/unit/martial_arts_database/martial_arts_data_structure_definition_test.gd` — must exist and pass

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (武学属性存储), Story 003 (数据访问接口)