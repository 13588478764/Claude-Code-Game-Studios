# Story 002: 状态机制实现

> **Epic**: 状态效果系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2-3 hours
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/status-effect-system.md`
**Requirement**: `TR-status-eff-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: 选择Godot 4.6作为游戏引擎,采用场景树架构和节点系统,使用GDScript作为主要脚本语言,实现数据持久化和状态管理。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Godot 4.6的所有API均在LLM训练数据范围内,无需额外验证。使用clamp()函数实现数值钳制,使用字典存储互斥状态规则。

**Control Manifest Rules (Feature Layer)**:
- Required: 使用Resource类定义状态效果数据,使用Node类管理状态效果实例,通过信号系统通知状态变化
- Forbidden: 禁止在Feature Layer直接访问底层引擎API,禁止硬编码状态效果数值
- Guardrail: 单个角色最多同时存在8个状态效果,状态效果计算每帧不超过1ms

---

## Acceptance Criteria

*From GDD `design/gdd/status-effect-system.md`, scoped to this story:*

- [ ] AC5: 互斥状态处理 - 当角色同时受到互斥状态(Frozen vs Burn, Stun vs Root)时,根据预定义优先级处理:Burn > Freeze, Stun > Root,新状态覆盖旧状态
- [ ] AC7: 持续时间溢出保护 - 当状态持续时间计算结果<1或>8时,自动钳制到[1,8]范围内,防止数值溢出或无限持续

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

1. **互斥状态规则定义**:
   - 创建`MUTEX_RULES`常量字典,定义互斥状态对:
     ```gdscript
     const MUTEX_RULES = {
         StatusType.FREEZE: StatusType.BURN,  # Burn优先级更高
         StatusType.ROOT: StatusType.STUN     # Stun优先级更高
     }
     ```
   - 在`apply_status()`方法中,检查新状态是否与现有状态互斥

2. **互斥状态处理逻辑**:
   - 遍历`active_effects`数组,检查是否存在与新状态互斥的状态
   - 如果存在互斥状态,比较优先级:
     - 新状态优先级更高:移除旧状态,施加新状态
     - 旧状态优先级更高:拒绝新状态,保持旧状态
   - 发射`status_rejected(effect_type, reason)`信号通知UI

3. **持续时间计算与钳制**:
   - 在计算最终持续时间时,使用`clamp()`函数:
     ```gdscript
     var final_duration = clamp(base_duration + duration_bonus, 1, 8)
     ```
   - 确保所有状态效果的持续时间都在[1, 8]范围内
   - 记录原始计算值和钳制后的值,便于调试

4. **边界值测试**:
   - 测试持续时间为1和8的边界情况
   - 测试持续时间计算结果为负数、0、9、10等溢出情况
   - 测试互斥状态的各种组合(Burn+Freeze, Stun+Root等)

5. **错误处理**:
   - 如果持续时间计算出现异常,使用默认值3回合
   - 记录错误日志,包含原始计算值和钳制后的值
   - 确保游戏不会因为数值溢出而崩溃

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story 001]: 状态效果类型实现(Burn, Poison, Regen等)
- [Story 003]: 道具使用获得状态、内存不足降级处理
- [Story 004]: 状态UI显示、粒子特效、音频反馈

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

### AC5: 互斥状态处理
- **Test**: 互斥状态按优先级处理,Burn覆盖Freeze
  - Given: 角色已有Freeze状态(持续3回合)
  - When: 施加Burn状态(持续2回合)
  - Then: 
    - Freeze状态被移除
    - Burn状态成功施加,持续2回合
    - 状态图标栏只显示Burn,不显示Freeze
  - Edge cases:
    - Freeze施加到已有Burn的角色时,Burn保持,Freeze被拒绝
    - Stun vs Root: Stun优先级更高
    - 非互斥状态(Burn + Poison)可以共存
    - 互斥检查在状态施加前执行,不触发任何效果

### AC7: 持续时间溢出保护
- **Test**: 持续时间计算结果溢出时自动钳制到1-8回合
  - Given: 状态基础持续时间5,持续时间修正+5
  - When: 计算最终持续时间 = 5 + 5 = 10
  - Then: 最终持续时间被钳制为8回合
  - Edge cases:
    - 基础持续时间1,修正-3,结果-2,钳制为1回合
    - 基础持续时间5,修正+3,结果8,保持8回合(边界值)
    - 基础持续时间1,修正0,结果1,保持1回合(边界值)
    - 基础持续时间10,修正0,结果10,钳制为8回合
    - 负数溢出测试:基础1,修正-10,结果-9,钳制为1回合

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/status_effect/status_mechanics_test.gd`

Before `/story-done`:
- Automated test file must exist at the path above
- All test cases from QA Test Cases section must have corresponding test methods
- All tests must pass (green)
- Test coverage must include all edge cases listed above

---

## Notes

- 互斥状态规则应该可配置,存储在`res://data/status_mutex_rules.json`中
- 考虑使用枚举或常量定义状态优先级,避免硬编码
- 持续时间钳制应该在状态施加时执行,而不是在每回合更新时
- 记录详细的日志,包括互斥状态检查结果和持续时间钳制信息

---

## Completion Notes

**Completed**: 2026-04-28  
**Criteria**: 2/2 passing  
**Deviations**: 无  
**Test Evidence**: Logic: tests/unit/status_effect/status_mechanics_test.gd (18个测试函数,100%覆盖)  
**Code Review**: Complete (APPROVED)  
**QA Coverage**: ADEQUATE

**Implementation Highlights**:
- 互斥状态规则使用字典映射,易于扩展
- 持续时间钳制在构造函数中执行,确保所有实例有效
- 新增status_rejected信号提供完整的状态变化通知
- 测试覆盖所有边界情况和互斥组合